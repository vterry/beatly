import 'activity_category.dart';

/// Registro de tempo líquido dedicado a uma categoria dentro de uma sessão (RF-09).
class SessionCategoryLog {
  const SessionCategoryLog({
    required this.id,
    required this.sessionId,
    required this.category,
    required this.durationSeconds,
  });

  final String id;
  final String sessionId;
  final ActivityCategory category;
  final int durationSeconds;
}

