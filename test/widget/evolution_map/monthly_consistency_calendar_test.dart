import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/evolution_map/widgets/monthly_consistency_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthlyConsistencyCalendar Widget Tests (TASK-07)', () {
    testWidgets(
      'Renderiza grade mensal, cabeçalho de dias ativos e destaca dias praticados',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ObsidianTheme.darkTheme,
            home: const Scaffold(
              body: MonthlyConsistencyCalendar(
                year: 2026,
                month: 11,
                activeDaysOfMonth: <int>{4, 12, 25},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Consistência Mensal'), findsOneWidget);
        expect(find.text('3 dias ativos'), findsOneWidget);

        // Verifica os cabeçalhos de dias da semana
        expect(find.text('D'), findsWidgets);
        expect(find.text('S'), findsWidgets);
        expect(find.text('T'), findsWidgets);
        expect(find.text('Q'), findsWidgets);

        // Verifica dias do mês
        expect(find.text('4'), findsOneWidget);
        expect(find.text('12'), findsOneWidget);
        expect(find.text('25'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
        // Novembro tem 30 dias, dia 31 não deve existir
        expect(find.text('31'), findsNothing);
      },
    );
  });
}
