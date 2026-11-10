import '../../domain/models/session_category_log.dart';
import '../../domain/models/study_session.dart';
import '../datasources/local/tables/session_category_logs_table.dart';
import '../datasources/local/tables/study_sessions_table.dart';
import 'routine_mapper.dart';

/// Mapeador bidirecional entre linhas SQLite e [StudySession] / [SessionCategoryLog].
abstract final class SessionMapper {
  static StudySession toDomain({
    required StudySessionRow row,
    required List<SessionCategoryLogRow> logRows,
  }) {
    return StudySession(
      id: row.id,
      routineId: row.routineId,
      routineNameSnapshot: row.routineNameSnapshot,
      startedAt: DateTime.fromMillisecondsSinceEpoch(row.startedAtMs, isUtc: true),
      endedAt: DateTime.fromMillisecondsSinceEpoch(row.endedAtMs, isUtc: true),
      totalDurationSeconds: row.totalDurationSeconds,
      isCompletedEarly: row.isCompletedEarly,
      categoryLogs: logRows
          .map(
            (l) => SessionCategoryLog(
              id: l.id,
              sessionId: l.sessionId,
              category: RoutineMapper.categoryFromKey(l.categoryKey),
              durationSeconds: l.durationSeconds,
            ),
          )
          .toList(),
    );
  }

  static StudySessionRow toSessionRow(StudySession session) {
    return StudySessionRow(
      id: session.id,
      routineId: session.routineId,
      routineNameSnapshot: session.routineNameSnapshot,
      startedAtMs: session.startedAt.toUtc().millisecondsSinceEpoch,
      endedAtMs: session.endedAt.toUtc().millisecondsSinceEpoch,
      totalDurationSeconds: session.totalDurationSeconds,
      isCompletedEarly: session.isCompletedEarly,
    );
  }

  static List<SessionCategoryLogRow> toLogRows(StudySession session) {
    return session.categoryLogs
        .map(
          (log) => SessionCategoryLogRow(
            id: log.id,
            sessionId: session.id,
            categoryKey: log.category.name,
            durationSeconds: log.durationSeconds,
          ),
        )
        .toList();
  }
}

