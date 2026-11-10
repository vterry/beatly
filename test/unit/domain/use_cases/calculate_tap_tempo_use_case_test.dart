import 'package:beatly/domain/use_cases/calculate_tap_tempo_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculateTapTempoUseCase (RF-01 / RN-01.2)', () {
    late CalculateTapTempoUseCase useCase;

    setUp(() {
      useCase = CalculateTapTempoUseCase();
    });

    test('TC-03.01: retorna nulo se houver menos de 2 toques registrados', () {
      expect(useCase.registerTap(1000), isNull);
    });

    test('TC-03.02: 4 toques espaçados em 500ms calculam exatamente 120 BPM (B-RF-01.3)', () {
      expect(useCase.registerTap(1000), isNull);
      expect(useCase.registerTap(1500), equals(120));
      expect(useCase.registerTap(2000), equals(120));
      expect(useCase.registerTap(2500), equals(120));
    });

    test('TC-03.03: toques espaçados em 1000ms calculam 60 BPM', () {
      useCase.registerTap(0);
      expect(useCase.registerTap(1000), equals(60));
      expect(useCase.registerTap(2000), equals(60));
    });

    test('TC-03.04: intervalo maior que 3000ms reinicia o histórico de toques', () {
      useCase.registerTap(1000);
      expect(useCase.registerTap(1500), equals(120));

      // Pausa longa de 4 segundos (> 3000ms) reinicia a janela
      expect(useCase.registerTap(5500), isNull);
      // Novo toque 600ms depois -> 100 BPM
      expect(useCase.registerTap(6100), equals(100));
    });
  });
}

