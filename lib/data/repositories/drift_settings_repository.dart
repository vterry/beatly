import '../../domain/contracts/settings_repository.dart';
import '../../domain/models/app_settings.dart';
import '../datasources/local/app_database.dart';
import '../mappers/settings_mapper.dart';

/// Implementação concreta de [SettingsRepository] apoiada no SQLite local via Drift (ADR-004).
class DriftSettingsRepository implements SettingsRepository {
  const DriftSettingsRepository({required AppDatabase database})
      : _db = database;

  static const String _globalSettingsKey = 'global_app_settings';

  final AppDatabase _db;

  @override
  Future<AppSettings> getSettings() async {
    final raw = await _db.settingsDao.getValueJson(_globalSettingsKey);
    return SettingsMapper.fromJsonString(raw);
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final raw = SettingsMapper.toJsonString(settings);
    await _db.settingsDao.upsertValueJson(_globalSettingsKey, raw);
  }

  @override
  Future<int> getTransitionCountdownSeconds() async {
    final settings = await getSettings();
    return settings.transitionCountdownSeconds;
  }

  @override
  Future<void> saveTransitionCountdownSeconds(int seconds) async {
    final current = await getSettings();
    await saveSettings(
      current.copyWith(transitionCountdownSeconds: seconds.clamp(0, 60)),
    );
  }
}

