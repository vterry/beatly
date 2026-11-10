import 'package:flutter/material.dart';

import '../../../../domain/models/routine_activity.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/obsidian_button.dart';

/// Overlay exibido durante o intervalo de transição suave entre duas atividades (RF-06).
class TransitionCountdownOverlay extends StatelessWidget {
  const TransitionCountdownOverlay({
    required this.nextActivity,
    required this.nextActivityIndex,
    required this.totalActivities,
    required this.remainingSeconds,
    required this.onSkipNow,
    super.key,
  });

  final RoutineActivity nextActivity;
  final int nextActivityIndex;
  final int totalActivities;
  final int remainingSeconds;
  final VoidCallback onSkipNow;

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppColors.forCategory(nextActivity.category);

    return Container(
      key: const ValueKey('execution_transition_overlay'),
      color: AppColors.background,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Transição Suave',
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
            style: AppTypography.timerDisplay.copyWith(color: AppColors.violetLight),
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
              nextActivity.category.label,
              style: TextStyle(
                color: categoryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            nextActivity.name,
            textAlign: TextAlign.center,
            style: AppTypography.heading.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            'Próxima: Atividade ${nextActivityIndex + 1} de $totalActivities',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppDimensions.xl),
          ObsidianButton(
            key: const ValueKey('transition_btn_skip_now'),
            label: 'Iniciar Agora',
            variant: ObsidianButtonVariant.primary,
            icon: Icons.play_arrow_rounded,
            onPressed: onSkipNow,
          ),
        ],
      ),
    );
  }
}
