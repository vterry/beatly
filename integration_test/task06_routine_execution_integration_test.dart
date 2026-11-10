import 'package:beatly/data/repositories/drift_session_repository.dart';
import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/routine.dart';
import 'package:beatly/domain/models/routine_activity.dart';
import 'package:beatly/domain/state_machines/routine_execution_coordinator.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/routine_execution/view_models/routine_execution_view_model.dart';
import 'package:beatly/ui/features/routine_execution/views/routine_execution_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fakes/fake_clock_port.dart';
import '../test/fakes/fake_metronome_audio_port.dart';
import '../test/fakes/in_memory_app_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 3, 15, 10, 0, 0);

  Routine createSampleRoutine() {
    return Routine(
      id: 'routine-integration-1',
      name: 'Rotina de Integração Drift',
      createdAt: now,
      updatedAt: now,
      activities: [
        RoutineActivity(
          id: 'act-int-1',
          routineId: 'routine-integration-1',
          orderIndex: 0,
          name: 'Arpejos Maiores',
          category: ActivityCategory.tecnica,
          durationSeconds: 10,
          bpm: 120,
          autoStartMetronome: true,
        ),
        RoutineActivity(
          id: 'act-int-2',
          routineId: 'routine-integration-1',
          orderIndex: 1,
          name: 'Padrões de Velocidade',
          category: ActivityCategory.velocidade,
          durationSeconds: 10,
          bpm: 160,
          autoStartMetronome: true,
        ),
      ],
    );
  }

  group('TASK-06 Integration Tests: Execução de Rotina e Persistência Drift', () {
    testWidgets(
      'Fluxo 1: Conclusão Manual Antecipada via botão "Concluir" persiste sessão no SQLite com isCompletedEarly == true',
      (tester) async {
        final db = createInMemoryAppDatabase();
        final sessionRepo = DriftSessionRepository(database: db);
        final clockPort = FakeClockPort(initialTime: now);
        final audioPort = FakeMetronomeAudioPort();

        final coordinator = RoutineExecutionCoordinator(
          clockPort: clockPort,
          audioPort: audioPort,
          sessionRepository: sessionRepo,
        );
        final viewModel = RoutineExecutionViewModel(coordinator: coordinator);

        await tester.pumpWidget(
          MaterialApp(
            theme: ObsidianTheme.darkTheme,
            home: RoutineExecutionScreen(
              viewModel: viewModel,
              routine: createSampleRoutine(),
              preparationSeconds: 0,
              transitionSeconds: 5,
            ),
          ),
        );
        await tester.pump();

        // Pratica 5 segundos da primeira atividade
        clockPort.advance(const Duration(seconds: 5));
        await tester.pump();

        // Clica no botão "Concluir"
        await tester.tap(find.byKey(const ValueKey('execution_btn_complete')));
        await tester.pumpAndSettle();

        // Verifica que a tela de conclusão está visível
        expect(find.byKey(const ValueKey('execution_completed_view')), findsOneWidget);

        // Consulta direto no SQLite via repositório Drift
        final savedSessions = await sessionRepo.getSessionsByMonth(
          year: 2026,
          month: 3,
        );

        expect(savedSessions.length, equals(1));
        final session = savedSessions.first;
        expect(session.isCompletedEarly, isTrue);
        expect(session.totalDurationSeconds, equals(5));
        expect(session.routineNameSnapshot, equals('Rotina de Integração Drift'));
        expect(session.categoryLogs.length, equals(1));
        expect(session.categoryLogs.first.category, equals(ActivityCategory.tecnica));
        expect(session.categoryLogs.first.durationSeconds, equals(5));

        viewModel.dispose();
        coordinator.dispose();
        clockPort.dispose();
        await db.close();
      },
    );

    testWidgets(
      'Fluxo 2: Cancelamento com Descarte via diálogo de confirmação descarta progresso sem salvar sessão no SQLite',
      (tester) async {
        final db = createInMemoryAppDatabase();
        final sessionRepo = DriftSessionRepository(database: db);
        final clockPort = FakeClockPort(initialTime: now);
        final audioPort = FakeMetronomeAudioPort();

        final coordinator = RoutineExecutionCoordinator(
          clockPort: clockPort,
          audioPort: audioPort,
          sessionRepository: sessionRepo,
        );
        final viewModel = RoutineExecutionViewModel(coordinator: coordinator);

        await tester.pumpWidget(
          MaterialApp(
            theme: ObsidianTheme.darkTheme,
            home: RoutineExecutionScreen(
              viewModel: viewModel,
              routine: createSampleRoutine(),
              preparationSeconds: 0,
              transitionSeconds: 5,
            ),
          ),
        );
        await tester.pump();

        // Pratica 4 segundos
        clockPort.advance(const Duration(seconds: 4));
        await tester.pump();

        // Clica em Cancelar treino
        await tester.tap(find.byKey(const ValueKey('execution_btn_cancel')));
        await tester.pumpAndSettle();

        // Confirma descarte no diálogo
        await tester.tap(find.byKey(const ValueKey('dialog_btn_confirm_cancel')));
        await tester.pumpAndSettle();

        // Consulta no SQLite: deve estar vazio
        final savedSessions = await sessionRepo.getSessionsByMonth(
          year: 2026,
          month: 3,
        );
        expect(savedSessions, isEmpty);

        viewModel.dispose();
        coordinator.dispose();
        clockPort.dispose();
        await db.close();
      },
    );

    testWidgets(
      'Fluxo 3: Conclusão Automática ao finalizar todas as atividades persiste sessão completa no SQLite com isCompletedEarly == false',
      (tester) async {
        final db = createInMemoryAppDatabase();
        final sessionRepo = DriftSessionRepository(database: db);
        final clockPort = FakeClockPort(initialTime: now);
        final audioPort = FakeMetronomeAudioPort();

        final singleRoutine = Routine(
          id: 'routine-single-flow',
          name: 'Rotina Curta Completa',
          createdAt: now,
          updatedAt: now,
          activities: [
            RoutineActivity(
              id: 'act-single-1',
              routineId: 'routine-single-flow',
              orderIndex: 0,
              name: 'Prática de Escalas',
              category: ActivityCategory.tecnica,
              durationSeconds: 10,
              bpm: 100,
              autoStartMetronome: true,
            ),
          ],
        );

        final coordinator = RoutineExecutionCoordinator(
          clockPort: clockPort,
          audioPort: audioPort,
          sessionRepository: sessionRepo,
        );
        final viewModel = RoutineExecutionViewModel(coordinator: coordinator);

        await tester.pumpWidget(
          MaterialApp(
            theme: ObsidianTheme.darkTheme,
            home: RoutineExecutionScreen(
              viewModel: viewModel,
              routine: singleRoutine,
              preparationSeconds: 0,
              transitionSeconds: 0,
            ),
          ),
        );
        await tester.pump();

        // Esgota todos os 10s da atividade
        clockPort.advance(const Duration(seconds: 10));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('execution_completed_view')), findsOneWidget);
        expect(find.text('Treino Concluído!'), findsOneWidget);

        final savedSessions = await sessionRepo.getSessionsByMonth(
          year: 2026,
          month: 3,
        );

        expect(savedSessions.length, equals(1));
        final session = savedSessions.first;
        expect(session.isCompletedEarly, isFalse);
        expect(session.totalDurationSeconds, equals(10));
        expect(session.routineNameSnapshot, equals('Rotina Curta Completa'));

        viewModel.dispose();
        coordinator.dispose();
        clockPort.dispose();
        await db.close();
      },
    );
  });
}
