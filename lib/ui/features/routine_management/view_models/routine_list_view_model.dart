import 'package:flutter/foundation.dart';

import '../../../../domain/contracts/routine_repository.dart';
import '../../../../domain/models/routine.dart';
import '../../../../domain/use_cases/id_generator.dart';

/// ViewModel reativo para listagem, busca, duplicação e remoção de Rotinas (RF-05).
class RoutineListViewModel extends ChangeNotifier {
  RoutineListViewModel({
    required RoutineRepository repository,
    String Function()? idGenerator,
  })  : _repository = repository,
        _idGenerator = idGenerator ?? IdGenerator.newUuidV4;

  final RoutineRepository _repository;
  final String Function() _idGenerator;

  List<Routine> _allRoutines = const <Routine>[];
  String _searchQuery = '';
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  List<Routine> get routines {
    if (_searchQuery.trim().isEmpty) return _allRoutines;
    final query = _searchQuery.trim().toLowerCase();
    return _allRoutines
        .where((r) => r.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  Future<void> loadRoutines() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allRoutines = await _repository.getAllRoutines();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<Routine> duplicateRoutine(String routineId) async {
    final copy = await _repository.duplicateRoutine(
      routineId,
      newRoutineId: _idGenerator(),
    );
    await loadRoutines();
    return copy;
  }

  Future<void> deleteRoutine(String routineId) async {
    await _repository.deleteRoutine(routineId);
    await loadRoutines();
  }
}
