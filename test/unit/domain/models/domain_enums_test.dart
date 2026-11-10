import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/beat_emphasis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BeatEmphasis (RN-03.1)', () {
    test('possui exatamente 4 estados de volume com níveis corretos', () {
      expect(BeatEmphasis.values.length, equals(4));
      expect(BeatEmphasis.forte.volumeRatio, equals(1.0));
      expect(BeatEmphasis.normal.volumeRatio, equals(0.7));
      expect(BeatEmphasis.fraco.volumeRatio, equals(0.4));
      expect(BeatEmphasis.mudo.volumeRatio, equals(0.0));
    });

    test('cicla entre os estados na ordem Forte -> Normal -> Fraco -> Mudo -> Forte (B-RF-03.1)', () {
      expect(BeatEmphasis.forte.next(), equals(BeatEmphasis.normal));
      expect(BeatEmphasis.normal.next(), equals(BeatEmphasis.fraco));
      expect(BeatEmphasis.fraco.next(), equals(BeatEmphasis.mudo));
      expect(BeatEmphasis.mudo.next(), equals(BeatEmphasis.forte));
    });
  });

  group('ActivityCategory (RN-06.1 / B-RF-06.1)', () {
    test('possui exclusivamente as 5 categorias canônicas do Beatly', () {
      expect(ActivityCategory.values.length, equals(5));
      expect(
        ActivityCategory.values.map((c) => c.label).toList(),
        equals([
          'Técnica',
          'Velocidade',
          'Teoria Musical',
          'Improviso',
          'Free Style',
        ]),
      );
    });
  });
}

