import 'session_category_log.dart';

/// Sessão de estudo concluída (automaticamente ou via botão "Concluir") (RF-07 / RF-09).
class StudySession {
  StudySession({
    required this.id,
    required this.routineNameSnapshot,
    required this.startedAt,
    required this.endedAt,
    required this.totalDurationSeconds,
    required List<SessionCategoryLog> categoryLogs,
    this.routineId,
    this.isCompletedEarly = false,
  }) : categoryLogs = List<SessionCategoryLog>.unmodifiable(categoryLogs);

  final String id;
  final String? routineId;
  final String routineNameSnapshot;
  final DateTime startedAt;
  final DateTime endedAt;
  final int totalDurationSeconds;
  final bool isCompletedEarly;
  final List<SessionCategoryLog> categoryLogs;
}

