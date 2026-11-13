import 'package:flutter/material.dart';

import '../../../../domain/models/beat_emphasis.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/obsidian_card.dart';
import '../../../core/widgets/pulse_led_indicator.dart';

/// Painel interativo de Pulsos e Volume por batida (RF-03).
class BeatStripSelector extends StatelessWidget {
  const BeatStripSelector({
    required this.beatPattern,
    required this.subdivision,
    required this.activeBeatIndex,
    required this.onBeatTapped,
    required this.onResetDefault,
    required this.onMuteAll,
    super.key,
  });

  final List<BeatEmphasis> beatPattern;
  final int subdivision;
  final int activeBeatIndex;
  final ValueChanged<int> onBeatTapped;
  final VoidCallback onResetDefault;
  final VoidCallback onMuteAll;

  @override
  Widget build(BuildContext context) {
    return ObsidianCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    size: 16,
                    color: AppColors.violetLight,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Pulsos e volume',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _QuickPresetChip(
                    chipKey: const ValueKey('beat_preset_default'),
                    label: 'Padrão',
                    onTap: onResetDefault,
                  ),
                  const SizedBox(width: 6),
                  _QuickPresetChip(
                    chipKey: const ValueKey('beat_preset_mute'),
                    label: 'Mudo',
                    onTap: onMuteAll,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Fita linear horizontal de pulsos centralizada (não quebra em linhas confusas)
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(beatPattern.length, (index) {
                final emphasis = beatPattern[index];
                final isActive = index == activeBeatIndex;
                final isStrongBeat = index == 0;
                final (barHeight, barColor) = switch (emphasis) {
                  BeatEmphasis.forte => (36.0, AppColors.amber),
                  BeatEmphasis.normal => (24.0, AppColors.violet),
                  BeatEmphasis.fraco => (
                    14.0,
                    AppColors.violetLight.withValues(alpha: 0.45),
                  ),
                  BeatEmphasis.mudo => (4.0, AppColors.border),
                };

                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 3,
                    right: index == beatPattern.length - 1 ? 0 : 3,
                  ),
                  child: InkWell(
                    key: ValueKey('beat_emphasis_item_$index'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onBeatTapped(index),
                    child: Container(
                      width: 48,
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isStrongBeat && !isActive
                            ? AppColors.amber.withValues(alpha: 0.05)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? AppColors.violetLight
                              : (isStrongBeat
                                  ? AppColors.amber.withValues(alpha: 0.5)
                                  : AppColors.border),
                          width: isActive ? 2.0 : (isStrongBeat ? 1.5 : 1.0),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PulseLedIndicator(
                            emphasis: emphasis,
                            isActive: isActive,
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 38,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 22,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          if (subdivision > 1) ...[
                            const SizedBox(height: 3),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List<Widget>.generate(
                                subdivision - 1,
                                (_) => Container(
                                  width: 4,
                                  height: 4,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: emphasis == BeatEmphasis.mudo
                                        ? AppColors.border
                                        : AppColors.violetLight,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 3),
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontFamily: AppTypography.monoFontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isStrongBeat
                                  ? AppColors.amber
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            emphasis.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isStrongBeat
                                  ? AppColors.amber.withValues(alpha: 0.8)
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _QuickPresetChip extends StatelessWidget {
  const _QuickPresetChip({
    required this.chipKey,
    required this.label,
    required this.onTap,
  });

  final Key chipKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: chipKey,
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.violetLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
