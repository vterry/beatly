/// Contrato abstrato de relógio monotônico injetável (ADR-003 / EC-08).
///
/// Permite testes unitários determinísticos e instantâneos via `FakeClockPort`
/// sem depender de `Timer.periodic` real ou relógio do sistema operacional.
abstract interface class ClockPort {
  /// Data/hora atual para carimbo de sessões.
  DateTime now();

  /// Milissegundos decorridos de forma monotônica (imune a mudanças de fuso/relógio).
  int elapsedMilliseconds();

  /// Emite ticks sequenciais (1, 2, 3...) a cada [interval].
  Stream<int> periodicTicks({required Duration interval});
}

