import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/evolution_map/widgets/radar_chart_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PentagonRadarChart Widget Tests (TASK-07)', () {
    testWidgets(
      'Renderiza CustomPaint com RadarChartPainter para categorias zeradas',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PentagonRadarChart(
                categoryDurations: <ActivityCategory, int>{},
                height: 200,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PentagonRadarChart), findsOneWidget);
        final customPaintFinder = find.descendant(
          of: find.byType(PentagonRadarChart),
          matching: find.byType(CustomPaint),
        );
        expect(customPaintFinder, findsOneWidget);

        final customPaint = tester.widget<CustomPaint>(customPaintFinder);
        expect(customPaint.painter, isA<RadarChartPainter>());
        final painter = customPaint.painter as RadarChartPainter;
        expect(painter.data.axes.length, equals(5));
        expect(painter.data.gridRings.length, equals(4));
        expect(painter.data.maxDurationSeconds, equals(0));
      },
    );

    testWidgets(
      'Renderiza com valores de categorias preenchidos e repassa geometria corretamente',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ObsidianTheme.darkTheme,
            home: const Scaffold(
              body: PentagonRadarChart(
                categoryDurations: <ActivityCategory, int>{
                  ActivityCategory.tecnica: 1200,
                  ActivityCategory.velocidade: 900,
                  ActivityCategory.teoriaMusical: 600,
                  ActivityCategory.improviso: 300,
                  ActivityCategory.freeStyle: 150,
                },
                height: 250,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PentagonRadarChart), findsOneWidget);
        final customPaintFinder = find.descendant(
          of: find.byType(PentagonRadarChart),
          matching: find.byType(CustomPaint),
        );
        expect(customPaintFinder, findsOneWidget);

        final customPaint = tester.widget<CustomPaint>(customPaintFinder);
        final painter = customPaint.painter as RadarChartPainter;
        expect(painter.data.maxDurationSeconds, equals(1200));
        expect(painter.data.axes.length, equals(5));
      },
    );
  });
}
