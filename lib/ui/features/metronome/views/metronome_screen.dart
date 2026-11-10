import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../view_models/metronome_view_model.dart';
import '../view_models/speed_challenge_view_model.dart';
import '../widgets/beat_strip_selector.dart';
import '../widgets/rotary_bpm_dial.dart';
import '../widgets/time_division_panel.dart';
import 'speed_challenge_bottom_sheet.dart';

/// Tela principal do Metrônomo no tema Obsidian Dark (RF-01 / RF-02 / RF-03 / RF-04).
class MetronomeScreen extends StatelessWidget {
  const MetronomeScreen({
    required this.viewModel,
    this.challengeViewModel,
    this.trailingHeaderAction,
    super.key,
  });

  final MetronomeViewModel viewModel;
  final SpeedChallengeViewModel? challengeViewModel;
  final Widget? trailingHeaderAction;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (challengeViewModel != null)
        TextButton.icon(
          key: const ValueKey('metronome_btn_open_challenge'),
          onPressed: () {
            SpeedChallengeBottomSheet.show(
              context,
              viewModel: challengeViewModel!,
              beatsPerBar: viewModel.beatsPerBar,
            );
          },
          icon: const Icon(
            Icons.bolt_rounded,
            size: 18,
            color: AppColors.violetLight,
          ),
          label: const Text(
            'Desafio',
            style: TextStyle(color: AppColors.violetLight),
          ),
        ),
      ?trailingHeaderAction,
    ];

    return AppScaffold(
      title: 'Metrônomo',
      actions: actions.isEmpty ? null : actions,
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (challengeViewModel != null)
                        _ChallengeActiveBanner(viewModel: challengeViewModel!),
                      RotaryBpmDial(
                        bpm: viewModel.bpm,
                        tempoMarking: viewModel.tempoMarking,
                        timeSignatureLabel:
                            '${viewModel.beatsPerBar}/${viewModel.beatUnit}',
                        isPlaying: viewModel.isPlaying,
                        onBpmChanged: viewModel.setBpm,
                        onStepBpm: (delta) => delta > 0
                            ? viewModel.incrementBpm(delta)
                            : viewModel.decrementBpm(delta.abs()),
                        onTogglePlay: viewModel.togglePlay,
                        onTapTempo: viewModel.registerTap,
                      ),
                      const SizedBox(height: 8),
                      TimeDivisionPanel(
                        beatsPerBar: viewModel.beatsPerBar,
                        beatUnit: viewModel.beatUnit,
                        subdivision: viewModel.subdivision,
                        onBeatsPerBarChanged: viewModel.setBeatsPerBar,
                        onBeatUnitChanged: viewModel.setBeatUnit,
                        onSubdivisionChanged: viewModel.setSubdivision,
                      ),
                      const SizedBox(height: 8),
                      BeatStripSelector(
                        beatPattern: viewModel.beatPattern,
                        subdivision: viewModel.subdivision,
                        activeBeatIndex: viewModel.activeBeatIndex,
                        onBeatTapped: viewModel.cycleBeatEmphasis,
                        onResetDefault: viewModel.resetBeatPatternToDefault,
                        onMuteAll: viewModel.muteAllBeats,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChallengeActiveBanner extends StatelessWidget {
  const _ChallengeActiveBanner({required this.viewModel});

  final SpeedChallengeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (!viewModel.isRunning && !viewModel.isCompleted) {
          return const SizedBox.shrink();
        }

        final pct = (viewModel.progressRatio * 100).round();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.violetLight.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 18,
                          color: AppColors.amber,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          viewModel.isCompleted
                              ? 'Desafio Concluído! (${viewModel.currentBpm} BPM)'
                              : 'Desafio: ${viewModel.config.startBpm} ➔ ${viewModel.config.targetBpm} BPM ($pct%)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (viewModel.isRunning)
                      InkWell(
                        onTap: viewModel.stopChallenge,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            'Parar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: viewModel.progressRatio,
                  minHeight: 5,
                  backgroundColor: AppColors.elevated,
                  color: AppColors.violetLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                if (viewModel.isRunning && viewModel.stepProgressText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Próximo incremento em: ${viewModel.stepProgressText}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
