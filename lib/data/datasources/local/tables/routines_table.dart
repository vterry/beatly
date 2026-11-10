/// Definição DDL e estrutura de linha da tabela `routines` (ADR-004).
class RoutinesTable {
  static const String tableName = 'routines';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS routines (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL,
      color_hex TEXT NOT NULL DEFAULT '#7C3AED',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
  ''';
}

class RoutineRow {
  const RoutineRow({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String name;
  final String colorHex;
  final int createdAtMs;
  final int updatedAtMs;
}

