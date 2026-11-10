import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/beat_emphasis.dart';
import 'package:beatly/domain/models/routine.dart';
import 'package:beatly/domain/models/routine_activity.dart';
import 'package:beatly/domain/models/routine_execution_state.dart';
import 'package:beatly/domain/state_machines/routine_execution_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_clock_port.dart';
import '../../../fakes/fake_metronome_audio_port.dart';
import '../../../fakes/fake_session_repository.dart';

void main() {
  late FakeClockPort clockPort;
  late FakeMetronomeAudioPort audioPort;
  late FakeSessionRepository sessionRepository;
  late RoutineExecutionCoordinator coordinator;

  final now = DateTime.utc(2026, 3, 15, 10, 0, 0);

  Routine createTestRoutine({
    int activity1Duration = 10,
    int activity2Duration = 10,
    bool autoStartMetronome = true,
    int? bpm = 120,
  }) {
    return Routine(
      id: 'routine-1',
      name: 'Rotina de Aquecimento',
      createdAt: now,
      updatedAt: now,
      activities: [
        RoutineActivity(
          id: 'act-1',
          routineId: 'routine-1',
          orderIndex: 0,
          name: 'Palhetada Alternada',
          category: ActivityCategory.tecnica,
          durationSeconds: activity1Duration,
          bpm: bpm,
          autoStartMetronome: autoStartMetronome,
        ),
        RoutineActivity(
          id: 'act-2',
          routineId: 'routine-1',
          orderIndex: 1,
          name: 'Escala Pentatônica',
          category: ActivityCategory.velocidade,
          durationSeconds: activity2Duration,
          bpm: 140,
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
      idGenerator: () => 'fixed-uuid',
    );
  });

  tearDown(() {
    coordinator.dispose();
    clockPort.dispose();
  });

  group('RoutineExecutionCoordinator Unit Tests', () {
    test(
      'TC-06.01: Ao chamar start(), transita imediatamente para ExecutionStatePreparing com 5s',
      () async {
        final routine = createTestRoutine();

        expect(coordinator.state, isA<ExecutionStateIdle>());

        await coordinator.start(routine, preparationSeconds: 5);

        expect(coordinator.state, isA<ExecutionStatePreparing>());
        final prepState = coordinator.state as ExecutionStatePreparing;
        expect(prepState.remainingSeconds, equals(5));
        expect(prepState.firstActivity.name, equals('Palhetada Alternada'));
        expect(prepState.totalActivities, equals(2));
        expect(audioPort.isPlaying, isFalse);
      },
    );

    test(
      'TC-06.02: Ao avançar 5s no FakeClockPort, transita automaticamente para ExecutionStateRunning e liga metrônomo se configurado',
      () async {
        final routine = createTestRoutine(autoStartMetronome: true, bpm: 120);
        await coordinator.start(routine, preparationSeconds: 5);

        // Avança 4 segundos: continua em preparação
        clockPort.advance(const Duration(seconds: 4));
        expect(coordinator.state, isA<ExecutionStatePreparing>());
        expect(
          (coordinator.state as ExecutionStatePreparing).remainingSeconds,
          equals(1),
        );
        expect(audioPort.isPlaying, isFalse);

        // Avança o 5º segundo: entra em Running da atividade 0
        clockPort.advance(const Duration(seconds: 1));
        expect(coordinator.state, isA<ExecutionStateRunning>());
        final runState = coordinator.state as ExecutionStateRunning;
        expect(runState.currentActivityIndex, equals(0));
        expect(runState.currentActivity.name, equals('Palhetada Alternada'));
        expect(runState.remainingDuration, equals(const Duration(seconds: 10)));
        expect(runState.isMetronomeActive, isTrue);
        expect(audioPort.isPlaying, isTrue);
        expect(audioPort.currentBpm, equals(120));
      },
    );

    test(
      'EC-03: se autoStartMetronome == false ou bpm == null, audioPort não inicia automaticamente',
      () async {
        final routine = createTestRoutine(autoStartMetronome: false, bpm: null);
        await coordinator.start(routine, preparationSeconds: 5);
        clockPort.advance(const Duration(seconds: 5));

        expect(coordinator.state, isA<ExecutionStateRunning>());
        final runState = coordinator.state as ExecutionStateRunning;
        expect(runState.isMetronomeActive, isFalse);
        expect(audioPort.isPlaying, isFalse);
      },
    );

    test(
      'TC-06.03: Ao esgotar o tempo da Atividade 1 em rotina multi-atividades, para metrônomo, toca aviso sonoro e entra em Transitioning com 5s',
      () async {
        final routine = createTestRoutine(activity1Duration: 10);
        await coordinator.start(routine, preparationSeconds: 0);

        expect(coordinator.state, isA<ExecutionStateRunning>());
        expect(audioPort.isPlaying, isTrue);

        // Avança 10 segundos para esgotar a atividade 1
        clockPort.advance(const Duration(seconds: 10));

        expect(audioPort.isPlaying, isFalse);
        expect(audioPort.playedChimesCount, equals(1));
        expect(coordinator.state, isA<ExecutionStateTransitioning>());

        final transState = coordinator.state as ExecutionStateTransitioning;
        expect(transState.remainingSeconds, equals(5));
        expect(transState.nextActivityIndex, equals(1));
        expect(transState.nextActivity.name, equals('Escala Pentatônica'));
      },
    );

    test(
      'TC-06.04: Durante ExecutionStateTransitioning, skipTransition() encerra contagem e inicia próxima atividade imediatamente',
      () async {
        final routine = createTestRoutine(activity1Duration: 10);
        await coordinator.start(routine, preparationSeconds: 0);
        clockPort.advance(const Duration(seconds: 10));

        expect(coordinator.state, isA<ExecutionStateTransitioning>());
        expect(audioPort.isPlaying, isFalse);

        await coordinator.skipTransition();

        expect(coordinator.state, isA<ExecutionStateRunning>());
        final runState = coordinator.state as ExecutionStateRunning;
        expect(runState.currentActivityIndex, equals(1));
        expect(runState.currentActivity.name, equals('Escala Pentatônica'));
        expect(runState.isMetronomeActive, isTrue);
        expect(audioPort.isPlaying, isTrue);
        expect(audioPort.currentBpm, equals(140));
      },
    );

    test(
      'TC-06.05: Conclusão Automática: Ao zerar o cronômetro da última atividade, transita para ExecutionStateCompleted, salva sessão com isCompletedEarly == false e desliga áudio',
      () async {
        final routine = Routine(
          id: 'routine-single',
          name: 'Rotina Curta Única',
          createdAt: now,
          updatedAt: now,
          activities: [
            RoutineActivity(
              id: 'act-only',
              routineId: 'routine-single',
              orderIndex: 0,
              name: 'Improviso Blues',
              category: ActivityCategory.improviso,
              durationSeconds: 10,
              bpm: 100,
              autoStartMetronome: true,
            ),
          ],
        );

        await coordinator.start(routine, preparationSeconds: 0);
        expect(coordinator.state, isA<ExecutionStateRunning>());
        expect(audioPort.isPlaying, isTrue);

        // Avança todos os 10 segundos
        clockPort.advance(const Duration(seconds: 10));

        expect(coordinator.state, isA<ExecutionStateCompleted>());
        expect(audioPort.isPlaying, isFalse);

        final completedState = coordinator.state as ExecutionStateCompleted;
        expect(completedState.session.isCompletedEarly, isFalse);
        expect(completedState.session.totalDurationSeconds, equals(10));
        expect(completedState.session.routineNameSnapshot, equals('Rotina Curta Única'));
        expect(
          completedState.results[ActivityCategory.improviso],
          equals(const Duration(seconds: 10)),
        );

        expect(sessionRepository.savedSessions.length, equals(1));
        expect(sessionRepository.savedSessions.first.isCompletedEarly, isFalse);
        expect(
          sessionRepository.savedSessions.first.categoryLogs.first.category,
          equals(ActivityCategory.improviso),
        );
      },
    );

    test(
      'TC-06.06: Conclusão Manual Antecipada ("Concluir"): acionar completeEarly() persiste tempo decorrido com isCompletedEarly == true',
      () async {
        final routine = createTestRoutine(activity1Duration: 10, activity2Duration: 10);
        await coordinator.start(routine, preparationSeconds: 0);

        // Pratica 10s da atividade 1 (técnica)
        clockPort.advance(const Duration(seconds: 10));
        expect(coordinator.state, isA<ExecutionStateTransitioning>());

        // Pula transição para entrar na atividade 2 (velocidade)
        await coordinator.skipTransition();
        expect(coordinator.state, isA<ExecutionStateRunning>());

        // Pratica 4s da atividade 2
        clockPort.advance(const Duration(seconds: 4));

        // Aciona Concluir Antecipado
        await coordinator.completeEarly();

        expect(coordinator.state, isA<ExecutionStateCompleted>());
        expect(audioPort.isPlaying, isFalse);

        final completedState = coordinator.state as ExecutionStateCompleted;
        expect(completedState.session.isCompletedEarly, isTrue);
        expect(completedState.session.totalDurationSeconds, equals(14));
        expect(
          completedState.results[ActivityCategory.tecnica],
          equals(const Duration(seconds: 10)),
        );
        expect(
          completedState.results[ActivityCategory.velocidade],
          equals(const Duration(seconds: 4)),
        );

        expect(sessionRepository.savedSessions.length, equals(1));
        expect(sessionRepository.savedSessions.first.isCompletedEarly, isTrue);
        expect(sessionRepository.savedSessions.first.totalDurationSeconds, equals(14));
      },
    );

    test(
      'TC-06.07: Cancelamento com Descarte ("Cancelar"): cancel() transita para Canceled, para áudio e NÃO salva sessão',
      () async {
        final routine = createTestRoutine(activity1Duration: 10);
        await coordinator.start(routine, preparationSeconds: 0);

        clockPort.advance(const Duration(seconds: 5));
        expect(coordinator.state, isA<ExecutionStateRunning>());

        await coordinator.cancel();

        expect(coordinator.state, isA<ExecutionStateCanceled>());
        expect(audioPort.isPlaying, isFalse);
        expect(sessionRepository.savedSessions, isEmpty);
      },
    );

    test(
      'TC-06.08: pause() e resume() congelam e reativam contagem regressiva e metrônomo sem perder segundos acumulados',
      () async {
        final routine = createTestRoutine(activity1Duration: 10);
        await coordinator.start(routine, preparationSeconds: 0);

        // Avança 3 segundos
        clockPort.advance(const Duration(seconds: 3));
        expect(
          (coordinator.state as ExecutionStateRunning).remainingDuration,
          equals(const Duration(seconds: 7)),
        );
        expect(audioPort.isPlaying, isTrue);

        // Pausa
        await coordinator.pause();
        expect(coordinator.state, isA<ExecutionStatePaused>());
        final pausedState = coordinator.state as ExecutionStatePaused;
        expect(pausedState.remainingDuration, equals(const Duration(seconds: 7)));
        expect(pausedState.wasMetronomeActive, isTrue);
        expect(audioPort.isPlaying, isFalse);

        // Avança tempo enquanto pausado: nada deve mudar
        clockPort.advance(const Duration(seconds: 10));
        expect(coordinator.state, isA<ExecutionStatePaused>());
        expect(
          (coordinator.state as ExecutionStatePaused).remainingDuration,
          equals(const Duration(seconds: 7)),
        );

        // Retoma
        await coordinator.resume();
        expect(coordinator.state, isA<ExecutionStateRunning>());
        expect(
          (coordinator.state as ExecutionStateRunning).remainingDuration,
          equals(const Duration(seconds: 7)),
        );
        expect(audioPort.isPlaying, isTrue);

        // Avança 2 segundos adicionais
        clockPort.advance(const Duration(seconds: 2));
        expect(
          (coordinator.state as ExecutionStateRunning).remainingDuration,
          equals(const Duration(seconds: 5)),
        );
      },
    );

    test(
      'EC-07: transitionSeconds == 0 transita imediatamente para próxima atividade sem estado Transitioning',
      () async {
        final routine = createTestRoutine(activity1Duration: 10, activity2Duration: 10);
        await coordinator.start(
          routine,
          preparationSeconds: 0,
          transitionSeconds: 0,
        );

        // Avança 10s
        clockPort.advance(const Duration(seconds: 10));

        // Entra direto em Running da atividade 1
        expect(coordinator.state, isA<ExecutionStateRunning>());
        final runState = coordinator.state as ExecutionStateRunning;
        expect(runState.currentActivityIndex, equals(1));
      },
    );

    test(
      'skipToNext() e previous() navegam pelas atividades e toggleMetronome() alterna som',
      () async {
        final routine = createTestRoutine(activity1Duration: 10, activity2Duration: 10);
        await coordinator.start(routine, preparationSeconds: 0);

        expect((coordinator.state as ExecutionStateRunning).currentActivityIndex, equals(0));

        await coordinator.skipToNext();
        expect((coordinator.state as ExecutionStateRunning).currentActivityIndex, equals(1));

        await coordinator.previous();
        expect((coordinator.state as ExecutionStateRunning).currentActivityIndex, equals(0));

        // Metrônomo estava ativo
        expect((coordinator.state as ExecutionStateRunning).isMetronomeActive, isTrue);
        expect(audioPort.isPlaying, isTrue);

        await coordinator.toggleMetronome();
        expect((coordinator.state as ExecutionStateRunning).isMetronomeActive, isFalse);
        expect(audioPort.isPlaying, isFalse);

        await coordinator.toggleMetronome();
        expect((coordinator.state as ExecutionStateRunning).isMetronomeActive, isTrue);
        expect(audioPort.isPlaying, isTrue);
      },
    );

    test(
      'updateBpm() e stepBpm() ajustam a velocidade em tempo real e atualizam audioPort',
      () async {
        final routine = createTestRoutine(activity1Duration: 20, bpm: 120);
        await coordinator.start(routine, preparationSeconds: 0);

        expect(coordinator.activeBpm, equals(120));
        expect(audioPort.currentBpm, equals(120));

        // Incrementa +5 BPM
        await coordinator.stepBpm(5);
        expect(coordinator.activeBpm, equals(125));
        expect(audioPort.currentBpm, equals(125));
        expect((coordinator.state as ExecutionStateRunning).currentActivity.bpm, equals(125));

        // Decrementa -1 BPM
        await coordinator.stepBpm(-1);
        expect(coordinator.activeBpm, equals(124));
        expect(audioPort.currentBpm, equals(124));

        // Ajuste direto para 160 BPM
        await coordinator.updateBpm(160);
        expect(coordinator.activeBpm, equals(160));
        expect(audioPort.currentBpm, equals(160));

        // Limita ao range permitido (20..300)
        await coordinator.updateBpm(500);
        expect(coordinator.activeBpm, equals(300));
        await coordinator.updateBpm(10);
        expect(coordinator.activeBpm, equals(20));
      },
    );

    test(
      'updateSubdivision, cycleBeatEmphasis, reset e mute ajustam subdivisão e volumes no treino',
      () async {
        final routine = createTestRoutine(activity1Duration: 20, bpm: 120);
        await coordinator.start(routine, preparationSeconds: 0);

        // Inicial padrão: 4 tempos [forte, normal, normal, normal], subdivisão 1
        expect(coordinator.activeSubdivision, equals(1));
        expect(
          coordinator.activePattern,
          equals([
            BeatEmphasis.forte,
            BeatEmphasis.normal,
            BeatEmphasis.normal,
            BeatEmphasis.normal,
          ]),
        );

        // Altera subdivisão para 3x (Tercina)
        await coordinator.updateSubdivision(3);
        expect(coordinator.activeSubdivision, equals(3));
        expect(audioPort.activeSubdivision, equals(3));

        // Cicla ênfase do primeiro tempo: de forte -> normal
        await coordinator.cycleBeatEmphasis(0);
        expect(coordinator.activePattern[0], equals(BeatEmphasis.normal));
        expect(audioPort.activePattern[0], equals(BeatEmphasis.normal));

        // Cicla novamente: normal -> fraco
        await coordinator.cycleBeatEmphasis(0);
        expect(coordinator.activePattern[0], equals(BeatEmphasis.fraco));

        // Cicla novamente: fraco -> mudo
        await coordinator.cycleBeatEmphasis(0);
        expect(coordinator.activePattern[0], equals(BeatEmphasis.mudo));

        // Cicla novamente: mudo -> forte
        await coordinator.cycleBeatEmphasis(0);
        expect(coordinator.activePattern[0], equals(BeatEmphasis.forte));

        // Mute all beats
        await coordinator.muteAllBeats();
        expect(
          coordinator.activePattern,
          equals([
            BeatEmphasis.mudo,
            BeatEmphasis.mudo,
            BeatEmphasis.mudo,
            BeatEmphasis.mudo,
          ]),
        );
        expect(audioPort.activePattern.every((b) => b == BeatEmphasis.mudo), isTrue);

        // Reset to default
        await coordinator.resetBeatPatternToDefault();
        expect(
          coordinator.activePattern,
          equals([
            BeatEmphasis.forte,
            BeatEmphasis.normal,
            BeatEmphasis.normal,
            BeatEmphasis.normal,
          ]),
        );
        expect(audioPort.activePattern[0], equals(BeatEmphasis.forte));
      },
    );
  });
}
