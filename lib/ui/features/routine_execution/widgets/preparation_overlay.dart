import 'package:flutter/material.dart';

import '../../../../domain/models/routine_activity.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/obsidian_button.dart';

/// Overlay de contagem regressiva de preparação inicial antes de iniciar o treino (RF-06).
class PreparationOverlay extends StatelessWidget {
  const PreparationOverlay({
    required this.remainingSeconds,
    required this.firstActivity,
    required this.totalActivities,
    required this.onSkipNow,
    super.key,
  });

  final int remainingSeconds;
  final RoutineActivity firstActivity;
  final int totalActivities;
  final VoidCallback onSkipNow;

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppColors.forCategory(firstActivity.category);

    return Container(
      key: const ValueKey('execution_prep_overlay'),
      color: AppColors.background,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Preparar',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            _formatTimer(remainingSeconds),
            style: AppTypography.timerDisplay.copyWith(color: AppColors.amber),
          ),
          const SizedBox(height: AppDimensions.lg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              border: Border.all(color: categoryColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              firstActivity.category.label,
              style: TextStyle(
                color: categoryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            firstActivity.name,
            textAlign: TextAlign.center,
            style: AppTypography.heading.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            'Atividade 1 de $totalActivities',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppDimensions.xl),
          ObsidianButton(
            key: const ValueKey('prep_btn_skip_now'),
            label: 'Iniciar Agora',
            variant: ObsidianButtonVariant.secondary,
            icon: Icons.play_arrow_rounded,
            onPressed: onSkipNow,
          ),
        ],
      ),
    );
  }
}
