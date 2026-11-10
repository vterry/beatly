import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../data/services/system/wakelock_service.dart';
import '../../../../domain/contracts/metronome_audio_port.dart';
import '../../../../domain/contracts/settings_repository.dart';
import '../../../../domain/models/app_settings.dart';

/// ViewModel reativo para gerenciamento das preferências e configurações do app (RF-11 / RF-12).
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required SettingsRepository repository,
    MetronomeAudioPort? audioPort,
    WakelockService? wakelockService,
  })  : _repository = repository,
        _audioPort = audioPort,
        _wakelockService = wakelockService;

  final SettingsRepository _repository;
  final MetronomeAudioPort? _audioPort;
  final WakelockService? _wakelockService;

  AppSettings _settings = const AppSettings();
  bool _isLoading = false;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  /// Carrega as preferências salvas localmente.
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _repository.getSettings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Define e persiste o tempo do contador de transição entre atividades (0..60 segundos) (RF-11 / EC-07).
  Future<void> setTransitionCountdownSeconds(int seconds) async {
    final clamped = seconds.clamp(0, 60);
    _settings = _settings.copyWith(transitionCountdownSeconds: clamped);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Define e persiste o timbre do aviso suave de transição (RF-12).
  Future<void> setTransitionAlertSound(TransitionAlertSound sound) async {
    _settings = _settings.copyWith(transitionAlertSound: sound);
    await _repository.saveSettings(_settings);
    notifyListeners();
    await previewSound(sound);
  }

  /// Toca uma prévia do aviso sonoro selecionado (ou haptic para mudo).
  Future<void> previewSound(TransitionAlertSound sound) async {
    if (sound == TransitionAlertSound.muteHapticOnly) {
      await HapticFeedback.mediumImpact();
      return;
    }

    final soundKey = switch (sound) {
      TransitionAlertSound.zenChime => 'chime_zen',
      TransitionAlertSound.softMarimba => 'chime_marimba',
      TransitionAlertSound.meditativeGong => 'chime_gong',
      _ => 'chime_zen',
    };

    await _audioPort?.playChime(
      soundName: soundKey,
      volume: _settings.transitionAlertVolume,
    );
  }

  /// Define e persiste o volume do aviso suave de transição (0.0..1.0).
  Future<void> setTransitionAlertVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    _settings = _settings.copyWith(transitionAlertVolume: clamped);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Define e persiste a preferência de vibração no primeiro pulso do compasso.
  Future<void> setHapticOnFirstBeat(bool enabled) async {
    _settings = _settings.copyWith(hapticOnFirstBeat: enabled);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Define e persiste a preferência de vibração durante a transição.
  Future<void> setHapticOnTransition(bool enabled) async {
    _settings = _settings.copyWith(hapticOnTransition: enabled);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  /// Define e persiste a preferência de manter a tela ligada durante o treino (RF-12).
  Future<void> setKeepScreenAwake(bool enabled) async {
    _settings = _settings.copyWith(keepScreenAwake: enabled);
    await _repository.saveSettings(_settings);
    if (!enabled) {
      await _wakelockService?.disable();
    }
    notifyListeners();
  }
}
