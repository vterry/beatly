import '../../domain/contracts/session_repository.dart';
import '../../domain/models/activity_category.dart';
import '../../domain/models/study_session.dart';
import '../datasources/local/app_database.dart';
import '../mappers/routine_mapper.dart';
import '../mappers/session_mapper.dart';

/// Implementação concreta de [SessionRepository] apoiada no SQLite local via Drift (ADR-004).
class DriftSessionRepository implements SessionRepository {
  const DriftSessionRepository({required AppDatabase database})
      : _db = database;

  final AppDatabase _db;

  @override
  Future<void> saveSession(StudySession session) async {
    await _db.sessionDao.insertSessionWithLogs(
      session: SessionMapper.toSessionRow(session),
      logs: SessionMapper.toLogRows(session),
    );
  }

  @override
  Future<List<StudySession>> getSessionsByMonth({
    required int year,
    required int month,
  }) async {
    final (startMs, endMs) = _monthBoundsUtcMs(year: year, month: month);
    final rows = await _db.sessionDao.getSessionsInRange(
      startInclusiveMs: startMs,
      endExclusiveMs: endMs,
    );

    final sessions = <StudySession>[];
    for (final row in rows) {
      final logs = await _db.sessionDao.getLogsForSession(row.id);
      sessions.add(SessionMapper.toDomain(row: row, logRows: logs));
    }
    return sessions;
  }

  @override
  Future<Map<ActivityCategory, int>> getCategoryAggregatesByMonth({
    required int year,
    required int month,
  }) async {
    final (startMs, endMs) = _monthBoundsUtcMs(year: year, month: month);
    final rawTotals = await _db.sessionDao.sumCategoryDurationsInRange(
      startInclusiveMs: startMs,
      endExclusiveMs: endMs,
    );

    final aggregates = <ActivityCategory, int>{
      for (final category in ActivityCategory.values) category: 0,
    };

    for (final entry in rawTotals.entries) {
      final category = RoutineMapper.categoryFromKey(entry.key);
      aggregates[category] = (aggregates[category] ?? 0) + entry.value;
    }

    return aggregates;
  }

  (int, int) _monthBoundsUtcMs({required int year, required int month}) {
    final start = DateTime.utc(year, month);
    final end = month == 12
        ? DateTime.utc(year + 1)
        : DateTime.utc(year, month + 1);
    return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
  }
}

