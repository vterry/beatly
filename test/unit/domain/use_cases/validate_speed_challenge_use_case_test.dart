import 'package:beatly/domain/models/speed_challenge_config.dart';
import 'package:beatly/domain/use_cases/validate_speed_challenge_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ValidateSpeedChallengeUseCase (RF-04 / EC-01)', () {
    const validator = ValidateSpeedChallengeUseCase();

    test('TC-04.01: retorna erro se startBpm >= targetBpm (B-RF-04.2 / EC-01)', () {
      const config = SpeedChallengeConfig(
        startBpm: 140,
        targetBpm: 120,
        bpmStep: 5,
      );
      final error = validator.validate(config);
      expect(error, isNotNull);
      expect(error, contains('BPM Inicial deve ser menor que o BPM Final'));
    });

    test('TC-04.02: retorna erro se bpmStep <= 0 ou bpmStep > (targetBpm - startBpm)', () {
      const zeroStep = SpeedChallengeConfig(
        startBpm: 100,
        targetBpm: 120,
        bpmStep: 0,
      );
      expect(validator.validate(zeroStep), isNotNull);

      const excessiveStep = SpeedChallengeConfig(
        startBpm: 100,
        targetBpm: 110,
        bpmStep: 15,
      );
      expect(validator.validate(excessiveStep), isNotNull);
    });

    test('TC-04.03: valida com sucesso parâmetros consistentes (100 -> 140, +5)', () {
      const validConfig = SpeedChallengeConfig(
        startBpm: 100,
        targetBpm: 140,
        bpmStep: 5,
        everyBars: 4,
      );
      expect(validator.validate(validConfig), isNull);
    });
  });
}

