import 'package:beatly/domain/models/speed_challenge_config.dart';
import 'package:beatly/domain/state_machines/speed_challenge_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_clock_port.dart';
import '../../../fakes/fake_metronome_audio_port.dart';

void main() {
  group('SpeedChallengeCoordinator (RF-04 / EC-02)', () {
    late FakeMetronomeAudioPort audioPort;
    late FakeClockPort clockPort;
    late SpeedChallengeCoordinator coordinator;

    setUp(() {
      audioPort = FakeMetronomeAudioPort();
      clockPort = FakeClockPort();
      coordinator = SpeedChallengeCoordinator(
        audioPort: audioPort,
        clockPort: clockPort,
      );
    });

    tearDown(() async {
      await coordinator.dispose();
      clockPort.dispose();
    });

    test('TC-04.04: desafio por compassos: 100 -> 120 (+5 a cada 4 compassos) sobe para 105 após 4º compasso (B-RF-04.1)', () async {
      await coordinator.startChallenge(
        const SpeedChallengeConfig(
          startBpm: 100,
          targetBpm: 120,
          bpmStep: 5,
          triggerMode: ChallengeTriggerMode.byBars,
          everyBars: 4,
        ),
        beatsPerBar: 4,
      );

      expect(coordinator.currentBpm, equals(100));
      expect(audioPort.currentBpm, equals(100));

      // 3 compassos completos: ainda em 100 BPM
      await coordinator.onBarCompleted();
      await coordinator.onBarCompleted();
      await coordinator.onBarCompleted();
      expect(coordinator.currentBpm, equals(100));

      // 4º compasso completo -> sobe imediatamente para 105 BPM
      await coordinator.onBarCompleted();
      expect(coordinator.currentBpm, equals(105));
      expect(audioPort.currentBpm, equals(105));
    });

    test('TC-04.05: ajuste no teto (EC-02): atual 115, step 10, max 120 trava exatamente em 120 BPM', () async {
      await coordinator.startChallenge(
        const SpeedChallengeConfig(
          startBpm: 115,
          targetBpm: 120,
          bpmStep: 10,
          triggerMode: ChallengeTriggerMode.byBars,
          everyBars: 1,
        ),
        beatsPerBar: 4,
      );

      // Como step (10) > (120-115), testamos iniciando em 105 -> +10 -> 115 -> +10 -> 120:
      await coordinator.startChallenge(
        const SpeedChallengeConfig(
          startBpm: 105,
          targetBpm: 120,
          bpmStep: 10,
          triggerMode: ChallengeTriggerMode.byBars,
          everyBars: 1,
        ),
        beatsPerBar: 4,
      );

      expect(coordinator.currentBpm, equals(105));
      await coordinator.onBarCompleted();
      expect(coordinator.currentBpm, equals(115));

      // Próximo incremento (+10) passaria para 125, mas EC-02 trava em 120:
      await coordinator.onBarCompleted();
      expect(coordinator.currentBpm, equals(120));
      expect(audioPort.currentBpm, equals(120));
    });

    test('TC-04.06: opção stopAndChime no teto: ao completar compasso final no BPM máximo, toca chime e para', () async {
      await coordinator.startChallenge(
        const SpeedChallengeConfig(
          startBpm: 110,
          targetBpm: 120,
          bpmStep: 10,
          triggerMode: ChallengeTriggerMode.byBars,
          everyBars: 1,
          onTargetReached: ChallengeCompletionBehavior.stopAndChime,
        ),
        beatsPerBar: 4,
      );

      // 1º compasso -> atinge 120 BPM (teto)
      await coordinator.onBarCompleted();
      expect(coordinator.currentBpm, equals(120));
      expect(coordinator.isRunning, isTrue);

      // Compasso de finalização em 120 BPM -> toca chime e encerra
      await coordinator.onBarCompleted();
      expect(coordinator.isRunning, isFalse);
      expect(coordinator.isCompleted, isTrue);
      expect(audioPort.playedChimesCount, equals(1));
      expect(audioPort.isPlaying, isFalse);
    });

    test('TC-04.07: opção keepRunning no teto: mantém tocando em BPM máximo indefinidamente', () async {
      await coordinator.startChallenge(
        const SpeedChallengeConfig(
          startBpm: 115,
          targetBpm: 120,
          bpmStep: 5,
          triggerMode: ChallengeTriggerMode.byBars,
          everyBars: 1,
          onTargetReached: ChallengeCompletionBehavior.keepRunning,
        ),
        beatsPerBar: 4,
      );

      await coordinator.onBarCompleted();
      expect(coordinator.currentBpm, equals(120));

      await coordinator.onBarCompleted();
      await coordinator.onBarCompleted();
      expect(coordinator.isRunning, isTrue);
      expect(coordinator.currentBpm, equals(120));
      expect(audioPort.isPlaying, isTrue);
    });
  });
}

