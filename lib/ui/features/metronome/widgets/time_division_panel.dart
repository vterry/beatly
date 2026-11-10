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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: AppColors.violetLight,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Divisão do tempo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.violetLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$beatsPerBar/$beatUnit • ${subdivision}x',
                  key: const ValueKey('time_division_badge'),
                  style: const TextStyle(
                    fontFamily: AppTypography.monoFontFamily,
                    fontSize: 12,
                    color: AppColors.violetLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Seção 1: Compasso (Numerador [−/+] e Denominador [2, 4, 8, 16])
          Row(
            children: [
              // Controles do Numerador (Tempos por Compasso)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepBtn(
                    buttonKey: const ValueKey('beats_per_bar_minus'),
                    icon: Icons.remove_rounded,
                    tooltip: 'Diminuir compasso',
                    onTap: () => onBeatsPerBarChanged(beatsPerBar - 1),
                  ),
                  Container(
                    width: 44,
                    height: 38,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppColors.elevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '$beatsPerBar',
                      key: const ValueKey('beats_per_bar_text'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppTypography.monoFontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _StepBtn(
                    buttonKey: const ValueKey('beats_per_bar_plus'),
                    icon: Icons.add_rounded,
                    tooltip: 'Aumentar compasso',
                    onTap: () => onBeatsPerBarChanged(beatsPerBar + 1),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '/',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              // Denominadores
              Expanded(
                child: Row(
                  children: _denominators.map((den) {
                    final selected = den == beatUnit;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: InkWell(
                          key: ValueKey('beat_unit_$den'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => onBeatUnitChanged(den),
                          child: Container(
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.violet
                                  : AppColors.elevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected
                                    ? AppColors.violetLight
                                    : AppColors.border,
                                width: selected ? 1.6 : 1.0,
                              ),
                            ),
                            child: Text(
                              '$den',
                              style: TextStyle(
                                fontFamily: AppTypography.monoFontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Seção 2: Subdivisões de tempo
          Row(
            children: _subdivisions.map((item) {
              final (value, icon, label) = item;
              final selected = value == subdivision;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    key: ValueKey('subdivision_card_$value'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onSubdivisionChanged(value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.violet.withValues(alpha: 0.24)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.violetLight : AppColors.border,
                          width: selected ? 1.6 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            icon,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? AppColors.violetLight
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final Key buttonKey;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: buttonKey,
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.elevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
