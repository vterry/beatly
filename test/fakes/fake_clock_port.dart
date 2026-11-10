import 'dart:async';

import 'package:beatly/domain/contracts/clock_port.dart';

/// Implementação em memória de [ClockPort] para testes unitários determinísticos (ADR-003).
class FakeClockPort implements ClockPort {
  FakeClockPort({DateTime? initialTime})
      : _initialTime = initialTime ?? DateTime.utc(2026, 1, 1);

  final DateTime _initialTime;
  int _elapsedMs = 0;
  final List<_PeriodicSub> _subscriptions = [];

  @override
  DateTime now() => _initialTime.add(Duration(milliseconds: _elapsedMs));

  @override
  int elapsedMilliseconds() => _elapsedMs;

  @override
  Stream<int> periodicTicks({required Duration interval}) {
    late final _PeriodicSub sub;
    final controller = StreamController<int>(
      sync: true,
      onCancel: () => _subscriptions.remove(sub),
    );
    sub = _PeriodicSub(
      intervalMs: interval.inMilliseconds,
      lastTickAtMs: _elapsedMs,
      controller: controller,
    );
    _subscriptions.add(sub);
    return controller.stream;
  }

  /// Avança manualmente o relógio em [duration], disparando todos os ticks correspondentes.
  void advance(Duration duration) {
    final deltaMs = duration.inMilliseconds;
    if (deltaMs <= 0) return;

    _elapsedMs += deltaMs;

    for (final sub in List<_PeriodicSub>.of(_subscriptions)) {
      if (sub.intervalMs <= 0) continue;
      while (_elapsedMs - sub.lastTickAtMs >= sub.intervalMs) {
        sub.lastTickAtMs += sub.intervalMs;
        sub.tickCount += 1;
        if (!sub.controller.isClosed) {
          sub.controller.add(sub.tickCount);
        }
      }
    }
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.controller.close();
    }
    _subscriptions.clear();
  }
}

class _PeriodicSub {
  _PeriodicSub({
    required this.intervalMs,
    required this.lastTickAtMs,
    required this.controller,
  });

  final int intervalMs;
  int lastTickAtMs;
  int tickCount = 0;
  final StreamController<int> controller;
}

