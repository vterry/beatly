import 'package:beatly/data/repositories/drift_routine_repository.dart';
import 'package:beatly/data/repositories/drift_session_repository.dart';
import 'package:beatly/data/repositories/drift_settings_repository.dart';
import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/routine.dart';
import 'package:beatly/domain/models/routine_activity.dart';
import 'package:beatly/domain/models/session_category_log.dart';
import 'package:beatly/domain/models/study_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fakes/in_memory_app_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ITC-02.01: Fluxo integrado de persistência SQLite (Rotinas, Sessões e Configurações)', (tester) async {
    final db = createInMemoryAppDatabase();
    addTearDown(db.close);

    final routineRepo = DriftRoutineRepository(database: db);
    final sessionRepo = DriftSessionRepository(database: db);
    final settingsRepo = DriftSettingsRepository(database: db);

    // 1. Verifica contador de transição default = 5s
    expect(await settingsRepo.getTransitionCountdownSeconds(), equals(5));

    // 2. Cria rotina e salva
    final now = DateTime.utc(2026, 11, 8, 15);
    await routineRepo.saveRoutine(
      Routine(
        id: 'r-int-1',
        name: 'Rotina Integração',
        createdAt: now,
        updatedAt: now,
        activities: [
          RoutineActivity(
            id: 'a-int-1',
            routineId: 'r-int-1',
            name: 'Escala Menor Harmônica',
            category: ActivityCategory.tecnica,
            durationSeconds: 600,
            bpm: 120,
            autoStartMetronome: true,
            orderIndex: 0,
          ),
        ],
      ),
    );

    // 3. Registra sessão vinculada
    await sessionRepo.saveSession(
      StudySession(
        id: 's-int-1',
        routineId: 'r-int-1',
        routineNameSnapshot: 'Rotina Integração',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 10)),
        totalDurationSeconds: 600,
        categoryLogs: const [
          SessionCategoryLog(
            id: 'log-int-1',
            sessionId: 's-int-1',
            category: ActivityCategory.tecnica,
            durationSeconds: 600,
          ),
        ],
      ),
    );

    // 4. Consulta agregação mensal
    final monthly = await sessionRepo.getCategoryAggregatesByMonth(
      year: 2026,
      month: 11,
    );
    expect(monthly[ActivityCategory.tecnica], equals(600));
  });
}

