import 'dart:async';

import '../contracts/clock_port.dart';
import '../contracts/metronome_audio_port.dart';
import '../contracts/session_repository.dart';
import '../models/activity_category.dart';
import '../models/beat_emphasis.dart';
import '../models/routine.dart';
import '../models/routine_execution_state.dart';
import '../models/session_category_log.dart';
import '../models/study_session.dart';
import '../use_cases/id_generator.dart';

/// Coordenador / Máquina de Estados da Execução de Rotina (RF-06, RF-07 / ADR-003).
///
/// Gerencia os ciclos de Vida de uma rotina de estudos com contagem regressiva,
/// transições suaves sonoras e persistência determinística no [SessionRepository].
class RoutineExecutionCoordinator {
  RoutineExecutionCoordinator({
    required ClockPort clockPort,
    required MetronomeAudioPort audioPort,
    required SessionRepository sessionRepository,
    IdGeneratorFn? idGenerator,
    void Function(RoutineExecutionState state)? onStateChanged,
  })  : _clockPort = clockPort,
        _audioPort = audioPort,
        _sessionRepository = sessionRepository,
        _idGenerator = idGenerator ?? IdGenerator.newUuidV4,
        _onStateChanged = onStateChanged;

  final ClockPort _clockPort;
  final MetronomeAudioPort _audioPort;
  final SessionRepository _sessionRepository;
  final IdGeneratorFn _idGenerator;
  final void Function(RoutineExecutionState state)? _onStateChanged;

  final StreamController<RoutineExecutionState> _stateController =
      StreamController<RoutineExecutionState>.broadcast(sync: true);

  RoutineExecutionState _state = const ExecutionStateIdle();
  StreamSubscription<int>? _tickSubscription;

  Routine? _routine;
  DateTime? _startedAt;
  int _transitionSeconds = 5;
  String _transitionChime = 'chime_zen';
  double _transitionVolume = 0.8;
  int _currentActivityIndex = 0;
  int _remainingSeconds = 0;
  bool _isMetronomeActive = false;
  bool _isPaused = false;
  int _activeBpm = 120;
  List<BeatEmphasis> _activePattern = const [
    BeatEmphasis.forte,
    BeatEmphasis.normal,
    BeatEmphasis.normal,
    BeatEmphasis.normal,
  ];
  int _activeSubdivision = 1;
  final Map<ActivityCategory, int> _practicedSecondsByCategory = {};

  RoutineExecutionState get state => _state;
  Stream<RoutineExecutionState> get stateStream => _stateController.stream;
  Routine? get routine => _routine;
  int get activeBpm => _activeBpm;
  List<BeatEmphasis> get activePattern => _activePattern;
  int get activeSubdivision => _activeSubdivision;

