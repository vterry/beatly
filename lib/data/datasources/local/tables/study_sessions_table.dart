/// Definição DDL e estrutura de linha da tabela `study_sessions` (ADR-004).
///
/// Usa `ON DELETE SET NULL` na FK `routine_id` para preservar o histórico mensal
/// mesmo quando o usuário exclui a rotina original.
class StudySessionsTable {
  static const String tableName = 'study_sessions';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS study_sessions (
      id TEXT PRIMARY KEY NOT NULL,
      routine_id TEXT NULL,
      routine_name_snapshot TEXT NOT NULL,
      started_at INTEGER NOT NULL,
      ended_at INTEGER NOT NULL,
      total_duration_seconds INTEGER NOT NULL,
      is_completed_early INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (routine_id) REFERENCES routines(id) ON DELETE SET NULL
    );
  ''';
}

class StudySessionRow {
  const StudySessionRow({
    required this.id,
    required this.routineId,
    required this.routineNameSnapshot,
    required this.startedAtMs,
    required this.endedAtMs,
    required this.totalDurationSeconds,
    required this.isCompletedEarly,
  });

  final String id;
  final String? routineId;
  final String routineNameSnapshot;
  final int startedAtMs;
  final int endedAtMs;
  final int totalDurationSeconds;
  final bool isCompletedEarly;
}

