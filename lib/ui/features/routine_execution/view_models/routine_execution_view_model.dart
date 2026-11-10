import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/models/beat_emphasis.dart';
import '../../../../domain/models/routine.dart';
import '../../../../domain/models/routine_execution_state.dart';
import '../../../../domain/state_machines/routine_execution_coordinator.dart';

/// ViewModel que expõe os estados e ações da execução de rotina para a UI (RF-06 / ADR-001).
class RoutineExecutionViewModel extends ChangeNotifier {
  RoutineExecutionViewModel({
    required RoutineExecutionCoordinator coordinator,
  }) : _coordinator = coordinator {
    _stateSubscription = _coordinator.stateStream.listen((_) {
      notifyListeners();
    });
  }

  final RoutineExecutionCoordinator _coordinator;
  StreamSubscription<RoutineExecutionState>? _stateSubscription;

  RoutineExecutionState get state => _coordinator.state;
  Routine? get currentRoutine => _coordinator.routine;
  int get activeBpm => _coordinator.activeBpm;
  List<BeatEmphasis> get activePattern => _coordinator.activePattern;
  int get activeSubdivision => _coordinator.activeSubdivision;

  /// Inicia a rotina com os tempos configurados de preparação e transição.
  Future<void> startRoutine(
    Routine routine, {
    int preparationSeconds = 5,
    int transitionSeconds = 5,
    String transitionChime = 'chime_zen',
    double transitionVolume = 0.8,
  }) async {
    await _coordinator.start(
      routine,
      preparationSeconds: preparationSeconds,
      transitionSeconds: transitionSeconds,
      transitionChime: transitionChime,
      transitionVolume: transitionVolume,
    );
  }

  /// Pausa o treino e o som do metrônomo.
  Future<void> pause() async {
    await _coordinator.pause();
  }

  /// Retoma o treino da rotina.
  Future<void> resume() async {
    await _coordinator.resume();
  }

  /// Avança manualmente para a próxima atividade da rotina.
  Future<void> skipToNext() async {
    await _coordinator.skipToNext();
  }

  /// Retorna à atividade anterior da rotina.
  Future<void> previous() async {
    await _coordinator.previous();
  }

  /// Pula imediatamente a contagem regressiva de preparação ou transição.
  Future<void> skipTransition() async {
    await _coordinator.skipTransition();
  }

  /// Alterna o metrônomo ligado/desligado manualmente.
  Future<void> toggleMetronome() async {
    await _coordinator.toggleMetronome();
  }

  /// Ajusta a velocidade do metrônomo dinamicamente durante o treino.
  Future<void> updateBpm(int bpm) async {
    await _coordinator.updateBpm(bpm);
  }

  /// Incrementa ou decrementa a velocidade do metrônomo em delta BPM.
  Future<void> stepBpm(int delta) async {
    await _coordinator.stepBpm(delta);
  }

  /// Atualiza a divisão de tempo (1x, 2x, 3x, 4x) durante o treino.
  Future<void> updateSubdivision(int subdivision) async {
    await _coordinator.updateSubdivision(subdivision);
  }

  /// Alterna o volume/ênfase do pulso em tempo real.
  Future<void> cycleBeatEmphasis(int index) async {
    await _coordinator.cycleBeatEmphasis(index);
  }

  /// Atualiza o padrão completo de ênfases.
  Future<void> updatePattern(List<BeatEmphasis> pattern) async {
    await _coordinator.updatePattern(pattern);
  }

  /// Restaura o padrão de acentuações para o padrão.
  Future<void> resetBeatPatternToDefault() async {
    await _coordinator.resetBeatPatternToDefault();
  }

  /// Muta todos os pulsos do compasso.
  Future<void> muteAllBeats() async {
    await _coordinator.muteAllBeats();
  }

  /// Conclui o treino de forma antecipada gravando a sessão de estudo.
  Future<void> completeRoutineEarly() async {
    await _coordinator.completeEarly();
  }

  /// Descarta e cancela a sessão em andamento sem salvar no banco de dados.
  Future<void> cancelRoutine() async {
    await _coordinator.cancel();
  }

  /// Indica se a execução atual já foi finalizada ou cancelada.
  bool get isFinished =>
      state is ExecutionStateCompleted || state is ExecutionStateCanceled;

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
    _coordinator.dispose();
    super.dispose();
  }
}
