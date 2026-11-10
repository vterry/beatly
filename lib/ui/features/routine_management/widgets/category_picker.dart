import 'package:flutter/material.dart';

import '../../../../domain/models/activity_category.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';

/// Seletor fechado e canônico com exclusivamente as 5 categorias de estudo (RF-06 / RN-06.1).
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    required this.selectedCategory,
    required this.onCategorySelected,
    super.key,
  });

  final ActivityCategory selectedCategory;
  final ValueChanged<ActivityCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('category_picker'),
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: [
        for (final category in ActivityCategory.values)
          _CategoryChip(
            key: ValueKey('category_chip_${category.name}'),
            category: category,
            isSelected: category == selectedCategory,
            onTap: () => onCategorySelected(category),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final ActivityCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppColors.forCategory(category);
    return Material(
      color: isSelected
          ? categoryColor.withValues(alpha: 0.22)
          : AppColors.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: isSelected ? categoryColor : AppColors.border,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                category.label,
                style: AppTypography.caption.copyWith(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

