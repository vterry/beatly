import 'package:flutter/material.dart';

import '../../../../domain/models/activity_category.dart';
import '../../../../domain/models/study_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/obsidian_button.dart';
import '../../../core/widgets/obsidian_card.dart';
import '../widgets/radar_chart_painter.dart';

/// Modal/Diálogo pós-rotina exibindo teia de competências da sessão e foco principal (ADR-004 / RN-09).
class SessionCompletedDialog extends StatelessWidget {
  const SessionCompletedDialog({
    required this.session,
    this.onClose,
    super.key,
  });

  final StudySession session;
  final VoidCallback? onClose;

  static Future<void> show(
    BuildContext context, {
    required StudySession session,
    VoidCallback? onClose,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SessionCompletedDialog(
        session: session,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = <ActivityCategory, int>{
      for (final cat in ActivityCategory.values) cat: 0,
    };
    for (final log in session.categoryLogs) {
      categoryTotals[log.category] =
          (categoryTotals[log.category] ?? 0) + log.durationSeconds;
    }

    final totalSeconds = session.totalDurationSeconds > 0
        ? session.totalDurationSeconds
        : categoryTotals.values.fold(0, (a, b) => a + b);

    ActivityCategory? topCat;
    var maxSeconds = 0;
    for (final cat in ActivityCategory.values) {
      final sec = categoryTotals[cat] ?? 0;
      if (sec > maxSeconds) {
        maxSeconds = sec;
        topCat = cat;
      }
    }

    final topPercentage = totalSeconds > 0 && maxSeconds > 0
        ? (maxSeconds / totalSeconds) * 100.0
        : 0.0;

    final highlightText = (topCat != null && maxSeconds > 0)
        ? 'Foco Principal: ${topCat.label} (${topPercentage.toStringAsFixed(1)}%)'
        : 'Sem atividades registradas';

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              const Text(
                'Sessão Concluída',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session.routineNameSnapshot,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.violetLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.md),

              // Gráfico Pentagonal
              PentagonRadarChart(
                key: const ValueKey('session_radar_chart'),
                categoryDurations: categoryTotals,
                height: 150,
              ),
              const SizedBox(height: AppDimensions.sm),

              // Card de Destaque
              ObsidianCard(
                key: const ValueKey('session_highlight_category'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.sm,
                ),
                borderColor: topCat != null
                    ? AppColors.violetLight.withValues(alpha: 0.5)
                    : AppColors.border,
                child: Text(
                  highlightText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.md),

              // Lista das 5 categorias
              ...ActivityCategory.values.map((cat) {
                final duration = categoryTotals[cat] ?? 0;
                final isZero = duration == 0;
                final catColor = AppColors.forCategory(cat);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isZero ? AppColors.textMuted : catColor,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Text(
                        cat.label,
                        style: TextStyle(
                          color: isZero
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          color: isZero
                              ? AppColors.textMuted
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight:
                              isZero ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: AppDimensions.lg),

              // Botão de fechar
              ObsidianButton(
                key: const ValueKey('session_dialog_btn_close'),
                label: 'Fechar',
                variant: ObsidianButtonVariant.primary,
                onPressed: () {
                  if (onClose != null) {
                    onClose!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '${m}m';
    return '${s}s';
  }
}
