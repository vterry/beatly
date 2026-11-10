import 'package:beatly/domain/models/app_settings.dart';
import 'package:beatly/ui/features/settings/view_models/settings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_settings_repository.dart';

void main() {
  group('SettingsViewModel (RF-11 / RF-12 / EC-07)', () {
    late FakeSettingsRepository repository;
    late SettingsViewModel viewModel;

    setUp(() {
      repository = FakeSettingsRepository();
      viewModel = SettingsViewModel(repository: repository);
    });

    test('inicializa com configurações padrão', () async {
      await viewModel.loadSettings();
      expect(viewModel.settings.transitionCountdownSeconds, equals(5));
      expect(viewModel.settings.transitionAlertSound, equals(TransitionAlertSound.zenChime));
      expect(viewModel.settings.keepScreenAwake, isTrue);
      expect(viewModel.settings.hapticOnTransition, isTrue);
      expect(viewModel.settings.hapticOnFirstBeat, isFalse);
    });

    test(
      'TC-08.01: Salvar transição em 0 segundos é aceito e persistido (RF-11 / EC-07)',
      () async {
        await viewModel.loadSettings();

        await viewModel.setTransitionCountdownSeconds(0);

        expect(viewModel.settings.transitionCountdownSeconds, equals(0));
        final persisted = await repository.getSettings();
        expect(persisted.transitionCountdownSeconds, equals(0));

        // Testa clamp de valores fora do limite 0..60
        await viewModel.setTransitionCountdownSeconds(75);
        expect(viewModel.settings.transitionCountdownSeconds, equals(60));

        await viewModel.setTransitionCountdownSeconds(-10);
        expect(viewModel.settings.transitionCountdownSeconds, equals(0));
      },
    );

    test(
      'TC-08.02: Alterar aviso sonoro e wakelock atualiza e persiste as preferências (RF-12)',
      () async {
        await viewModel.loadSettings();

        await viewModel.setTransitionAlertSound(TransitionAlertSound.softMarimba);
        expect(
          viewModel.settings.transitionAlertSound,
          equals(TransitionAlertSound.softMarimba),
        );

        await viewModel.setKeepScreenAwake(false);
        expect(viewModel.settings.keepScreenAwake, isFalse);

        await viewModel.setTransitionAlertVolume(0.5);
        expect(viewModel.settings.transitionAlertVolume, equals(0.5));

        await viewModel.setHapticOnFirstBeat(true);
        expect(viewModel.settings.hapticOnFirstBeat, isTrue);

        await viewModel.setHapticOnTransition(false);
        expect(viewModel.settings.hapticOnTransition, isFalse);

        // Verifica persistência final no repositório
        final saved = await repository.getSettings();
        expect(saved.transitionAlertSound, equals(TransitionAlertSound.softMarimba));
        expect(saved.keepScreenAwake, isFalse);
        expect(saved.transitionAlertVolume, equals(0.5));
        expect(saved.hapticOnFirstBeat, isTrue);
        expect(saved.hapticOnTransition, isFalse);
      },
    );
  });
}
