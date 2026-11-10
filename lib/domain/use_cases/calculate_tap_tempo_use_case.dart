/// Use Case puro em Dart para cálculo de BPM via Tap Tempo (RF-01 / RN-01.2).
///
/// Calcula a média móvel dos últimos 4 toques consecutivos com intervalos
/// válidos entre [minIntervalMs] (200ms -> 300 BPM) e [maxIntervalMs] (3000ms -> 20 BPM).
class CalculateTapTempoUseCase {
  static const int minIntervalMs = 200;
  static const int maxIntervalMs = 3000;
  static const int maxTapsWindow = 4;

  final List<int> _tapTimestampsMs = [];

  /// Registra um toque no instante [elapsedMs] e retorna o BPM calculado [20..300]
  /// ou `null` caso ainda não existam pelo menos 2 toques válidos na janela.
  int? registerTap(int elapsedMs) {
    if (_tapTimestampsMs.isNotEmpty) {
      final delta = elapsedMs - _tapTimestampsMs.last;
      if (delta > maxIntervalMs || delta < 0) {
        _tapTimestampsMs.clear();
      } else if (delta < minIntervalMs) {
        // Ignora toques involuntários acima de 300 BPM.
        return null;
      }
    }

    _tapTimestampsMs.add(elapsedMs);
    if (_tapTimestampsMs.length > maxTapsWindow) {
      _tapTimestampsMs.removeAt(0);
    }

    if (_tapTimestampsMs.length < 2) {
      return null;
    }

    var totalIntervalsMs = 0;
    for (var i = 1; i < _tapTimestampsMs.length; i++) {
      totalIntervalsMs += _tapTimestampsMs[i] - _tapTimestampsMs[i - 1];
    }

    final avgIntervalMs = totalIntervalsMs / (_tapTimestampsMs.length - 1);
    final rawBpm = (60000 / avgIntervalMs).round();
    return rawBpm.clamp(20, 300);
  }

  void reset() => _tapTimestampsMs.clear();
}

