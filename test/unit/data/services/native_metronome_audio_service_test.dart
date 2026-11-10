import 'package:beatly/data/services/audio/native_metronome_audio_service.dart';
import 'package:beatly/data/services/audio/pcm_sound_cache.dart';
import 'package:beatly/data/services/system/wakelock_service.dart';
import 'package:beatly/domain/models/beat_emphasis.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_clock_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeMetronomeAudioService & Wakelock (MethodChannel integration)', () {
    const audioChannel = MethodChannel('com.beatly.app/audio');
    const wakelockChannel = MethodChannel('com.beatly.app/wakelock');
    final audioCalls = <MethodCall>[];
    final wakelockCalls = <MethodCall>[];

    setUp(() {
      audioCalls.clear();
      wakelockCalls.clear();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(audioChannel, (call) async {
        audioCalls.add(call);
        return null;
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(wakelockChannel, (call) async {
        wakelockCalls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(audioChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(wakelockChannel, null);
    });

    test('start, updateBpm, updatePattern, stop invocam métodos no canal nativo de áudio', () async {
      final cache = PcmSoundCache();
      final clockPort = FakeClockPort();
      final service = NativeMetronomeAudioService(
        soundCache: cache,
        clockPort: clockPort,
        channel: audioChannel,
      );

      await service.initialize();
      expect(audioCalls.any((c) => c.method == 'initialize'), isTrue);

      await service.start(
        bpm: 130,
        pattern: const [BeatEmphasis.forte, BeatEmphasis.normal],
        subdivision: 2,
      );
      final startCall = audioCalls.firstWhere((c) => c.method == 'start');
      expect(startCall.arguments['bpm'], equals(130));
      expect(startCall.arguments['pattern'], equals(['forte', 'normal']));
      expect(startCall.arguments['subdivision'], equals(2));

      await service.updateBpm(140);
      final updateBpmCall = audioCalls.firstWhere((c) => c.method == 'updateBpm');
      expect(updateBpmCall.arguments['bpm'], equals(140));

      await service.updatePattern(const [BeatEmphasis.forte], subdivision: 1);
      final updatePatternCall = audioCalls.firstWhere((c) => c.method == 'updatePattern');
      expect(updatePatternCall.arguments['pattern'], equals(['forte']));

      await service.playChime(soundName: 'chime_zen', volume: 0.8);
      final playChimeCall = audioCalls.firstWhere((c) => c.method == 'playChime');
      expect(playChimeCall.arguments['soundName'], equals('chime_zen'));
      expect(playChimeCall.arguments['volume'], equals(0.8));

      await service.stop();
      expect(audioCalls.any((c) => c.method == 'stop'), isTrue);
    });

    test('WakelockService invoca enable e disable no canal nativo', () async {
      final wakelock = WakelockService(channel: wakelockChannel);

      await wakelock.enable();
      expect(wakelockCalls.any((c) => c.method == 'enable'), isTrue);
      expect(wakelock.isEnabled, isTrue);

      await wakelock.disable();
      expect(wakelockCalls.any((c) => c.method == 'disable'), isTrue);
      expect(wakelock.isEnabled, isFalse);
    });

    test('subdivisão de colcheias preserva o padrão de acentuações na cabeça do tempo', () async {
      final cache = PcmSoundCache();
      await cache.preloadAll();
      final clockPort = FakeClockPort();
      final service = NativeMetronomeAudioService(
        soundCache: cache,
        clockPort: clockPort,
        channel: audioChannel,
      );

      final playedSamples = <(String, double)>[];
      service.onSamplePlayed = (sample, vol) {
        playedSamples.add((sample, vol));
      };

      // Compasso com 2 tempos: Forte (1.0), Normal (0.75), com subdivisão = 2 (colcheias)
      await service.start(
        bpm: 120,
        pattern: const [BeatEmphasis.forte, BeatEmphasis.normal],
        subdivision: 2,
      );

      // 4 ticks = 2 batimentos completos (com 2 colcheias cada)
      // Tick 1 (Tempo 1, Subdiv 0): Forte
      clockPort.advance(const Duration(milliseconds: 250));
      // Tick 2 (Tempo 1, Subdiv 1): Subdivisão suave
      clockPort.advance(const Duration(milliseconds: 250));
      // Tick 3 (Tempo 2, Subdiv 0): Normal
      clockPort.advance(const Duration(milliseconds: 250));
      // Tick 4 (Tempo 2, Subdiv 1): Subdivisão suave
      clockPort.advance(const Duration(milliseconds: 250));

      expect(playedSamples.length, equals(4));
      // Tempo 1, cabeça
      expect(playedSamples[0].$1, equals('click_wood_high'));
      expect(playedSamples[0].$2, equals(1.0));
      // Tempo 1, contratempo
      expect(playedSamples[1].$1, equals('click_wood_low'));
      expect(playedSamples[1].$2, equals(0.30));
      // Tempo 2, cabeça
      expect(playedSamples[2].$1, equals('click_wood_mid'));
      expect(playedSamples[2].$2, equals(0.75));
      // Tempo 2, contratempo
      expect(playedSamples[3].$1, equals('click_wood_low'));
      expect(playedSamples[3].$2, equals(0.30));

      await service.stop();
    });
  });
}
