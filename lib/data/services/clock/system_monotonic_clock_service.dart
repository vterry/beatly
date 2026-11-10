import 'dart:async';

import '../../../domain/contracts/clock_port.dart';

/// Implementação de [ClockPort] utilizando o [Stopwatch] monotônico do SO (ADR-003 / EC-08).
///
/// Imune a alterações de horário de verão, fuso horário ou ajustes manuais do relógio
/// de parede do sistema operacional.
class SystemMonotonicClockService implements ClockPort {
  SystemMonotonicClockService({
    DateTime Function()? wallClock,
    Stopwatch? stopwatch,
  })  : _wallClock = wallClock ?? DateTime.now,
        _stopwatch = stopwatch ?? (Stopwatch()..start());

  final DateTime Function() _wallClock;
  final Stopwatch _stopwatch;

  @override
  DateTime now() => _wallClock();

  @override
  int elapsedMilliseconds() => _stopwatch.elapsedMilliseconds;

  @override
  Stream<int> periodicTicks({required Duration interval}) {
    return Stream<int>.periodic(
      interval,
      (computationCount) => computationCount + 1,
    );
  }
}
