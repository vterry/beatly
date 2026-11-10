/// Definição DDL da tabela chave-valor `app_settings` (ADR-004).
class AppSettingsTable {
  static const String tableName = 'app_settings';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS app_settings (
      setting_key TEXT PRIMARY KEY NOT NULL,
      value_json TEXT NOT NULL
    );
  ''';
}

