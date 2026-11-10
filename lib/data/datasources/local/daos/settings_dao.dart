import 'package:drift/drift.dart';

import '../app_database.dart';

/// DAO de leitura e gravação na tabela `app_settings` (ADR-004).
class SettingsDao {
  const SettingsDao(this._db);

  final AppDatabase _db;

  Future<String?> getValueJson(String key) async {
    final rows = await _db.customSelect(
      'SELECT value_json FROM app_settings WHERE setting_key = ? LIMIT 1',
      variables: [Variable.withString(key)],
    ).get();

    if (rows.isEmpty) return null;
    return rows.first.read<String>('value_json');
  }

  Future<void> upsertValueJson(String key, String valueJson) async {
    await _db.customStatement(
      'INSERT INTO app_settings (setting_key, value_json) VALUES (?, ?) '
      'ON CONFLICT(setting_key) DO UPDATE SET value_json = excluded.value_json',
      [key, valueJson],
    );
  }
}

