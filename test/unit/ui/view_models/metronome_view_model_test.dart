import 'package:beatly/domain/models/beat_emphasis.dart';
import 'package:beatly/domain/use_cases/calculate_tap_tempo_use_case.dart';
import 'package:beatly/ui/features/metronome/view_models/metronome_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_clock_port.dart';
import '../../../fakes/fake_metronome_audio_port.dart';

void main() {
  group('MetronomeViewModel (RF-01 / RF-02 / RF-03)', () {
    late FakeMetronomeAudioPort audioPort;
    late FakeClockPort clockPort;
    late MetronomeViewModel viewModel;

    setUp(() {
      audioPort = FakeMetronomeAudioPort();
      clockPort = FakeClockPort();
      viewModel = MetronomeViewModel(
        audioPort: audioPort,
        clockPort: clockPort,
        tapTempoUseCase: CalculateTapTempoUseCase(),
      );
    });

    tearDown(() {
      viewModel.dispose();
      clockPort.dispose();
    });

    test('TC-03.05: inicialização padrão em 120 BPM, compasso 4/4, subdivisão 1 e padrão [Forte, Normal, Normal, Normal]', () {
      expect(viewModel.bpm, equals(120));
      expect(viewModel.beatsPerBar, equals(4));
      expect(viewModel.beatUnit, equals(4));
      expect(viewModel.subdivision, equals(1));
      expect(viewModel.isPlaying, isFalse);
      expect(
        viewModel.beatPattern,
        equals([
          BeatEmphasis.forte,
          BeatEmphasis.normal,
          BeatEmphasis.normal,
          BeatEmphasis.normal,
        ]),
      );
      expect(viewModel.tempoMarking, equals('Allegro'));
    });

    test('TC-03.06: incrementBpm(5) eleva de 120 para 125 e atualiza audioPort quando ativo (B-RF-01.1)', () async {
      await viewModel.togglePlay();
      expect(audioPort.isPlaying, isTrue);
      expect(audioPort.currentBpm, equals(120));

      await viewModel.incrementBpm(5);
      expect(viewModel.bpm, equals(125));
      expect(audioPort.currentBpm, equals(125));
    });

    test('TC-03.07: incrementBpm(5) em 298 BPM trava rigorosamente em 300 BPM (B-RF-01.2)', () async {
      await viewModel.setBpm(298);
      await viewModel.incrementBpm(5);
      expect(viewModel.bpm, equals(300));
      expect(viewModel.canIncrementBpm, isFalse);
    });

    test('TC-03.08: decrementBpm(5) em 22 BPM trava rigorosamente em 20 BPM', () async {
      await viewModel.setBpm(22);
      await viewModel.decrementBpm(5);
      expect(viewModel.bpm, equals(20));
      expect(viewModel.canDecrementBpm, isFalse);
    });

    test('TC-03.09: cycleBeatEmphasis(1) alterna batida 2 entre Normal -> Fraco -> Mudo -> Forte (B-RF-03.1)', () async {
      expect(viewModel.beatPattern[1], equals(BeatEmphasis.normal));

      await viewModel.cycleBeatEmphasis(1);
      expect(viewModel.beatPattern[1], equals(BeatEmphasis.fraco));

      await viewModel.cycleBeatEmphasis(1);
      expect(viewModel.beatPattern[1], equals(BeatEmphasis.mudo));

      await viewModel.cycleBeatEmphasis(1);
      expect(viewModel.beatPattern[1], equals(BeatEmphasis.forte));
    });

    test('TC-03.10: togglePlay() aciona audioPort.start() quando parado e audioPort.stop() quando tocando', () async {
      await viewModel.togglePlay();
      expect(viewModel.isPlaying, isTrue);
      expect(audioPort.isPlaying, isTrue);

      await viewModel.togglePlay();
      expect(viewModel.isPlaying, isFalse);
      expect(audioPort.isPlaying, isFalse);
    });

    test('TC-03.11: alterar compasso (setBeatsPerBar) e subdivisão ajusta padrão e propaga para audioPort', () async {
      await viewModel.togglePlay();
      await viewModel.setBeatsPerBar(7);
      await viewModel.setBeatUnit(8);
      await viewModel.setSubdivision(2);

      expect(viewModel.beatsPerBar, equals(7));
      expect(viewModel.beatUnit, equals(8));
      expect(viewModel.subdivision, equals(2));
      expect(viewModel.beatPattern.length, equals(7));
      expect(audioPort.activePattern.length, equals(7));
      expect(audioPort.activeSubdivision, equals(2));
    });
  });
}

