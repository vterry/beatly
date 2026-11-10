import 'routine_activity.dart';

/// Agrupamento sequencial e ordenado de atividades de estudo (RF-05).
class Routine {
  Routine({
    required this.id,
    required this.name,
    required List<RoutineActivity> activities,
    required this.createdAt,
    required this.updatedAt,
    this.colorHex = '#7C3AED',
  }) : assert(name.trim().isNotEmpty, 'Nome da rotina não pode ser vazio'),
       activities = List<RoutineActivity>.unmodifiable(activities);

  final String id;
  final String name;
  final String colorHex;
  final List<RoutineActivity> activities;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Soma pura da duração das atividades em segundos.
  int get activitiesDurationSeconds =>
      activities.fold<int>(0, (sum, item) => sum + item.durationSeconds);

  /// Duração total estimada incluindo as transições entre atividades (RN-05.2).
  ///
  /// Para N atividades (N > 1), existem (N - 1) intervalos de transição entre elas.
  int totalEstimatedDurationSeconds({int transitionSeconds = 5}) {
    if (activities.isEmpty) return 0;
    final transitionsCount = activities.length > 1 ? activities.length - 1 : 0;
    return activitiesDurationSeconds + (transitionsCount * transitionSeconds);
  }

  Routine copyWith({
    String? id,
    String? name,
    String? colorHex,
    List<RoutineActivity>? activities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      activities: activities ?? this.activities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

