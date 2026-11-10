import 'package:beatly/data/datasources/local/app_database.dart';
import 'package:beatly/data/repositories/drift_routine_repository.dart';
import 'package:beatly/data/repositories/drift_session_repository.dart';
import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/routine.dart';
import 'package:beatly/domain/models/routine_activity.dart';
import 'package:beatly/domain/models/session_category_log.dart';
import 'package:beatly/domain/models/study_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_app_database.dart';

void main() {
  group('DriftSessionRepository (ADR-004 / RF-09 / RF-10)', () {
    late AppDatabase db;
    late DriftRoutineRepository routineRepository;
    late DriftSessionRepository sessionRepository;

    setUp(() {
      db = createInMemoryAppDatabase();
      routineRepository = DriftRoutineRepository(database: db);
      sessionRepository = DriftSessionRepository(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('TC-02.05: salva sessão com 3 logs de categorias diferentes de forma atômica', () async {
      final session = StudySession(
        id: 'session-1',
        routineNameSnapshot: 'Treino Fusion',
        startedAt: DateTime.utc(2026, 11, 8, 14),
        endedAt: DateTime.utc(2026, 11, 8, 14, 45),
        totalDurationSeconds: 2700,
        categoryLogs: const [
          SessionCategoryLog(
            id: 'log-1',
            sessionId: 'session-1',
            category: ActivityCategory.tecnica,
            durationSeconds: 1200,
          ),
          SessionCategoryLog(
            id: 'log-2',
            sessionId: 'session-1',
            category: ActivityCategory.velocidade,
            durationSeconds: 900,
          ),
          SessionCategoryLog(
            id: 'log-3',
            sessionId: 'session-1',
            category: ActivityCategory.teoriaMusical,
            durationSeconds: 600,
          ),
        ],
      );

      await sessionRepository.saveSession(session);

      final novemberSessions = await sessionRepository.getSessionsByMonth(
        year: 2026,
        month: 11,
      );
      expect(novemberSessions.length, equals(1));
      expect(novemberSessions.first.categoryLogs.length, equals(3));
    });

    test('TC-02.06: getCategoryAggregatesByMonth consolida segundos por categoria no mês (B-RF-10.1)', () async {
      for (var i = 1; i <= 3; i++) {
        await sessionRepository.saveSession(
          StudySession(
            id: 'session-$i',
            routineNameSnapshot: 'Prática de Improviso',
            startedAt: DateTime.utc(2026, 11, i, 18),
            endedAt: DateTime.utc(2026, 11, i, 18, 30),
            totalDurationSeconds: 1800,
            categoryLogs: [
              SessionCategoryLog(
                id: 'log-$i',
                sessionId: 'session-$i',
                category: ActivityCategory.improviso,
                durationSeconds: 1800,
              ),
            ],
          ),
        );
      }

      final aggregates = await sessionRepository.getCategoryAggregatesByMonth(
        year: 2026,
        month: 11,
      );

      expect(aggregates[ActivityCategory.improviso], equals(5400)); // 90 min
      expect(aggregates[ActivityCategory.tecnica], equals(0));
      expect(aggregates[ActivityCategory.velocidade], equals(0));
      expect(aggregates[ActivityCategory.teoriaMusical], equals(0));
      expect(aggregates[ActivityCategory.freeStyle], equals(0));
    });

    test('TC-02.07: ao excluir rotina original, preserva study_sessions com routineId == null e snapshot intacto', () async {
      final now = DateTime.utc(2026, 11, 8, 9);
      final routine = Routine(
        id: 'routine-temp',
        name: 'Rotina Temporária',
        createdAt: now,
        updatedAt: now,
        activities: [
          RoutineActivity(
            id: 'act-temp',
            routineId: 'routine-temp',
            name: 'Free Jam',
            category: ActivityCategory.freeStyle,
            durationSeconds: 600,
            orderIndex: 0,
          ),
        ],
      );
      await routineRepository.saveRoutine(routine);

      await sessionRepository.saveSession(
        StudySession(
          id: 'session-linked',
          routineId: 'routine-temp',
          routineNameSnapshot: 'Rotina Temporária',
          startedAt: now,
          endedAt: now.add(const Duration(minutes: 10)),
          totalDurationSeconds: 600,
          categoryLogs: const [
            SessionCategoryLog(
              id: 'log-linked',
              sessionId: 'session-linked',
              category: ActivityCategory.freeStyle,
              durationSeconds: 600,
            ),
          ],
        ),
      );

      await routineRepository.deleteRoutine('routine-temp');

      final sessions = await sessionRepository.getSessionsByMonth(
        year: 2026,
        month: 11,
      );
      expect(sessions.length, equals(1));
      expect(sessions.first.routineId, isNull);
      expect(sessions.first.routineNameSnapshot, equals('Rotina Temporária'));
    });
  });
}

