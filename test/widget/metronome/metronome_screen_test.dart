import 'package:beatly/domain/models/beat_emphasis.dart';
import 'package:beatly/ui/core/theme/obsidian_theme.dart';
import 'package:beatly/ui/features/metronome/view_models/metronome_view_model.dart';
import 'package:beatly/ui/features/metronome/views/metronome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_clock_port.dart';
import '../../fakes/fake_metronome_audio_port.dart';

void main() {
  group('MetronomeScreen Widget Tests (WTC-03)', () {
    late FakeMetronomeAudioPort audioPort;
    late FakeClockPort clockPort;
    late MetronomeViewModel viewModel;

    setUp(() {
      audioPort = FakeMetronomeAudioPort();
      clockPort = FakeClockPort();
      viewModel = MetronomeViewModel(
        audioPort: audioPort,
        clockPort: clockPort,
      );
    });

    tearDown(() {
      viewModel.dispose();
      clockPort.dispose();
    });

    Widget buildTestWidget() {
      return MaterialApp(
        theme: ObsidianTheme.darkTheme,
        home: MetronomeScreen(viewModel: viewModel),
      );
    }

    testWidgets('WTC-03.01: clicar em metronome_btn_play_pause alterna execução no ViewModel e AudioPort', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final playBtn = find.byKey(const ValueKey('metronome_btn_play_pause'));
      expect(playBtn, findsOneWidget);
      expect(viewModel.isPlaying, isFalse);

      await tester.tap(playBtn);
      await tester.pump();

      expect(viewModel.isPlaying, isTrue);
      expect(audioPort.isPlaying, isTrue);

      await tester.tap(playBtn);
      await tester.pump();

      expect(viewModel.isPlaying, isFalse);
      expect(audioPort.isPlaying, isFalse);
    });

    testWidgets('WTC-03.02: clicar nos botões de canto |◀ e ▶| altera o BPM exibido', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('120'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('metronome_bpm_plus_1')));
      await tester.pump();
      expect(find.text('121'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('metronome_bpm_minus_1')));
      await tester.pump();
      expect(find.text('120'), findsOneWidget);
    });

    testWidgets('WTC-03.03: clicar em beat_emphasis_item_1 cicla o estado de volume do pulso 2', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final beatFinder = find.byKey(const ValueKey('beat_emphasis_item_1'));
      await tester.ensureVisible(beatFinder);
      await tester.pumpAndSettle();

      expect(viewModel.beatPattern[1], equals(BeatEmphasis.normal));

      await tester.tap(beatFinder);
      await tester.pump();
      expect(viewModel.beatPattern[1], equals(BeatEmphasis.fraco));

      await tester.tap(beatFinder);
      await tester.pump();
      expect(viewModel.beatPattern[1], equals(BeatEmphasis.mudo));
    });

    testWidgets('WTC-03.04: tocar 4 vezes em metronome_btn_tap_tempo com intervalos de 600ms calcula 100 BPM', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final tapBtn = find.byKey(const ValueKey('metronome_btn_tap_tempo'));
      for (var i = 0; i < 4; i++) {
        await tester.tap(tapBtn);
        clockPort.advance(const Duration(milliseconds: 600));
        await tester.pump();
      }

      expect(viewModel.bpm, equals(100));
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('WTC-03.05: painel de Divisão do tempo altera compasso e subdivisão em tempo real', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('4/4 • 1x'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('beats_per_bar_plus')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('beat_unit_8')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('subdivision_card_3')));
      await tester.pump();

      expect(find.text('5/8 • 3x'), findsOneWidget);
      expect(viewModel.beatPattern.length, equals(5));
    });
  });
}
