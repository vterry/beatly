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

/// Divisão de tempo aplicada durante o Modo Desafio.
enum ChallengeTimeDivision {
  /// Pulso padrão (1x / Semínima).
  pulso,

  /// Mínimas (metade dos pulsos do compasso).
  minima,

  /// Colcheias (2x por pulso).
  colcheia,

  /// Tercinas (3x por pulso).
  tercina,

  /// Semicolcheias (4x por pulso).
  semicolcheia,
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
    this.timeDivision = ChallengeTimeDivision.pulso,
  });

  final int startBpm;
  final int targetBpm;
  final int bpmStep;
  final ChallengeTriggerMode triggerMode;
  final int everyBars;
  final int everySeconds;
  final ChallengeCompletionBehavior onTargetReached;
  final ChallengeTimeDivision timeDivision;

  SpeedChallengeConfig copyWith({
    int? startBpm,
    int? targetBpm,
    int? bpmStep,
    ChallengeTriggerMode? triggerMode,
    int? everyBars,
    int? everySeconds,
    ChallengeCompletionBehavior? onTargetReached,
    ChallengeTimeDivision? timeDivision,
  }) {
    return SpeedChallengeConfig(
      startBpm: startBpm ?? this.startBpm,
      targetBpm: targetBpm ?? this.targetBpm,
      bpmStep: bpmStep ?? this.bpmStep,
      triggerMode: triggerMode ?? this.triggerMode,
      everyBars: everyBars ?? this.everyBars,
      everySeconds: everySeconds ?? this.everySeconds,
      onTargetReached: onTargetReached ?? this.onTargetReached,
      timeDivision: timeDivision ?? this.timeDivision,
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
        other.onTargetReached == onTargetReached &&
        other.timeDivision == timeDivision;
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
        timeDivision,
      );
}

