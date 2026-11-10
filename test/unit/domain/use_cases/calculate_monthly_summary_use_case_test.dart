import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/session_category_log.dart';
import 'package:beatly/domain/models/study_session.dart';
import 'package:beatly/domain/use_cases/calculate_monthly_summary_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = CalculateMonthlySummaryUseCase();

  group('CalculateMonthlySummaryUseCase Tests (TASK-07)', () {
    test(
      'TC-07.05: Três rotinas concluídas em Novembro/2026 com 1800s (30m) de Improviso cada devem totalizar 5400s (90m) de Improviso e 3 sessões concluídas',
      () {
        final sessions = [
          StudySession(
            id: 's-1',
            routineNameSnapshot: 'Jazz Soloing',
            startedAt: DateTime.utc(2026, 11, 2, 10, 0),
            endedAt: DateTime.utc(2026, 11, 2, 10, 30),
            totalDurationSeconds: 1800,
            categoryLogs: [
              const SessionCategoryLog(
                id: 'log-1',
                sessionId: 's-1',
                category: ActivityCategory.improviso,
                durationSeconds: 1800,
              ),
            ],
          ),
          StudySession(
            id: 's-2',
            routineNameSnapshot: 'Jazz Soloing',
            startedAt: DateTime.utc(2026, 11, 5, 14, 0),
            endedAt: DateTime.utc(2026, 11, 5, 14, 30),
            totalDurationSeconds: 1800,
            categoryLogs: [
              const SessionCategoryLog(
                id: 'log-2',
                sessionId: 's-2',
                category: ActivityCategory.improviso,
                durationSeconds: 1800,
              ),
            ],
          ),
          StudySession(
            id: 's-3',
            routineNameSnapshot: 'Jazz Soloing',
            startedAt: DateTime.utc(2026, 11, 12, 18, 0),
            endedAt: DateTime.utc(2026, 11, 12, 18, 30),
            totalDurationSeconds: 1800,
            categoryLogs: [
              const SessionCategoryLog(
                id: 'log-3',
                sessionId: 's-3',
                category: ActivityCategory.improviso,
                durationSeconds: 1800,
              ),
            ],
          ),
        ];

        final summary = useCase.execute(
          year: 2026,
          month: 11,
          sessions: sessions,
        );

        expect(summary.totalSessionsCount, equals(3));
        expect(summary.totalDurationSeconds, equals(5400));
        expect(summary.topCategory, equals(ActivityCategory.improviso));

        final improSummary = summary.categoryBreakdown.firstWhere(
          (c) => c.category == ActivityCategory.improviso,
        );
        expect(improSummary.durationSeconds, equals(5400));
        expect(improSummary.percentage, closeTo(100.0, 1e-5));
        expect(improSummary.isTopCategory, isTrue);

        final tecnicaSummary = summary.categoryBreakdown.firstWhere(
          (c) => c.category == ActivityCategory.tecnica,
        );
        expect(tecnicaSummary.durationSeconds, equals(0));
        expect(tecnicaSummary.percentage, equals(0.0));
        expect(tecnicaSummary.isTopCategory, isFalse);
      },
    );

    test(
      'TC-07.06: Deve calcular a média diária considerando apenas os dias do mês com treinos registrados (3 sessões em 2 dias distintos totalizando 3600s -> activeDaysCount == 2 e dailyAverageSecondsOnActiveDays == 1800.0)',
      () {
        final sessions = [
          StudySession(
            id: 's-10',
            routineNameSnapshot: 'Treino A',
            startedAt: DateTime.utc(2026, 11, 10, 9, 0),
            endedAt: DateTime.utc(2026, 11, 10, 9, 20),
            totalDurationSeconds: 1200,
            categoryLogs: [
              const SessionCategoryLog(
                id: 'l-10',
                sessionId: 's-10',
                category: ActivityCategory.tecnica,
                durationSeconds: 1200,
              ),
            ],
          ),
          StudySession(
            id: 's-11',
            routineNameSnapshot: 'Treino B',
            startedAt: DateTime.utc(2026, 11, 10, 16, 0),
            endedAt: DateTime.utc(2026, 11, 10, 16, 20),
            totalDurationSeconds: 1200,
            categoryLogs: [
              const SessionCategoryLog(
                id: 'l-11',
                sessionId: 's-11',
                category: ActivityCategory.velocidade,
                durationSeconds: 1200,
              ),
            ],
          ),
          StudySession(
            id: 's-12',
            routineNameSnapshot: 'Treino C',
            startedAt: DateTime.utc(2026, 11, 15, 10, 0),
            endedAt: DateTime.utc(2026, 11, 15, 10, 20),
            totalDurationSeconds: 1200,
            categoryLogs: [
              const SessionCategoryLog(
                id: 'l-12',
                sessionId: 's-12',
                category: ActivityCategory.teoriaMusical,
                durationSeconds: 1200,
              ),
            ],
          ),
        ];

        final summary = useCase.execute(
          year: 2026,
          month: 11,
          sessions: sessions,
        );

        expect(summary.totalSessionsCount, equals(3));
        expect(summary.totalDurationSeconds, equals(3600));
        expect(summary.activeDaysOfMonth, equals({10, 15}));
        expect(summary.activeDaysCount, equals(2));
        expect(summary.dailyAverageSecondsOnActiveDays, closeTo(1800.0, 1e-5));
      },
    );

    test(
      'Para mês sem sessões cadastradas, retorna sumário zerado com dailyAverage == 0.0 e topCategory == null',
      () {
        final summary = useCase.execute(
          year: 2026,
          month: 11,
          sessions: const [],
        );

        expect(summary.totalSessionsCount, equals(0));
        expect(summary.totalDurationSeconds, equals(0));
        expect(summary.activeDaysCount, equals(0));
        expect(summary.dailyAverageSecondsOnActiveDays, equals(0.0));
        expect(summary.topCategory, isNull);
        expect(summary.categoryBreakdown.length, equals(5));
        for (final cat in summary.categoryBreakdown) {
          expect(cat.durationSeconds, equals(0));
          expect(cat.percentage, equals(0.0));
          expect(cat.isTopCategory, isFalse);
        }
      },
    );
  });
}
