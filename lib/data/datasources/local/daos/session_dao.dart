import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/session_category_logs_table.dart';
import '../tables/study_sessions_table.dart';

/// DAO de acesso parametrizado às tabelas `study_sessions` e `session_category_logs` (ADR-004).
class SessionDao {
  const SessionDao(this._db);

  final AppDatabase _db;

  Future<void> insertSessionWithLogs({
    required StudySessionRow session,
    required List<SessionCategoryLogRow> logs,
  }) async {
    await _db.transaction(() async {
      await _db.customStatement(
        'INSERT INTO study_sessions '
        '(id, routine_id, routine_name_snapshot, started_at, ended_at, '
        'total_duration_seconds, is_completed_early) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          session.id,
          session.routineId,
          session.routineNameSnapshot,
          session.startedAtMs,
          session.endedAtMs,
          session.totalDurationSeconds,
          session.isCompletedEarly ? 1 : 0,
        ],
      );

      for (final log in logs) {
        await _db.customStatement(
          'INSERT INTO session_category_logs '
          '(id, session_id, category, duration_seconds) '
          'VALUES (?, ?, ?, ?)',
          [
            log.id,
            log.sessionId,
            log.categoryKey,
            log.durationSeconds,
          ],
        );
      }
    });
  }

  Future<List<StudySessionRow>> getSessionsInRange({
    required int startInclusiveMs,
    required int endExclusiveMs,
  }) async {
    final rows = await _db.customSelect(
      'SELECT id, routine_id, routine_name_snapshot, started_at, ended_at, '
      'total_duration_seconds, is_completed_early '
      'FROM study_sessions '
      'WHERE started_at >= ? AND started_at < ? '
      'ORDER BY started_at DESC',
      variables: [
        Variable.withInt(startInclusiveMs),
        Variable.withInt(endExclusiveMs),
      ],
    ).get();

    return rows
        .map(
          (row) => StudySessionRow(
            id: row.read<String>('id'),
            routineId: row.readNullable<String>('routine_id'),
            routineNameSnapshot: row.read<String>('routine_name_snapshot'),
            startedAtMs: row.read<int>('started_at'),
            endedAtMs: row.read<int>('ended_at'),
            totalDurationSeconds: row.read<int>('total_duration_seconds'),
            isCompletedEarly: row.read<int>('is_completed_early') == 1,
          ),
        )
        .toList();
  }

  Future<List<SessionCategoryLogRow>> getLogsForSession(String sessionId) async {
    final rows = await _db.customSelect(
      'SELECT id, session_id, category, duration_seconds '
      'FROM session_category_logs WHERE session_id = ?',
      variables: [Variable.withString(sessionId)],
    ).get();

    return rows
        .map(
          (row) => SessionCategoryLogRow(
            id: row.read<String>('id'),
            sessionId: row.read<String>('session_id'),
            categoryKey: row.read<String>('category'),
            durationSeconds: row.read<int>('duration_seconds'),
          ),
        )
        .toList();
  }

  /// Consulta analítica SQL agrupando segundos por categoria em um intervalo de datas (RF-10).
  Future<Map<String, int>> sumCategoryDurationsInRange({
    required int startInclusiveMs,
    required int endExclusiveMs,
  }) async {
    final rows = await _db.customSelect(
      'SELECT l.category AS category_key, '
      'COALESCE(SUM(l.duration_seconds), 0) AS total_seconds '
      'FROM session_category_logs l '
      'INNER JOIN study_sessions s ON s.id = l.session_id '
      'WHERE s.started_at >= ? AND s.started_at < ? '
      'GROUP BY l.category',
      variables: [
        Variable.withInt(startInclusiveMs),
        Variable.withInt(endExclusiveMs),
      ],
    ).get();

    final result = <String, int>{};
    for (final row in rows) {
      result[row.read<String>('category_key')] = row.read<int>('total_seconds');
    }
    return result;
  }
}

