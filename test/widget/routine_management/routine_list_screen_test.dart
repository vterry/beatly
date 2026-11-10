import 'package:beatly/data/datasources/local/app_database.dart';
import 'package:beatly/data/repositories/drift_routine_repository.dart';
import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/routine.dart';
import 'package:beatly/domain/models/routine_activity.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/routine_management/view_models/routine_list_view_model.dart';
import 'package:beatly/ui/features/routine_management/views/routine_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/in_memory_app_database.dart';

void main() {
  group('RoutineListScreen Widget Tests (TASK-05)', () {
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

    testWidgets(
      'lista rotinas cadastradas, permite duplicar e excluir',
      (tester) async {
        final now = DateTime.utc(2026, 11, 8, 15);
        await repository.saveRoutine(
          Routine(
            id: 'r-10',
            name: 'Estudo de Jazz',
            createdAt: now,
            updatedAt: now,
            activities: [
              RoutineActivity(
                id: 'a-10',
                routineId: 'r-10',
                name: 'II-V-I em 12 tons',
                category: ActivityCategory.improviso,
                durationSeconds: 600,
                orderIndex: 0,
              ),
            ],
          ),
        );
        await viewModel.loadRoutines();

        await tester.pumpWidget(
          MaterialApp(
            theme: ObsidianTheme.darkTheme,
            home: RoutineListScreen(
              viewModel: viewModel,
              repository: repository,
            ),
          ),
        );

        expect(find.text('Estudo de Jazz'), findsOneWidget);

        // Duplica a rotina
        await tester.tap(find.byKey(const ValueKey('routine_duplicate_r-10')));
        await tester.pumpAndSettle();

        expect(find.text('Estudo de Jazz (Cópia)'), findsOneWidget);

        // Exclui a rotina original
        await tester.tap(find.byKey(const ValueKey('routine_delete_r-10')));
        await tester.pumpAndSettle();

        expect(find.text('Estudo de Jazz'), findsNothing);
        expect(find.text('Estudo de Jazz (Cópia)'), findsOneWidget);
      },
    );
  });
}

