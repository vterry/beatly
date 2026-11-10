import 'package:flutter/material.dart';

import '../../../domain/models/beat_emphasis.dart';
import '../constants/app_colors.dart';

/// LED visual sincronizado com cada pulso do compasso (RN-03.2).
class PulseLedIndicator extends StatelessWidget {
  const PulseLedIndicator({
    required this.emphasis,
    required this.isActive,
    super.key,
  });

  final BeatEmphasis emphasis;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final baseColor = switch (emphasis) {
      BeatEmphasis.forte => AppColors.amber,
      BeatEmphasis.normal => AppColors.violet,
      BeatEmphasis.fraco => AppColors.violetLight.withValues(alpha: 0.55),
      BeatEmphasis.mudo => AppColors.border,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? baseColor : baseColor.withValues(alpha: 0.35),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.7),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
