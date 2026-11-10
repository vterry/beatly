import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/routine_management/widgets/category_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryPicker Widget Tests (TASK-05)', () {
    testWidgets(
      'renderiza exclusivamente as 5 categorias canônicas e notifica seleção',
      (tester) async {
        ActivityCategory selected = ActivityCategory.tecnica;

        await tester.pumpWidget(
          MaterialApp(
            theme: ObsidianTheme.darkTheme,
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: CategoryPicker(
                    selectedCategory: selected,
                    onCategorySelected: (cat) => setState(() => selected = cat),
                  ),
                );
              },
            ),
          ),
        );

        expect(find.byKey(const ValueKey('category_picker')), findsOneWidget);
        expect(find.text('Técnica'), findsOneWidget);
        expect(find.text('Velocidade'), findsOneWidget);
        expect(find.text('Teoria Musical'), findsOneWidget);
        expect(find.text('Improviso'), findsOneWidget);
        expect(find.text('Free Style'), findsOneWidget);

        await tester.tap(find.text('Improviso'));
        await tester.pump();

        expect(selected, equals(ActivityCategory.improviso));
      },
    );
  });
}

