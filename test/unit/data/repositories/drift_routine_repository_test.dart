import 'package:beatly/data/datasources/local/app_database.dart';
import 'package:beatly/data/repositories/drift_routine_repository.dart';
import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/routine.dart';
import 'package:beatly/domain/models/routine_activity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_app_database.dart';

void main() {
  group('DriftRoutineRepository (ADR-004 / RF-05 / RF-06)', () {
    late AppDatabase db;
    late DriftRoutineRepository repository;

    setUp(() {
      db = createInMemoryAppDatabase();
      repository = DriftRoutineRepository(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    Routine buildSampleRoutine() {
      final now = DateTime.utc(2026, 11, 8, 10);
      return Routine(
        id: 'routine-1',
        name: 'Treino Técnico',
        createdAt: now,
        updatedAt: now,
        activities: [
          RoutineActivity(
            id: 'act-1',
            routineId: 'routine-1',
            name: 'Aquecimento Cromático',
            category: ActivityCategory.tecnica,
            durationSeconds: 600,
            bpm: 110,
            autoStartMetronome: true,
            orderIndex: 0,
          ),
          RoutineActivity(
            id: 'act-2',
            routineId: 'routine-1',
            name: 'Palhetada Alternada',
            category: ActivityCategory.velocidade,
            durationSeconds: 900,
            bpm: 145,
            autoStartMetronome: true,
            orderIndex: 1,
          ),
          RoutineActivity(
            id: 'act-3',
            routineId: 'routine-1',
            name: 'Tríades Abertas',
            category: ActivityCategory.teoriaMusical,
            durationSeconds: 300,
            orderIndex: 2,
          ),
        ],
      );
    }

    test('TC-02.01: salva rotina com 3 atividades ordenadas e recupera preservando orderIndex (0, 1, 2)', () async {
      final routine = buildSampleRoutine();
      await repository.saveRoutine(routine);

      final loaded = await repository.getRoutineById('routine-1');
      expect(loaded, isNotNull);
      expect(loaded!.name, equals('Treino Técnico'));
      expect(loaded.activities.length, equals(3));
      expect(
        loaded.activities.map((a) => a.orderIndex).toList(),
        equals([0, 1, 2]),
      );
      expect(
        loaded.activities.map((a) => a.name).toList(),
        equals([
          'Aquecimento Cromático',
          'Palhetada Alternada',
          'Tríades Abertas',
        ]),
      );
      expect(loaded.activities[0].bpm, equals(110));
      expect(loaded.activities[0].autoStartMetronome, isTrue);
      expect(loaded.activities[2].bpm, isNull);
      expect(loaded.activities[2].autoStartMetronome, isFalse);
      // B-RF-05.1: 10m + 15m + 5m + 2 transições de 5s = 1810s (30m 10s)
      expect(loaded.totalEstimatedDurationSeconds(transitionSeconds: 5), equals(1810));
    });

    test('TC-02.02: ao atualizar rotina removendo uma atividade, remove órfãos da tabela routine_activities', () async {
      final routine = buildSampleRoutine();
      await repository.saveRoutine(routine);

      final updated = routine.copyWith(
        name: 'Treino Enxuto',
        activities: [
          routine.activities[0].copyWith(orderIndex: 0),
          routine.activities[2].copyWith(orderIndex: 1),
        ],
      );
      await repository.saveRoutine(updated);

      final loaded = await repository.getRoutineById('routine-1');
      expect(loaded, isNotNull);
      expect(loaded!.name, equals('Treino Enxuto'));
      expect(loaded.activities.length, equals(2));
      expect(
        loaded.activities.map((a) => a.id).toList(),
        equals(['act-1', 'act-3']),
      );
    });

    test('TC-02.03: ao excluir rotina via deleteRoutine(id), deleta atividades em cascata (ON DELETE CASCADE)', () async {
      final routine = buildSampleRoutine();
      await repository.saveRoutine(routine);

      await repository.deleteRoutine('routine-1');

      final loaded = await repository.getRoutineById('routine-1');
      expect(loaded, isNull);

      final orphanRows = await db.routineDao.getActivitiesForRoutine('routine-1');
      expect(orphanRows, isEmpty);
    });

    test('TC-02.04: duplicateRoutine(id) cria cópia com novo ID, sufixo " (Cópia)" e todas as atividades', () async {
      final routine = buildSampleRoutine();
      await repository.saveRoutine(routine);

      final duplicated = await repository.duplicateRoutine(
        'routine-1',
        newRoutineId: 'routine-copy',
      );

      expect(duplicated.id, equals('routine-copy'));
      expect(duplicated.name, equals('Treino Técnico (Cópia)'));
      expect(duplicated.activities.length, equals(3));
      expect(
        duplicated.activities.every((a) => a.routineId == 'routine-copy'),
        isTrue,
      );

      final all = await repository.getAllRoutines();
      expect(all.length, equals(2));
    });
  });
}

