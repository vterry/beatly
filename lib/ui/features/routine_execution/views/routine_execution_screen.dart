import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/services/system/wakelock_service.dart';
import '../../../../domain/models/activity_category.dart';
import '../../../../domain/models/beat_emphasis.dart';
import '../../../../domain/models/routine.dart';
import '../../../../domain/models/routine_activity.dart';
import '../../../../domain/models/routine_execution_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/obsidian_button.dart';
import '../../../core/widgets/obsidian_card.dart';
import '../../evolution_map/widgets/radar_chart_painter.dart';
import '../view_models/routine_execution_view_model.dart';
import '../widgets/execution_controls_bar.dart';
import '../widgets/preparation_overlay.dart';
import '../widgets/transition_countdown_overlay.dart';

/// Tela de foco e execução ativa de rotina de estudos (RF-06 / RF-07).
class RoutineExecutionScreen extends StatefulWidget {
  const RoutineExecutionScreen({
    required this.viewModel,
    required this.routine,
    this.preparationSeconds = 5,
    this.transitionSeconds = 5,
    this.transitionChime = 'chime_zen',
    this.transitionVolume = 0.8,
    this.keepScreenAwake = true,
    this.hapticOnTransition = true,
    this.wakelockService,
    super.key,
  });

  final RoutineExecutionViewModel viewModel;
  final Routine routine;
  final int preparationSeconds;
  final int transitionSeconds;
  final String transitionChime;
  final double transitionVolume;
  final bool keepScreenAwake;
  final bool hapticOnTransition;
  final WakelockService? wakelockService;

  @override
  State<RoutineExecutionScreen> createState() => _RoutineExecutionScreenState();
}

class _RoutineExecutionScreenState extends State<RoutineExecutionScreen> {
  late final WakelockService _wakelock;

  @override
  void initState() {
    super.initState();
    _wakelock = widget.wakelockService ?? WakelockService();
    if (widget.keepScreenAwake) {
      _wakelock.enable();
    }
    if (widget.viewModel.state is ExecutionStateIdle) {
      widget.viewModel.startRoutine(
        widget.routine,
        preparationSeconds: widget.preparationSeconds,
        transitionSeconds: widget.transitionSeconds,
        transitionChime: widget.transitionChime,
        transitionVolume: widget.transitionVolume,
      );
    }
  }

  @override
  void dispose() {
    if (widget.keepScreenAwake) {
      _wakelock.disable();
    }
    super.dispose();
  }

  Future<void> _showCancelConfirmationDialog() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Cancelar treino em andamento?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Todo o progresso desta sessão será descartado e nenhum tempo será registrado.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          ObsidianButton(
            key: const ValueKey('dialog_btn_confirm_cancel'),
            label: 'Descartar e cancelar',
            variant: ObsidianButtonVariant.danger,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          const SizedBox(height: AppDimensions.xs),
          ObsidianButton(
            key: const ValueKey('dialog_btn_keep_training'),
            label: 'Continuar treino',
            variant: ObsidianButtonVariant.primary,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      await widget.viewModel.cancelRoutine();
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    }
  }

  String _formatTimer(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes == 0) return '${seconds}s';
    if (seconds == 0) return '${minutes}m';
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final state = widget.viewModel.state;

        if (state is ExecutionStatePreparing) {
          return Scaffold(
            body: SafeArea(
              child: PreparationOverlay(
                remainingSeconds: state.remainingSeconds,
                firstActivity: state.firstActivity,
                totalActivities: state.totalActivities,
                onSkipNow: widget.viewModel.skipTransition,
              ),
            ),
          );
        }

        if (state is ExecutionStateTransitioning) {
          if (widget.hapticOnTransition) {
            HapticFeedback.selectionClick();
          }
          return Scaffold(
            body: SafeArea(
              child: TransitionCountdownOverlay(
                nextActivity: state.nextActivity,
                nextActivityIndex: state.nextActivityIndex,
                totalActivities: state.totalActivities,
                remainingSeconds: state.remainingSeconds,
                onSkipNow: widget.viewModel.skipTransition,
              ),
            ),
          );
        }

        if (state is ExecutionStateCompleted) {
          return _buildCompletedView(context, state);
        }

