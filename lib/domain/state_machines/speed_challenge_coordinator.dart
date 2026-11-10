import 'dart:async';
import 'dart:math' as math;

import '../contracts/clock_port.dart';
import '../contracts/metronome_audio_port.dart';
import '../models/beat_emphasis.dart';
import '../models/speed_challenge_config.dart';

/// Coordenador de estado para o Modo Desafio / Speed Trainer (RF-04 / EC-02).
class SpeedChallengeCoordinator {
  SpeedChallengeCoordinator({
    required MetronomeAudioPort audioPort,
    required ClockPort clockPort,
    this.onBpmChanged,
  })  : _audioPort = audioPort,
        _clockPort = clockPort;

  final MetronomeAudioPort _audioPort;
  final ClockPort _clockPort;
  final void Function(int bpm)? onBpmChanged;

  final List<void Function()> _listeners = <void Function()>[];

  SpeedChallengeConfig _activeConfig = const SpeedChallengeConfig();
  int _currentBpm = 90;
  int _beatsPerBar = 4;
  int _completedBarsInStep = 0;
  int _elapsedSecondsInStep = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  StreamSubscription<int>? _clockSub;
  Stopwatch? _barStopwatch;

  SpeedChallengeConfig get activeConfig => _activeConfig;
  int get currentBpm => _currentBpm;
  int get completedBarsInStep => _completedBarsInStep;
  int get elapsedSecondsInStep => _elapsedSecondsInStep;
  bool get isRunning => _isRunning;
  bool get isCompleted => _isCompleted;

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }

  /// Inicia o desafio de velocidade na configuração informada.
  Future<void> startChallenge(
    SpeedChallengeConfig config, {
    int beatsPerBar = 4,
    List<BeatEmphasis>? pattern,
    int subdivision = 1,
  }) async {
    await _clockSub?.cancel();
    _clockSub = null;

    _activeConfig = config;
    _currentBpm = config.startBpm.clamp(20, 300);
    _beatsPerBar = beatsPerBar.clamp(1, 16);
    _completedBarsInStep = 0;
    _elapsedSecondsInStep = 0;
    _isRunning = true;
    _isCompleted = false;

    final effectivePattern = pattern ??
        List<BeatEmphasis>.generate(
          _beatsPerBar,
          (index) => index == 0 ? BeatEmphasis.forte : BeatEmphasis.normal,
        );

    await _audioPort.start(
      bpm: _currentBpm,
      pattern: effectivePattern,
      subdivision: subdivision,
    );

    if (config.triggerMode == ChallengeTriggerMode.byDuration) {
      _clockSub = _clockPort
          .periodicTicks(interval: const Duration(seconds: 1))
          .listen((_) => unawaited(_onSecondTick()));
    } else {
      _barStopwatch = Stopwatch()..start();
      _clockSub = _clockPort
          .periodicTicks(interval: const Duration(milliseconds: 50))
          .listen((_) => unawaited(_onBarWatchTick()));
    }

    _notify();
  }

  Future<void> _onBarWatchTick() async {
    if (!_isRunning ||
        _barStopwatch == null ||
        _activeConfig.triggerMode != ChallengeTriggerMode.byBars) {
      return;
    }
    final msPerBar = (60000.0 / _currentBpm) * _beatsPerBar;
    if (_barStopwatch!.elapsedMilliseconds >= msPerBar) {
      _barStopwatch!.reset();
      await onBarCompleted();
    }
  }

  /// Notifica que 1 compasso completo foi executado no metrônomo.
  Future<void> onBarCompleted() async {
    if (!_isRunning ||
        _activeConfig.triggerMode != ChallengeTriggerMode.byBars) {
      return;
    }

    _completedBarsInStep += 1;
    if (_completedBarsInStep >= _activeConfig.everyBars) {
      _completedBarsInStep = 0;
      await _advanceStepOrFinish();
    } else {
      _notify();
    }
  }

  Future<void> _onSecondTick() async {
    if (!_isRunning ||
        _activeConfig.triggerMode != ChallengeTriggerMode.byDuration) {
      return;
    }

    _elapsedSecondsInStep += 1;
    if (_elapsedSecondsInStep >= _activeConfig.everySeconds) {
      _elapsedSecondsInStep = 0;
      await _advanceStepOrFinish();
    } else {
      _notify();
    }
  }

  Future<void> _advanceStepOrFinish() async {
    if (_currentBpm >= _activeConfig.targetBpm) {
      if (_activeConfig.onTargetReached ==
          ChallengeCompletionBehavior.stopAndChime) {
        await _clockSub?.cancel();
        _clockSub = null;
        _isRunning = false;
        _isCompleted = true;
        await _audioPort.playTransitionChime();
        await _audioPort.stop();
      }
      _notify();
      return;
    }

    // EC-02: trava exatamente no BPM alvo se o incremento exceder a diferença restante.
    final nextBpm = math.min(
      _currentBpm + _activeConfig.bpmStep,
      _activeConfig.targetBpm,
    );
    _currentBpm = nextBpm;
    await _audioPort.updateBpm(_currentBpm);
    onBpmChanged?.call(_currentBpm);
    _notify();
  }

  /// Interrompe o desafio de velocidade imediatamente.
  Future<void> stopChallenge() async {
    await _clockSub?.cancel();
    _clockSub = null;
    _barStopwatch?.stop();
    _barStopwatch = null;
    _isRunning = false;
    await _audioPort.stop();
    _notify();
  }

  Future<void> dispose() async {
    await _clockSub?.cancel();
    _clockSub = null;
    _listeners.clear();
  }
}
