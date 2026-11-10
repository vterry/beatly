import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

enum ObsidianButtonVariant { primary, secondary, danger, subtleLink }

/// Botão padronizado do Design System Obsidian Dark.
class ObsidianButton extends StatelessWidget {
  const ObsidianButton({
    required this.label,
    required this.onPressed,
    this.variant = ObsidianButtonVariant.primary,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final ObsidianButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (variant == ObsidianButtonVariant.subtleLink) {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textMuted,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.xs,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }

    final (bgColor, fgColor, borderColor) = switch (variant) {
      ObsidianButtonVariant.primary => (
        AppColors.violet,
        Colors.white,
        AppColors.violet,
      ),
      ObsidianButtonVariant.secondary => (
        AppColors.elevated,
        AppColors.textPrimary,
        AppColors.border,
      ),
      ObsidianButtonVariant.danger => (
        AppColors.error,
        Colors.white,
        AppColors.error,
      ),
      ObsidianButtonVariant.subtleLink => (
        Colors.transparent,
        AppColors.textMuted,
        Colors.transparent,
      ),
    };

    return Opacity(
      opacity: onPressed == null ? 0.45 : 1.0,
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fgColor),
                  const SizedBox(width: AppDimensions.sm),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

