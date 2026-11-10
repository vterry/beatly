import 'package:beatly/data/services/audio/android_metronome_audio_service.dart';
import 'package:beatly/data/services/audio/pcm_sound_cache.dart';
import 'package:beatly/domain/models/beat_emphasis.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_clock_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PcmSoundCache (ADR-002)', () {
    late PcmSoundCache cache;

    setUp(() {
      cache = PcmSoundCache();
    });

    test('preloadAll carrega todas as 6 amostras PCM WAV em memória RAM', () async {
      expect(cache.isLoaded, isFalse);
      expect(cache.loadedKeys, isEmpty);

      await cache.preloadAll();

      expect(cache.isLoaded, isTrue);
      expect(cache.loadedKeys.length, equals(6));

      const expectedKeys = [
        'click_wood_high',
        'click_wood_mid',
        'click_wood_low',
        'chime_tibetan_bowl',
        'chime_marimba',
        'chime_gong',
      ];

      for (final key in expectedKeys) {
        final sample = cache.getSample(key);
        expect(sample, isNotNull);
        expect(sample!.length, greaterThan(44));
        // Valida cabeçalho RIFF WAVE
        expect(String.fromCharCodes(sample.sublist(0, 4)), equals('RIFF'));
        expect(String.fromCharCodes(sample.sublist(8, 12)), equals('WAVE'));
      }
    });

    test('clear remove todas as amostras da memória RAM', () async {
      await cache.preloadAll();
      expect(cache.isLoaded, isTrue);

      cache.clear();
      expect(cache.isLoaded, isFalse);
      expect(cache.loadedKeys, isEmpty);
      expect(cache.getSample('click_wood_high'), isNull);
    });
  });

  group('AndroidMetronomeAudioService (ADR-002 / ADR-006 / EC-05)', () {
    late PcmSoundCache cache;
    late FakeClockPort clockPort;
    late AndroidMetronomeAudioService audioService;

    setUp(() async {
      cache = PcmSoundCache();
      await cache.preloadAll();
      clockPort = FakeClockPort();
      audioService = AndroidMetronomeAudioService(
        soundCache: cache,
        clockPort: clockPort,
      );
      await audioService.initialize();
    });

    tearDown(() async {
      await audioService.dispose();
    });

    test('start inicia metrônomo e ticks reproduzem amostras sonoras', () async {
      final playedSamples = <String>[];
      audioService.onSamplePlayed = (key, volume) {
        playedSamples.add(key);
      };

      await audioService.start(
        bpm: 120,
        pattern: [
          BeatEmphasis.forte,
          BeatEmphasis.normal,
          BeatEmphasis.fraco,
          BeatEmphasis.mudo,
        ],
      );

      expect(audioService.isRunning, isTrue);

      // Simula 4 ticks do metrônomo (500ms por batida a 120 BPM)
      clockPort.advance(const Duration(milliseconds: 500));
      clockPort.advance(const Duration(milliseconds: 500));
      clockPort.advance(const Duration(milliseconds: 500));
      clockPort.advance(const Duration(milliseconds: 500));

      // Pulso 1: forte (high), Pulso 2: normal (mid), Pulso 3: fraco (low), Pulso 4: mudo (nenhuma amostra)
      expect(playedSamples, contains('click_wood_high'));
      expect(playedSamples, contains('click_wood_mid'));
      expect(playedSamples, contains('click_wood_low'));
      // Mudo não deve emitir som
      expect(playedSamples.length, equals(3));
    });

    test('EC-05: perda de AudioFocus pausa imediatamente o metrônomo', () async {
      var audioFocusLostTriggered = false;
      audioService.onAudioFocusLost = () {
        audioFocusLostTriggered = true;
      };

      await audioService.start(
        bpm: 120,
        pattern: [BeatEmphasis.forte, BeatEmphasis.normal],
      );

      expect(audioService.isRunning, isTrue);
      expect(audioService.hasAudioFocus, isTrue);

      // Chamada telefônica recebida: sistema notifica perda de AudioFocus
      audioService.handleAudioFocusChange(gained: false);

      expect(audioService.hasAudioFocus, isFalse);
      expect(audioService.isRunning, isFalse);
      expect(audioFocusLostTriggered, isTrue);
    });

    test('playTransitionChime emite amostra sonora de chime zen', () async {
      String? playedChimeKey;
      double? playedChimeVolume;

      audioService.onSamplePlayed = (key, volume) {
        playedChimeKey = key;
        playedChimeVolume = volume;
      };

      await audioService.playTransitionChime(volume: 0.9);

      expect(playedChimeKey, equals('chime_tibetan_bowl'));
      expect(playedChimeVolume, equals(0.9));
    });

    test('playChime reproduz diferentes timbres sonoros (marimba, gong)', () async {
      final playedSamples = <String>[];

      audioService.onSamplePlayed = (key, volume) {
        playedSamples.add(key);
      };

      await audioService.playChime(soundName: 'chime_marimba', volume: 0.7);
      await audioService.playChime(soundName: 'chime_gong', volume: 0.85);

      expect(playedSamples, contains('chime_marimba'));
      expect(playedSamples, contains('chime_gong'));
    });
  });
}
