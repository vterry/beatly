import 'package:beatly/data/datasources/local/app_database.dart';
import 'package:beatly/data/repositories/drift_settings_repository.dart';
import 'package:beatly/domain/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/in_memory_app_database.dart';

void main() {
  group('DriftSettingsRepository (RF-11 / RF-12)', () {
    late AppDatabase db;
    late DriftSettingsRepository repository;

    setUp(() {
      db = createInMemoryAppDatabase();
      repository = DriftSettingsRepository(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('TC-02.08: retorna default de 5 segundos para transição quando nenhuma preferência foi salva', () async {
      final seconds = await repository.getTransitionCountdownSeconds();
      expect(seconds, equals(5));

      final settings = await repository.getSettings();
      expect(settings.transitionCountdownSeconds, equals(5));
      expect(settings.transitionAlertSound, equals(TransitionAlertSound.zenChime));
      expect(settings.keepScreenAwake, isTrue);
    });

    test('TC-02.09: persiste novo valor de transição e preferências de áudio e recupera com exatidão', () async {
      await repository.saveTransitionCountdownSeconds(10);
      expect(await repository.getTransitionCountdownSeconds(), equals(10));

      const updated = AppSettings(
        transitionCountdownSeconds: 0,
        transitionAlertVolume: 0.6,
        transitionAlertSound: TransitionAlertSound.softMarimba,
        hapticOnFirstBeat: true,
        hapticOnTransition: false,
        keepScreenAwake: false,
      );
      await repository.saveSettings(updated);

      final loaded = await repository.getSettings();
      expect(loaded.transitionCountdownSeconds, equals(0));
      expect(loaded.transitionAlertVolume, closeTo(0.6, 0.001));
      expect(loaded.transitionAlertSound, equals(TransitionAlertSound.softMarimba));
      expect(loaded.hapticOnFirstBeat, isTrue);
      expect(loaded.hapticOnTransition, isFalse);
      expect(loaded.keepScreenAwake, isFalse);
    });

    test('TC-02.10: salva e recupera lastMetronomeBpm e executeRoutinesInBackground', () async {
      // Valores padrão quando não configurados
      expect(await repository.getLastMetronomeBpm(), equals(120));
      expect(await repository.getExecuteRoutinesInBackground(), isTrue);

      // Salva novos valores diretamente
      await repository.saveLastMetronomeBpm(160);
      expect(await repository.getLastMetronomeBpm(), equals(160));

      await repository.saveExecuteRoutinesInBackground(false);
      expect(await repository.getExecuteRoutinesInBackground(), isFalse);

      // Salva via AppSettings completo
      final current = await repository.getSettings();
      final updated = current.copyWith(
        lastMetronomeBpm: 144,
        executeRoutinesInBackground: true,
      );
      await repository.saveSettings(updated);

      final loaded = await repository.getSettings();
      expect(loaded.lastMetronomeBpm, equals(144));
      expect(loaded.executeRoutinesInBackground, isTrue);
    });
  });
}

