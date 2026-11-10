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
  });
}
