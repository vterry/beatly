import '../models/activity_category.dart';
import '../models/practice_category_summary.dart';
import '../models/study_session.dart';

/// Caso de uso analítico para consolidação mensal dos treinos e consistência (ADR-004 / RN-06).
class CalculateMonthlySummaryUseCase {
  const CalculateMonthlySummaryUseCase();

  MonthlyEvolutionSummary execute({
    required int year,
    required int month,
    required List<StudySession> sessions,
    Map<ActivityCategory, int>? precomputedCategoryTotals,
  }) {
    // Filtra estritamente as sessões pertencentes ao ano e mês solicitados (UTC)
    final monthSessions = sessions.where((s) {
      final utc = s.startedAt.toUtc();
      return utc.year == year && utc.month == month;
    }).toList();

    final categoryTotals = <ActivityCategory, int>{
      for (final cat in ActivityCategory.values) cat: 0,
    };

    if (precomputedCategoryTotals != null) {
      for (final cat in ActivityCategory.values) {
        categoryTotals[cat] = precomputedCategoryTotals[cat] ?? 0;
      }
    } else {
      for (final session in monthSessions) {
        for (final log in session.categoryLogs) {
          categoryTotals[log.category] =
              (categoryTotals[log.category] ?? 0) + log.durationSeconds;
        }
      }
    }

    final totalSessionsCount = monthSessions.length;

    var totalDurationSeconds =
        monthSessions.fold(0, (sum, s) => sum + s.totalDurationSeconds);

    if (totalDurationSeconds == 0) {
      totalDurationSeconds =
          categoryTotals.values.fold(0, (sum, val) => sum + val);
    }

    final activeDaysOfMonth =
        monthSessions.map((s) => s.startedAt.toUtc().day).toSet();
    final activeDaysCount = activeDaysOfMonth.length;

    final dailyAverageSecondsOnActiveDays = activeDaysCount > 0
        ? totalDurationSeconds / activeDaysCount
        : 0.0;

    // Identifica categoria de maior foco (> 0 segundos)
    ActivityCategory? topCategory;
    var maxSeconds = 0;
    for (final cat in ActivityCategory.values) {
      final seconds = categoryTotals[cat] ?? 0;
      if (seconds > maxSeconds) {
        maxSeconds = seconds;
        topCategory = cat;
      }
    }

    // Monta breakdown percentual na ordem dos 5 eixos canônicos
    final categoryBreakdown = <PracticeCategorySummary>[];
    for (final cat in ActivityCategory.values) {
      final catSeconds = categoryTotals[cat] ?? 0;
      final percentage = totalDurationSeconds > 0
          ? (catSeconds / totalDurationSeconds) * 100.0
          : 0.0;
      final isTopCategory = (cat == topCategory && catSeconds > 0);

      categoryBreakdown.add(
        PracticeCategorySummary(
          category: cat,
          durationSeconds: catSeconds,
          percentage: percentage,
          isTopCategory: isTopCategory,
        ),
      );
    }

    return MonthlyEvolutionSummary(
      year: year,
      month: month,
      totalSessionsCount: totalSessionsCount,
      totalDurationSeconds: totalDurationSeconds,
      activeDaysCount: activeDaysCount,
      dailyAverageSecondsOnActiveDays: dailyAverageSecondsOnActiveDays,
      activeDaysOfMonth: activeDaysOfMonth,
      categoryBreakdown: categoryBreakdown,
      topCategory: topCategory,
    );
  }
}
