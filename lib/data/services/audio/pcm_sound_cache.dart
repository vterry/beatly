import 'dart:math' as math;
import 'dart:typed_data';

/// Gerenciador de amostras PCM curtas de 16-bit 44.1kHz pré-carregadas em memória RAM (ADR-002).
class PcmSoundCache {
  final Map<String, Uint8List> _samples = <String, Uint8List>{};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<String> get loadedKeys => List<String>.unmodifiable(_samples.keys);

  Uint8List? getSample(String key) => _samples[key];

  /// Pré-carrega todas as amostras de clicks de madeira e chimes em memória RAM.
  Future<void> preloadAll() async {
    _samples['click_wood_high'] = _generateWav(
      frequencyHz: 1200.0,
      durationSeconds: 0.035,
      attackSeconds: 0.002,
      decayExponent: 8.0,
    );
    _samples['click_wood_mid'] = _generateWav(
      frequencyHz: 800.0,
      durationSeconds: 0.04,
      attackSeconds: 0.002,
      decayExponent: 7.0,
    );
    _samples['click_wood_low'] = _generateWav(
      frequencyHz: 440.0,
      durationSeconds: 0.05,
      attackSeconds: 0.003,
      decayExponent: 6.0,
    );
    _samples['chime_tibetan_bowl'] = _generateWav(
      frequencyHz: 528.0,
      durationSeconds: 0.5,
      attackSeconds: 0.01,
      decayExponent: 3.5,
    );
    _samples['chime_marimba'] = _generateWav(
      frequencyHz: 440.0,
      durationSeconds: 0.35,
      attackSeconds: 0.005,
      decayExponent: 5.0,
    );
    _samples['chime_gong'] = _generateWav(
      frequencyHz: 220.0,
      durationSeconds: 0.6,
      attackSeconds: 0.015,
      decayExponent: 3.0,
    );

    _isLoaded = true;
  }

  /// Limpa todas as amostras da memória RAM.
  void clear() {
    _samples.clear();
    _isLoaded = false;
  }

  /// Gera um buffer PCM WAV padrão RIFF 16-bit 44.1kHz mono programaticamente.
  static Uint8List _generateWav({
    required double frequencyHz,
    required double durationSeconds,
    required double attackSeconds,
    required double decayExponent,
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationSeconds).round();
    final dataSize = numSamples * 2;
    final totalSize = 44 + dataSize;
    final bytes = Uint8List(totalSize);
    final byteData = ByteData.sublistView(bytes);

    // RIFF chunk
    bytes.setRange(0, 4, 'RIFF'.codeUnits);
    byteData.setUint32(4, 36 + dataSize, Endian.little);
    bytes.setRange(8, 12, 'WAVE'.codeUnits);

    // fmt subchunk
    bytes.setRange(12, 16, 'fmt '.codeUnits);
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little); // PCM format
    byteData.setUint16(22, 1, Endian.little); // Mono
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little); // Block align
    byteData.setUint16(34, 16, Endian.little); // Bits per sample

    // data subchunk
    bytes.setRange(36, 40, 'data'.codeUnits);
    byteData.setUint32(40, dataSize, Endian.little);

    // Sintetiza áudio com decaimento exponencial
    const twoPi = 2.0 * math.pi;
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final progress = t / durationSeconds;
      final envelope = (t < attackSeconds)
          ? (t / attackSeconds)
          : math.exp(-decayExponent * progress);

      final sampleValue = math.sin(twoPi * frequencyHz * t) * envelope;
      final sampleInt16 =
          (sampleValue * 32767.0).clamp(-32768.0, 32767.0).round();
      byteData.setInt16(44 + i * 2, sampleInt16, Endian.little);
    }

    return bytes;
  }
}
