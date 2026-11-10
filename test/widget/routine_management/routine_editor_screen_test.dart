import 'package:beatly/data/datasources/local/app_database.dart';
import 'package:beatly/data/repositories/drift_routine_repository.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/routine_management/view_models/routine_editor_view_model.dart';
import 'package:beatly/ui/features/routine_management/views/routine_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/in_memory_app_database.dart';

void main() {
  group('RoutineEditorScreen Widget Tests (TASK-05)', () {
    late AppDatabase db;
    late DriftRoutineRepository repository;
    late RoutineEditorViewModel viewModel;

    setUp(() {
      db = createInMemoryAppDatabase();
      repository = DriftRoutineRepository(database: db);
      viewModel = RoutineEditorViewModel(repository: repository);
    });

    tearDown(() async {
      viewModel.dispose();
      await db.close();
    });

    Widget buildHarness() {
      return MaterialApp(
        theme: ObsidianTheme.darkTheme,
        home: RoutineEditorScreen(viewModel: viewModel),
      );
    }

    testWidgets(
      'WTC-05.01: category_picker renderiza exatamente as 5 categorias canônicas',
      (tester) async {
        await tester.pumpWidget(buildHarness());

        expect(find.byKey(const ValueKey('category_picker')), findsOneWidget);
        expect(find.text('Técnica'), findsOneWidget);
        expect(find.text('Velocidade'), findsOneWidget);
        expect(find.text('Teoria Musical'), findsOneWidget);
        expect(find.text('Improviso'), findsOneWidget);
        expect(find.text('Free Style'), findsOneWidget);
      },
    );

    testWidgets(
      'WTC-05.02: switch activity_switch_autostart permanece desabilitado enquanto activity_input_bpm estiver vazio (EC-03)',
      (tester) async {
        await tester.pumpWidget(buildHarness());

        Switch switchWidget = tester.widget<Switch>(
          find.byKey(const ValueKey('activity_switch_autostart')),
        );
        expect(switchWidget.onChanged, isNull);

        // Preenche BPM válido -> habilita o switch
        await tester.enterText(
          find.byKey(const ValueKey('activity_input_bpm')),
          '120',
        );
        await tester.pump();

        switchWidget = tester.widget<Switch>(
          find.byKey(const ValueKey('activity_switch_autostart')),
        );
        expect(switchWidget.onChanged, isNotNull);

        // Limpa o BPM -> desabilita novamente
        await tester.enterText(
          find.byKey(const ValueKey('activity_input_bpm')),
          '',
        );
        await tester.pump();

        switchWidget = tester.widget<Switch>(
          find.byKey(const ValueKey('activity_switch_autostart')),
        );
        expect(switchWidget.onChanged, isNull);
      },
    );

    testWidgets(
      'WTC-05.03: preencher routine_input_name, adicionar 2 atividades e tocar em routine_btn_save salva com sucesso',
      (tester) async {
        await tester.pumpWidget(buildHarness());

        await tester.enterText(
          find.byKey(const ValueKey('routine_input_name')),
          'Rotina Noturna',
        );
        await tester.pump();

        // Adiciona atividade 1
        await tester.enterText(
          find.byKey(const ValueKey('activity_input_name')),
          'Cromatismo',
        );
        await tester.pump();
        final addBtn = find.byKey(const ValueKey('activity_btn_add'));
        await tester.ensureVisible(addBtn);
        await tester.tap(addBtn);
        await tester.pump();

        // Adiciona atividade 2
        await tester.enterText(
          find.byKey(const ValueKey('activity_input_name')),
          'Tríades',
        );
        await tester.pump();
        await tester.ensureVisible(addBtn);
        await tester.tap(addBtn);
        await tester.pump();

        expect(viewModel.activities.length, equals(2));

        // Clica em Salvar
        await tester.tap(find.byKey(const ValueKey('routine_btn_save')));
        await tester.pumpAndSettle();

        final savedRoutines = await repository.getAllRoutines();
        expect(savedRoutines.length, equals(1));
        expect(savedRoutines.single.name, equals('Rotina Noturna'));
        expect(savedRoutines.single.activities.length, equals(2));
      },
    );

    testWidgets(
      'WTC-05.04: editar atividade carrega campos com notas e salvar atualiza o item existente',
      (tester) async {
        await tester.pumpWidget(buildHarness());

        // Preenche atividade inicial com nota
        await tester.enterText(
          find.byKey(const ValueKey('activity_input_name')),
          'Escala Menor Melódica',
        );
        await tester.enterText(
          find.byKey(const ValueKey('activity_input_notes')),
          'Foco no 6º e 7º graus maiores',
        );
        await tester.pump();

        final addBtn = find.byKey(const ValueKey('activity_btn_add'));
        await tester.ensureVisible(addBtn);
        await tester.tap(addBtn);
        await tester.pump();

        expect(find.text('Escala Menor Melódica'), findsOneWidget);
        expect(find.text('Foco no 6º e 7º graus maiores'), findsOneWidget);

        final activityId = viewModel.activities.single.id;

        // Clica no botão de editar da atividade
        final editBtn = find.byKey(ValueKey('activity_edit_$activityId'));
        await tester.ensureVisible(editBtn);
        await tester.tap(editBtn);
        await tester.pump();

        expect(find.text('Editar Atividade'), findsOneWidget);
        expect(find.byKey(const ValueKey('activity_btn_save_edit')), findsOneWidget);

        // Altera nome e notas
        await tester.enterText(
          find.byKey(const ValueKey('activity_input_name')),
          'Menor Melódica com Arpejos',
        );
        await tester.enterText(
          find.byKey(const ValueKey('activity_input_notes')),
          'Tocar em tercinas a 120 BPM',
        );
        await tester.pump();

        final saveEditBtn = find.byKey(const ValueKey('activity_btn_save_edit'));
        await tester.ensureVisible(saveEditBtn);
        await tester.tap(saveEditBtn);
        await tester.pump();

        // Saiu do modo edição e atualizou
        expect(find.text('Nova Atividade'), findsOneWidget);
        expect(find.text('Menor Melódica com Arpejos'), findsOneWidget);
        expect(find.text('Tocar em tercinas a 120 BPM'), findsOneWidget);
        expect(viewModel.activities.length, equals(1));
        expect(viewModel.activities.single.name, equals('Menor Melódica com Arpejos'));
        expect(viewModel.activities.single.notes, equals('Tocar em tercinas a 120 BPM'));
      },
    );
  });
}

