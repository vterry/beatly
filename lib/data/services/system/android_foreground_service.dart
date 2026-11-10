import 'package:flutter/services.dart';

/// Serviço de Foreground Execution com notificação persistente no Android (ADR-006 / RNF-05).
class AndroidForegroundService {
  AndroidForegroundService({MethodChannel? channel})
      : _channel =
            channel ?? const MethodChannel('com.beatly.app/foreground_service');

  final MethodChannel _channel;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  /// Inicia o serviço em primeiro plano com notificação persistente de treino.
  Future<void> startForegroundSession({
    required String title,
    required String subtitle,
  }) async {
    _isRunning = true;
    try {
      await _channel.invokeMethod<void>('startForeground', <String, dynamic>{
        'title': title,
        'subtitle': subtitle,
      });
    } catch (_) {
      // Ignora silenciosamente em ambiente de teste
    }
  }

  /// Encerra o serviço em primeiro plano e remove a notificação do sistema.
  Future<void> stopForegroundSession() async {
    _isRunning = false;
    try {
      await _channel.invokeMethod<void>('stopForeground');
    } catch (_) {
      // Ignora silenciosamente em ambiente de teste
    }
  }
}
