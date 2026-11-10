import 'package:beatly/domain/contracts/settings_repository.dart';
import 'package:beatly/domain/models/app_settings.dart';

/// Implementação em memória de [SettingsRepository] para testes determinísticos.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({AppSettings? initialSettings})
      : _settings = initialSettings ?? const AppSettings();

  AppSettings _settings;
  int saveCount = 0;

  @override
  Future<AppSettings> getSettings() async {
    return _settings;
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
    saveCount++;
  }

  @override
  Future<int> getTransitionCountdownSeconds() async {
    return _settings.transitionCountdownSeconds;
  }

  @override
  Future<void> saveTransitionCountdownSeconds(int seconds) async {
    _settings = _settings.copyWith(
      transitionCountdownSeconds: seconds.clamp(0, 60),
    );
    saveCount++;
  }
}
