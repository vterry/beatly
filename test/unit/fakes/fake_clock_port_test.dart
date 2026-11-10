import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_clock_port.dart';

void main() {
  group('FakeClockPort (ADR-003)', () {
    late FakeClockPort clock;

    setUp(() {
      clock = FakeClockPort(initialTime: DateTime.utc(2026, 11, 8, 12));
    });

    tearDown(() {
      clock.dispose();
    });

    test('TC-01.01: retorna tempo inicial configurado e avança milissegundos exatamente em advance()', () {
      expect(clock.now(), equals(DateTime.utc(2026, 11, 8, 12)));
      expect(clock.elapsedMilliseconds(), equals(0));

      clock.advance(const Duration(seconds: 5, milliseconds: 250));

      expect(clock.elapsedMilliseconds(), equals(5250));
      expect(
        clock.now(),
        equals(DateTime.utc(2026, 11, 8, 12, 0, 5, 250)),
      );
    });

    test('TC-01.02: emite ticks em periodicTicks quando o tempo avança múltiplos do intervalo', () async {
      final emittedTicks = <int>[];
      final sub = clock
          .periodicTicks(interval: const Duration(seconds: 1))
          .listen(emittedTicks.add);

      clock.advance(const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero);

      expect(emittedTicks, equals([1, 2, 3, 4, 5]));
      await sub.cancel();
    });

    test('TC-01.03: não emite ticks se o tempo avançado for inferior ao intervalo configurado', () async {
      final emittedTicks = <int>[];
      final sub = clock
          .periodicTicks(interval: const Duration(seconds: 1))
          .listen(emittedTicks.add);

      clock.advance(const Duration(milliseconds: 999));
      await Future<void>.delayed(Duration.zero);

      expect(emittedTicks, isEmpty);

      clock.advance(const Duration(milliseconds: 1));
      await Future<void>.delayed(Duration.zero);

      expect(emittedTicks, equals([1]));
      await sub.cancel();
    });
  });
}
