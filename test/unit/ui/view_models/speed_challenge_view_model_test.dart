import 'package:beatly/domain/models/beat_emphasis.dart';
import 'package:beatly/domain/models/speed_challenge_config.dart';
import 'package:beatly/domain/state_machines/speed_challenge_coordinator.dart';
import 'package:beatly/ui/features/metronome/view_models/speed_challenge_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_clock_port.dart';
import '../../../fakes/fake_metronome_audio_port.dart';

void main() {
  group('SpeedChallengeViewModel (RF-04)', () {
    late FakeMetronomeAudioPort audioPort;
    late FakeClockPort clockPort;
    late SpeedChallengeCoordinator coordinator;
    late SpeedChallengeViewModel viewModel;

    setUp(() {
      audioPort = FakeMetronomeAudioPort();
      clockPort = FakeClockPort();
      coordinator = SpeedChallengeCoordinator(
        audioPort: audioPort,
        clockPort: clockPort,
      );
      viewModel = SpeedChallengeViewModel(coordinator: coordinator);
    });

    tearDown(() async {
      viewModel.dispose();
      await coordinator.dispose();
      clockPort.dispose();
    });

    test('valida formulário em tempo real e calcula progresso percentual', () async {
      viewModel.setStartBpm(140);
      viewModel.setTargetBpm(120);
      expect(viewModel.isValid, isFalse);
      expect(viewModel.validationError, isNotNull);

      viewModel.setStartBpm(100);
      viewModel.setTargetBpm(140);
      viewModel.setBpmStep(10);
      viewModel.setEveryBars(2);
      expect(viewModel.isValid, isTrue);

      await viewModel.startChallenge(beatsPerBar: 4);
      expect(viewModel.isRunning, isTrue);
      expect(viewModel.progressRatio, equals(0.0));

      await coordinator.onBarCompleted();
      await coordinator.onBarCompleted();
      expect(viewModel.currentBpm, equals(110));
      expect(viewModel.progressRatio, closeTo(0.25, 0.01));
    });

    test('exibe a velocidade atingida ao concluir o desafio', () async {
      viewModel.setStartBpm(100);
      viewModel.setTargetBpm(120);
      viewModel.setBpmStep(20);
      viewModel.setEveryBars(1);
      viewModel.setCompletionBehavior(ChallengeCompletionBehavior.stopAndChime);

      await viewModel.startChallenge(beatsPerBar: 4);
      // 1o compasso sobe para 120
      await coordinator.onBarCompleted();
      expect(viewModel.currentBpm, equals(120));

      // 2o compasso conclui no teto 120
      await coordinator.onBarCompleted();
      expect(viewModel.isCompleted, isTrue);
      expect(viewModel.isRunning, isFalse);
      expect(viewModel.currentBpm, equals(120));
    });

    test('aplica divisão do tempo configurada no desafio (Tercinas e Mínimas)', () async {
      viewModel.setTimeDivision(ChallengeTimeDivision.tercina);
      await viewModel.startChallenge(beatsPerBar: 4);
      expect(audioPort.activeSubdivision, equals(3));

      await viewModel.stopChallenge();

      viewModel.setTimeDivision(ChallengeTimeDivision.minima);
      await viewModel.startChallenge(beatsPerBar: 4);
      expect(audioPort.activeSubdivision, equals(1));
      expect(
        audioPort.activePattern,
        equals([
          BeatEmphasis.forte,
          BeatEmphasis.mudo,
          BeatEmphasis.normal,
          BeatEmphasis.mudo,
        ]),
      );
    });
  });
}
