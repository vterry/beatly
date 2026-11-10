import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/obsidian_card.dart';

/// Painel unificado de Divisão do Tempo (Compasso + Subdivisão de cada tempo) (RF-02).
class TimeDivisionPanel extends StatelessWidget {
  const TimeDivisionPanel({
    required this.beatsPerBar,
    required this.beatUnit,
    required this.subdivision,
    required this.onBeatsPerBarChanged,
    required this.onBeatUnitChanged,
    required this.onSubdivisionChanged,
    super.key,
  });

  final int beatsPerBar;
  final int beatUnit;
  final int subdivision;
  final ValueChanged<int> onBeatsPerBarChanged;
  final ValueChanged<int> onBeatUnitChanged;
  final ValueChanged<int> onSubdivisionChanged;

  static const List<(int, String, String)> _subdivisions = [
    (1, '♩', 'Pulso'),
    (2, '♪♪', 'Colcheias'),
    (3, '3', 'Tercina'),
    (4, '♬♬', 'Semicol.'),
  ];

  static const List<int> _denominators = [2, 4, 8, 16];

  @override
  Widget build(BuildContext context) {
    return ObsidianCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Divisão do tempo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$beatsPerBar/$beatUnit • ${subdivision}x',
                  key: const ValueKey('time_division_badge'),
                  style: const TextStyle(
                    fontFamily: AppTypography.monoFontFamily,
                    fontSize: 11,
                    color: AppColors.violetLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Compasso: Numerador (1-16) e Denominador (2/4/8/16)
          Row(
            children: [
              _SmallStepBtn(
                buttonKey: const ValueKey('beats_per_bar_minus'),
                label: '−',
                onTap: () => onBeatsPerBarChanged(beatsPerBar - 1),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$beatsPerBar',
                  key: const ValueKey('beats_per_bar_text'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.monoFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _SmallStepBtn(
                buttonKey: const ValueKey('beats_per_bar_plus'),
                label: '+',
                onTap: () => onBeatsPerBarChanged(beatsPerBar + 1),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('/', style: TextStyle(color: AppColors.textMuted)),
              ),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  children: _denominators.map((den) {
                    final selected = den == beatUnit;
                    return InkWell(
                      key: ValueKey('beat_unit_$den'),
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => onBeatUnitChanged(den),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.violet
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: selected
                                ? AppColors.violet
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '$den',
                          style: TextStyle(
                            fontFamily: AppTypography.monoFontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Subdivisão de cada tempo (4 cartões visuais)
          Row(
            children: _subdivisions.map((item) {
              final (value, icon, label) = item;
              final selected = value == subdivision;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: value < 4 ? 6 : 0),
                  child: InkWell(
                    key: ValueKey('subdivision_card_$value'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onSubdivisionChanged(value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.violet.withValues(alpha: 0.22)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? AppColors.violet : AppColors.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            icon,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SmallStepBtn extends StatelessWidget {
  const _SmallStepBtn({
    required this.buttonKey,
    required this.label,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

