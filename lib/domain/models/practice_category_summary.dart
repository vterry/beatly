import 'activity_category.dart';

/// Sumário consolidado de prática para uma categoria específica.
class PracticeCategorySummary {
  const PracticeCategorySummary({
    required this.category,
    required this.durationSeconds,
    required this.percentage,
    required this.isTopCategory,
  });

  final ActivityCategory category;
  final int durationSeconds;
  final double percentage;
  final bool isTopCategory;
}

/// Sumário analítico consolidado das práticas em um determinado mês.
class MonthlyEvolutionSummary {
  MonthlyEvolutionSummary({
    required this.year,
    required this.month,
    required this.totalSessionsCount,
    required this.totalDurationSeconds,
    required this.activeDaysCount,
    required this.dailyAverageSecondsOnActiveDays,
    required Set<int> activeDaysOfMonth,
    required List<PracticeCategorySummary> categoryBreakdown,
    required this.topCategory,
  })  : activeDaysOfMonth = Set<int>.unmodifiable(activeDaysOfMonth),
        categoryBreakdown =
            List<PracticeCategorySummary>.unmodifiable(categoryBreakdown);

  final int year;
  final int month;
  final int totalSessionsCount;
  final int totalDurationSeconds;
  final int activeDaysCount;
  final double dailyAverageSecondsOnActiveDays;
  final Set<int> activeDaysOfMonth;
  final List<PracticeCategorySummary> categoryBreakdown;
  final ActivityCategory? topCategory;
}
