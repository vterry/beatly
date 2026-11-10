import 'package:beatly/domain/state_machines/speed_challenge_coordinator.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/metronome/view_models/speed_challenge_view_model.dart';
import 'package:beatly/ui/features/metronome/views/speed_challenge_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_clock_port.dart';
import '../../fakes/fake_metronome_audio_port.dart';

void main() {
  group('SpeedChallengeBottomSheet Widget Tests (TASK-04)', () {
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

    Widget buildHarness() {
      return MaterialApp(
        theme: ObsidianTheme.darkTheme,
        home: Scaffold(
          body: SpeedChallengeBottomSheet(viewModel: viewModel),
        ),
      );
    }

    testWidgets(
      'WTC-04.01: digitar BPM inicial = 150 e BPM final = 120 desabilita challenge_btn_start e exibe challenge_error_text (EC-01)',
      (tester) async {
        await tester.pumpWidget(buildHarness());

        await tester.enterText(
          find.byKey(const ValueKey('challenge_input_start_bpm')),
          '150',
        );
        await tester.enterText(
          find.byKey(const ValueKey('challenge_input_target_bpm')),
          '120',
        );
        await tester.pump();

        expect(
          find.byKey(const ValueKey('challenge_error_text')),
          findsOneWidget,
        );
        expect(viewModel.isValid, isFalse);

        // Tentar clicar no botão desabilitado não deve iniciar o desafio
        await tester.tap(find.byKey(const ValueKey('challenge_btn_start')));
        await tester.pump();
        expect(viewModel.isRunning, isFalse);
      },
    );

    testWidgets(
      'WTC-04.02: com campos válidos, clicar em challenge_btn_start inicia o desafio e exibe challenge_progress_bar',
      (tester) async {
        await tester.pumpWidget(buildHarness());

        await tester.enterText(
          find.byKey(const ValueKey('challenge_input_start_bpm')),
          '100',
        );
        await tester.enterText(
          find.byKey(const ValueKey('challenge_input_target_bpm')),
          '140',
        );
        await tester.enterText(
          find.byKey(const ValueKey('challenge_input_bpm_step')),
          '10',
        );
        await tester.enterText(
          find.byKey(const ValueKey('challenge_input_every_bars')),
          '2',
        );
        await tester.pump();

        expect(find.byKey(const ValueKey('challenge_error_text')), findsNothing);

        final startBtn = find.byKey(const ValueKey('challenge_btn_start'));
        await tester.ensureVisible(startBtn);
        await tester.tap(startBtn);
        await tester.pump();

        expect(viewModel.isRunning, isTrue);
        expect(
          find.byKey(const ValueKey('challenge_progress_bar')),
          findsOneWidget,
        );

        // Avança 2 compassos -> BPM sobe de 100 para 110
        await coordinator.onBarCompleted();
        await coordinator.onBarCompleted();
        await tester.pump();

        expect(viewModel.currentBpm, equals(110));
        expect(find.text('EM CURSO • 110 BPM'), findsOneWidget);
      },
    );
  });
}

