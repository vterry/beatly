import 'dart:math' as math;

/// Assinatura da função geradora de identificadores para inversão de dependência (ADR-004).
typedef IdGeneratorFn = String Function();

/// Gerador puro de identificadores únicos UUID v4 sem dependências externas.
abstract final class IdGenerator {
  static final math.Random _rng = _createRandom();

  static math.Random _createRandom() {
    try {
      return math.Random.secure();
    } on UnsupportedError {
      return math.Random();
    }
  }

  /// Gera um UUID v4 RFC-4122 (ex.: `f47ac10b-58cc-4372-a567-0e02b2c3d479`).
  static String newUuidV4() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx

    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}

