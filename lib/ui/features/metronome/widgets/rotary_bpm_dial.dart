import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/obsidian_card.dart';

/// Roda Giratória Central (Rotary Jog Wheel / Dial) com 4 botões nos cantos (RN-01.2).
///
/// Projetada conforme a referência visual validada pelo Piloto:
/// - Topo central: Andamento italiano (ex: Allegro), número de BPM em destaque e arco superior.
/// - Centro: Roda giratória interativa que responde ao arraste circular.
/// - 4 Cantos: Decremento (`|◀`), Incremento (`▶|`), Play/Pause (`▶`/`⏸`) e `TAP`.
class RotaryBpmDial extends StatefulWidget {
  const RotaryBpmDial({
    required this.bpm,
    required this.tempoMarking,
    required this.timeSignatureLabel,
    required this.isPlaying,
    required this.onBpmChanged,
    required this.onStepBpm,
    required this.onTogglePlay,
    required this.onTapTempo,
    super.key,
  });

  final int bpm;
  final String tempoMarking;
  final String timeSignatureLabel;
  final bool isPlaying;
  final ValueChanged<int> onBpmChanged;
  final ValueChanged<int> onStepBpm;
  final VoidCallback onTogglePlay;
  final VoidCallback onTapTempo;

  @override
  State<RotaryBpmDial> createState() => _RotaryBpmDialState();
}

class _RotaryBpmDialState extends State<RotaryBpmDial> {
  double? _lastAngle;
  double _accumulatedDelta = 0.0;
  double _currentMarkerAngle = 0.0;
  bool _isDragging = false;

  void _handlePanStart(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angle = math.atan2(
      localPosition.dy - center.dy,
      localPosition.dx - center.dx,
    );
    setState(() {
      _isDragging = true;
      _lastAngle = angle;
      _accumulatedDelta = 0.0;
      _currentMarkerAngle = angle + (math.pi / 2);
    });
  }

  void _handlePanUpdate(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angle = math.atan2(
      localPosition.dy - center.dy,
      localPosition.dx - center.dx,
    );

    setState(() {
      _currentMarkerAngle = angle + (math.pi / 2);
    });

    if (_lastAngle != null) {
      var delta = angle - _lastAngle!;
      if (delta > math.pi) delta -= 2 * math.pi;
      if (delta < -math.pi) delta += 2 * math.pi;

      _accumulatedDelta += delta;

      // Cada ~4.5 graus (0.08 radianos) de giro contínuo altera 1 BPM
      const radiansPerBpm = 0.08;
      final steps = (_accumulatedDelta / radiansPerBpm).truncate();
      if (steps != 0) {
        final nextBpm = (widget.bpm + steps).clamp(20, 300);
        if (nextBpm != widget.bpm) {
          widget.onBpmChanged(nextBpm);
        }
        _accumulatedDelta -= steps * radiansPerBpm;
      }
      _lastAngle = angle;
    } else {
      _lastAngle = angle;
    }
  }

