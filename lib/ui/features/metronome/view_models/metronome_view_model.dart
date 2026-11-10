import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/contracts/clock_port.dart';
import '../../../../domain/contracts/metronome_audio_port.dart';
import '../../../../domain/models/beat_emphasis.dart';
import '../../../../domain/models/metronome_config.dart';
import '../../../../domain/use_cases/calculate_tap_tempo_use_case.dart';

/// ViewModel reativo do Metrônomo (ADR-001 / RF-01 / RF-02 / RF-03).
class MetronomeViewModel extends ChangeNotifier {
  MetronomeViewModel({
    required MetronomeAudioPort audioPort,
    required ClockPort clockPort,
    CalculateTapTempoUseCase? tapTempoUseCase,
  }) : _audioPort = audioPort,
       _clockPort = clockPort,
       _tapTempoUseCase = tapTempoUseCase ?? CalculateTapTempoUseCase();

  static const int minBpm = 20;
  static const int maxBpm = 300;

  final MetronomeAudioPort _audioPort;
  final ClockPort _clockPort;
  final CalculateTapTempoUseCase _tapTempoUseCase;

  MetronomeConfig _config = MetronomeConfig();
  bool _isPlaying = false;
  int _activeBeatIndex = -1;
  StreamSubscription<int>? _visualPulseSub;
  Stopwatch? _pulseStopwatch;

  MetronomeConfig get config => _config;
  int get bpm => _config.bpm;
  int get beatsPerBar => _config.beatsPerBar;
  int get beatUnit => _config.beatUnit;
  int get subdivision => _config.subdivision;
  List<BeatEmphasis> get beatPattern => _config.beatPattern;
  String get tempoMarking => _config.tempoMarking;

  bool get isPlaying => _isPlaying;
  int get activeBeatIndex => _activeBeatIndex;
  bool get canIncrementBpm => _config.bpm < maxBpm;
  bool get canDecrementBpm => _config.bpm > minBpm;

  Future<void> setBpm(int newBpm) async {
    final clamped = newBpm.clamp(minBpm, maxBpm);
    if (clamped == _config.bpm) return;

    _config = _config.copyWith(bpm: clamped);
    if (_isPlaying) {
      await _audioPort.updateBpm(clamped);
      _restartVisualPulseTicker();
    }
    notifyListeners();
  }

  Future<void> incrementBpm(int delta) => setBpm(_config.bpm + delta);

  Future<void> decrementBpm(int delta) => setBpm(_config.bpm - delta);

  Future<void> registerTap() async {
    final calculated = _tapTempoUseCase.registerTap(
      _clockPort.elapsedMilliseconds(),
    );
    if (calculated != null) {
      await setBpm(calculated);
    }
  }

  Future<void> cycleBeatEmphasis(int beatIndex) async {
    if (beatIndex < 0 || beatIndex >= _config.beatPattern.length) return;
    final updated = List<BeatEmphasis>.of(_config.beatPattern);
    updated[beatIndex] = updated[beatIndex].next();
    _config = _config.copyWith(beatPattern: updated);

    if (_isPlaying) {
      await _audioPort.updatePattern(
        _config.beatPattern,
        subdivision: _config.subdivision,
      );
    }
    notifyListeners();
  }

  Future<void> resetBeatPatternToDefault() async {
    final updated = List<BeatEmphasis>.generate(
      _config.beatsPerBar,
      (i) => i == 0 ? BeatEmphasis.forte : BeatEmphasis.normal,
    );
    _config = _config.copyWith(beatPattern: updated);
    if (_isPlaying) {
      _activeBeatIndex = 0;
      _pulseStopwatch = Stopwatch()..start();
      _restartVisualPulseTicker();
      await _audioPort.updatePattern(
        _config.beatPattern,
        subdivision: _config.subdivision,
        resetCycle: true,
      );
    }
    notifyListeners();
  }

  Future<void> muteAllBeats() async {
    final updated = List<BeatEmphasis>.filled(
      _config.beatsPerBar,
      BeatEmphasis.mudo,
    );
    _config = _config.copyWith(beatPattern: updated);
    if (_isPlaying) {
      await _audioPort.updatePattern(
        _config.beatPattern,
        subdivision: _config.subdivision,
      );
    }
    notifyListeners();
  }

  Future<void> setBeatsPerBar(int count) async {
    final clamped = count.clamp(1, 16);
    if (clamped == _config.beatsPerBar) return;
    _config = _config.copyWith(beatsPerBar: clamped);
    _activeBeatIndex = 0;
    if (_isPlaying) {
      _pulseStopwatch = Stopwatch()..start();
      _restartVisualPulseTicker();
      await _audioPort.updatePattern(
        _config.beatPattern,
        subdivision: _config.subdivision,
        resetCycle: true,
      );
    }
    notifyListeners();
  }

  Future<void> setBeatUnit(int denominator) async {
    if (!const [2, 4, 8, 16].contains(denominator)) return;
    _config = _config.copyWith(beatUnit: denominator);
    notifyListeners();
  }

  Future<void> setSubdivision(int sub) async {
    final clamped = sub.clamp(1, 4);
    if (clamped == _config.subdivision) return;
    _config = _config.copyWith(subdivision: clamped);
    if (_isPlaying) {
      await _audioPort.updatePattern(
        _config.beatPattern,
        subdivision: _config.subdivision,
      );
    }
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await stop();
    } else {
      await start();
    }
  }

  Future<void> start() async {
    if (_isPlaying) return;
    _isPlaying = true;
    _activeBeatIndex = 0;
    _pulseStopwatch = Stopwatch()..start();
    await _audioPort.start(
      bpm: _config.bpm,
      pattern: _config.beatPattern,
      subdivision: _config.subdivision,
    );
    _restartVisualPulseTicker();
    notifyListeners();
  }

  Future<void> stop() async {
    if (!_isPlaying) return;
    _isPlaying = false;
    _activeBeatIndex = -1;
    _pulseStopwatch?.stop();
    _pulseStopwatch = null;
    final sub = _visualPulseSub;
    _visualPulseSub = null;
    unawaited(sub?.cancel());
    await _audioPort.stop();
    notifyListeners();
  }

  void _restartVisualPulseTicker() {
    _visualPulseSub?.cancel();
    if (!_isPlaying) return;
    _pulseStopwatch ??= Stopwatch()..start();

    // Duração de uma batida em milissegundos
    final msPerBeat = 60000.0 / _config.bpm;

    // Ticker frequente para sincronização exata com o áudio sem deriva temporal
    _visualPulseSub = _clockPort
        .periodicTicks(interval: const Duration(milliseconds: 25))
        .listen((_) {
          if (!_isPlaying || _pulseStopwatch == null) return;
          final elapsed = _pulseStopwatch!.elapsedMilliseconds;
          final currentBeat =
              (elapsed / msPerBeat).floor() % _config.beatsPerBar;
          if (currentBeat != _activeBeatIndex) {
            _activeBeatIndex = currentBeat;
            notifyListeners();
          }
        });
  }

  @override
  void dispose() {
    _visualPulseSub?.cancel();
    super.dispose();
  }
}
