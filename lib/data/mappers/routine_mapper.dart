import '../../domain/models/activity_category.dart';
import '../../domain/models/routine.dart';
import '../../domain/models/routine_activity.dart';
import '../datasources/local/tables/routine_activities_table.dart';
import '../datasources/local/tables/routines_table.dart';

/// Mapeador bidirecional entre linhas SQLite e modelos de domínio [Routine] e [RoutineActivity].
abstract final class RoutineMapper {
  static Routine toDomain({
    required RoutineRow row,
    required List<RoutineActivityRow> activityRows,
  }) {
    final activities = activityRows.map(activityToDomain).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Routine(
      id: row.id,
      name: row.name,
      colorHex: row.colorHex,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAtMs, isUtc: true),
      activities: activities,
    );
  }

  static RoutineActivity activityToDomain(RoutineActivityRow row) {
    return RoutineActivity(
      id: row.id,
      routineId: row.routineId,
      name: row.name,
      category: categoryFromKey(row.categoryKey),
      durationSeconds: row.durationSeconds,
      bpm: row.bpm,
      autoStartMetronome: row.autoStartMetronome,
      notes: row.notes,
      orderIndex: row.orderIndex,
    );
  }

  static RoutineRow toRoutineRow(Routine routine) {
    return RoutineRow(
      id: routine.id,
      name: routine.name,
      colorHex: routine.colorHex,
      createdAtMs: routine.createdAt.toUtc().millisecondsSinceEpoch,
      updatedAtMs: routine.updatedAt.toUtc().millisecondsSinceEpoch,
    );
  }

  static List<RoutineActivityRow> toActivityRows(Routine routine) {
    return routine.activities
        .asMap()
        .entries
        .map(
          (entry) => RoutineActivityRow(
            id: entry.value.id,
            routineId: routine.id,
            name: entry.value.name,
            categoryKey: entry.value.category.name,
            durationSeconds: entry.value.durationSeconds,
            bpm: entry.value.bpm,
            autoStartMetronome: entry.value.autoStartMetronome,
            notes: entry.value.notes,
            orderIndex: entry.value.orderIndex,
          ),
        )
        .toList();
  }

  static ActivityCategory categoryFromKey(String key) {
    return ActivityCategory.values.firstWhere(
      (c) => c.name == key,
      orElse: () => ActivityCategory.tecnica,
    );
  }
}

