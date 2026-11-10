import 'package:flutter/material.dart';

import '../../../../domain/models/app_settings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/obsidian_card.dart';
import '../view_models/settings_view_model.dart';

/// Tela de Configurações Gerais e Ajustes do Beatly no tema Obsidian Dark (RF-11 / RF-12).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.viewModel,
    super.key,
  });

  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ajustes & Preferências',
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final settings = viewModel.settings;
          final transitionSeconds = settings.transitionCountdownSeconds;
          final transitionText = transitionSeconds == 0
              ? '0s (Imediato)'
              : '${transitionSeconds}s';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Card: Transição entre Atividades
                ObsidianCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transição entre Exercícios',
                            style: AppTypography.heading,
                          ),
                          Text(
                            transitionText,
                            key: const ValueKey(
                              'settings_transition_value_text',
                            ),
                            style: AppTypography.heading.copyWith(
                              color: AppColors.violetLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      const Text(
                        'Tempo de contagem regressiva e aviso suave entre as atividades de uma rotina.',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      Slider(
                        key: const ValueKey('settings_transition_slider'),
                        value: transitionSeconds.toDouble(),
                        min: 0,
                        max: 60,
                        divisions: 60,
                        activeColor: AppColors.violet,
                        inactiveColor: AppColors.border,
                        onChanged: (v) =>
                            viewModel.setTransitionCountdownSeconds(v.round()),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                            key: const ValueKey('settings_transition_minus_1'),
                            onPressed: transitionSeconds > 0
                                ? () => viewModel
                                      .setTransitionCountdownSeconds(
                                        transitionSeconds - 1,
                                      )
                                : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: const Text('-1s'),
                          ),
                          OutlinedButton(
                            key: const ValueKey('settings_transition_zero'),
                            onPressed: () =>
                                viewModel.setTransitionCountdownSeconds(0),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.amber,
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: const Text('0s (Imediato)'),
                          ),
                          OutlinedButton(
                            key: const ValueKey('settings_transition_plus_1'),
                            onPressed: transitionSeconds < 60
                                ? () => viewModel
                                      .setTransitionCountdownSeconds(
                                        transitionSeconds + 1,
                                      )
                                : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: const Text('+1s'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                // 2. Card: Som de Aviso de Transição
                ObsidianCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aviso Sonoro de Transição',
                        style: AppTypography.heading,
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      const Text(
                        'Timbre tocado ao finalizar uma atividade para alertar sobre o próximo exercício.',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      RadioGroup<TransitionAlertSound>(
                        groupValue: settings.transitionAlertSound,
                        onChanged: (val) {
                          if (val != null) {
                            viewModel.setTransitionAlertSound(val);
                          }
                        },
                        child: Column(
                          children: [
                            for (final sound in TransitionAlertSound.values)
                              RadioListTile<TransitionAlertSound>(
                                key: ValueKey('settings_sound_${sound.name}'),
                                title: Text(
                                  sound.label,
                                  style: AppTypography.body,
                                ),
                                value: sound,
                                activeColor: AppColors.violetLight,
                                contentPadding: EdgeInsets.zero,
                                secondary: IconButton(
                                  key: ValueKey('settings_btn_preview_${sound.name}'),
                                  icon: Icon(
                                    sound == TransitionAlertSound.muteHapticOnly
                                        ? Icons.vibration_rounded
                                        : Icons.volume_up_rounded,
                                    color: settings.transitionAlertSound == sound
                                        ? AppColors.violetLight
                                        : AppColors.textSecondary,
                                  ),
                                  tooltip: sound == TransitionAlertSound.muteHapticOnly
                                      ? 'Testar vibração'
                                      : 'Ouvir exemplo sonoro',
                                  onPressed: () => viewModel.previewSound(sound),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Volume do Aviso',
                            style: AppTypography.caption,
                          ),
                          Text(
                            '${(settings.transitionAlertVolume * 100).round()}%',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.violetLight,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        key: const ValueKey('settings_chime_volume_slider'),
                        value: settings.transitionAlertVolume,
                        min: 0.0,
                        max: 1.0,
                        activeColor: AppColors.violet,
                        inactiveColor: AppColors.border,
                        onChanged: viewModel.setTransitionAlertVolume,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                // 3. Card: Tela Ativa & Feedback Tátil
                ObsidianCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tela & Vibração',
                        style: AppTypography.heading,
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      SwitchListTile(
                        key: const ValueKey('settings_switch_wakelock'),
                        title: const Text(
                          'Manter Tela Sempre Ativa',
                          style: AppTypography.body,
                        ),
                        subtitle: const Text(
                          'Evita que a tela apague durante as sessões de treino.',
                          style: AppTypography.caption,
                        ),
                        value: settings.keepScreenAwake,
                        activeThumbColor: AppColors.violetLight,
                        contentPadding: EdgeInsets.zero,
                        onChanged: viewModel.setKeepScreenAwake,
                      ),
                      const Divider(color: AppColors.border),
                      SwitchListTile(
                        key: const ValueKey(
                          'settings_switch_haptic_transition',
                        ),
                        title: const Text(
                          'Vibração na Transição',
                          style: AppTypography.body,
                        ),
                        subtitle: const Text(
                          'Emite um pulso tátil curto na contagem regressiva.',
                          style: AppTypography.caption,
                        ),
                        value: settings.hapticOnTransition,
                        activeThumbColor: AppColors.violetLight,
                        contentPadding: EdgeInsets.zero,
                        onChanged: viewModel.setHapticOnTransition,
                      ),
                      const Divider(color: AppColors.border),
                      SwitchListTile(
                        key: const ValueKey(
                          'settings_switch_haptic_first_beat',
                        ),
                        title: const Text(
                          'Vibração no 1º Pulso do Compasso',
                          style: AppTypography.body,
                        ),
                        subtitle: const Text(
                          'Vibra sincronizado com a cabeça do compasso.',
                          style: AppTypography.caption,
                        ),
                        value: settings.hapticOnFirstBeat,
                        activeThumbColor: AppColors.violetLight,
                        contentPadding: EdgeInsets.zero,
                        onChanged: viewModel.setHapticOnFirstBeat,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}
