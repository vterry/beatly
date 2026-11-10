import 'package:beatly/data/datasources/local/app_database.dart';
import 'package:beatly/data/datasources/local/tables/session_category_logs_table.dart';
import 'package:beatly/data/datasources/local/tables/study_sessions_table.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_app_database.dart';

void main() {
  group('SessionDao (SQLite / Drift)', () {
    late AppDatabase db;

    setUp(() {
      db = createInMemoryAppDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('agrega somatório por categoria apenas dentro do intervalo solicitado', () async {
      await db.sessionDao.insertSessionWithLogs(
        session: const StudySessionRow(
          id: 's-in',
          routineId: null,
          routineNameSnapshot: 'Dentro do Mês',
          startedAtMs: 1500,
          endedAtMs: 2500,
          totalDurationSeconds: 1000,
          isCompletedEarly: false,
        ),
        logs: const [
          SessionCategoryLogRow(
            id: 'l-1',
            sessionId: 's-in',
            categoryKey: 'tecnica',
            durationSeconds: 600,
          ),
          SessionCategoryLogRow(
            id: 'l-2',
            sessionId: 's-in',
            categoryKey: 'improviso',
            durationSeconds: 400,
          ),
        ],
      );

      await db.sessionDao.insertSessionWithLogs(
        session: const StudySessionRow(
          id: 's-out',
          routineId: null,
          routineNameSnapshot: 'Fora do Mês',
          startedAtMs: 5000,
          endedAtMs: 6000,
          totalDurationSeconds: 1000,
          isCompletedEarly: false,
        ),
        logs: const [
          SessionCategoryLogRow(
            id: 'l-3',
            sessionId: 's-out',
            categoryKey: 'tecnica',
            durationSeconds: 999,
          ),
        ],
      );

      final sums = await db.sessionDao.sumCategoryDurationsInRange(
        startInclusiveMs: 1000,
        endExclusiveMs: 3000,
      );

      expect(sums['tecnica'], equals(600));
      expect(sums['improviso'], equals(400));
    });
  });
}

