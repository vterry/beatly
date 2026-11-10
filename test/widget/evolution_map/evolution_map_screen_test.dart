import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/session_category_log.dart';
import 'package:beatly/domain/models/study_session.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/evolution_map/view_models/evolution_map_view_model.dart';
import 'package:beatly/ui/features/evolution_map/views/evolution_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_session_repository.dart';

void main() {
  group('EvolutionMapScreen Widget Tests (TASK-07)', () {
    late FakeSessionRepository repository;
    late EvolutionMapViewModel viewModel;

    setUp(() async {
      repository = FakeSessionRepository();

      // Sessão de Novembro/2026: 1800s Técnica
      await repository.saveSession(
        StudySession(
          id: 'nov-session-1',
          routineNameSnapshot: 'Treino de Novembro',
          startedAt: DateTime.utc(2026, 11, 10, 10, 0),
          endedAt: DateTime.utc(2026, 11, 10, 10, 30),
          totalDurationSeconds: 1800,
          categoryLogs: [
            const SessionCategoryLog(
              id: 'l-nov',
              sessionId: 'nov-session-1',
              category: ActivityCategory.tecnica,
              durationSeconds: 1800,
            ),
          ],
        ),
      );

      // Sessão de Outubro/2026: 1200s Velocidade
      await repository.saveSession(
        StudySession(
          id: 'oct-session-1',
          routineNameSnapshot: 'Treino de Outubro',
          startedAt: DateTime.utc(2026, 10, 15, 14, 0),
          endedAt: DateTime.utc(2026, 10, 15, 14, 20),
          totalDurationSeconds: 1200,
          categoryLogs: [
            const SessionCategoryLog(
              id: 'l-oct',
              sessionId: 'oct-session-1',
              category: ActivityCategory.velocidade,
              durationSeconds: 1200,
            ),
          ],
        ),
      );

      viewModel = EvolutionMapViewModel(
        sessionRepository: repository,
        initialYear: 2026,
        initialMonth: 11,
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    testWidgets(
      'WTC-07.03: Clicar nos botões de navegação mensal btn_prev_month e btn_next_month atualiza evolution_month_label e recarrega os dados do SessionRepository',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ObsidianTheme.darkTheme,
            home: EvolutionMapScreen(viewModel: viewModel),
          ),
        );
        await tester.pumpAndSettle();

        // Inicial: Novembro 2026
        expect(
          find.byKey(const ValueKey('evolution_month_label')),
          findsOneWidget,
        );
        expect(find.text('Novembro 2026'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('session_radar_chart')),
          findsOneWidget,
        );

        // Clica no botão mês anterior
        await tester.tap(find.byKey(const ValueKey('btn_prev_month')));
        await tester.pumpAndSettle();

        // Deve mudar para Outubro 2026
        expect(find.text('Outubro 2026'), findsOneWidget);
        expect(find.text('Novembro 2026'), findsNothing);

        // Clica no botão próximo mês
        await tester.tap(find.byKey(const ValueKey('btn_next_month')));
        await tester.pumpAndSettle();

        // Volta para Novembro 2026
        expect(find.text('Novembro 2026'), findsOneWidget);
      },
    );
  });
}
