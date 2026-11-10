import '../models/activity_category.dart';
import '../models/study_session.dart';

/// Contrato do repositório de Sessões e Analytics do Mapa de Evolução (ADR-004).
abstract interface class SessionRepository {
  Future<void> saveSession(StudySession session);
  Future<List<StudySession>> getSessionsByMonth({
    required int year,
    required int month,
  });

  /// Retorna o total acumulado em segundos para cada uma das 5 categorias no mês.
  Future<Map<ActivityCategory, int>> getCategoryAggregatesByMonth({
    required int year,
    required int month,
  });
}

