import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/routine.dart';
import 'package:beatly/domain/models/routine_activity.dart';
import 'package:beatly/domain/models/routine_execution_state.dart';
import 'package:beatly/domain/state_machines/routine_execution_coordinator.dart';
import 'package:beatly/ui/features/routine_execution/view_models/routine_execution_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_clock_port.dart';
import '../../../fakes/fake_metronome_audio_port.dart';
import '../../../fakes/fake_session_repository.dart';

void main() {
  late FakeClockPort clockPort;
  late FakeMetronomeAudioPort audioPort;
  late FakeSessionRepository sessionRepository;
  late RoutineExecutionCoordinator coordinator;
  late RoutineExecutionViewModel viewModel;

  final now = DateTime.utc(2026, 3, 15, 10, 0, 0);

  Routine createTestRoutine() {
    return Routine(
      id: 'routine-vm',
      name: 'Rotina ViewModel Test',
      createdAt: now,
      updatedAt: now,
      activities: [
        RoutineActivity(
          id: 'act-vm-1',
          routineId: 'routine-vm',
          orderIndex: 0,
          name: 'Atividade 1',
          category: ActivityCategory.tecnica,
          durationSeconds: 15,
          bpm: 110,
          autoStartMetronome: true,
        ),
        RoutineActivity(
          id: 'act-vm-2',
          routineId: 'routine-vm',
          orderIndex: 1,
          name: 'Atividade 2',
          category: ActivityCategory.improviso,
          durationSeconds: 20,
          bpm: 130,
          autoStartMetronome: false,
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
      idGenerator: () => 'uuid-vm',
    );
    viewModel = RoutineExecutionViewModel(coordinator: coordinator);
  });

  tearDown(() {
    viewModel.dispose();
    coordinator.dispose();
    clockPort.dispose();
  });

  group('RoutineExecutionViewModel Unit Tests', () {
    test('Estado inicial é ExecutionStateIdle', () {
      expect(viewModel.state, isA<ExecutionStateIdle>());
      expect(viewModel.currentRoutine, isNull);
    });

    test('startRoutine atualiza estado e notifica listeners', () async {
      final routine = createTestRoutine();
      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      await viewModel.startRoutine(routine, preparationSeconds: 5);

      expect(viewModel.state, isA<ExecutionStatePreparing>());
      expect(viewModel.currentRoutine?.name, equals('Rotina ViewModel Test'));
      expect(notifyCount, greaterThanOrEqualTo(1));
    });

    test('skipTransition avança de preparação diretamente para running', () async {
      final routine = createTestRoutine();
      await viewModel.startRoutine(routine, preparationSeconds: 5);

      await viewModel.skipTransition();

      expect(viewModel.state, isA<ExecutionStateRunning>());
      final running = viewModel.state as ExecutionStateRunning;
      expect(running.currentActivityIndex, equals(0));
      expect(running.currentActivity.name, equals('Atividade 1'));
    });

    test('pause e resume alternam estado e notificam listeners', () async {
      final routine = createTestRoutine();
      await viewModel.startRoutine(routine, preparationSeconds: 0);

      expect(viewModel.state, isA<ExecutionStateRunning>());

      await viewModel.pause();
      expect(viewModel.state, isA<ExecutionStatePaused>());

      await viewModel.resume();
      expect(viewModel.state, isA<ExecutionStateRunning>());
    });

    test('skipToNext e previous navegam pelas atividades', () async {
      final routine = createTestRoutine();
      await viewModel.startRoutine(routine, preparationSeconds: 0);

      expect((viewModel.state as ExecutionStateRunning).currentActivityIndex, equals(0));

      await viewModel.skipToNext();
      expect((viewModel.state as ExecutionStateRunning).currentActivityIndex, equals(1));

      await viewModel.previous();
      expect((viewModel.state as ExecutionStateRunning).currentActivityIndex, equals(0));
    });

    test('toggleMetronome alterna status do metrônomo', () async {
      final routine = createTestRoutine();
      await viewModel.startRoutine(routine, preparationSeconds: 0);

      expect((viewModel.state as ExecutionStateRunning).isMetronomeActive, isTrue);

      await viewModel.toggleMetronome();
      expect((viewModel.state as ExecutionStateRunning).isMetronomeActive, isFalse);

      await viewModel.toggleMetronome();
      expect((viewModel.state as ExecutionStateRunning).isMetronomeActive, isTrue);
    });

    test('completeRoutineEarly transita para completed e grava sessão', () async {
      final routine = createTestRoutine();
      await viewModel.startRoutine(routine, preparationSeconds: 0);
      clockPort.advance(const Duration(seconds: 5));

      await viewModel.completeRoutineEarly();

      expect(viewModel.state, isA<ExecutionStateCompleted>());
      expect(sessionRepository.savedSessions.length, equals(1));
      expect(sessionRepository.savedSessions.first.isCompletedEarly, isTrue);
    });

    test('cancelRoutine transita para canceled sem gravar sessão', () async {
      final routine = createTestRoutine();
      await viewModel.startRoutine(routine, preparationSeconds: 0);
      clockPort.advance(const Duration(seconds: 5));

      await viewModel.cancelRoutine();

      expect(viewModel.state, isA<ExecutionStateCanceled>());
      expect(sessionRepository.savedSessions, isEmpty);
    });
  });
}
