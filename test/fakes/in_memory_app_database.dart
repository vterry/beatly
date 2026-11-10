import 'package:beatly/data/datasources/local/app_database.dart';
import 'package:drift/native.dart';

/// Cria uma instância limpa do [AppDatabase] em memória (`NativeDatabase.memory()`) para TDD.
AppDatabase createInMemoryAppDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

