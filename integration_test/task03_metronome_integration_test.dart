import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/metronome/view_models/metronome_view_model.dart';
import 'package:beatly/ui/features/metronome/views/metronome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fakes/fake_clock_port.dart';
import '../test/fakes/fake_metronome_audio_port.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ITC-03.01: Fluxo integrado do Metrônomo (BPM, Divisão do Tempo, Pulsos e Sincronismo de LED)', (tester) async {
    final audioPort = FakeMetronomeAudioPort();
    final clockPort = FakeClockPort();
    final viewModel = MetronomeViewModel(
      audioPort: audioPort,
      clockPort: clockPort,
    );
    addTearDown(() {
      viewModel.dispose();
      clockPort.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ObsidianTheme.darkTheme,
        home: MetronomeScreen(viewModel: viewModel),
      ),
    );

    // Inicia em 120 BPM (500ms por pulso)
    await tester.tap(find.byKey(const ValueKey('metronome_btn_play_pause')));
    await tester.pump();
    expect(viewModel.activeBeatIndex, equals(0));

    // Avança 500ms no relógio -> avança para o pulso 2 (índice 1)
    clockPort.advance(const Duration(milliseconds: 500));
    await tester.pump();
    expect(viewModel.activeBeatIndex, equals(1));
  });
}

