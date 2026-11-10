import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/routine_activities_table.dart';
import '../tables/routines_table.dart';

/// DAO de acesso parametrizado às tabelas `routines` e `routine_activities` (ADR-004).
class RoutineDao {
  const RoutineDao(this._db);

  final AppDatabase _db;

  Future<List<RoutineRow>> getAllRoutineRows() async {
    final rows = await _db.customSelect(
      'SELECT id, name, color_hex, created_at, updated_at '
      'FROM routines ORDER BY created_at DESC',
    ).get();

    return rows.map(_mapRoutineRow).toList();
  }

  Future<RoutineRow?> getRoutineRowById(String id) async {
    final rows = await _db.customSelect(
      'SELECT id, name, color_hex, created_at, updated_at '
      'FROM routines WHERE id = ? LIMIT 1',
      variables: [Variable.withString(id)],
    ).get();

    if (rows.isEmpty) return null;
    return _mapRoutineRow(rows.first);
  }

  Future<List<RoutineActivityRow>> getActivitiesForRoutine(
    String routineId,
  ) async {
    final rows = await _db.customSelect(
      'SELECT id, routine_id, name, category, duration_seconds, bpm, '
      'auto_start_metronome, notes, order_index '
      'FROM routine_activities WHERE routine_id = ? ORDER BY order_index ASC',
      variables: [Variable.withString(routineId)],
    ).get();

    return rows.map(_mapActivityRow).toList();
  }

  Future<void> upsertRoutineWithActivities({
    required RoutineRow routine,
    required List<RoutineActivityRow> activities,
  }) async {
    await _db.transaction(() async {
      await _db.customStatement(
        'INSERT INTO routines (id, name, color_hex, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?) '
        'ON CONFLICT(id) DO UPDATE SET '
        'name = excluded.name, '
        'color_hex = excluded.color_hex, '
        'updated_at = excluded.updated_at',
        [
          routine.id,
          routine.name,
          routine.colorHex,
          routine.createdAtMs,
          routine.updatedAtMs,
        ],
      );

      // Remove atividades antigas e insere a lista atualizada ordenada (sem órfãos).
      await _db.customStatement(
        'DELETE FROM routine_activities WHERE routine_id = ?',
        [routine.id],
      );

      for (final act in activities) {
        await _db.customStatement(
          'INSERT INTO routine_activities '
          '(id, routine_id, name, category, duration_seconds, bpm, '
          'auto_start_metronome, notes, order_index) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            act.id,
            act.routineId,
            act.name,
            act.categoryKey,
            act.durationSeconds,
            act.bpm,
            act.autoStartMetronome ? 1 : 0,
            act.notes,
            act.orderIndex,
          ],
        );
      }
    });
  }

  Future<void> deleteRoutineById(String id) async {
    await _db.customStatement(
      'DELETE FROM routines WHERE id = ?',
      [id],
    );
  }

  RoutineRow _mapRoutineRow(QueryRow row) {
    return RoutineRow(
      id: row.read<String>('id'),
      name: row.read<String>('name'),
      colorHex: row.read<String>('color_hex'),
      createdAtMs: row.read<int>('created_at'),
      updatedAtMs: row.read<int>('updated_at'),
    );
  }

  RoutineActivityRow _mapActivityRow(QueryRow row) {
    return RoutineActivityRow(
      id: row.read<String>('id'),
      routineId: row.read<String>('routine_id'),
      name: row.read<String>('name'),
      categoryKey: row.read<String>('category'),
      durationSeconds: row.read<int>('duration_seconds'),
      bpm: row.readNullable<int>('bpm'),
      autoStartMetronome: row.read<int>('auto_start_metronome') == 1,
      notes: row.read<String>('notes'),
      orderIndex: row.read<int>('order_index'),
    );
  }
}

