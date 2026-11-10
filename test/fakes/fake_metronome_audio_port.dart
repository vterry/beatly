import 'package:beatly/domain/contracts/metronome_audio_port.dart';
import 'package:beatly/domain/models/beat_emphasis.dart';

/// Implementação em memória de [MetronomeAudioPort] para TDD sem hardware de som (ADR-002).
class FakeMetronomeAudioPort implements MetronomeAudioPort {
  bool isInitialized = false;
  bool isPlaying = false;
  int? currentBpm;
  List<BeatEmphasis> activePattern = const [];
  int activeSubdivision = 1;
  int playedChimesCount = 0;
  double? lastChimeVolume;
  String? lastChimeSoundName;
  final List<String> playedChimes = [];
  bool isDisposed = false;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<void> start({
    required int bpm,
    required List<BeatEmphasis> pattern,
    int subdivision = 1,
  }) async {
    isPlaying = true;
    currentBpm = bpm;
    activePattern = List<BeatEmphasis>.unmodifiable(pattern);
    activeSubdivision = subdivision;
  }

  @override
  Future<void> updateBpm(int bpm) async {
    currentBpm = bpm;
  }

  @override
  Future<void> updatePattern(
    List<BeatEmphasis> pattern, {
    int subdivision = 1,
  }) async {
    activePattern = List<BeatEmphasis>.unmodifiable(pattern);
    activeSubdivision = subdivision;
  }

  @override
  Future<void> stop() async {
    isPlaying = false;
  }

  @override
  Future<void> playTransitionChime({
    double volume = 0.8,
    String soundName = 'chime_zen',
  }) async {
    playedChimesCount += 1;
    lastChimeVolume = volume;
    lastChimeSoundName = soundName;
    playedChimes.add(soundName);
  }

  @override
  Future<void> playChime({
    String soundName = 'chime_zen',
    double volume = 0.8,
  }) async {
    await playTransitionChime(volume: volume, soundName: soundName);
  }

  @override
  Future<void> dispose() async {
    isPlaying = false;
    isDisposed = true;
  }
}

