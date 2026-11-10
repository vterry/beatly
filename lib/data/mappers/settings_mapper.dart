import 'dart:convert';

import '../../domain/models/app_settings.dart';

/// Serializador JSON seguro para [AppSettings].
abstract final class SettingsMapper {
  static String toJsonString(AppSettings settings) {
    final map = <String, Object>{
      'transitionCountdownSeconds': settings.transitionCountdownSeconds,
      'transitionAlertVolume': settings.transitionAlertVolume,
      'transitionAlertSound': settings.transitionAlertSound.name,
      'hapticOnFirstBeat': settings.hapticOnFirstBeat,
      'hapticOnTransition': settings.hapticOnTransition,
      'keepScreenAwake': settings.keepScreenAwake,
    };
    return jsonEncode(map);
  }

  static AppSettings fromJsonString(String? rawJson) {
    if (rawJson == null || rawJson.isEmpty) {
      return const AppSettings();
    }
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, Object?>) {
      return const AppSettings();
    }

    final soundName = decoded['transitionAlertSound'] as String?;
    final sound = TransitionAlertSound.values.firstWhere(
      (s) => s.name == soundName,
      orElse: () => TransitionAlertSound.zenChime,
    );

    final countdown = (decoded['transitionCountdownSeconds'] as num?)?.toInt() ?? 5;
    final volume = (decoded['transitionAlertVolume'] as num?)?.toDouble() ?? 0.8;

    return AppSettings(
      transitionCountdownSeconds: countdown.clamp(0, 60),
      transitionAlertVolume: volume.clamp(0.0, 1.0),
      transitionAlertSound: sound,
      hapticOnFirstBeat: (decoded['hapticOnFirstBeat'] as bool?) ?? false,
      hapticOnTransition: (decoded['hapticOnTransition'] as bool?) ?? true,
      keepScreenAwake: (decoded['keepScreenAwake'] as bool?) ?? true,
    );
  }
}

