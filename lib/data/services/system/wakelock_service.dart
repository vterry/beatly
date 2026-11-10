import 'package:flutter/services.dart';

/// Serviço de controle de tela ativa (Wakelock) com fallback seguro (ADR-006 / RF-12).
class WakelockService {
  WakelockService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.beatly.app/wakelock');

  final MethodChannel _channel;
  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  /// Mantém a tela ligada sem apagar.
  Future<void> enable() async {
    _isEnabled = true;
    try {
      await _channel.invokeMethod<void>('enable');
    } catch (_) {
      // Ignora silenciosamente em ambiente de teste ou quando plugin não registrado
    }
  }

  /// Permite que a tela apague seguindo as configurações do SO.
  Future<void> disable() async {
    _isEnabled = false;
    try {
      await _channel.invokeMethod<void>('disable');
    } catch (_) {
      // Ignora silenciosamente em ambiente de teste
    }
  }

  /// Aplica a preferência considerando se há treino ativo e se a opção está habilitada.
  Future<void> applyPreference({
    required bool keepScreenAwake,
    required bool isTrainingActive,
  }) async {
    if (keepScreenAwake && isTrainingActive) {
      await enable();
    } else {
      await disable();
    }
  }
}
