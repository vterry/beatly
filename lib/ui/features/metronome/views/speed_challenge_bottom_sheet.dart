import 'package:flutter/material.dart';

import '../../../../domain/models/speed_challenge_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/obsidian_button.dart';
import '../../../core/widgets/obsidian_card.dart';
import '../view_models/speed_challenge_view_model.dart';

/// Painel modal (Bottom Sheet) para o Modo Desafio / Speed Trainer (RF-04).
class SpeedChallengeBottomSheet extends StatefulWidget {
  const SpeedChallengeBottomSheet({
    required this.viewModel,
    this.beatsPerBar = 4,
    super.key,
  });

  final SpeedChallengeViewModel viewModel;
  final int beatsPerBar;

  /// Exibe o painel modal de Modo Desafio.
  static Future<void> show(
    BuildContext context, {
    required SpeedChallengeViewModel viewModel,
    int beatsPerBar = 4,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.cardRadius),
        ),
      ),
      builder: (_) => SpeedChallengeBottomSheet(
        viewModel: viewModel,
        beatsPerBar: beatsPerBar,
      ),
    );
  }

  @override
  State<SpeedChallengeBottomSheet> createState() =>
      _SpeedChallengeBottomSheetState();
}

class _SpeedChallengeBottomSheetState extends State<SpeedChallengeBottomSheet> {
  late final TextEditingController _startBpmCtrl;
  late final TextEditingController _targetBpmCtrl;
  late final TextEditingController _bpmStepCtrl;
  late final TextEditingController _everyBarsCtrl;

  @override
  void initState() {
    super.initState();
    final cfg = widget.viewModel.config;
    _startBpmCtrl = TextEditingController(text: cfg.startBpm.toString());
    _targetBpmCtrl = TextEditingController(text: cfg.targetBpm.toString());
    _bpmStepCtrl = TextEditingController(text: cfg.bpmStep.toString());
    _everyBarsCtrl = TextEditingController(text: cfg.everyBars.toString());
  }

