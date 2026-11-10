import 'package:flutter/foundation.dart';

import '../../../../domain/contracts/session_repository.dart';
import '../../../../domain/models/activity_category.dart';
import '../../../../domain/models/practice_category_summary.dart';
import '../../../../domain/use_cases/calculate_monthly_summary_use_case.dart';
import '../../../../domain/use_cases/calculate_radar_geometry_use_case.dart';

/// ViewModel do Mapa de Evolução gerenciando navegação de meses e métricas (ADR-004 / ADR-007).
class EvolutionMapViewModel extends ChangeNotifier {
  EvolutionMapViewModel({
    required SessionRepository sessionRepository,
    CalculateMonthlySummaryUseCase? summaryUseCase,
    CalculateRadarGeometryUseCase? radarUseCase,
    int? initialYear,
    int? initialMonth,
  })  : _sessionRepository = sessionRepository,
        _summaryUseCase =
            summaryUseCase ?? const CalculateMonthlySummaryUseCase(),
        _radarUseCase = radarUseCase ?? const CalculateRadarGeometryUseCase(),
        _currentYear = initialYear ?? DateTime.now().year,
        _currentMonth = (initialMonth ?? DateTime.now().month).clamp(1, 12);

  final SessionRepository _sessionRepository;
  final CalculateMonthlySummaryUseCase _summaryUseCase;
  final CalculateRadarGeometryUseCase _radarUseCase;

  int _currentYear;
  int _currentMonth;
  bool _isLoading = false;
  MonthlyEvolutionSummary? _summary;
  Map<ActivityCategory, int> _categoryDurations = {
    for (final cat in ActivityCategory.values) cat: 0,
  };

  int get currentYear => _currentYear;
  int get currentMonth => _currentMonth;
  bool get isLoading => _isLoading;
  MonthlyEvolutionSummary? get summary => _summary;
  Map<ActivityCategory, int> get categoryDurations => _categoryDurations;
  CalculateRadarGeometryUseCase get radarUseCase => _radarUseCase;

  Future<void> loadMonth({int? year, int? month}) async {
    if (year != null) _currentYear = year;
    if (month != null) _currentMonth = month.clamp(1, 12);

    _isLoading = true;
    notifyListeners();

    try {
      final sessions = await _sessionRepository.getSessionsByMonth(
        year: _currentYear,
        month: _currentMonth,
      );
      final aggregates = await _sessionRepository.getCategoryAggregatesByMonth(
        year: _currentYear,
        month: _currentMonth,
      );

      _summary = _summaryUseCase.execute(
        year: _currentYear,
        month: _currentMonth,
        sessions: sessions,
        precomputedCategoryTotals: aggregates.isNotEmpty ? aggregates : null,
      );

      _categoryDurations = {
        for (final item in _summary!.categoryBreakdown)
          item.category: item.durationSeconds,
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> previousMonth() async {
    if (_currentMonth == 1) {
      _currentMonth = 12;
      _currentYear -= 1;
    } else {
      _currentMonth -= 1;
    }
    await loadMonth(year: _currentYear, month: _currentMonth);
  }

  Future<void> nextMonth() async {
    if (_currentMonth == 12) {
      _currentMonth = 1;
      _currentYear += 1;
    } else {
      _currentMonth += 1;
    }
    await loadMonth(year: _currentYear, month: _currentMonth);
  }
}
