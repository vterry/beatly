import 'package:drift/drift.dart';

import 'daos/routine_dao.dart';
import 'daos/session_dao.dart';
import 'daos/settings_dao.dart';
import 'tables/app_settings_table.dart';
import 'tables/routine_activities_table.dart';
import 'tables/routines_table.dart';
import 'tables/session_category_logs_table.dart';
import 'tables/study_sessions_table.dart';

/// Banco de dados SQLite local do Beatly gerenciado pelo Drift (ADR-004).
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor) {
    routineDao = RoutineDao(this);
    sessionDao = SessionDao(this);
    settingsDao = SettingsDao(this);
  }

  late final RoutineDao routineDao;
  late final SessionDao sessionDao;
  late final SettingsDao settingsDao;

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement(RoutinesTable.createTableSql);
      await customStatement(RoutineActivitiesTable.createTableSql);
      await customStatement(StudySessionsTable.createTableSql);
      await customStatement(SessionCategoryLogsTable.createTableSql);
      await customStatement(AppSettingsTable.createTableSql);
    },
    beforeOpen: (details) async {
      // Ativa chaves estrangeiras do SQLite para ON DELETE CASCADE e ON DELETE SET NULL.
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );
}

