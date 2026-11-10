/// Definição DDL e estrutura de linha da tabela `session_category_logs` (ADR-004).
class SessionCategoryLogsTable {
  static const String tableName = 'session_category_logs';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS session_category_logs (
      id TEXT PRIMARY KEY NOT NULL,
      session_id TEXT NOT NULL,
      category TEXT NOT NULL,
      duration_seconds INTEGER NOT NULL,
      FOREIGN KEY (session_id) REFERENCES study_sessions(id) ON DELETE CASCADE
    );
  ''';
}

class SessionCategoryLogRow {
  const SessionCategoryLogRow({
    required this.id,
    required this.sessionId,
    required this.categoryKey,
    required this.durationSeconds,
  });

  final String id;
  final String sessionId;
  final String categoryKey;
  final int durationSeconds;
}

