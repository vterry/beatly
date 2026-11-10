import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/session_category_log.dart';
import 'package:beatly/domain/models/study_session.dart';
import 'package:beatly/ui/features/evolution_map/view_models/evolution_map_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_session_repository.dart';

void main() {
  group('EvolutionMapViewModel Unit Tests (TASK-07)', () {
    late FakeSessionRepository repository;

    setUp(() {
      repository = FakeSessionRepository();
    });

    test('Carrega dados do mês especificado e atualiza summary e categoryDurations', () async {
      await repository.saveSession(
        StudySession(
          id: 's-1',
          routineNameSnapshot: 'Rotina Teste',
          startedAt: DateTime.utc(2026, 11, 4, 10, 0),
          endedAt: DateTime.utc(2026, 11, 4, 10, 20),
          totalDurationSeconds: 1200,
          categoryLogs: [
            const SessionCategoryLog(
              id: 'l-1',
              sessionId: 's-1',
              category: ActivityCategory.tecnica,
              durationSeconds: 1200,
            ),
          ],
        ),
      );

      final viewModel = EvolutionMapViewModel(
        sessionRepository: repository,
        initialYear: 2026,
        initialMonth: 11,
      );

      expect(viewModel.currentYear, equals(2026));
      expect(viewModel.currentMonth, equals(11));
      expect(viewModel.summary, isNull);

      await viewModel.loadMonth();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.summary, isNotNull);
      expect(viewModel.summary!.totalSessionsCount, equals(1));
      expect(viewModel.summary!.totalDurationSeconds, equals(1200));
      expect(viewModel.categoryDurations[ActivityCategory.tecnica], equals(1200));
      expect(viewModel.categoryDurations[ActivityCategory.velocidade], equals(0));
    });

    test('previousMonth() decrementa mês e lida corretamente com virada de ano (Janeiro para Dezembro anterior)', () async {
      final viewModel = EvolutionMapViewModel(
        sessionRepository: repository,
        initialYear: 2026,
        initialMonth: 1,
      );

      await viewModel.previousMonth();

      expect(viewModel.currentYear, equals(2025));
      expect(viewModel.currentMonth, equals(12));

      await viewModel.previousMonth();

      expect(viewModel.currentYear, equals(2025));
      expect(viewModel.currentMonth, equals(11));
    });

    test('nextMonth() incrementa mês e lida corretamente com virada de ano (Dezembro para Janeiro subsequente)', () async {
      final viewModel = EvolutionMapViewModel(
        sessionRepository: repository,
        initialYear: 2026,
        initialMonth: 12,
      );

      await viewModel.nextMonth();

      expect(viewModel.currentYear, equals(2027));
      expect(viewModel.currentMonth, equals(1));

      await viewModel.nextMonth();

      expect(viewModel.currentYear, equals(2027));
      expect(viewModel.currentMonth, equals(2));
    });
  });
}