  void _emitState(RoutineExecutionState newState) {
    _state = newState;
    _onStateChanged?.call(newState);
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  /// Inicia a execução da rotina com tempo de preparação opcional (padrão 5s).
  Future<void> start(
    Routine routine, {
    int preparationSeconds = 5,
    int transitionSeconds = 5,
    String transitionChime = 'chime_zen',
    double transitionVolume = 0.8,
  }) async {
    assert(routine.activities.isNotEmpty, 'Rotina deve possuir atividades');

    _tickSubscription?.cancel();
    _routine = routine;
    _transitionSeconds = transitionSeconds;
    _transitionChime = transitionChime;
    _transitionVolume = transitionVolume;
    _startedAt = _clockPort.now();
    _practicedSecondsByCategory.clear();
    _isPaused = false;

    _startTimer();

    if (preparationSeconds > 0) {
      _emitState(
        ExecutionStatePreparing(
          remainingSeconds: preparationSeconds,
          firstActivity: routine.activities.first,
          totalActivities: routine.activities.length,
        ),
      );
    } else {
      await _startActivity(0);
    }
  }

  void _startTimer() {
    _tickSubscription?.cancel();
    _tickSubscription = _clockPort
        .periodicTicks(interval: const Duration(seconds: 1))
        .listen((_) => _onTick());
  }

  Future<void> _onTick() async {
    if (_isPaused) return;

    final currentState = _state;

    if (currentState is ExecutionStatePreparing) {
      final nextRemaining = currentState.remainingSeconds - 1;
      if (nextRemaining <= 0) {
        await _startActivity(0);
      } else {
        _emitState(
          ExecutionStatePreparing(
            remainingSeconds: nextRemaining,
            firstActivity: currentState.firstActivity,
            totalActivities: currentState.totalActivities,
          ),
        );
      }
      return;
    }

    if (currentState is ExecutionStateRunning) {
      final currentActivity = currentState.currentActivity;
      final category = currentActivity.category;
      _practicedSecondsByCategory[category] =
          (_practicedSecondsByCategory[category] ?? 0) + 1;

      _remainingSeconds -= 1;

      if (_remainingSeconds > 0) {
        _emitState(
          ExecutionStateRunning(
            currentActivity: currentActivity,
            currentActivityIndex: currentState.currentActivityIndex,
            totalActivities: currentState.totalActivities,
            remainingDuration: Duration(seconds: _remainingSeconds),
            isMetronomeActive: _isMetronomeActive,
          ),
        );
      } else {
        // Tempo da atividade esgotado
        if (_currentActivityIndex + 1 < _routine!.activities.length) {
          unawaited(_audioPort.stop());
          if (_transitionChime != 'mute') {
            unawaited(_audioPort.playTransitionChime(
              soundName: _transitionChime,
              volume: _transitionVolume,
            ));
          }
          if (_transitionSeconds > 0) {
            _emitState(
              ExecutionStateTransitioning(
                nextActivity: _routine!.activities[_currentActivityIndex + 1],
                nextActivityIndex: _currentActivityIndex + 1,
                totalActivities: _routine!.activities.length,
                remainingSeconds: _transitionSeconds,
              ),
            );
          } else {
            await _startActivity(_currentActivityIndex + 1);
          }
        } else {
          // Última atividade concluída automaticamente (TC-06.05, EC-04)
          await _completeRoutine(isCompletedEarly: false);
        }
      }
      return;
    }

    if (currentState is ExecutionStateTransitioning) {
      final nextRemaining = currentState.remainingSeconds - 1;
      if (nextRemaining <= 0) {
        await _startActivity(currentState.nextActivityIndex);
      } else {
        _emitState(
          ExecutionStateTransitioning(
            nextActivity: currentState.nextActivity,
            nextActivityIndex: currentState.nextActivityIndex,
            totalActivities: currentState.totalActivities,
            remainingSeconds: nextRemaining,
          ),
        );
      }
      return;
    }
  }

  Future<void> _startActivity(int index) async {
    _currentActivityIndex = index;
    final activity = _routine!.activities[index];
    _remainingSeconds = activity.durationSeconds;
    _activeBpm = activity.bpm ?? 120;
    final shouldStartMetronome =
        activity.autoStartMetronome && activity.bpm != null;
    _isMetronomeActive = shouldStartMetronome;

    _emitState(
      ExecutionStateRunning(
        currentActivity: activity.copyWith(bpm: _activeBpm),
        currentActivityIndex: index,
        totalActivities: _routine!.activities.length,
        remainingDuration: Duration(seconds: _remainingSeconds),
        isMetronomeActive: _isMetronomeActive,
      ),
    );

    if (shouldStartMetronome) {
      await _audioPort.start(
        bpm: _activeBpm,
        pattern: _activePattern,
        subdivision: _activeSubdivision,
      );
    } else {
      await _audioPort.stop();
    }
  }

  /// Pula imediatamente a transição ou preparação e inicia a atividade correspondente.
  Future<void> skipTransition() async {
    final currentState = _state;
    if (currentState is ExecutionStateTransitioning) {
      await _startActivity(currentState.nextActivityIndex);
    } else if (currentState is ExecutionStatePreparing) {
      await _startActivity(0);
    }
  }

  /// Pausa o treino e o metrônomo (TC-06.08).
  Future<void> pause() async {
    if (_state is! ExecutionStateRunning) return;
    final running = _state as ExecutionStateRunning;

    _isPaused = true;
    await _audioPort.stop();

    _emitState(
      ExecutionStatePaused(
        currentActivity: running.currentActivity,
        currentActivityIndex: running.currentActivityIndex,
        totalActivities: running.totalActivities,
        remainingDuration: running.remainingDuration,
        wasMetronomeActive: _isMetronomeActive,
      ),
    );
  }

  /// Retoma o treino e o metrônomo se estava ativo (TC-06.08).
  Future<void> resume() async {
    if (_state is! ExecutionStatePaused) return;
    final paused = _state as ExecutionStatePaused;

    _isPaused = false;

    if (paused.wasMetronomeActive) {
      await _audioPort.start(
        bpm: _activeBpm,
        pattern: _activePattern,
        subdivision: _activeSubdivision,
      );
      _isMetronomeActive = true;
    } else {
      _isMetronomeActive = false;
    }

    _emitState(
      ExecutionStateRunning(
        currentActivity: paused.currentActivity.copyWith(bpm: _activeBpm),
        currentActivityIndex: paused.currentActivityIndex,
        totalActivities: paused.totalActivities,
        remainingDuration: paused.remainingDuration,
        isMetronomeActive: _isMetronomeActive,
      ),
    );
  }

  /// Ajusta a velocidade do metrônomo (BPM) dinamicamente durante o treino.
  Future<void> updateBpm(int newBpm) async {
    final clamped = newBpm.clamp(20, 300);
    _activeBpm = clamped;

    final currentState = _state;
    if (currentState is ExecutionStateRunning) {
      final updatedActivity = currentState.currentActivity.copyWith(bpm: _activeBpm);
      if (_isMetronomeActive) {
        await _audioPort.updateBpm(_activeBpm);
      }
      _emitState(
        ExecutionStateRunning(
          currentActivity: updatedActivity,
          currentActivityIndex: currentState.currentActivityIndex,
          totalActivities: currentState.totalActivities,
          remainingDuration: currentState.remainingDuration,
          isMetronomeActive: _isMetronomeActive,
        ),
      );
    } else if (currentState is ExecutionStatePaused) {
      final updatedActivity = currentState.currentActivity.copyWith(bpm: _activeBpm);
      _emitState(
        ExecutionStatePaused(
          currentActivity: updatedActivity,
          currentActivityIndex: currentState.currentActivityIndex,
          totalActivities: currentState.totalActivities,
          remainingDuration: currentState.remainingDuration,
          wasMetronomeActive: currentState.wasMetronomeActive,
        ),
      );
    }
  }

  /// Incrementa ou decrementa a velocidade do metrônomo em delta BPM.
  Future<void> stepBpm(int delta) async {
    await updateBpm(_activeBpm + delta);
  }

  /// Atualiza o padrão de acentuações e volumes dos pulsos em tempo real durante o treino.
  Future<void> updatePattern(List<BeatEmphasis> pattern) async {
    _activePattern = List<BeatEmphasis>.unmodifiable(pattern);
    if (_isMetronomeActive) {
      await _audioPort.updatePattern(
        _activePattern,
        subdivision: _activeSubdivision,
      );
    }
    _notifyStateRefresh();
  }

  /// Atualiza a subdivisão de tempo (1x Pulso, 2x Colcheias, 3x Tercinas, 4x Semicolcheias) durante o treino.
  Future<void> updateSubdivision(int subdivision) async {
    _activeSubdivision = subdivision.clamp(1, 4);
    if (_isMetronomeActive) {
      await _audioPort.updatePattern(
        _activePattern,
        subdivision: _activeSubdivision,
      );
    }
    _notifyStateRefresh();
  }

  /// Alterna a acentuação (Forte -> Normal -> Fraco -> Mudo) de um pulso específico durante o treino.
  Future<void> cycleBeatEmphasis(int index) async {
    if (index < 0 || index >= _activePattern.length) return;
    final current = _activePattern[index];
    final next = switch (current) {
      BeatEmphasis.forte => BeatEmphasis.normal,
      BeatEmphasis.normal => BeatEmphasis.fraco,
      BeatEmphasis.fraco => BeatEmphasis.mudo,
      BeatEmphasis.mudo => BeatEmphasis.forte,
    };
    final nextPattern = List<BeatEmphasis>.from(_activePattern);
    nextPattern[index] = next;
    await updatePattern(nextPattern);
  }

  /// Restaura o padrão de acentuações padrão (Forte no 1º tempo, Normal nos demais).
  Future<void> resetBeatPatternToDefault() async {
    final nextPattern = List<BeatEmphasis>.generate(
      _activePattern.length,
      (i) => i == 0 ? BeatEmphasis.forte : BeatEmphasis.normal,
    );
    await updatePattern(nextPattern);
  }

  /// Silencia todos os pulsos (modo mudo).
  Future<void> muteAllBeats() async {
    final nextPattern = List<BeatEmphasis>.filled(
      _activePattern.length,
      BeatEmphasis.mudo,
    );
    await updatePattern(nextPattern);
  }

  void _notifyStateRefresh() {
    final currentState = _state;
    if (currentState is ExecutionStateRunning) {
      _emitState(
        ExecutionStateRunning(
          currentActivity:
              currentState.currentActivity.copyWith(bpm: _activeBpm),
          currentActivityIndex: currentState.currentActivityIndex,
          totalActivities: currentState.totalActivities,
          remainingDuration: currentState.remainingDuration,
          isMetronomeActive: _isMetronomeActive,
        ),
      );
    } else if (currentState is ExecutionStatePaused) {
      _emitState(
        ExecutionStatePaused(
          currentActivity:
              currentState.currentActivity.copyWith(bpm: _activeBpm),
          currentActivityIndex: currentState.currentActivityIndex,
          totalActivities: currentState.totalActivities,
          remainingDuration: currentState.remainingDuration,
          wasMetronomeActive: currentState.wasMetronomeActive,
        ),
      );
    }
  }

  /// Liga ou desliga manualmente o metrônomo durante a execução.
  Future<void> toggleMetronome() async {
    final currentState = _state;
    if (currentState is! ExecutionStateRunning) return;

    if (_isMetronomeActive) {
      await _audioPort.stop();
      _isMetronomeActive = false;
    } else {
      await _audioPort.start(
        bpm: _activeBpm,
        pattern: _activePattern,
        subdivision: _activeSubdivision,
      );
      _isMetronomeActive = true;
    }

    _emitState(
      ExecutionStateRunning(
        currentActivity: currentState.currentActivity.copyWith(bpm: _activeBpm),
        currentActivityIndex: currentState.currentActivityIndex,
        totalActivities: currentState.totalActivities,
        remainingDuration: Duration(seconds: _remainingSeconds),
        isMetronomeActive: _isMetronomeActive,
      ),
    );
  }

  /// Avança manualmente para a próxima atividade da rotina.
  Future<void> skipToNext() async {
    if (_routine != null &&
        _currentActivityIndex + 1 < _routine!.activities.length) {
      await _startActivity(_currentActivityIndex + 1);
    }
  }

  /// Retorna manualmente para a atividade anterior da rotina.
  Future<void> previous() async {
    if (_routine != null && _currentActivityIndex > 0) {
      await _startActivity(_currentActivityIndex - 1);
    }
  }

  /// Conclusão antecipada acionada pelo usuário via botão "Concluir" (TC-06.06, EC-06).
  Future<void> completeEarly() async {
    await _completeRoutine(isCompletedEarly: true);
  }

  Future<void> _completeRoutine({required bool isCompletedEarly}) async {
    _tickSubscription?.cancel();
    _tickSubscription = null;

    final sessionId = _idGenerator();
    final endedAt = _clockPort.now();

    final results = <ActivityCategory, Duration>{};
    for (final entry in _practicedSecondsByCategory.entries) {
      if (entry.value > 0) {
        results[entry.key] = Duration(seconds: entry.value);
      }
    }

    final totalDurationSeconds = _practicedSecondsByCategory.values
        .fold<int>(0, (sum, val) => sum + val);

    final logs = results.entries
        .map(
          (e) => SessionCategoryLog(
            id: _idGenerator(),
            sessionId: sessionId,
            category: e.key,
            durationSeconds: e.value.inSeconds,
          ),
        )
        .toList();

    final session = StudySession(
      id: sessionId,
      routineId: _routine?.id,
      routineNameSnapshot: _routine?.name ?? 'Rotina de Estudos',
      startedAt: _startedAt ?? endedAt,
      endedAt: endedAt,
      totalDurationSeconds: totalDurationSeconds,
      categoryLogs: logs,
      isCompletedEarly: isCompletedEarly,
    );

    _emitState(
      ExecutionStateCompleted(
        session: session,
        results: results,
      ),
    );

    unawaited(_audioPort.stop());
    await _sessionRepository.saveSession(session);
  }

  /// Cancelamento com descarte do treino em andamento (TC-06.07, EC-06).
  Future<void> cancel() async {
    _tickSubscription?.cancel();
    _tickSubscription = null;
    await _audioPort.stop();

    _practicedSecondsByCategory.clear();
    _isPaused = false;

    _emitState(const ExecutionStateCanceled());
  }

  /// Libera recursos da máquina de estados.
  Future<void> dispose() async {
    _tickSubscription?.cancel();
    _tickSubscription = null;
    await _audioPort.stop();
    await _stateController.close();
  }
}
