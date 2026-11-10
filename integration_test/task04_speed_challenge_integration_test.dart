import 'package:beatly/domain/state_machines/speed_challenge_coordinator.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/metronome/view_models/metronome_view_model.dart';
import 'package:beatly/ui/features/metronome/view_models/speed_challenge_view_model.dart';
import 'package:beatly/ui/features/metronome/views/metronome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fakes/fake_clock_port.dart';
import '../test/fakes/fake_metronome_audio_port.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'TASK-04 Integration: abrir Modo Desafio pela MetronomeScreen, iniciar e progredir velocidade',
    (tester) async {
      final audioPort = FakeMetronomeAudioPort();
      final clockPort = FakeClockPort();
      final metronomeVm = MetronomeViewModel(
        audioPort: audioPort,
        clockPort: clockPort,
      );
      final coordinator = SpeedChallengeCoordinator(
        audioPort: audioPort,
        clockPort: clockPort,
      );
      final challengeVm = SpeedChallengeViewModel(coordinator: coordinator);

      await tester.pumpWidget(
        MaterialApp(
          theme: ObsidianTheme.darkTheme,
          home: MetronomeScreen(
            viewModel: metronomeVm,
            challengeViewModel: challengeVm,
          ),
        ),
      );

      // Abre o BottomSheet pelo botão de cabeçalho
      await tester.tap(
        find.byKey(const ValueKey('metronome_btn_open_challenge')),
      );
      await tester.pumpAndSettle();

      // Inicia o desafio com os valores padrão válidos (90 -> 140, +5 a cada 4 compassos)
      final startBtn = find.byKey(const ValueKey('challenge_btn_start'));
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      await tester.pump();

      expect(challengeVm.isRunning, isTrue);
      expect(audioPort.currentBpm, equals(90));

      for (var i = 0; i < 4; i++) {
        await coordinator.onBarCompleted();
      }
      await tester.pump();

      expect(challengeVm.currentBpm, equals(95));
      expect(audioPort.currentBpm, equals(95));

      challengeVm.dispose();
      await coordinator.dispose();
      metronomeVm.dispose();
      clockPort.dispose();
    },
  );
}

