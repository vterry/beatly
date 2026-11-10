import 'dart:async';

import 'package:flutter/services.dart';

import '../../../domain/contracts/clock_port.dart';
import '../../../domain/contracts/metronome_audio_port.dart';
import '../../../domain/models/beat_emphasis.dart';
import 'pcm_sound_cache.dart';

/// Implementação de [MetronomeAudioPort] para Android com baixa latência e controle de AudioFocus (ADR-002 / ADR-006 / EC-05).
///
/// Integra-se com o motor nativo Kotlin (`BeatlyAudioEngine`) através do canal `com.beatly.app/audio`,
/// garantindo precisão sample-accurate via AudioTrack e controle de AudioFocus.
/// Em ambientes onde o motor nativo não está disponível (ex: testes de unidade fora do Android),
/// mantém fallback suave e transparente via [PcmSoundCache] e [ClockPort].
class AndroidMetronomeAudioService implements MetronomeAudioPort {
  AndroidMetronomeAudioService({
    required PcmSoundCache soundCache,
    required ClockPort clockPort,
    MethodChannel? channel,
  })  : _soundCache = soundCache,
        _clockPort = clockPort,
        _channel = channel ?? const MethodChannel('com.beatly.app/audio') {
    try {
      _channel.setMethodCallHandler(_handleNativeCall);
    } catch (_) {
      // Ignora silenciosamente em testes puros sem WidgetsBinding inicializado
    }
  }

  final PcmSoundCache _soundCache;
  final ClockPort _clockPort;
  final MethodChannel _channel;

  bool _isRunning = false;
  bool _hasAudioFocus = true;
  int _bpm = 120;
  int _subdivision = 1;
  List<BeatEmphasis> _pattern = const <BeatEmphasis>[];
  int _beatIndex = 0;
  int _subdivisionIndex = 0;
  StreamSubscription<int>? _tickSubscription;

  /// Callback disparado quando uma amostra PCM é emitida (útil para instrumentação e testes).
  void Function(String sampleKey, double volume)? onSamplePlayed;

  /// Callback disparado quando o app perde o foco de áudio (EC-05).
  void Function()? onAudioFocusLost;

