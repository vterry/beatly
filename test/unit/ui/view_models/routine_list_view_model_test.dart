import 'package:beatly/data/datasources/local/app_database.dart';
import 'package:beatly/data/repositories/drift_routine_repository.dart';
import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/routine.dart';
import 'package:beatly/domain/models/routine_activity.dart';
import 'package:beatly/ui/features/routine_management/view_models/routine_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_app_database.dart';

void main() {
  group('RoutineListViewModel (RF-05)', () {
    late AppDatabase db;
    late DriftRoutineRepository repository;
    late RoutineListViewModel viewModel;

    setUp(() {
      db = createInMemoryAppDatabase();
      repository = DriftRoutineRepository(database: db);
      viewModel = RoutineListViewModel(repository: repository);
    });

    tearDown(() async {
      viewModel.dispose();
      await db.close();
    });

    test(
      'TC-05.07: duplicateRoutine(id) chama o repositório e recarrega a lista exibindo a nova rotina duplicada',
      () async {
        final now = DateTime.utc(2026, 11, 8, 14);
        final original = Routine(
          id: 'r-orig',
          name: 'Técnica Diária',
          createdAt: now,
          updatedAt: now,
          activities: [
            RoutineActivity(
              id: 'a-orig-1',
              routineId: 'r-orig',
              name: 'Arpejos',
              category: ActivityCategory.tecnica,
              durationSeconds: 600,
              bpm: 110,
              autoStartMetronome: true,
              orderIndex: 0,
            ),
          ],
        );

        await repository.saveRoutine(original);
        await viewModel.loadRoutines();
        expect(viewModel.routines.length, equals(1));

        await viewModel.duplicateRoutine('r-orig');
        expect(viewModel.routines.length, equals(2));
        expect(
          viewModel.routines.any((r) => r.name.contains('(Cópia)')),
          isTrue,
        );
      },
    );
  });
}
