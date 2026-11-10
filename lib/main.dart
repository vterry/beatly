import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'data/datasources/local/app_database.dart';
import 'data/repositories/drift_routine_repository.dart';
import 'data/repositories/drift_session_repository.dart';
import 'data/repositories/drift_settings_repository.dart';
import 'data/services/audio/native_metronome_audio_service.dart';
import 'data/services/audio/pcm_sound_cache.dart';
import 'data/services/clock/system_monotonic_clock_service.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'beatly.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase(_openConnection());
  final routineRepository = DriftRoutineRepository(database: database);
  final sessionRepository = DriftSessionRepository(database: database);
  final settingsRepository = DriftSettingsRepository(database: database);

  final clockPort = SystemMonotonicClockService();
  final soundCache = PcmSoundCache();
  await soundCache.preloadAll();

  final audioPort = NativeMetronomeAudioService(
    soundCache: soundCache,
    clockPort: clockPort,
  );
  await audioPort.initialize();

  runApp(
    BeatlyApp(
      routineRepository: routineRepository,
      sessionRepository: sessionRepository,
      settingsRepository: settingsRepository,
      clockPort: clockPort,
      audioPort: audioPort,
    ),
  );
}
