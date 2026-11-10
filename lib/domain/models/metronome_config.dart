import 'beat_emphasis.dart';

/// Modelo imutável de configuração do Metrônomo (RF-01 / RF-02 / RF-03).
class MetronomeConfig {
  MetronomeConfig({
    this.bpm = 120,
    this.beatsPerBar = 4,
    this.beatUnit = 4,
    this.subdivision = 1,
    List<BeatEmphasis>? beatPattern,
  }) : assert(bpm >= 20 && bpm <= 300, 'BPM deve estar entre 20 e 300'),
       assert(
         beatsPerBar >= 1 && beatsPerBar <= 16,
         'Numerador deve estar entre 1 e 16',
       ),
       assert(
         beatUnit == 2 || beatUnit == 4 || beatUnit == 8 || beatUnit == 16,
         'Denominador deve ser 2, 4, 8 ou 16',
       ),
       assert(
         subdivision >= 1 && subdivision <= 4,
         'Subdivisão deve estar entre 1 e 4',
       ),
       beatPattern = List<BeatEmphasis>.unmodifiable(
         beatPattern ?? _defaultPattern(beatsPerBar),
       );

  final int bpm;
  final int beatsPerBar;
  final int beatUnit;
  final int subdivision;
  final List<BeatEmphasis> beatPattern;

  static List<BeatEmphasis> _defaultPattern(int count) {
    return List<BeatEmphasis>.generate(
      count,
      (index) => index == 0 ? BeatEmphasis.forte : BeatEmphasis.normal,
    );
  }

  /// Classificação clássica de andamento musical em italiano.
  String get tempoMarking {
    if (bpm < 60) return 'Largo';
    if (bpm < 76) return 'Adagio';
    if (bpm < 108) return 'Andante';
    if (bpm < 120) return 'Moderato';
    if (bpm < 156) return 'Allegro';
    if (bpm < 176) return 'Vivace';
    return 'Presto';
  }

  MetronomeConfig copyWith({
    int? bpm,
    int? beatsPerBar,
    int? beatUnit,
    int? subdivision,
    List<BeatEmphasis>? beatPattern,
  }) {
    final nextBeats = beatsPerBar ?? this.beatsPerBar;
    List<BeatEmphasis> nextPattern = beatPattern ?? this.beatPattern;
    if (beatPattern == null && nextBeats != this.beatsPerBar) {
      nextPattern = List<BeatEmphasis>.generate(
        nextBeats,
        (i) => i < this.beatPattern.length
            ? this.beatPattern[i]
            : BeatEmphasis.normal,
      );
    }

    return MetronomeConfig(
      bpm: (bpm ?? this.bpm).clamp(20, 300),
      beatsPerBar: nextBeats.clamp(1, 16),
      beatUnit: beatUnit ?? this.beatUnit,
      subdivision: (subdivision ?? this.subdivision).clamp(1, 4),
      beatPattern: nextPattern,
    );
  }
}

