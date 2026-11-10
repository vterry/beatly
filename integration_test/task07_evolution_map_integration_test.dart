import 'package:beatly/data/repositories/drift_session_repository.dart';
import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/session_category_log.dart';
import 'package:beatly/domain/models/study_session.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/evolution_map/view_models/evolution_map_view_model.dart';
import 'package:beatly/ui/features/evolution_map/views/evolution_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fakes/in_memory_app_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('TASK-07 Integration Tests: Mapa de Evolução (Analytics Local & Radar Chart)', () {
    testWidgets(
      'Persiste múltiplas sessões no Drift SQLite em meses distintos, valida renderização do Radar Chart e navegação mensal',
      (tester) async {
        final db = createInMemoryAppDatabase();
        final sessionRepo = DriftSessionRepository(database: db);

        // Salva sessão em Outubro/2026: 1200s Teoria Musical
        await sessionRepo.saveSession(
          StudySession(
            id: 'int-sess-oct',
            routineNameSnapshot: 'Harmonia Funcional',
            startedAt: DateTime.utc(2026, 10, 20, 16, 0),
            endedAt: DateTime.utc(2026, 10, 20, 16, 20),
            totalDurationSeconds: 1200,
            categoryLogs: [
              const SessionCategoryLog(
                id: 'log-oct-1',
                sessionId: 'int-sess-oct',
                category: ActivityCategory.teoriaMusical,
                durationSeconds: 1200,
              ),
            ],
          ),
        );

        // Salva sessão em Novembro/2026: 1800s Técnica e 900s Velocidade
        await sessionRepo.saveSession(
          StudySession(
            id: 'int-sess-nov',
            routineNameSnapshot: 'Rotina Mista Pesada',
            startedAt: DateTime.utc(2026, 11, 5, 9, 0),
            endedAt: DateTime.utc(2026, 11, 5, 9, 45),
            totalDurationSeconds: 2700,
            categoryLogs: [
              const SessionCategoryLog(
                id: 'log-nov-1',
                sessionId: 'int-sess-nov',
                category: ActivityCategory.tecnica,
                durationSeconds: 1800,
              ),
              const SessionCategoryLog(
                id: 'log-nov-2',
                sessionId: 'int-sess-nov',
                category: ActivityCategory.velocidade,
                durationSeconds: 900,
              ),
            ],
          ),
        );

        final viewModel = EvolutionMapViewModel(
          sessionRepository: sessionRepo,
          initialYear: 2026,
          initialMonth: 11,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ObsidianTheme.darkTheme,
            home: EvolutionMapScreen(viewModel: viewModel),
          ),
        );
        await tester.pumpAndSettle();

        // Valida visualização de Novembro/2026
        expect(
          find.byKey(const ValueKey('evolution_month_label')),
          findsOneWidget,
        );
        expect(find.text('Novembro 2026'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('session_radar_chart')),
          findsOneWidget,
        );

        // Verifica que o agregado de Novembro reflete 2700s (45m)
        expect(find.textContaining('45'), findsWidgets);

        // Navega para Outubro/2026
        await tester.tap(find.byKey(const ValueKey('btn_prev_month')));
        await tester.pumpAndSettle();

        expect(find.text('Outubro 2026'), findsOneWidget);
        expect(find.text('Novembro 2026'), findsNothing);

        // Verifica que o agregado de Outubro reflete 1200s (20m)
        expect(find.textContaining('20'), findsWidgets);

        viewModel.dispose();
        await db.close();
      },
    );
  });
}
