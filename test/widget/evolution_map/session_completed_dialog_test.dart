import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/session_category_log.dart';
import 'package:beatly/domain/models/study_session.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/evolution_map/views/session_completed_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionCompletedDialog Widget Tests (TASK-07)', () {
    testWidgets(
      'WTC-07.01: Com Técnica 1200s, Velocidade 900s, Teoria 600s (total 2700s, Técnica 44.4%), renderiza session_radar_chart e destaque "Foco Principal: Técnica (44.4%)"',
      (tester) async {
        final session = StudySession(
          id: 'test-session-1',
          routineNameSnapshot: 'Treino de Velocidade e Técnica',
          startedAt: DateTime.utc(2026, 11, 8, 14, 0),
          endedAt: DateTime.utc(2026, 11, 8, 14, 45),
          totalDurationSeconds: 2700,
          categoryLogs: [
            const SessionCategoryLog(
              id: 'log-1',
              sessionId: 'test-session-1',
              category: ActivityCategory.tecnica,
              durationSeconds: 1200,
            ),
            const SessionCategoryLog(
              id: 'log-2',
              sessionId: 'test-session-1',
              category: ActivityCategory.velocidade,
              durationSeconds: 900,
            ),
            const SessionCategoryLog(
              id: 'log-3',
              sessionId: 'test-session-1',
              category: ActivityCategory.teoriaMusical,
              durationSeconds: 600,
            ),
            const SessionCategoryLog(
              id: 'log-4',
              sessionId: 'test-session-1',
              category: ActivityCategory.improviso,
              durationSeconds: 0,
            ),
            const SessionCategoryLog(
              id: 'log-5',
              sessionId: 'test-session-1',
              category: ActivityCategory.freeStyle,
              durationSeconds: 0,
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ObsidianTheme.darkTheme,
            home: Scaffold(
              body: SessionCompletedDialog(session: session),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('session_radar_chart')), findsOneWidget);
        expect(find.byKey(const ValueKey('session_highlight_category')), findsOneWidget);
        expect(
          find.textContaining('Foco Principal: Técnica (44.4%)'),
          findsOneWidget,
        );
        expect(find.text('Sessão Concluída'), findsOneWidget);
        expect(find.text('Treino de Velocidade e Técnica'), findsOneWidget);
      },
    );

    testWidgets(
      'WTC-07.02: Tocar no botão session_dialog_btn_close fecha o diálogo',
      (tester) async {
        var closed = false;
        final session = StudySession(
          id: 'test-session-2',
          routineNameSnapshot: 'Rotina Rápida',
          startedAt: DateTime.utc(2026, 11, 8, 15, 0),
          endedAt: DateTime.utc(2026, 11, 8, 15, 10),
          totalDurationSeconds: 600,
          categoryLogs: const [],
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ObsidianTheme.darkTheme,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => SessionCompletedDialog(
                      session: session,
                      onClose: () {
                        closed = true;
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        final closeBtn = find.byKey(const ValueKey('session_dialog_btn_close'));
        expect(closeBtn, findsOneWidget);
        await tester.ensureVisible(closeBtn);
        await tester.pumpAndSettle();

        await tester.tap(closeBtn);
        await tester.pumpAndSettle();

        expect(closed, isTrue);
        expect(find.byKey(const ValueKey('session_dialog_btn_close')), findsNothing);
      },
    );
  });
}
