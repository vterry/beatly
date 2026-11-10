import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/obsidian_button.dart';

/// Barra de controles de transporte, conclusão e cancelamento da rotina (RF-06).
class ExecutionControlsBar extends StatelessWidget {
  const ExecutionControlsBar({
    required this.isPaused,
    required this.onPauseResume,
    required this.onPrevious,
    required this.onSkipNext,
    required this.onComplete,
    required this.onCancel,
    this.canGoPrevious = true,
    this.canGoNext = true,
    super.key,
  });

  final bool isPaused;
  final VoidCallback onPauseResume;
  final VoidCallback onPrevious;
  final VoidCallback onSkipNext;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final bool canGoPrevious;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Linha principal de transporte (Anterior, Pausar/Retomar, Pular)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const ValueKey('execution_btn_previous'),
              icon: const Icon(Icons.skip_previous_rounded, size: 32),
              color: canGoPrevious ? AppColors.textPrimary : AppColors.textMuted,
              onPressed: canGoPrevious ? onPrevious : null,
              tooltip: 'Atividade anterior',
            ),
            const SizedBox(width: AppDimensions.lg),
            InkResponse(
              key: const ValueKey('execution_btn_pause_resume'),
              onTap: onPauseResume,
              radius: 36,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPaused ? AppColors.violet : AppColors.elevated,
                  border: Border.all(
                    color: isPaused ? AppColors.violetLight : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: isPaused ? Colors.white : AppColors.textPrimary,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.lg),
            IconButton(
              key: const ValueKey('execution_btn_skip_next'),
              icon: const Icon(Icons.skip_next_rounded, size: 32),
              color: canGoNext ? AppColors.textPrimary : AppColors.textMuted,
              onPressed: canGoNext ? onSkipNext : null,
              tooltip: 'Próxima atividade',
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.lg),
        // Botão explícito de destaque "Concluir"
        ObsidianButton(
          key: const ValueKey('execution_btn_complete'),
          label: 'Concluir',
          icon: Icons.check_circle_outline_rounded,
          variant: ObsidianButtonVariant.primary,
          onPressed: onComplete,
        ),
        const SizedBox(height: AppDimensions.sm),
        // Ação discreta e secundária "Cancelar treino"
        ObsidianButton(
          key: const ValueKey('execution_btn_cancel'),
          label: 'Cancelar treino',
          variant: ObsidianButtonVariant.subtleLink,
          onPressed: onCancel,
        ),
      ],
    );
  }
}