  bool get isRunning => _isRunning;
  bool get hasAudioFocus => _hasAudioFocus;
  int get currentBpm => _bpm;
  int get currentSubdivision => _subdivision;
  List<BeatEmphasis> get currentPattern =>
      List<BeatEmphasis>.unmodifiable(_pattern);

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onAudioFocusLost':
        handleAudioFocusChange(gained: false);
        break;
    }
  }

  Future<void> _invokeNativeSafe(String method, [dynamic arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } catch (_) {
      // Ignora silenciosamente em testes de unidade ou ambientes sem o host Android
    }
  }

  @override
  Future<void> initialize() async {
    if (!_soundCache.isLoaded) {
      await _soundCache.preloadAll();
    }
    _hasAudioFocus = true;
    await _invokeNativeSafe('initialize');
  }

  @override
  Future<void> start({
    required int bpm,
    required List<BeatEmphasis> pattern,
    int subdivision = 1,
  }) async {
    await stop();
    _bpm = bpm;
    _pattern = List<BeatEmphasis>.from(pattern);
    _subdivision = subdivision.clamp(1, 4);
    _beatIndex = 0;
    _subdivisionIndex = 0;
    _isRunning = true;

    await _invokeNativeSafe('start', {
      'bpm': _bpm,
      'pattern': _pattern.map((e) => e.name).toList(),
      'subdivision': _subdivision,
    });

    _scheduleTicks();
  }

  @override
  Future<void> updateBpm(int bpm) async {
    if (_bpm == bpm) return;
    _bpm = bpm;
    if (_isRunning) {
      _scheduleTicks();
    }
    await _invokeNativeSafe('updateBpm', {'bpm': _bpm});
  }

  @override
  Future<void> updatePattern(
    List<BeatEmphasis> pattern, {
    int subdivision = 1,
    bool resetCycle = false,
  }) async {
    final sizeChanged = pattern.length != _pattern.length;
    _pattern = List<BeatEmphasis>.from(pattern);
    _subdivision = subdivision.clamp(1, 4);
    if (resetCycle || sizeChanged) {
      _beatIndex = 0;
      _subdivisionIndex = 0;
    }
    if (_isRunning) {
      _scheduleTicks();
    }
    await _invokeNativeSafe('updatePattern', {
      'pattern': _pattern.map((e) => e.name).toList(),
      'subdivision': _subdivision,
      'resetCycle': resetCycle || sizeChanged,
    });
  }

  @override
  Future<void> stop() async {
    _isRunning = false;
    await _tickSubscription?.cancel();
    _tickSubscription = null;
    _beatIndex = 0;
    _subdivisionIndex = 0;
    await _invokeNativeSafe('stop');
  }

  @override
  Future<void> playTransitionChime({
    double volume = 0.8,
    String soundName = 'chime_zen',
  }) async {
    await playChime(soundName: soundName, volume: volume);
  }

  @override
  Future<void> playChime({
    String soundName = 'chime_zen',
    double volume = 0.8,
  }) async {
    await _invokeNativeSafe('playChime', {
      'soundName': soundName,
      'volume': volume,
    });

    final sampleKey = switch (soundName) {
      'chime_marimba' || 'softMarimba' || 'marimba' => 'chime_marimba',
      'chime_gong' || 'meditativeGong' || 'gong' => 'chime_gong',
      _ => 'chime_tibetan_bowl',
    };
    final sample = _soundCache.getSample(sampleKey);
    if (sample != null && _hasAudioFocus) {
      onSamplePlayed?.call(sampleKey, volume);
    }
  }

  /// Trata mudanças de AudioFocus emitidas pelo Android AudioManager (EC-05).
  void handleAudioFocusChange({required bool gained}) {
    _hasAudioFocus = gained;
    if (!gained) {
      if (_isRunning) {
        stop();
      }
      onAudioFocusLost?.call();
    }
  }

  void _scheduleTicks() {
    _tickSubscription?.cancel();
    if (!_isRunning || _pattern.isEmpty) return;

    final intervalMs = (60000.0 / (_bpm * _subdivision)).round();
    final interval = Duration(milliseconds: intervalMs.clamp(1, 60000));

    _tickSubscription = _clockPort
        .periodicTicks(interval: interval)
        .listen((_) => _onTick());
  }

  void _onTick() {
    if (!_isRunning || !_hasAudioFocus || _pattern.isEmpty) return;

    if (_subdivisionIndex == 0) {
      final emphasis = _pattern[_beatIndex % _pattern.length];
      if (emphasis != BeatEmphasis.mudo) {
        final (sampleKey, volume) = switch (emphasis) {
          BeatEmphasis.forte => ('click_wood_high', 1.0),
          BeatEmphasis.normal => ('click_wood_mid', 0.75),
          BeatEmphasis.fraco => ('click_wood_low', 0.45),
          BeatEmphasis.mudo => ('', 0.0),
        };

        final sample = _soundCache.getSample(sampleKey);
        if (sample != null) {
          onSamplePlayed?.call(sampleKey, volume);
        }
      }
    } else {
      final parentEmphasis = _pattern[_beatIndex % _pattern.length];
      if (parentEmphasis != BeatEmphasis.mudo) {
        final sample = _soundCache.getSample('click_wood_low');
        if (sample != null) {
          onSamplePlayed?.call('click_wood_low', 0.30);
        }
      }
    }

    _subdivisionIndex++;
    if (_subdivisionIndex >= _subdivision) {
      _subdivisionIndex = 0;
      _beatIndex = (_beatIndex + 1) % _pattern.length;
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _invokeNativeSafe('dispose');
  }
}
