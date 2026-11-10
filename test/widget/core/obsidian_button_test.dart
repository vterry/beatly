import 'package:beatly/ui/core/constants/app_colors.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/core/widgets/obsidian_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ObsidianButton (WTC-01)', () {
    testWidgets('WTC-01.01: renderiza variante primária com cor violeta e dispara callback ao clicar', (tester) async {
      var clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ObsidianTheme.darkTheme,
          home: Scaffold(
            body: ObsidianButton(
              key: const ValueKey('obsidian_button'),
              label: 'Iniciar Rotina',
              onPressed: () => clicked = true,
            ),
          ),
        ),
      );

      final buttonFinder = find.byKey(const ValueKey('obsidian_button'));
      expect(buttonFinder, findsOneWidget);

      final material = tester.widget<Material>(
        find.descendant(of: buttonFinder, matching: find.byType(Material)),
      );
      expect(material.color, equals(AppColors.violet));

      await tester.tap(buttonFinder);
      await tester.pump();
      expect(clicked, isTrue);
    });

    testWidgets('WTC-01.02: respeita estado desabilitado (onPressed == null) com opacidade reduzida', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ObsidianTheme.darkTheme,
          home: const Scaffold(
            body: ObsidianButton(
              key: ValueKey('disabled_button'),
              label: 'Desabilitado',
              onPressed: null,
            ),
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byKey(const ValueKey('disabled_button')),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, lessThan(1.0));
    });

    testWidgets('WTC-01.03: renderiza variante subtleLink discreta para ação de Cancelar rotina', (tester) async {
      var canceled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ObsidianTheme.darkTheme,
          home: Scaffold(
            body: ObsidianButton(
              key: const ValueKey('cancel_link_button'),
              label: 'Cancelar rotina',
              variant: ObsidianButtonVariant.subtleLink,
              onPressed: () => canceled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('cancel_link_button')));
      await tester.pump();
      expect(canceled, isTrue);
    });
  });
}

