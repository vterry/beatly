import 'package:beatly/domain/models/app_settings.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/settings/view_models/settings_view_model.dart';
import 'package:beatly/ui/features/settings/views/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_metronome_audio_port.dart';
import '../../fakes/fake_settings_repository.dart';

void main() {
  group('SettingsScreen Widget Tests (RF-11 / RF-12 / EC-07)', () {
    late FakeSettingsRepository repository;
    late FakeMetronomeAudioPort audioPort;
    late SettingsViewModel viewModel;

    setUp(() async {
      repository = FakeSettingsRepository();
      audioPort = FakeMetronomeAudioPort();
      viewModel = SettingsViewModel(
        repository: repository,
        audioPort: audioPort,
      );
      await viewModel.loadSettings();
    });

    Widget createTestApp() {
      return MaterialApp(
        theme: ObsidianTheme.darkTheme,
        home: SettingsScreen(viewModel: viewModel),
      );
    }

    testWidgets('renderiza tela de configurações com valores padrão', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Ajustes & Preferências'), findsOneWidget);
      expect(find.byKey(const ValueKey('settings_transition_value_text')), findsOneWidget);
      expect(find.text('5s'), findsOneWidget);
      expect(find.byKey(const ValueKey('settings_switch_wakelock')), findsOneWidget);
    });

    testWidgets('clicar em settings_transition_zero define transição imediata 0s', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final zeroBtn = find.byKey(const ValueKey('settings_transition_zero'));
      await tester.tap(zeroBtn);
      await tester.pumpAndSettle();

      final valueText = tester.widget<Text>(
        find.byKey(const ValueKey('settings_transition_value_text')),
      );
      expect(valueText.data, equals('0s (Imediato)'));
      expect(viewModel.settings.transitionCountdownSeconds, equals(0));
    });

    testWidgets('clicar em settings_transition_plus_1 incrementa contador em 1 segundo', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final plusBtn = find.byKey(const ValueKey('settings_transition_plus_1'));
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();

      expect(find.text('6s'), findsOneWidget);
      expect(viewModel.settings.transitionCountdownSeconds, equals(6));
    });

    testWidgets('selecionar som de aviso softMarimba atualiza preferência', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final marimbaOption = find.byKey(
        ValueKey('settings_sound_${TransitionAlertSound.softMarimba.name}'),
      );
      await tester.scrollUntilVisible(marimbaOption, 100);
      await tester.tap(marimbaOption);
      await tester.pumpAndSettle();

      expect(
        viewModel.settings.transitionAlertSound,
        equals(TransitionAlertSound.softMarimba),
      );
    });

    testWidgets('alternar chave settings_switch_wakelock desativa tela ativa', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final wakelockSwitch = find.byKey(const ValueKey('settings_switch_wakelock'));
      await tester.scrollUntilVisible(wakelockSwitch, 100);
      await tester.tap(wakelockSwitch);
      await tester.pumpAndSettle();

      expect(viewModel.settings.keepScreenAwake, isFalse);
    });

    testWidgets('clicar no botão de prévia de som toca o chime correspondente', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final previewZen = find.byKey(
        ValueKey('settings_btn_preview_${TransitionAlertSound.zenChime.name}'),
      );
      await tester.scrollUntilVisible(previewZen, 100);
      await tester.tap(previewZen);
      await tester.pumpAndSettle();

      expect(audioPort.playedChimes, contains('chime_zen'));

      final previewGong = find.byKey(
        ValueKey('settings_btn_preview_${TransitionAlertSound.meditativeGong.name}'),
      );
      await tester.scrollUntilVisible(previewGong, 100);
      await tester.tap(previewGong);
      await tester.pumpAndSettle();

      expect(audioPort.playedChimes, contains('chime_gong'));
    });
  });
}
