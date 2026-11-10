import 'package:beatly/domain/models/beat_emphasis.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_metronome_audio_port.dart';

void main() {
  group('FakeMetronomeAudioPort (ADR-002)', () {
    late FakeMetronomeAudioPort audioPort;

    setUp(() {
      audioPort = FakeMetronomeAudioPort();
    });

    test('TC-01.04: inicializa parado (isPlaying == false) e sem BPM ativo', () async {
      await audioPort.initialize();
      expect(audioPort.isInitialized, isTrue);
      expect(audioPort.isPlaying, isFalse);
      expect(audioPort.currentBpm, isNull);
      expect(audioPort.playedChimesCount, equals(0));
    });

    test('TC-01.05: ao chamar start, registra isPlaying == true, currentBpm e padrão rítmico', () async {
      await audioPort.initialize();
      const pattern = [
        BeatEmphasis.forte,
        BeatEmphasis.normal,
        BeatEmphasis.normal,
        BeatEmphasis.fraco,
      ];

      await audioPort.start(bpm: 120, pattern: pattern, subdivision: 2);

      expect(audioPort.isPlaying, isTrue);
      expect(audioPort.currentBpm, equals(120));
      expect(audioPort.activePattern, equals(pattern));
      expect(audioPort.activeSubdivision, equals(2));
    });

    test('TC-01.06: ao chamar stop, redefine isPlaying == false preservando histórico', () async {
      await audioPort.initialize();
      await audioPort.start(
        bpm: 140,
        pattern: const [BeatEmphasis.forte, BeatEmphasis.normal],
      );
      expect(audioPort.isPlaying, isTrue);

      await audioPort.stop();
      expect(audioPort.isPlaying, isFalse);
    });

    test('TC-01.07: ao chamar playTransitionChime, incrementa playedChimesCount', () async {
      await audioPort.initialize();
      await audioPort.playTransitionChime();
      await audioPort.playTransitionChime();

      expect(audioPort.playedChimesCount, equals(2));
    });

    test('ao chamar playChime, registra playedChimesCount, volume e soundName', () async {
      await audioPort.initialize();
      await audioPort.playChime(soundName: 'chime_marimba', volume: 0.75);

      expect(audioPort.playedChimesCount, equals(1));
      expect(audioPort.lastChimeVolume, equals(0.75));
      expect(audioPort.lastChimeSoundName, equals('chime_marimba'));
    });
  });
}