        if (state is ExecutionStateCanceled) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                'Treino cancelado',
                style: AppTypography.caption,
              ),
            ),
          );
        }

        // ExecutionStateRunning ou ExecutionStatePaused
        final (
          bool isPaused,
          RoutineActivity currentActivity,
          int currentActivityIndex,
          int totalActivities,
          Duration remainingDuration,
          bool isMetronomeActive,
        ) = switch (state) {
          ExecutionStateRunning r => (
              false,
              r.currentActivity,
              r.currentActivityIndex,
              r.totalActivities,
              r.remainingDuration,
              r.isMetronomeActive,
            ),
          ExecutionStatePaused p => (
              true,
              p.currentActivity,
              p.currentActivityIndex,
              p.totalActivities,
              p.remainingDuration,
              false,
            ),
          _ => throw StateError('Estado inesperado de execução: $state'),
        };

        return AppScaffold(
          title: widget.routine.name,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
              ),
              tooltip: 'Cancelar treino',
              onPressed: _showCancelConfirmationDialog,
            ),
          ],
          body: Column(
            children: [
              // Indicador de progresso da rotina
              Text(
                'Atividade ${currentActivityIndex + 1} de $totalActivities',
                style: AppTypography.caption.copyWith(letterSpacing: 1.1),
              ),
              const SizedBox(height: AppDimensions.sm),
              // Badge de Categoria
              _buildCategoryBadge(currentActivity.category),
              const SizedBox(height: AppDimensions.sm),
              // Nome da Atividade
              Text(
                currentActivity.name,
                textAlign: TextAlign.center,
                style: AppTypography.heading.copyWith(fontSize: 24),
              ),
              if (currentActivity.notes.trim().isNotEmpty) ...[
                const SizedBox(height: AppDimensions.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.sticky_note_2_rounded,
                        size: 14,
                        color: AppColors.violetLight,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          currentActivity.notes.trim(),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Cronômetro grande regressivo
              Text(
                _formatTimer(remainingDuration),
                key: const ValueKey('execution_timer_text'),
                style: AppTypography.timerDisplay.copyWith(
                  color: isPaused ? AppColors.textMuted : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              // Indicador e controle do metrônomo
              _buildMetronomeIndicator(
                activity: currentActivity,
                isActive: isMetronomeActive,
              ),
              const Spacer(),
              // Barra de transporte e controle
              ExecutionControlsBar(
                isPaused: isPaused,
                canGoPrevious: currentActivityIndex > 0,
                canGoNext: currentActivityIndex + 1 < totalActivities,
                onPauseResume: () {
                  if (isPaused) {
                    widget.viewModel.resume();
                  } else {
                    widget.viewModel.pause();
                  }
                },
                onPrevious: widget.viewModel.previous,
                onSkipNext: widget.viewModel.skipToNext,
                onComplete: widget.viewModel.completeRoutineEarly,
                onCancel: _showCancelConfirmationDialog,
              ),
              const SizedBox(height: AppDimensions.sm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryBadge(ActivityCategory category) {
    final color = AppColors.forCategory(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        category.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMetronomeIndicator({
    required RoutineActivity activity,
    required bool isActive,
  }) {
    final bpm = activity.bpm ?? 120;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isActive
              ? AppColors.violet.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Display do BPM e status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.elevated,
                  borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      size: 16,
                      color: isActive ? AppColors.violetLight : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$bpm BPM',
                      key: const ValueKey('execution_metronome_bpm_text'),
                      style: AppTypography.bpmDisplay.copyWith(
                        fontSize: 15,
                        color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Ações: Som e Botão de Ajustar Metrônomo
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const ValueKey('execution_btn_toggle_metronome'),
                    icon: Icon(
                      isActive ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: isActive ? AppColors.violetLight : AppColors.textMuted,
                      size: 20,
                    ),
                    tooltip: isActive ? 'Desativar som' : 'Ativar som',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.elevated,
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                    ),
                    onPressed: widget.viewModel.toggleMetronome,
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    key: const ValueKey('execution_btn_open_metronome_sheet'),
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    onTap: () => _showRoutineMetronomeSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.violet.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                        border: Border.all(
                          color: AppColors.violetLight.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: AppColors.violetLight,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Ajustar',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.violetLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Linha de ajuste de velocidade do BPM
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const ValueKey('execution_btn_bpm_minus_5'),
                icon: const Text(
                  '-5',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                tooltip: 'Diminuir 5 BPM',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 32),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.elevated,
                ),
                onPressed: () => widget.viewModel.stepBpm(-5),
              ),
              const SizedBox(width: 6),
              IconButton(
                key: const ValueKey('execution_btn_bpm_minus_1'),
                icon: const Icon(
                  Icons.remove_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                tooltip: 'Diminuir 1 BPM',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 32),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.elevated,
                ),
                onPressed: () => widget.viewModel.stepBpm(-1),
              ),
              const SizedBox(width: 12),
              const Text(
                'Velocidade',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                key: const ValueKey('execution_btn_bpm_plus_1'),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                tooltip: 'Aumentar 1 BPM',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 32),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.elevated,
                ),
                onPressed: () => widget.viewModel.stepBpm(1),
              ),
              const SizedBox(width: 6),
              IconButton(
                key: const ValueKey('execution_btn_bpm_plus_5'),
                icon: const Text(
                  '+5',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                tooltip: 'Aumentar 5 BPM',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 32),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.elevated,
                ),
                onPressed: () => widget.viewModel.stepBpm(5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRoutineMetronomeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final activeSubdivision = widget.viewModel.activeSubdivision;
            final pattern = widget.viewModel.activePattern;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ajustes do Metrônomo no Treino',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'SUBDIVISÃO DE TEMPO',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        (1, '1x', 'Pulso'),
                        (2, '2x', 'Colcheia'),
                        (3, '3x', 'Tercina'),
                        (4, '4x', 'Semicol.'),
                      ].map((item) {
                        final (sub, label, sublabel) = item;
                        final isSelected = activeSubdivision == sub;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              key: ValueKey('routine_subdivision_btn_$sub'),
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => widget.viewModel.updateSubdivision(sub),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.violet.withValues(alpha: 0.22) : AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.violetLight : AppColors.border,
                                    width: isSelected ? 1.6 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? AppColors.violetLight : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      sublabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'VOLUMES DOS PULSOS',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              key: const ValueKey('routine_metronome_reset_pattern'),
                              onPressed: () => widget.viewModel.resetBeatPatternToDefault(),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: const Text('Padrão', style: TextStyle(fontSize: 12, color: AppColors.violetLight)),
                            ),
                            TextButton(
                              key: const ValueKey('routine_metronome_mute_pattern'),
                              onPressed: () => widget.viewModel.muteAllBeats(),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: const Text('Silenciar', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: List<Widget>.generate(pattern.length, (idx) {
                          final emphasis = pattern[idx];
                          final (barHeight, barColor) = switch (emphasis) {
                            BeatEmphasis.forte => (32.0, AppColors.amber),
                            BeatEmphasis.normal => (22.0, AppColors.violet),
                            BeatEmphasis.fraco => (12.0, AppColors.violetLight.withValues(alpha: 0.45)),
                            BeatEmphasis.mudo => (4.0, AppColors.border),
                          };
                          final label = switch (emphasis) {
                            BeatEmphasis.forte => 'Forte',
                            BeatEmphasis.normal => 'Normal',
                            BeatEmphasis.fraco => 'Fraco',
                            BeatEmphasis.mudo => 'Mudo',
                          };

                          return InkWell(
                            key: ValueKey('routine_beat_emphasis_btn_$idx'),
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => widget.viewModel.cycleBeatEmphasis(idx),
                            child: Container(
                              width: 54,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '#${idx + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 34,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        width: 20,
                                        height: barHeight,
                                        decoration: BoxDecoration(
                                          color: barColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: emphasis == BeatEmphasis.mudo ? AppColors.textMuted : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedView(
    BuildContext context,
    ExecutionStateCompleted state,
  ) {
    final categoryDurations = <ActivityCategory, int>{
      for (final cat in ActivityCategory.values)
        cat: state.results[cat]?.inSeconds ?? 0,
    };

    return Scaffold(
      key: const ValueKey('execution_completed_view'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 56,
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      const Text(
                        'Treino Concluído!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        widget.routine.name,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppDimensions.md),
                      ObsidianCard(
                        padding: const EdgeInsets.all(AppDimensions.sm),
                        child: Column(
                          children: [
                            const Text(
                              'Tempo Total Praticado',
                              style: AppTypography.caption,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatSeconds(state.session.totalDurationSeconds),
                              style: AppTypography.timerDisplay.copyWith(
                                fontSize: 28,
                                color: AppColors.violetLight,
                              ),
                            ),
                            if (state.session.isCompletedEarly) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Concluído Antecipadamente',
                                  style: TextStyle(
                                    color: AppColors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      PentagonRadarChart(
                        categoryDurations: categoryDurations,
                        height: 140,
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      if (state.results.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Categorias Praticadas',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.xs),
                        ...state.results.entries.map((entry) {
                          final catColor = AppColors.forCategory(entry.key);
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppDimensions.xs,
                            ),
                            child: ObsidianCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: catColor,
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.sm),
                                  Text(
                                    entry.key.label,
                                    style: AppTypography.body,
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatSeconds(entry.value.inSeconds),
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              ObsidianButton(
                key: const ValueKey('execution_completed_btn_close'),
                label: 'Fechar',
                variant: ObsidianButtonVariant.primary,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
