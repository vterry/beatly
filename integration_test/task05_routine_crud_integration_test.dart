import 'package:beatly/data/repositories/drift_routine_repository.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/routine_management/view_models/routine_list_view_model.dart';
import 'package:beatly/ui/features/routine_management/views/routine_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fakes/in_memory_app_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'TASK-05 Integration: criar nova rotina pelo fluxo completo de UI, salvar e visualizar na lista',
    (tester) async {
      final db = createInMemoryAppDatabase();
      final repository = DriftRoutineRepository(database: db);
      final listVm = RoutineListViewModel(repository: repository);

      await tester.pumpWidget(
        MaterialApp(
          theme: ObsidianTheme.darkTheme,
          home: RoutineListScreen(
            viewModel: listVm,
            repository: repository,
          ),
        ),
      );

      // Clica em Nova Rotina
      await tester.tap(find.byKey(const ValueKey('routine_btn_create')));
      await tester.pumpAndSettle();

      // Preenche o nome da rotina e adiciona 1 atividade
      await tester.enterText(
        find.byKey(const ValueKey('routine_input_name')),
        'Treino de Guitarra',
      );
      await tester.enterText(
        find.byKey(const ValueKey('activity_input_name')),
        'Alternate Picking',
      );
      await tester.pump();

      final addBtn = find.byKey(const ValueKey('activity_btn_add'));
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pump();

      // Salva e retorna à lista
      await tester.tap(find.byKey(const ValueKey('routine_btn_save')));
      await tester.pumpAndSettle();

      expect(find.text('Treino de Guitarra'), findsOneWidget);

      listVm.dispose();
      await db.close();
    },
  );
}

