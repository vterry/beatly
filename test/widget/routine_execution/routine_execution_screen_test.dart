import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/routine.dart';
import 'package:beatly/domain/models/routine_activity.dart';
import 'package:beatly/domain/models/routine_execution_state.dart';
import 'package:beatly/domain/state_machines/routine_execution_coordinator.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/routine_execution/view_models/routine_execution_view_model.dart';
import 'package:beatly/ui/features/routine_execution/views/routine_execution_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_clock_port.dart';
import '../../fakes/fake_metronome_audio_port.dart';
import '../../fakes/fake_session_repository.dart';

void main() {
  late FakeClockPort clockPort;
  late FakeMetronomeAudioPort audioPort;
  late FakeSessionRepository sessionRepository;
  late RoutineExecutionCoordinator coordinator;
  late RoutineExecutionViewModel viewModel;

  final now = DateTime.utc(2026, 3, 15, 10, 0, 0);

  Routine createTestRoutine() {
    return Routine(
      id: 'routine-screen-test',
      name: 'Rotina de Aquecimento Widget',
      createdAt: now,
      updatedAt: now,
      activities: [
        RoutineActivity(
          id: 'act-w-1',
          routineId: 'routine-screen-test',
          orderIndex: 0,
          name: 'Atividade Técnica 1',
          category: ActivityCategory.tecnica,
          durationSeconds: 10,
          bpm: 120,
          autoStartMetronome: true,
        ),
        RoutineActivity(
          id: 'act-w-2',
          routineId: 'routine-screen-test',
          orderIndex: 1,
          name: 'Atividade Velocidade 2',
          category: ActivityCategory.velocidade,
          durationSeconds: 10,
          bpm: 150,
          autoStartMetronome: true,
        ),
      ],
    );
  }

  setUp(() {
    clockPort = FakeClockPort(initialTime: now);
    audioPort = FakeMetronomeAudioPort();
    sessionRepository = FakeSessionRepository();
    coordinator = RoutineExecutionCoordinator(
      clockPort: clockPort,
      audioPort: audioPort,
      sessionRepository: sessionRepository,
      idGenerator: () => 'fixed-screen-uuid',
    );
    viewModel = RoutineExecutionViewModel(coordinator: coordinator);
  });

  tearDown(() {
    viewModel.dispose();
    coordinator.dispose();
    clockPort.dispose();
  });

  Widget buildTestApp({required Routine routine, int prepSeconds = 5}) {
    return MaterialApp(
      theme: ObsidianTheme.darkTheme,
      home: RoutineExecutionScreen(
        viewModel: viewModel,
        routine: routine,
        preparationSeconds: prepSeconds,
        transitionSeconds: 5,
      ),
    );
  }

  group('RoutineExecutionScreen Widget Tests', () {
    testWidgets(
      'WTC-06.01: Durante preparação, widget execution_prep_overlay exibe "Preparar" e contagem decrescente',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final routine = createTestRoutine();
        await tester.pumpWidget(buildTestApp(routine: routine, prepSeconds: 5));
        await tester.pump();

        expect(find.byKey(const ValueKey('execution_prep_overlay')), findsOneWidget);
        expect(find.text('Preparar'), findsOneWidget);
        expect(find.text('00:05'), findsOneWidget);
        expect(find.text('Atividade Técnica 1'), findsOneWidget);

        // Avança 2 segundos no relógio
        clockPort.advance(const Duration(seconds: 2));
        await tester.pump();

        expect(find.text('00:03'), findsOneWidget);
        expect(find.byKey(const ValueKey('prep_btn_skip_now')), findsOneWidget);
      },
    );

    testWidgets(
      'WTC-06.02: Durante transição, clicar em transition_btn_skip_now encerra transição e inicia próxima atividade',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final routine = createTestRoutine();
        // Inicia sem preparação para entrar direto em running
        await tester.pumpWidget(buildTestApp(routine: routine, prepSeconds: 0));
        await tester.pump();

        expect(find.text('Atividade Técnica 1'), findsOneWidget);

        // Avança 10s para esgotar a atividade 1 e entrar na transição
        clockPort.advance(const Duration(seconds: 10));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('execution_transition_overlay')),
          findsOneWidget,
        );
        expect(find.text('Transição Suave'), findsOneWidget);
        expect(find.text('Atividade Velocidade 2'), findsOneWidget);

        // Clica em Iniciar Agora para pular transição
        final skipBtn = find.byKey(const ValueKey('transition_btn_skip_now'));
        expect(skipBtn, findsOneWidget);
        await tester.tap(skipBtn);
        await tester.pump();

        expect(
          find.byKey(const ValueKey('execution_transition_overlay')),
          findsNothing,
        );
        expect(find.text('Atividade Velocidade 2'), findsOneWidget);
        expect(find.byKey(const ValueKey('execution_timer_text')), findsOneWidget);
      },
    );

    testWidgets(
      'WTC-06.03: Clicar no botão execution_btn_complete conclui antecipadamente e apresenta execution_completed_view persistindo no repositório',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final routine = createTestRoutine();
        await tester.pumpWidget(buildTestApp(routine: routine, prepSeconds: 0));
        await tester.pump();

        // Pratica 3 segundos da atividade 1
        clockPort.advance(const Duration(seconds: 3));
        await tester.pump();

        final completeBtn = find.byKey(const ValueKey('execution_btn_complete'));
        expect(completeBtn, findsOneWidget);
        await tester.tap(completeBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('execution_completed_view')),
          findsOneWidget,
        );
        expect(find.text('Treino Concluído!'), findsOneWidget);
        expect(find.text('Técnica'), findsOneWidget);

        expect(sessionRepository.savedSessions.length, equals(1));
        expect(sessionRepository.savedSessions.first.isCompletedEarly, isTrue);
        expect(
          sessionRepository.savedSessions.first.totalDurationSeconds,
          equals(3),
        );
      },
    );

    testWidgets(
      'WTC-06.04: Clicar em execution_btn_cancel abre confirmação; dialog_btn_keep_training mantém; dialog_btn_confirm_cancel descarta sem salvar sessão',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final routine = createTestRoutine();
        await tester.pumpWidget(buildTestApp(routine: routine, prepSeconds: 0));
        await tester.pump();

        clockPort.advance(const Duration(seconds: 4));
        await tester.pump();

        // Clica em Cancelar treino
        final cancelBtn = find.byKey(const ValueKey('execution_btn_cancel'));
        expect(cancelBtn, findsOneWidget);
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        // Diálogo de confirmação aberto
        expect(find.text('Cancelar treino em andamento?'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('dialog_btn_keep_training')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('dialog_btn_confirm_cancel')),
          findsOneWidget,
        );

        // Clica em "Continuar treino"
        await tester.tap(find.byKey(const ValueKey('dialog_btn_keep_training')));
        await tester.pumpAndSettle();

        // Diálogo fechou, continua em running
        expect(find.text('Cancelar treino em andamento?'), findsNothing);
        expect(coordinator.state, isA<ExecutionStateRunning>());
        expect(sessionRepository.savedSessions, isEmpty);

        // Clica novamente em Cancelar treino
        await tester.tap(find.byKey(const ValueKey('execution_btn_cancel')));
        await tester.pumpAndSettle();

        // Confirma cancelamento
        await tester.tap(find.byKey(const ValueKey('dialog_btn_confirm_cancel')));
        await tester.pumpAndSettle();

        expect(coordinator.state, isA<ExecutionStateCanceled>());
        expect(sessionRepository.savedSessions, isEmpty);
      },
    );

    testWidgets(
      'WTC-06.05: Ajuste de BPM em tempo real durante a execução da rotina',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final routine = createTestRoutine();
        await tester.pumpWidget(buildTestApp(routine: routine, prepSeconds: 0));
        await tester.pump();

        expect(find.text('120 BPM'), findsOneWidget);

        // Toca em +5
        await tester.tap(find.byKey(const ValueKey('execution_btn_bpm_plus_5')));
        await tester.pump();
        expect(find.text('125 BPM'), findsOneWidget);
        expect(audioPort.currentBpm, equals(125));

        // Toca em +1
        await tester.tap(find.byKey(const ValueKey('execution_btn_bpm_plus_1')));
        await tester.pump();
        expect(find.text('126 BPM'), findsOneWidget);

        // Toca em -5
        await tester.tap(find.byKey(const ValueKey('execution_btn_bpm_minus_5')));
        await tester.pump();
        expect(find.text('121 BPM'), findsOneWidget);

        // Toca em -1
        await tester.tap(find.byKey(const ValueKey('execution_btn_bpm_minus_1')));
        await tester.pump();
        expect(find.text('120 BPM'), findsOneWidget);
      },
    );

    testWidgets(
      'WTC-06.06: Abrir modal de ajustes de metrônomo no treino, alterar subdivisão e volumes dos pulsos',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final routine = createTestRoutine();
        await tester.pumpWidget(buildTestApp(routine: routine, prepSeconds: 0));
        await tester.pump();

        // Abre o modal de ajustes do metrônomo
        final openBtn = find.byKey(const ValueKey('execution_btn_open_metronome_sheet'));
        expect(openBtn, findsOneWidget);
        await tester.tap(openBtn);
        await tester.pumpAndSettle();

        expect(find.text('Ajustes do Metrônomo no Treino'), findsOneWidget);
        expect(find.text('SUBDIVISÃO DE TEMPO'), findsOneWidget);
        expect(find.text('VOLUMES DOS PULSOS'), findsOneWidget);

        // Seleciona subdivisão 3x (Tercina)
        await tester.tap(find.byKey(const ValueKey('routine_subdivision_btn_3')));
        await tester.pump();
        expect(viewModel.activeSubdivision, equals(3));
        expect(audioPort.activeSubdivision, equals(3));

        // Toca no primeiro pulso para alterar de forte para normal
        await tester.tap(find.byKey(const ValueKey('routine_beat_emphasis_btn_0')));
        await tester.pump();
        expect(viewModel.activePattern[0].name, equals('normal'));

        // Clica em silenciar
        await tester.tap(find.byKey(const ValueKey('routine_metronome_mute_pattern')));
        await tester.pump();
        expect(viewModel.activePattern.every((p) => p.name == 'mudo'), isTrue);

        // Clica em padrão
        await tester.tap(find.byKey(const ValueKey('routine_metronome_reset_pattern')));
        await tester.pump();
        expect(viewModel.activePattern[0].name, equals('forte'));
      },
    );
  });
}
