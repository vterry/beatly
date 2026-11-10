/// Definição DDL e estrutura de linha da tabela `routine_activities` (ADR-004).
class RoutineActivitiesTable {
  static const String tableName = 'routine_activities';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS routine_activities (
      id TEXT PRIMARY KEY NOT NULL,
      routine_id TEXT NOT NULL,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      duration_seconds INTEGER NOT NULL,
      bpm INTEGER NULL,
      auto_start_metronome INTEGER NOT NULL DEFAULT 0,
      notes TEXT NOT NULL DEFAULT '',
      order_index INTEGER NOT NULL,
      FOREIGN KEY (routine_id) REFERENCES routines(id) ON DELETE CASCADE
    );
  ''';
}

class RoutineActivityRow {
  const RoutineActivityRow({
    required this.id,
    required this.routineId,
    required this.name,
    required this.categoryKey,
    required this.durationSeconds,
    required this.bpm,
    required this.autoStartMetronome,
    required this.notes,
    required this.orderIndex,
  });

  final String id;
  final String routineId;
  final String name;
  final String categoryKey;
  final int durationSeconds;
  final int? bpm;
  final bool autoStartMetronome;
  final String notes;
  final int orderIndex;
}

