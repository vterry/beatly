import 'package:beatly/data/datasources/local/app_database.dart';
import 'package:beatly/data/datasources/local/tables/routine_activities_table.dart';
import 'package:beatly/data/datasources/local/tables/routines_table.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_app_database.dart';

void main() {
  group('RoutineDao (SQLite / Drift)', () {
    late AppDatabase db;

    setUp(() {
      db = createInMemoryAppDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('insere e ordena atividades por order_index ASC', () async {
      await db.routineDao.upsertRoutineWithActivities(
        routine: const RoutineRow(
          id: 'r1',
          name: 'Rotina A',
          colorHex: '#7C3AED',
          createdAtMs: 1000,
          updatedAtMs: 1000,
        ),
        activities: const [
          RoutineActivityRow(
            id: 'a2',
            routineId: 'r1',
            name: 'Segunda',
            categoryKey: 'velocidade',
            durationSeconds: 300,
            bpm: 140,
            autoStartMetronome: true,
            notes: '',
            orderIndex: 1,
          ),
          RoutineActivityRow(
            id: 'a1',
            routineId: 'r1',
            name: 'Primeira',
            categoryKey: 'tecnica',
            durationSeconds: 300,
            bpm: 100,
            autoStartMetronome: true,
            notes: '',
            orderIndex: 0,
          ),
        ],
      );

      final rows = await db.routineDao.getActivitiesForRoutine('r1');
      expect(rows.map((r) => r.id).toList(), equals(['a1', 'a2']));
    });
  });
}

