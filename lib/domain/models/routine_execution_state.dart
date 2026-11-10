import 'package:flutter/foundation.dart';

import 'activity_category.dart';
import 'routine_activity.dart';
import 'study_session.dart';

/// Máquina de estados finitos imutável da Execução de Rotina (RF-06 / ADR-003).
@immutable
sealed class RoutineExecutionState {
  const RoutineExecutionState();
}

/// Estado inicial ou após descarte completo da rotina.
final class ExecutionStateIdle extends RoutineExecutionState {
  const ExecutionStateIdle();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExecutionStateIdle;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'ExecutionStateIdle()';
}

/// Contagem regressiva de preparação inicial (5s padrão).
final class ExecutionStatePreparing extends RoutineExecutionState {
  const ExecutionStatePreparing({
    required this.remainingSeconds,
    required this.firstActivity,
    required this.totalActivities,
  });

  final int remainingSeconds;
  final RoutineActivity firstActivity;
  final int totalActivities;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExecutionStatePreparing &&
          remainingSeconds == other.remainingSeconds &&
          firstActivity == other.firstActivity &&
          totalActivities == other.totalActivities;

  @override
  int get hashCode =>
      Object.hash(remainingSeconds, firstActivity, totalActivities);

  @override
  String toString() =>
      'ExecutionStatePreparing(remainingSeconds: $remainingSeconds, firstActivity: ${firstActivity.name})';
}

/// Atividade em execução ativa com cronômetro decrescente.
final class ExecutionStateRunning extends RoutineExecutionState {
  const ExecutionStateRunning({
    required this.currentActivity,
    required this.currentActivityIndex,
    required this.totalActivities,
    required this.remainingDuration,
    required this.isMetronomeActive,
  });

  final RoutineActivity currentActivity;
  final int currentActivityIndex;
  final int totalActivities;
  final Duration remainingDuration;
  final bool isMetronomeActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExecutionStateRunning &&
          currentActivity == other.currentActivity &&
          currentActivityIndex == other.currentActivityIndex &&
          totalActivities == other.totalActivities &&
          remainingDuration == other.remainingDuration &&
          isMetronomeActive == other.isMetronomeActive;

  @override
  int get hashCode => Object.hash(
        currentActivity,
        currentActivityIndex,
        totalActivities,
        remainingDuration,
        isMetronomeActive,
      );

  @override
  String toString() =>
      'ExecutionStateRunning(activity: ${currentActivity.name}, remaining: ${remainingDuration.inSeconds}s, metronome: $isMetronomeActive)';
}

/// Atividade pausada mantendo o tempo restante e estado do metrônomo.
final class ExecutionStatePaused extends RoutineExecutionState {
  const ExecutionStatePaused({
    required this.currentActivity,
    required this.currentActivityIndex,
    required this.totalActivities,
    required this.remainingDuration,
    required this.wasMetronomeActive,
  });

  final RoutineActivity currentActivity;
  final int currentActivityIndex;
  final int totalActivities;
  final Duration remainingDuration;
  final bool wasMetronomeActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExecutionStatePaused &&
          currentActivity == other.currentActivity &&
          currentActivityIndex == other.currentActivityIndex &&
          totalActivities == other.totalActivities &&
          remainingDuration == other.remainingDuration &&
          wasMetronomeActive == other.wasMetronomeActive;

  @override
  int get hashCode => Object.hash(
        currentActivity,
        currentActivityIndex,
        totalActivities,
        remainingDuration,
        wasMetronomeActive,
      );

  @override
  String toString() =>
      'ExecutionStatePaused(activity: ${currentActivity.name}, remaining: ${remainingDuration.inSeconds}s)';
}

/// Intervalo de transição suave entre duas atividades (5s padrão).
final class ExecutionStateTransitioning extends RoutineExecutionState {
  const ExecutionStateTransitioning({
    required this.nextActivity,
    required this.nextActivityIndex,
    required this.totalActivities,
    required this.remainingSeconds,
  });

  final RoutineActivity nextActivity;
  final int nextActivityIndex;
  final int totalActivities;
  final int remainingSeconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExecutionStateTransitioning &&
          nextActivity == other.nextActivity &&
          nextActivityIndex == other.nextActivityIndex &&
          totalActivities == other.totalActivities &&
          remainingSeconds == other.remainingSeconds;

  @override
  int get hashCode => Object.hash(
        nextActivity,
        nextActivityIndex,
        totalActivities,
        remainingSeconds,
      );

  @override
  String toString() =>
      'ExecutionStateTransitioning(nextActivity: ${nextActivity.name}, remainingSeconds: $remainingSeconds)';
}

/// Rotina finalizada (conclusão automática ou manual antecipada) com sessão persistida.
final class ExecutionStateCompleted extends RoutineExecutionState {
  const ExecutionStateCompleted({
    required this.session,
    required this.results,
  });

  final StudySession session;
  final Map<ActivityCategory, Duration> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExecutionStateCompleted &&
          session == other.session &&
          mapEquals(results, other.results);

  @override
  int get hashCode => Object.hash(session, Object.hashAll(results.entries));

  @override
  String toString() =>
      'ExecutionStateCompleted(sessionId: ${session.id}, totalSecs: ${session.totalDurationSeconds})';
}

/// Rotina cancelada pelo usuário após confirmação explícita no diálogo (descarte sem salvar).
final class ExecutionStateCanceled extends RoutineExecutionState {
  const ExecutionStateCanceled();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExecutionStateCanceled;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'ExecutionStateCanceled()';
}
