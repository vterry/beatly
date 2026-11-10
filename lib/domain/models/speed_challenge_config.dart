import 'package:flutter/foundation.dart';

/// Critério de progressão de velocidade no Modo Desafio (RF-04).
enum ChallengeTriggerMode {
  /// Incrementa o BPM a cada N compassos completos.
  byBars,

  /// Incrementa o BPM a cada N segundos decorridos.
  byDuration,
}

/// Comportamento ao atingir o BPM alvo (RF-04).
enum ChallengeCompletionBehavior {
  /// Continua tocando indefinidamente no BPM máximo atingido.
  keepRunning,

  /// Toca um chime suave e encerra automaticamente ao concluir o ciclo no BPM máximo.
  stopAndChime,
}

/// Modelo imutável de configuração do Modo Desafio / Speed Trainer (RF-04).
@immutable
class SpeedChallengeConfig {
  const SpeedChallengeConfig({
    this.startBpm = 90,
    this.targetBpm = 140,
    this.bpmStep = 5,
    this.triggerMode = ChallengeTriggerMode.byBars,
    this.everyBars = 4,
    this.everySeconds = 30,
    this.onTargetReached = ChallengeCompletionBehavior.keepRunning,
  });

  final int startBpm;
  final int targetBpm;
  final int bpmStep;
  final ChallengeTriggerMode triggerMode;
  final int everyBars;
  final int everySeconds;
  final ChallengeCompletionBehavior onTargetReached;

  SpeedChallengeConfig copyWith({
    int? startBpm,
    int? targetBpm,
    int? bpmStep,
    ChallengeTriggerMode? triggerMode,
    int? everyBars,
    int? everySeconds,
    ChallengeCompletionBehavior? onTargetReached,
  }) {
    return SpeedChallengeConfig(
      startBpm: startBpm ?? this.startBpm,
      targetBpm: targetBpm ?? this.targetBpm,
      bpmStep: bpmStep ?? this.bpmStep,
      triggerMode: triggerMode ?? this.triggerMode,
      everyBars: everyBars ?? this.everyBars,
      everySeconds: everySeconds ?? this.everySeconds,
      onTargetReached: onTargetReached ?? this.onTargetReached,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpeedChallengeConfig &&
        other.startBpm == startBpm &&
        other.targetBpm == targetBpm &&
        other.bpmStep == bpmStep &&
        other.triggerMode == triggerMode &&
        other.everyBars == everyBars &&
        other.everySeconds == everySeconds &&
        other.onTargetReached == onTargetReached;
  }

  @override
  int get hashCode => Object.hash(
        startBpm,
        targetBpm,
        bpmStep,
        triggerMode,
        everyBars,
        everySeconds,
        onTargetReached,
      );
}