  @override
  void dispose() {
    _startBpmCtrl.dispose();
    _targetBpmCtrl.dispose();
    _bpmStepCtrl.dispose();
    _everyBarsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final error = vm.validationError;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: AppDimensions.md,
              right: AppDimensions.md,
              top: AppDimensions.md,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + AppDimensions.lg,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Modo Desafio (Speed Trainer)',
                        style: AppTypography.heading,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.violet.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          vm.isRunning
                              ? 'EM CURSO • ${vm.currentBpm} BPM'
                              : (vm.isCompleted ? 'CONCLUÍDO' : 'CONFIGURAR'),
                          key: const ValueKey('challenge_current_bpm_text'),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.violetLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Campos de BPM Inicial e BPM Final
                  Row(
                    children: [
                      Expanded(
                        child: _NumericFieldCard(
                          fieldKey: const ValueKey('challenge_input_start_bpm'),
                          label: 'BPM Inicial',
                          controller: _startBpmCtrl,
                          enabled: !vm.isRunning,
                          onChanged: (v) {
                            final parsed = int.tryParse(v);
                            if (parsed != null) vm.setStartBpm(parsed);
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: _NumericFieldCard(
                          fieldKey: const ValueKey('challenge_input_target_bpm'),
                          label: 'BPM Final (Alvo)',
                          controller: _targetBpmCtrl,
                          enabled: !vm.isRunning,
                          onChanged: (v) {
                            final parsed = int.tryParse(v);
                            if (parsed != null) vm.setTargetBpm(parsed);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm),

                  // Campos de Incremento e Compassos
                  Row(
                    children: [
                      Expanded(
                        child: _NumericFieldCard(
                          fieldKey: const ValueKey('challenge_input_bpm_step'),
                          label: 'Incremento (+BPM)',
                          controller: _bpmStepCtrl,
                          enabled: !vm.isRunning,
                          onChanged: (v) {
                            final parsed = int.tryParse(v);
                            if (parsed != null) vm.setBpmStep(parsed);
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: _NumericFieldCard(
                          fieldKey: const ValueKey('challenge_input_every_bars'),
                          label: 'A cada N compassos',
                          controller: _everyBarsCtrl,
                          enabled: !vm.isRunning,
                          onChanged: (v) {
                            final parsed = int.tryParse(v);
                            if (parsed != null) vm.setEveryBars(parsed);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm),

                  // Divisão do tempo opcional (Mínimas, Colcheias, Tercinas, Semicolcheias)
                  ObsidianCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.music_note_rounded,
                              size: 16,
                              color: AppColors.violetLight,
                            ),
                            SizedBox(width: AppDimensions.xs),
                            Text(
                              'Divisão do Tempo (Opcional):',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        Row(
                          children: [
                            (ChallengeTimeDivision.minima, 'Mínimas'),
                            (ChallengeTimeDivision.colcheia, 'Colcheias'),
                            (ChallengeTimeDivision.tercina, 'Tercinas'),
                            (ChallengeTimeDivision.semicolcheia, 'Semicol.'),
                          ].map((item) {
                            final (div, label) = item;
                            final isSelected = vm.config.timeDivision == div;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                child: InkWell(
                                  key: ValueKey('challenge_division_${div.name}'),
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: vm.isRunning
                                      ? null
                                      : () => vm.setTimeDivision(div),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.violet.withValues(alpha: 0.24)
                                          : AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.violetLight
                                            : AppColors.border,
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
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
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),

                  // Comportamento no teto
                  ObsidianCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 16,
                              color: AppColors.violetLight,
                            ),
                            SizedBox(width: AppDimensions.xs),
                            Text(
                              'Ao atingir o BPM Alvo:',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        SegmentedButton<ChallengeCompletionBehavior>(
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          segments: const [
                            ButtonSegment(
                              value: ChallengeCompletionBehavior.keepRunning,
                              label: Text('Manter'),
                              icon: Icon(Icons.repeat_rounded, size: 16),
                            ),
                            ButtonSegment(
                              value: ChallengeCompletionBehavior.stopAndChime,
                              label: Text('Parar + Chime'),
                              icon: Icon(
                                Icons.notifications_active_rounded,
                                size: 16,
                              ),
                            ),
                          ],
                          selected: {vm.config.onTargetReached},
                          onSelectionChanged: vm.isRunning
                              ? null
                              : (selection) {
                                  vm.setCompletionBehavior(selection.first);
                                },
                        ),
                      ],
                    ),
                  ),

                  // Mensagem de erro de validação (EC-01)
                  if (error != null) ...[
                    const SizedBox(height: AppDimensions.sm),
                    Container(
                      key: const ValueKey('challenge_error_text'),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        error,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],

                  // Velocímetro dinâmico / barra de progresso quando ativo ou concluído
                  if (vm.isRunning || vm.isCompleted) ...[
                    const SizedBox(height: AppDimensions.md),
                    ObsidianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${vm.config.startBpm} BPM',
                                style: AppTypography.caption,
                              ),
                              Text(
                                '${vm.currentBpm} BPM',
                                style: AppTypography.heading.copyWith(
                                  color: AppColors.violetLight,
                                ),
                              ),
                              Text(
                                '${vm.config.targetBpm} BPM',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            key: const ValueKey('challenge_progress_bar'),
                            value: vm.progressRatio,
                            minHeight: 8,
                            backgroundColor: AppColors.elevated,
                            color: AppColors.violetLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          if (vm.isRunning && vm.stepProgressText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Próximo incremento em: ${vm.stepProgressText}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppDimensions.md),

                  // Botão principal Iniciar / Parar Desafio
                  if (!vm.isRunning)
                    ObsidianButton(
                      key: const ValueKey('challenge_btn_start'),
                      label: 'Iniciar Desafio',
                      icon: Icons.bolt_rounded,
                      onPressed: vm.isValid
                          ? () => vm.startChallenge(
                                beatsPerBar: widget.beatsPerBar,
                              )
                          : null,
                    )
                  else
                    ObsidianButton(
                      key: const ValueKey('challenge_btn_stop'),
                      label: 'Parar Desafio',
                      icon: Icons.stop_rounded,
                      variant: ObsidianButtonVariant.secondary,
                      onPressed: vm.stopChallenge,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NumericFieldCard extends StatelessWidget {
  const _NumericFieldCard({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ObsidianCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 4),
          TextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            style: AppTypography.heading,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
