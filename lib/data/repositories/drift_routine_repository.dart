import '../../domain/contracts/routine_repository.dart';
import '../../domain/models/routine.dart';
import '../datasources/local/app_database.dart';
import '../mappers/routine_mapper.dart';

/// Implementação concreta de [RoutineRepository] apoiada no SQLite local via Drift (ADR-004).
class DriftRoutineRepository implements RoutineRepository {
  const DriftRoutineRepository({required AppDatabase database})
      : _db = database;

  final AppDatabase _db;

  @override
  Future<List<Routine>> getAllRoutines() async {
    final routineRows = await _db.routineDao.getAllRoutineRows();
    final routines = <Routine>[];
    for (final row in routineRows) {
      final actRows = await _db.routineDao.getActivitiesForRoutine(row.id);
      routines.add(RoutineMapper.toDomain(row: row, activityRows: actRows));
    }
    return routines;
  }

  @override
  Future<Routine?> getRoutineById(String id) async {
    final row = await _db.routineDao.getRoutineRowById(id);
    if (row == null) return null;
    final actRows = await _db.routineDao.getActivitiesForRoutine(id);
    return RoutineMapper.toDomain(row: row, activityRows: actRows);
  }

  @override
  Future<void> saveRoutine(Routine routine) async {
    await _db.routineDao.upsertRoutineWithActivities(
      routine: RoutineMapper.toRoutineRow(routine),
      activities: RoutineMapper.toActivityRows(routine),
    );
  }

  @override
  Future<void> deleteRoutine(String id) async {
    await _db.routineDao.deleteRoutineById(id);
  }

  @override
  Future<Routine> duplicateRoutine(
    String id, {
    required String newRoutineId,
  }) async {
    final existing = await getRoutineById(id);
    if (existing == null) {
      throw StateError('Rotina não encontrada para duplicação: $id');
    }

    final now = DateTime.now().toUtc();
    final copiedActivities = existing.activities
        .asMap()
        .entries
        .map(
          (entry) => entry.value.copyWith(
            id: '${newRoutineId}_act_${entry.key}',
            routineId: newRoutineId,
            orderIndex: entry.key,
          ),
        )
        .toList();

    final copy = Routine(
      id: newRoutineId,
      name: '${existing.name} (Cópia)',
      colorHex: existing.colorHex,
      createdAt: now,
      updatedAt: now,
      activities: copiedActivities,
    );

    await saveRoutine(copy);
    return copy;
  }
}

