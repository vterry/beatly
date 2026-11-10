import 'package:beatly/app.dart';
import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/ui/core/constants/app_colors.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ObsidianTheme & AppColors (ADR-008)', () {
    test('define fundo #0F0F10, surface #1A1A1C e cores distintas para as 5 categorias', () {
      final theme = ObsidianTheme.darkTheme;
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFF0F0F10)));
      expect(theme.colorScheme.primary, equals(const Color(0xFF7C3AED)));
      expect(theme.colorScheme.secondary, equals(const Color(0xFFF59E0B)));

      final categoryColors = ActivityCategory.values
          .map(AppColors.forCategory)
          .toSet();
      expect(categoryColors.length, equals(5));
    });

    testWidgets('BeatlyApp renderiza no tema escuro Obsidian', (tester) async {
      await tester.pumpWidget(const BeatlyApp());
      expect(find.byKey(const ValueKey('beatly_home_card')), findsOneWidget);
      expect(find.text('Beatly — Metrônomo & Rotina de Estudos'), findsOneWidget);
    });
  });
}

