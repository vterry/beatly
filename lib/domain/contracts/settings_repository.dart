import '../models/app_settings.dart';

/// Contrato do repositório de Configurações Gerais (RF-11 / RF-12).
abstract interface class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<int> getTransitionCountdownSeconds();
  Future<void> saveTransitionCountdownSeconds(int seconds);
}

