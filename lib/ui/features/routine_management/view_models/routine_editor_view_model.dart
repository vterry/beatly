import 'package:flutter/foundation.dart';

import '../../../../domain/contracts/routine_repository.dart';
import '../../../../domain/models/activity_category.dart';
import '../../../../domain/models/routine.dart';
import '../../../../domain/models/routine_activity.dart';
import '../../../../domain/use_cases/id_generator.dart';

/// ViewModel reativo para criação e edição de Rotina e suas Atividades (RF-05 / RF-06 / EC-03).
class RoutineEditorViewModel extends ChangeNotifier {
  RoutineEditorViewModel({
    required RoutineRepository repository,
    Routine? initialRoutine,
    String Function()? idGenerator,
  })  : _repository = repository,
        _idGenerator = idGenerator ?? IdGenerator.newUuidV4 {
    if (initialRoutine != null) {
      _routineId = initialRoutine.id;
      _routineName = initialRoutine.name;
      _colorHex = initialRoutine.colorHex;
      _createdAt = initialRoutine.createdAt;
      _activities = List<RoutineActivity>.from(initialRoutine.activities);
    } else {
      _routineId = _idGenerator();
    }
  }

  final RoutineRepository _repository;
  final String Function() _idGenerator;

  late final String _routineId;
  String _routineName = '';
  String _colorHex = '#7C3AED';
  DateTime? _createdAt;
  List<RoutineActivity> _activities = <RoutineActivity>[];

  // Estado de rascunho para o formulário de adição/edição rápida de atividade
  String? _editingActivityId;
  String _draftActivityName = '';
  ActivityCategory _draftCategory = ActivityCategory.tecnica;
  int _draftDurationSeconds = 300;
  int? _draftBpm;
  bool _draftAutoStartMetronome = false;
  String _draftNotes = '';

  String get routineId => _routineId;
  String get routineName => _routineName;
  String get colorHex => _colorHex;
  List<RoutineActivity> get activities =>
      List<RoutineActivity>.unmodifiable(_activities);

  /// Lista fechada e canônica das 5 categorias de estudo (RN-06.1).
  List<ActivityCategory> get availableCategories => ActivityCategory.values;

  String? get editingActivityId => _editingActivityId;
  bool get isEditingActivity => _editingActivityId != null;
  String get draftActivityName => _draftActivityName;
  ActivityCategory get draftCategory => _draftCategory;
  int get draftDurationSeconds => _draftDurationSeconds;
  int? get draftBpm => _draftBpm;
  bool get draftAutoStartMetronome => _draftAutoStartMetronome;
  String get draftNotes => _draftNotes;
  bool get canEnableDraftAutoStart => _draftBpm != null;

  bool get isValid =>
      _routineName.trim().isNotEmpty &&
      _routineName.trim().length <= 60 &&
      _activities.isNotEmpty;

  String? get validationError {
    if (_routineName.trim().isEmpty) {
      return 'Informe um nome para a rotina.';
    }
    if (_routineName.trim().length > 60) {
      return 'O nome da rotina deve ter no máximo 60 caracteres.';
    }
    if (_activities.isEmpty) {
      return 'Adicione pelo menos 1 atividade à rotina.';
    }
    return null;
  }

  /// Duração total estimada (soma das atividades + intervalos de transição).
  int totalEstimatedDurationSeconds({int transitionSeconds = 5}) {
    if (_activities.isEmpty) return 0;
    final activitiesSum = _activities.fold<int>(
      0,
      (sum, item) => sum + item.durationSeconds,
    );
    final transitionsCount = _activities.length > 1 ? _activities.length - 1 : 0;
    return activitiesSum + (transitionsCount * transitionSeconds);
  }

  void setRoutineName(String name) {
    _routineName = name;
    notifyListeners();
  }

  void setColorHex(String hex) {
    _colorHex = hex;
    notifyListeners();
  }

  void setDraftActivityName(String name) {
    _draftActivityName = name;
    notifyListeners();
  }

  void setDraftCategory(ActivityCategory category) {
    _draftCategory = category;
    notifyListeners();
  }

  void setDraftDurationSeconds(int seconds) {
    _draftDurationSeconds = seconds.clamp(10, 10800);
    notifyListeners();
  }

  void setDraftBpm(int? bpm) {
    if (bpm == null || bpm < 20 || bpm > 300) {
      _draftBpm = null;
      // RN-06.2 / EC-03: sem BPM válido, autoStart deve ser desativado imediatamente.
      _draftAutoStartMetronome = false;
    } else {
      _draftBpm = bpm;
    }
    notifyListeners();
  }

