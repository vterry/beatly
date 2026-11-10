import 'package:beatly/data/datasources/local/app_database.dart';
import 'package:beatly/data/repositories/drift_routine_repository.dart';
import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/ui/features/routine_management/view_models/routine_editor_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_app_database.dart';

void main() {
  group('RoutineEditorViewModel (RF-05 / RF-06 / EC-03)', () {
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

    test(
      'TC-05.03: categorias selecionáveis contêm única e exclusivamente as 5 categorias canônicas (B-RF-06.1)',
      () {
        expect(viewModel.availableCategories.length, equals(5));
        expect(
          viewModel.availableCategories.map((c) => c.label).toList(),
          equals([
            'Técnica',
            'Velocidade',
            'Teoria Musical',
            'Improviso',
            'Free Style',
          ]),
        );
      },
    );

    test(
      'TC-05.04: tentar ativar autoStartMetronome = true em atividade sem BPM mantém false (B-RF-06.2 / EC-03)',
      () {
        viewModel.setDraftBpm(null);
        viewModel.setDraftAutoStartMetronome(true);
        expect(viewModel.draftAutoStartMetronome, isFalse);

        viewModel.addOrUpdateActivity(
          name: 'Leitura Rítmica',
          category: ActivityCategory.teoriaMusical,
          durationSeconds: 300,
          bpm: null,
          autoStartMetronome: true,
        );

        expect(viewModel.activities.single.bpm, isNull);
        expect(viewModel.activities.single.autoStartMetronome, isFalse);
      },
    );

    test(
      'TC-05.05: se atividade tinha BPM 120 e autoStart = true, ao limpar o BPM muda automaticamente para false',
      () {
        viewModel.setDraftBpm(120);
        viewModel.setDraftAutoStartMetronome(true);
        expect(viewModel.draftAutoStartMetronome, isTrue);

        // Limpa o BPM no rascunho do formulário
        viewModel.setDraftBpm(null);
        expect(viewModel.draftAutoStartMetronome, isFalse);
      },
    );

    test(
      'TC-05.06: reorderActivity(oldIndex, newIndex) atualiza a lista preservando a nova sequência ordinal',
      () {
        viewModel.addOrUpdateActivity(
          name: 'Ativ 1',
          category: ActivityCategory.tecnica,
          durationSeconds: 300,
        );
        viewModel.addOrUpdateActivity(
          name: 'Ativ 2',
          category: ActivityCategory.velocidade,
          durationSeconds: 600,
        );
        viewModel.addOrUpdateActivity(
          name: 'Ativ 3',
          category: ActivityCategory.improviso,
          durationSeconds: 300,
        );

        // Move o item 0 ('Ativ 1') para o final (newIndex = 3 no ReorderableListView)
        viewModel.reorderActivity(0, 3);

        expect(
          viewModel.activities.map((a) => a.name).toList(),
          equals(['Ativ 2', 'Ativ 3', 'Ativ 1']),
        );
        expect(
          viewModel.activities.map((a) => a.orderIndex).toList(),
          equals([0, 1, 2]),
        );
      },
    );

    test(
      'TC-05.08: startEditingActivity carrega atividade para o draft e commitDraftActivity atualiza a atividade existente',
      () {
        viewModel.addOrUpdateActivity(
          name: 'Arpejos Diminutos',
          category: ActivityCategory.tecnica,
          durationSeconds: 300,
          bpm: 100,
          autoStartMetronome: true,
          notes: 'Dedilhado clássico',
        );

        final original = viewModel.activities.single;
        expect(viewModel.isEditingActivity, isFalse);

        viewModel.startEditingActivity(original);
        expect(viewModel.isEditingActivity, isTrue);
        expect(viewModel.editingActivityId, equals(original.id));
        expect(viewModel.draftActivityName, equals('Arpejos Diminutos'));
        expect(viewModel.draftBpm, equals(100));
        expect(viewModel.draftNotes, equals('Dedilhado clássico'));

        // Modifica os campos
        viewModel.setDraftActivityName('Arpejos Diminutos com Sweep');
        viewModel.setDraftBpm(130);
        viewModel.setDraftNotes('Foco na mão direita');
        viewModel.commitDraftActivity();

        expect(viewModel.isEditingActivity, isFalse);
        expect(viewModel.editingActivityId, isNull);
        expect(viewModel.activities.length, equals(1));
        final updated = viewModel.activities.single;
        expect(updated.id, equals(original.id));
        expect(updated.name, equals('Arpejos Diminutos com Sweep'));
        expect(updated.bpm, equals(130));
        expect(updated.notes, equals('Foco na mão direita'));
      },
    );

    test(
      'TC-05.09: setDraftNotes limita tamanho máximo em 100 caracteres',
      () {
        final longNote = 'a' * 150;
        viewModel.setDraftNotes(longNote);
        expect(viewModel.draftNotes.length, equals(100));
        expect(viewModel.draftNotes, equals('a' * 100));
      },
    );
  });
}
