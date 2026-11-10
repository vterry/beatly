/// Estados cíclicos de ênfase e volume para cada pulso do compasso (RN-03.1).
enum BeatEmphasis {
  /// Acento / Forte (Volume 100%).
  forte(volumeRatio: 1.0, label: 'Forte'),

  /// Normal / Médio (Volume 70%).
  normal(volumeRatio: 0.7, label: 'Normal'),

  /// Subdivisão / Fraco (Volume 40%).
  fraco(volumeRatio: 0.4, label: 'Fraco'),

  /// Mudo / Silêncio rítmico (Volume 0%).
  mudo(volumeRatio: 0.0, label: 'Mudo');

  const BeatEmphasis({
    required this.volumeRatio,
    required this.label,
  });

  /// Proporção de volume de 0.0 a 1.0.
  final double volumeRatio;

  /// Rótulo legível na interface.
  final String label;

  /// Retorna o próximo estado no ciclo: Forte -> Normal -> Fraco -> Mudo -> Forte.
  BeatEmphasis next() => switch (this) {
    BeatEmphasis.forte => BeatEmphasis.normal,
    BeatEmphasis.normal => BeatEmphasis.fraco,
    BeatEmphasis.fraco => BeatEmphasis.mudo,
    BeatEmphasis.mudo => BeatEmphasis.forte,
  };
}

