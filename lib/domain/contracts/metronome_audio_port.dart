import '../models/beat_emphasis.dart';

/// Contrato abstrato do motor de áudio isócrono do metrônomo e avisos suaves (ADR-002).
abstract interface class MetronomeAudioPort {
  /// Pré-carrega os buffers PCM de baixa latência em memória.
  Future<void> initialize();

  /// Inicia o loop rítmico isócrono com o [bpm], [pattern] de pulsos e [subdivision].
  Future<void> start({
    required int bpm,
    required List<BeatEmphasis> pattern,
    int subdivision = 1,
  });

  /// Atualiza a velocidade em tempo real sem interromper a fase do compasso.
  Future<void> updateBpm(int bpm);

  /// Atualiza o padrão de acentuação/volume dos pulsos e subdivisão.
  /// Se [resetCycle] for true, reinicia a contagem para que o próximo clique seja o tempo forte.
  Future<void> updatePattern(
    List<BeatEmphasis> pattern, {
    int subdivision = 1,
    bool resetCycle = false,
  });

  /// Interrompe imediatamente a emissão sonora do metrônomo.
  Future<void> stop();

  /// Reproduz o aviso sonoro suave de transição entre atividades (RN-08.1).
  Future<void> playTransitionChime({
    double volume = 0.8,
    String soundName = 'chime_zen',
  });

  /// Reproduz um chime sonoro específico pelo nome de timbre e volume.
  Future<void> playChime({
    String soundName = 'chime_zen',
    double volume = 0.8,
  });

  /// Libera recursos nativos de áudio.
  Future<void> dispose();
}

