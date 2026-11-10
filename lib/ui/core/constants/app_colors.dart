import 'package:flutter/material.dart';

import '../../../domain/models/activity_category.dart';

/// Paleta de cores minimalista inspirada no tema escuro do Obsidian (ADR-008 / RNF-04).
abstract final class AppColors {
  static const Color background = Color(0xFF0F0F10);
  static const Color surface = Color(0xFF1A1A1C);
  static const Color elevated = Color(0xFF242426);
  static const Color border = Color(0xFF2E2E32);

  static const Color textPrimary = Color(0xFFEDEDEF);
  static const Color textSecondary = Color(0xFF9E9EA9);
  static const Color textMuted = Color(0xFF71717A);

  static const Color violet = Color(0xFF7C3AED);
  static const Color violetLight = Color(0xFFA78BFA);
  static const Color amber = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  /// Cores semânticas fixas para as 5 categorias canônicas de estudo.
  static Color forCategory(ActivityCategory category) => switch (category) {
    ActivityCategory.tecnica => const Color(0xFF8B5CF6),
    ActivityCategory.velocidade => const Color(0xFFF59E0B),
    ActivityCategory.teoriaMusical => const Color(0xFF3B82F6),
    ActivityCategory.improviso => const Color(0xFF10B981),
    ActivityCategory.freeStyle => const Color(0xFFEC4899),
  };
}

