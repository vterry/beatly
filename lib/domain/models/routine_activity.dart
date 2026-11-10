import 'activity_category.dart';

/// Unidade atômica de estudo dentro de uma rotina (RF-06).
class RoutineActivity {
  RoutineActivity({
    required this.id,
    required this.routineId,
    required this.name,
    required this.category,
    required this.durationSeconds,
    required this.orderIndex,
    this.bpm,
    bool autoStartMetronome = false,
    this.notes = '',
  }) : assert(name.trim().isNotEmpty, 'Nome da atividade não pode ser vazio'),
       assert(
         durationSeconds >= 10 && durationSeconds <= 10800,
         'Duração deve estar entre 10s e 180min',
       ),
       assert(
         bpm == null || (bpm >= 20 && bpm <= 300),
         'BPM deve estar entre 20 e 300',
       ),
       // RN-06.2 / EC-03: autoStartMetronome só pode ser true se bpm != null.
       autoStartMetronome = bpm != null && autoStartMetronome;

  final String id;
  final String routineId;
  final String name;
  final ActivityCategory category;
  final int durationSeconds;
  final int? bpm;
  final bool autoStartMetronome;
  final String notes;
  final int orderIndex;

  RoutineActivity copyWith({
    String? id,
    String? routineId,
    String? name,
    ActivityCategory? category,
    int? durationSeconds,
    int? bpm,
    bool clearBpm = false,
    bool? autoStartMetronome,
    String? notes,
    int? orderIndex,
  }) {
    final nextBpm = clearBpm ? null : (bpm ?? this.bpm);
    return RoutineActivity(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      name: name ?? this.name,
      category: category ?? this.category,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      bpm: nextBpm,
      autoStartMetronome: autoStartMetronome ?? this.autoStartMetronome,
      notes: notes ?? this.notes,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}

