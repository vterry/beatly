import 'package:flutter/material.dart';

import '../../../../domain/models/routine_activity.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/obsidian_card.dart';

/// Card de atividade de estudo dentro do editor de rotina com suporte a reordenação (RF-06).
class ActivityListTile extends StatelessWidget {
  const ActivityListTile({
    required this.activity,
    required this.index,
    required this.onDelete,
    this.onEdit,
    this.isEditing = false,
    super.key,
  });

  final RoutineActivity activity;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final bool isEditing;

  static String formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (secs == 0) return '${mins}m';
    if (mins == 0) return '${secs}s';
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppColors.forCategory(activity.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: ObsidianCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          borderColor:
              isEditing ? AppColors.violetLight : AppColors.border,
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
              ),
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isEditing
                            ? AppColors.violetLight
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          activity.category.label,
                          style: AppTypography.caption.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '• ${formatDuration(activity.durationSeconds)}',
                          style: AppTypography.caption,
                        ),
                        if (activity.bpm != null)
                          Text(
                            '• ${activity.bpm} BPM${activity.autoStartMetronome ? ' (Auto)' : ''}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.violetLight,
                            ),
                          ),
                      ],
                    ),
                    if (activity.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.sticky_note_2_rounded,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              activity.notes.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  key: ValueKey('activity_edit_${activity.id}'),
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.violetLight,
                    size: 20,
                  ),
                  tooltip: 'Editar atividade',
                ),
              IconButton(
                key: ValueKey('activity_delete_${activity.id}'),
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                tooltip: 'Remover atividade',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

