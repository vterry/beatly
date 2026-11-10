import 'package:beatly/domain/contracts/session_repository.dart';
import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/study_session.dart';

/// Implementação em memória de [SessionRepository] para TDD determinístico (ADR-004).
class FakeSessionRepository implements SessionRepository {
  final List<StudySession> savedSessions = [];

  @override
  Future<void> saveSession(StudySession session) async {
    savedSessions.add(session);
  }

  @override
  Future<List<StudySession>> getSessionsByMonth({
    required int year,
    required int month,
  }) async {
    return savedSessions.where((s) {
      final utc = s.startedAt.toUtc();
      return utc.year == year && utc.month == month;
    }).toList();
  }

  @override
  Future<Map<ActivityCategory, int>> getCategoryAggregatesByMonth({
    required int year,
    required int month,
  }) async {
    final totals = <ActivityCategory, int>{};
    for (final s in savedSessions) {
      final utc = s.startedAt.toUtc();
      if (utc.year == year && utc.month == month) {
        for (final log in s.categoryLogs) {
          totals[log.category] = (totals[log.category] ?? 0) + log.durationSeconds;
        }
      }
    }
    return totals;
  }
}
