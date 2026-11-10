import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/obsidian_card.dart';

/// Grade compacta do calendário mensal com destaque visual para dias ativos (ADR-004 / RN-06).
class MonthlyConsistencyCalendar extends StatelessWidget {
  const MonthlyConsistencyCalendar({
    required this.year,
    required this.month,
    required this.activeDaysOfMonth,
    super.key,
  });

  final int year;
  final int month;
  final Set<int> activeDaysOfMonth;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // DateTime.weekday: 1 = Seg, ..., 7 = Dom. Alinhamos para Dom = 0, Seg = 1, etc.
    final firstWeekday = DateTime(year, month, 1).weekday % 7;

    const weekdayLabels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    return ObsidianCard(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Consistência Mensal',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${activeDaysOfMonth.length} dias ativos',
                style: AppTypography.caption.copyWith(
                  color: AppColors.violetLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          // Cabeçalho dos dias da semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdayLabels.map((label) {
              return SizedBox(
                width: 28,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          // Grade dos dias
          _buildDaysGrid(firstWeekday, daysInMonth),
        ],
      ),
    );
  }

  Widget _buildDaysGrid(int firstWeekday, int daysInMonth) {
    final totalCells = firstWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rowCount, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - firstWeekday + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox(width: 28, height: 28);
              }

              final isActive = activeDaysOfMonth.contains(dayNumber);

              return Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.violet : AppColors.elevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive ? AppColors.violetLight : AppColors.border,
                    width: isActive ? 1.5 : 0.8,
                  ),
                ),
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
