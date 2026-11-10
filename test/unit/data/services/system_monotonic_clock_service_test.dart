
import 'package:beatly/data/services/clock/system_monotonic_clock_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SystemMonotonicClockService (ADR-003 / EC-08)', () {
    test(
      'TC-08.03: elapsedMilliseconds é estritamente monotônico e crescente mesmo com salto no relógio de parede',
      () async {
        var simulatedWallTime = DateTime(2026, 11, 8, 15, 30, 0);

        final clock = SystemMonotonicClockService(
          wallClock: () => simulatedWallTime,
        );

        expect(clock.now(), equals(DateTime(2026, 11, 8, 15, 30, 0)));

        final t0 = clock.elapsedMilliseconds();
        await Future<void>.delayed(const Duration(milliseconds: 15));
        final t1 = clock.elapsedMilliseconds();
        expect(t1, greaterThan(t0));

        // Simula mudança brusca de horário de verão ou ajuste manual de relógio para trás em 2 horas
        simulatedWallTime = simulatedWallTime.subtract(const Duration(hours: 2));
        expect(clock.now(), equals(DateTime(2026, 11, 8, 13, 30, 0)));

        // elapsedMilliseconds continua monotonicamente crescente, imune à alteração de fuso/relógio do SO
        await Future<void>.delayed(const Duration(milliseconds: 15));
        final t2 = clock.elapsedMilliseconds();
        expect(t2, greaterThan(t1));

        // Simula salto para frente em 1 dia
        simulatedWallTime = simulatedWallTime.add(const Duration(days: 1));
        expect(clock.now(), equals(DateTime(2026, 11, 9, 13, 30, 0)));

        await Future<void>.delayed(const Duration(milliseconds: 15));
        final t3 = clock.elapsedMilliseconds();
        expect(t3, greaterThan(t2));
      },
    );

    test('periodicTicks emite sequência de inteiros 1, 2, 3...', () async {
      final clock = SystemMonotonicClockService();
      final stream = clock.periodicTicks(
        interval: const Duration(milliseconds: 10),
      );

      final ticks = await stream.take(3).toList();
      expect(ticks, equals([1, 2, 3]));
    });
  });
}
