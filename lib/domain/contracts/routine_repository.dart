import '../models/routine.dart';

/// Contrato do repositório de Rotinas de Estudos (ADR-001 / ADR-004).
abstract interface class RoutineRepository {
  Future<List<Routine>> getAllRoutines();
  Future<Routine?> getRoutineById(String id);
  Future<void> saveRoutine(Routine routine);
  Future<void> deleteRoutine(String id);
  Future<Routine> duplicateRoutine(String id, {required String newRoutineId});
}

