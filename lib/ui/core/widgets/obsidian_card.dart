import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Card fosco com borda sutil no estilo Obsidian Dark.
class ObsidianCard extends StatelessWidget {
  const ObsidianCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.md),
    this.borderColor = AppColors.border,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

