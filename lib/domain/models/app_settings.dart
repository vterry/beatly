/// Sons disponíveis para o aviso suave de transição entre atividades (RN-12.2).
enum TransitionAlertSound {
  zenChime(label: 'Sino Tibetano / Chime Zen'),
  softMarimba(label: 'Marimba Suave'),
  meditativeGong(label: 'Gongo Meditativo'),
  muteHapticOnly(label: 'Mudo (Apenas vibração)');

  const TransitionAlertSound({required this.label});
  final String label;
}

/// Configurações gerais persistidas localmente no dispositivo (RF-11 / RF-12).
class AppSettings {
  const AppSettings({
    this.transitionCountdownSeconds = 5,
    this.transitionAlertVolume = 0.8,
    this.transitionAlertSound = TransitionAlertSound.zenChime,
    this.hapticOnFirstBeat = false,
    this.hapticOnTransition = true,
    this.keepScreenAwake = true,
  }) : assert(
         transitionCountdownSeconds >= 0 && transitionCountdownSeconds <= 60,
         'Contador de transição deve estar entre 0 e 60 segundos',
       );

  final int transitionCountdownSeconds;
  final double transitionAlertVolume;
  final TransitionAlertSound transitionAlertSound;
  final bool hapticOnFirstBeat;
  final bool hapticOnTransition;
  final bool keepScreenAwake;

  AppSettings copyWith({
    int? transitionCountdownSeconds,
    double? transitionAlertVolume,
    TransitionAlertSound? transitionAlertSound,
    bool? hapticOnFirstBeat,
    bool? hapticOnTransition,
    bool? keepScreenAwake,
  }) {
    return AppSettings(
      transitionCountdownSeconds:
          transitionCountdownSeconds ?? this.transitionCountdownSeconds,
      transitionAlertVolume:
          transitionAlertVolume ?? this.transitionAlertVolume,
      transitionAlertSound: transitionAlertSound ?? this.transitionAlertSound,
      hapticOnFirstBeat: hapticOnFirstBeat ?? this.hapticOnFirstBeat,
      hapticOnTransition: hapticOnTransition ?? this.hapticOnTransition,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
    );
  }
}

