import '../models/speed_challenge_config.dart';

/// Caso de uso puro para validação de parâmetros do Modo Desafio (RF-04 / EC-01).
class ValidateSpeedChallengeUseCase {
  const ValidateSpeedChallengeUseCase();

  /// Retorna uma mensagem de erro amigável se a configuração for inválida, ou `null` se válida.
  String? validate(SpeedChallengeConfig config) {
    if (config.startBpm < 20 || config.startBpm > 300) {
      return 'O BPM Inicial deve estar entre 20 e 300 BPM.';
    }
    if (config.targetBpm < 20 || config.targetBpm > 300) {
      return 'O BPM Final deve estar entre 20 e 300 BPM.';
    }
    if (config.startBpm >= config.targetBpm) {
      return 'O BPM Inicial deve ser menor que o BPM Final.';
    }
    if (config.bpmStep <= 0) {
      return 'O incremento de BPM deve ser maior que zero.';
    }
    final range = config.targetBpm - config.startBpm;
    if (config.bpmStep > range) {
      return 'O incremento de BPM não pode exceder a diferença entre o BPM Inicial e o Final.';
    }
    if (config.triggerMode == ChallengeTriggerMode.byBars && config.everyBars < 1) {
      return 'A quantidade de compassos por incremento deve ser no mínimo 1.';
    }
    if (config.triggerMode == ChallengeTriggerMode.byDuration &&
        config.everySeconds < 5) {
      return 'O intervalo de tempo por incremento deve ser de no mínimo 5 segundos.';
    }
    return null;
  }
}