  void setDraftAutoStartMetronome(bool enabled) {
    // RN-06.2 / EC-03: bloqueia ativação caso não haja BPM configurado.
    _draftAutoStartMetronome = _draftBpm != null && enabled;
    notifyListeners();
  }

  void setDraftNotes(String notes) {
    _draftNotes = notes.length > 100 ? notes.substring(0, 100) : notes;
    notifyListeners();
  }

  /// Inicia o modo de edição para uma atividade pré-existente da rotina.
  void startEditingActivity(RoutineActivity activity) {
    _editingActivityId = activity.id;
    _draftActivityName = activity.name;
    _draftCategory = activity.category;
    _draftDurationSeconds = activity.durationSeconds;
    _draftBpm = activity.bpm;
    _draftAutoStartMetronome = activity.autoStartMetronome;
    _draftNotes = activity.notes;
    notifyListeners();
  }

  /// Cancela o modo de edição e limpa os campos de rascunho.
  void cancelEditingActivity() {
    resetDraftActivity();
  }

  void resetDraftActivity() {
    _editingActivityId = null;
    _draftActivityName = '';
    _draftCategory = ActivityCategory.tecnica;
    _draftDurationSeconds = 300;
    _draftBpm = null;
    _draftAutoStartMetronome = false;
    _draftNotes = '';
    notifyListeners();
  }

  /// Adiciona uma nova atividade ou atualiza uma existente (se [activityId] for informado).
  void addOrUpdateActivity({
    String? activityId,
    required String name,
    required ActivityCategory category,
    required int durationSeconds,
    int? bpm,
    bool autoStartMetronome = false,
    String notes = '',
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final clampedDuration = durationSeconds.clamp(10, 10800);
    final validBpm = (bpm != null && bpm >= 20 && bpm <= 300) ? bpm : null;
    final effectiveAutoStart = validBpm != null && autoStartMetronome;

    if (activityId != null) {
      final index = _activities.indexWhere((a) => a.id == activityId);
      if (index != -1) {
        _activities[index] = _activities[index].copyWith(
          name: trimmedName,
          category: category,
          durationSeconds: clampedDuration,
          bpm: validBpm,
          clearBpm: validBpm == null,
          autoStartMetronome: effectiveAutoStart,
          notes: notes,
        );
        _reindexActivities();
        notifyListeners();
        return;
      }
    }

    _activities.add(
      RoutineActivity(
        id: _idGenerator(),
        routineId: _routineId,
        name: trimmedName,
        category: category,
        durationSeconds: clampedDuration,
        bpm: validBpm,
        autoStartMetronome: effectiveAutoStart,
        notes: notes,
        orderIndex: _activities.length,
      ),
    );
    _reindexActivities();
    notifyListeners();
  }

  /// Confirma e adiciona a atividade atualmente preenchida nos campos de rascunho.
  bool commitDraftActivity() {
    if (_draftActivityName.trim().isEmpty) return false;
    addOrUpdateActivity(
      activityId: _editingActivityId,
      name: _draftActivityName,
      category: _draftCategory,
      durationSeconds: _draftDurationSeconds,
      bpm: _draftBpm,
      autoStartMetronome: _draftAutoStartMetronome,
      notes: _draftNotes,
    );
    resetDraftActivity();
    return true;
  }

  void removeActivity(String activityId) {
    _activities.removeWhere((a) => a.id == activityId);
    _reindexActivities();
    notifyListeners();
  }

  /// Reordena as atividades seguindo a convenção de `ReorderableListView`.
  void reorderActivity(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _activities.length) return;
    var targetIndex = newIndex;
    if (oldIndex < targetIndex) {
      targetIndex -= 1;
    }
    targetIndex = targetIndex.clamp(0, _activities.length - 1);
    final moved = _activities.removeAt(oldIndex);
    _activities.insert(targetIndex, moved);
    _reindexActivities();
    notifyListeners();
  }

  void _reindexActivities() {
    _activities = List<RoutineActivity>.generate(
      _activities.length,
      (index) => _activities[index].copyWith(orderIndex: index),
    );
  }

  /// Persiste a rotina e suas atividades no repositório.
  Future<Routine?> saveRoutine() async {
    if (!isValid) {
      notifyListeners();
      return null;
    }
    final now = DateTime.now().toUtc();
    final routine = Routine(
      id: _routineId,
      name: _routineName.trim(),
      colorHex: _colorHex,
      createdAt: _createdAt ?? now,
      updatedAt: now,
      activities: _activities,
    );
    await _repository.saveRoutine(routine);
    return routine;
  }
}
