import 'package:flutter/foundation.dart';

import '../../../../domain/models/beat_emphasis.dart';
import '../../../../domain/models/speed_challenge_config.dart';
import '../../../../domain/state_machines/speed_challenge_coordinator.dart';
import '../../../../domain/use_cases/validate_speed_challenge_use_case.dart';

/// ViewModel reativo para configuração e execução do Modo Desafio (RF-04).
class SpeedChallengeViewModel extends ChangeNotifier {
  SpeedChallengeViewModel({
    required SpeedChallengeCoordinator coordinator,
    ValidateSpeedChallengeUseCase validator =
        const ValidateSpeedChallengeUseCase(),
  })  : _coordinator = coordinator,
        _validator = validator {
    _coordinator.addListener(_onCoordinatorChanged);
  }

  final SpeedChallengeCoordinator _coordinator;
  final ValidateSpeedChallengeUseCase _validator;

  SpeedChallengeConfig _config = const SpeedChallengeConfig();

  SpeedChallengeConfig get config => _config;
  String? get validationError => _validator.validate(_config);
  bool get isValid => validationError == null;

  bool get isRunning => _coordinator.isRunning;
  bool get isCompleted => _coordinator.isCompleted;
  int get currentBpm =>
      (_coordinator.isRunning || _coordinator.isCompleted)
          ? _coordinator.currentBpm
          : _config.startBpm;
  int get completedBarsInStep => _coordinator.completedBarsInStep;
  int get elapsedSecondsInStep => _coordinator.elapsedSecondsInStep;

  /// Texto descritivo do progresso dentro do bloco atual.
  String get stepProgressText {
    if (!isRunning) return '';
    if (_config.triggerMode == ChallengeTriggerMode.byBars) {
      return 'Compasso ${_coordinator.completedBarsInStep + 1} de ${_config.everyBars}';
    } else {
      final remaining = _config.everySeconds - _coordinator.elapsedSecondsInStep;
      return '${remaining > 0 ? remaining : 0}s restantes';
    }
  }

  /// Progresso percentual entre o BPM inicial (0.0) e o BPM final (1.0).
  double get progressRatio {
    final totalDelta = _config.targetBpm - _config.startBpm;
    if (totalDelta <= 0) return 0.0;
    final activeBpm =
        _coordinator.isRunning || _coordinator.isCompleted
            ? _coordinator.currentBpm
            : _config.startBpm;
    return ((activeBpm - _config.startBpm) / totalDelta).clamp(0.0, 1.0);
  }

  void _onCoordinatorChanged() {
    notifyListeners();
  }

  void setStartBpm(int value) {
    _config = _config.copyWith(startBpm: value);
    notifyListeners();
  }

  void setTargetBpm(int value) {
    _config = _config.copyWith(targetBpm: value);
    notifyListeners();
  }

  void setBpmStep(int value) {
    _config = _config.copyWith(bpmStep: value);
    notifyListeners();
  }

  void setEveryBars(int value) {
    _config = _config.copyWith(everyBars: value);
    notifyListeners();
  }

  void setEverySeconds(int value) {
    _config = _config.copyWith(everySeconds: value);
    notifyListeners();
  }

  void setTriggerMode(ChallengeTriggerMode mode) {
    _config = _config.copyWith(triggerMode: mode);
    notifyListeners();
  }

  void setCompletionBehavior(ChallengeCompletionBehavior behavior) {
    _config = _config.copyWith(onTargetReached: behavior);
    notifyListeners();
  }

  void setTimeDivision(ChallengeTimeDivision division) {
    final next = _config.timeDivision == division
        ? ChallengeTimeDivision.pulso
        : division;
    _config = _config.copyWith(timeDivision: next);
    notifyListeners();
  }

  Future<bool> startChallenge({int beatsPerBar = 4}) async {
    if (!isValid) {
      notifyListeners();
      return false;
    }

    final (int subdivision, List<BeatEmphasis>? pattern) =
        switch (_config.timeDivision) {
      ChallengeTimeDivision.pulso => (1, null),
      ChallengeTimeDivision.minima => (
          1,
          List<BeatEmphasis>.generate(
            beatsPerBar,
            (i) => i == 0
                ? BeatEmphasis.forte
                : (i.isEven ? BeatEmphasis.normal : BeatEmphasis.mudo),
          ),
        ),
      ChallengeTimeDivision.colcheia => (2, null),
      ChallengeTimeDivision.tercina => (3, null),
      ChallengeTimeDivision.semicolcheia => (4, null),
    };

    await _coordinator.startChallenge(
      _config,
      beatsPerBar: beatsPerBar,
      pattern: pattern,
      subdivision: subdivision,
    );
    notifyListeners();
    return true;
  }

  Future<void> stopChallenge() async {
    await _coordinator.stopChallenge();
    notifyListeners();
  }

  @override
  void dispose() {
    _coordinator.removeListener(_onCoordinatorChanged);
    super.dispose();
  }
}