  void _handlePanEnd() {
    setState(() {
      _isDragging = false;
      _lastAngle = null;
      _accumulatedDelta = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultWheelAngle = ((widget.bpm - 120) * 3) * (math.pi / 180.0);
    final displayAngle = _isDragging ? _currentMarkerAngle : defaultWheelAngle;

    return ObsidianCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.tempoMarking,
            key: const ValueKey('metronome_tempo_marking'),
            style: AppTypography.caption,
          ),
          const SizedBox(height: 1),
          Text(
            '${widget.bpm}',
            key: const ValueKey('metronome_bpm_text'),
            style: AppTypography.bpmDisplay.copyWith(fontSize: 40),
          ),
          const Text(
            'BPM',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: AppColors.violetLight,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 152,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Botão Canto Superior Esquerdo: -1 BPM (segurar: -5 BPM)
                Align(
                  alignment: Alignment.topLeft,
                  child: _CornerActionButton(
                    buttonKey: const ValueKey('metronome_bpm_minus_1'),
                    icon: Icons.remove_rounded,
                    tooltip: 'Diminuir BPM (-1 / segurar -5)',
                    onTap: () => widget.onStepBpm(-1),
                    onLongPress: () => widget.onStepBpm(-5),
                  ),
                ),

                // Botão Canto Superior Direito: +1 BPM (segurar: +5 BPM)
                Align(
                  alignment: Alignment.topRight,
                  child: _CornerActionButton(
                    buttonKey: const ValueKey('metronome_bpm_plus_1'),
                    icon: Icons.add_rounded,
                    tooltip: 'Aumentar BPM (+1 / segurar +5)',
                    onTap: () => widget.onStepBpm(1),
                    onLongPress: () => widget.onStepBpm(5),
                  ),
                ),

                // Roda Giratória Central (Rotary Jog Wheel)
                GestureDetector(
                  key: const ValueKey('metronome_rotary_dial'),
                  onPanStart: (details) => _handlePanStart(
                    details.localPosition,
                    const Size(136, 136),
                  ),
                  onPanUpdate: (details) => _handlePanUpdate(
                    details.localPosition,
                    const Size(136, 136),
                  ),
                  onPanEnd: (_) => _handlePanEnd(),
                  onPanCancel: () => _handlePanEnd(),
                  child: Container(
                    width: 136,
                    height: 136,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background,
                      border: Border.all(
                        color: _isDragging
                            ? AppColors.violet.withValues(alpha: 0.6)
                            : AppColors.elevated,
                        width: 5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: displayAngle,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isDragging
                                      ? AppColors.violetLight
                                      : AppColors.violet,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.violet.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            widget.timeSignatureLabel,
                            style: const TextStyle(
                              fontFamily: AppTypography.monoFontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botão Canto Inferior Esquerdo: Play / Pause
                Align(
                  alignment: Alignment.bottomLeft,
                  child: _CornerActionButton(
                    buttonKey: const ValueKey('metronome_btn_play_pause'),
                    icon: widget.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    isHighlighted: true,
                    isPrimaryPlay: !widget.isPlaying,
                    tooltip: widget.isPlaying
                        ? 'Parar Metrônomo'
                        : 'Iniciar Metrônomo',
                    onTap: widget.onTogglePlay,
                  ),
                ),

                // Botão Canto Inferior Direito: Tap Tempo
                Align(
                  alignment: Alignment.bottomRight,
                  child: _CornerActionButton(
                    buttonKey: const ValueKey('metronome_btn_tap_tempo'),
                    label: 'TAP',
                    tooltip: 'Tap Tempo',
                    onTap: widget.onTapTempo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerActionButton extends StatelessWidget {
  const _CornerActionButton({
    required this.buttonKey,
    required this.tooltip,
    required this.onTap,
    this.label,
    this.icon,
    this.onLongPress,
    this.isHighlighted = false,
    this.isPrimaryPlay = false,
  });

  final Key buttonKey;
  final String? label;
  final IconData? icon;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isHighlighted;
  final bool isPrimaryPlay;

  @override
  Widget build(BuildContext context) {
    final bgColor = isHighlighted
        ? (isPrimaryPlay ? AppColors.violet : AppColors.violet.withValues(alpha: 0.8))
        : AppColors.elevated;
    final borderColor = isHighlighted ? AppColors.violetLight : AppColors.border;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: borderColor,
            width: isHighlighted ? 1.5 : 1.0,
          ),
        ),
        elevation: isHighlighted ? 4 : 0,
        child: InkWell(
          key: buttonKey,
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: icon != null
                  ? Icon(
                      icon,
                      size: isHighlighted ? 26 : 22,
                      color: isHighlighted ? Colors.white : AppColors.textPrimary,
                    )
                  : Text(
                      label ?? '',
                      style: TextStyle(
                        fontFamily: AppTypography.monoFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isHighlighted ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

