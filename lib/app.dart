import 'package:flutter/material.dart';

import 'data/services/audio/native_metronome_audio_service.dart';
import 'data/services/audio/pcm_sound_cache.dart';
import 'data/services/clock/system_monotonic_clock_service.dart';
import 'domain/contracts/clock_port.dart';
import 'domain/contracts/metronome_audio_port.dart';
import 'domain/contracts/routine_repository.dart';
import 'domain/contracts/session_repository.dart';
import 'domain/contracts/settings_repository.dart';
import 'domain/models/app_settings.dart';
import 'domain/models/routine.dart';
import 'domain/models/routine_execution_state.dart';
import 'domain/state_machines/routine_execution_coordinator.dart';
import 'domain/state_machines/speed_challenge_coordinator.dart';
import 'ui/core/constants/app_colors.dart';
import 'ui/core/theme/obsidian_theme.dart';
import 'ui/core/widgets/app_scaffold.dart';
import 'ui/core/widgets/obsidian_card.dart';
import 'ui/features/evolution_map/view_models/evolution_map_view_model.dart';
import 'ui/features/evolution_map/views/evolution_map_screen.dart';
import 'ui/features/metronome/view_models/metronome_view_model.dart';
import 'ui/features/metronome/view_models/speed_challenge_view_model.dart';
import 'ui/features/metronome/views/metronome_screen.dart';
import 'ui/features/routine_execution/view_models/routine_execution_view_model.dart';
import 'ui/features/routine_execution/views/routine_execution_screen.dart';
import 'ui/features/routine_management/view_models/routine_list_view_model.dart';
import 'ui/features/routine_management/views/routine_list_screen.dart';
import 'ui/features/settings/view_models/settings_view_model.dart';
import 'ui/features/settings/views/settings_screen.dart';

/// Widget raiz do aplicativo Beatly (Standalone Android).
class BeatlyApp extends StatefulWidget {
  const BeatlyApp({
    super.key,
    this.routineRepository,
    this.sessionRepository,
    this.settingsRepository,
    this.clockPort,
    this.audioPort,
  });

  final RoutineRepository? routineRepository;
  final SessionRepository? sessionRepository;
  final SettingsRepository? settingsRepository;
  final ClockPort? clockPort;
  final MetronomeAudioPort? audioPort;

  @override
  State<BeatlyApp> createState() => _BeatlyAppState();
}

class _BeatlyAppState extends State<BeatlyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final ClockPort _clockPort;
  late final MetronomeAudioPort _audioPort;

  late final MetronomeViewModel _metronomeVm;
  late final SpeedChallengeViewModel _challengeVm;
  late final RoutineListViewModel _routineListVm;
  late final EvolutionMapViewModel _evolutionVm;
  late final SettingsViewModel _settingsVm;

  int _currentTabIndex = 0;
  bool _isConfigured = false;

  RoutineExecutionViewModel? _activeExecutionVm;
  Routine? _activeRoutine;

  @override
  void initState() {
    super.initState();

    final isFullShell =
        widget.routineRepository != null &&
        widget.sessionRepository != null &&
        widget.settingsRepository != null;

    if (isFullShell) {
      _clockPort = widget.clockPort ?? SystemMonotonicClockService();
      _audioPort =
          widget.audioPort ??
          NativeMetronomeAudioService(
            soundCache: PcmSoundCache(),
            clockPort: _clockPort,
          );

      _metronomeVm = MetronomeViewModel(
        audioPort: _audioPort,
        clockPort: _clockPort,
      );

      _challengeVm = SpeedChallengeViewModel(
        coordinator: SpeedChallengeCoordinator(
          clockPort: _clockPort,
          audioPort: _audioPort,
          onBpmChanged: (newBpm) {
            _metronomeVm.setBpm(newBpm);
          },
        ),
      );

      _routineListVm = RoutineListViewModel(
        repository: widget.routineRepository!,
      );

      _evolutionVm = EvolutionMapViewModel(
        sessionRepository: widget.sessionRepository!,
        initialYear: _clockPort.now().year,
        initialMonth: _clockPort.now().month,
      );

      _settingsVm = SettingsViewModel(
        repository: widget.settingsRepository!,
        audioPort: _audioPort,
      );

      _isConfigured = true;

      _routineListVm.loadRoutines();
      _evolutionVm.loadMonth();
      _settingsVm.loadSettings();
    }
  }

  @override
  void dispose() {
    if (_isConfigured) {
      _activeExecutionVm?.dispose();
      _activeExecutionVm = null;
      _metronomeVm.dispose();
      _challengeVm.dispose();
      _routineListVm.dispose();
      _evolutionVm.dispose();
      _settingsVm.dispose();
    }
    super.dispose();
  }

  String _mapAlertSound(TransitionAlertSound sound) {
    return switch (sound) {
      TransitionAlertSound.zenChime => 'chime_zen',
      TransitionAlertSound.softMarimba => 'chime_marimba',
      TransitionAlertSound.meditativeGong => 'chime_gong',
      TransitionAlertSound.muteHapticOnly => 'mute',
    };
  }

  Future<void> _handleStartRoutine(Routine routine) async {
    final settings = _settingsVm.settings;
    final chimeKey = _mapAlertSound(settings.transitionAlertSound);

    // Se já houver um treino da mesma rotina não finalizado, retoma-o diretamente
    if (_activeExecutionVm != null &&
        _activeRoutine?.id == routine.id &&
        !_activeExecutionVm!.isFinished) {
      final navigator = _navigatorKey.currentState;
      if (navigator != null) {
        await navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => RoutineExecutionScreen(
              viewModel: _activeExecutionVm!,
              routine: routine,
              preparationSeconds: 0,
              transitionSeconds: settings.transitionCountdownSeconds,
              transitionChime: chimeKey,
              transitionVolume: settings.transitionAlertVolume,
              keepScreenAwake: settings.keepScreenAwake,
              hapticOnTransition: settings.hapticOnTransition,
            ),
          ),
        );
      }
      if (_activeExecutionVm!.isFinished) {
        _activeExecutionVm?.dispose();
        _activeExecutionVm = null;
        _activeRoutine = null;
      }
      setState(() {});
      await _evolutionVm.loadMonth();
      return;
    }

    // Se havia outra rotina rodando, cancela e descarta a anterior para evitar vazamento
    if (_activeExecutionVm != null) {
      await _activeExecutionVm!.cancelRoutine();
      _activeExecutionVm!.dispose();
      _activeExecutionVm = null;
      _activeRoutine = null;
    }

    final execVm = RoutineExecutionViewModel(
      coordinator: RoutineExecutionCoordinator(
        clockPort: _clockPort,
        audioPort: _audioPort,
        sessionRepository: widget.sessionRepository!,
      ),
    );

    setState(() {
      _activeExecutionVm = execVm;
      _activeRoutine = routine;
    });

    final navigator = _navigatorKey.currentState;
    if (navigator != null) {
      await navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => RoutineExecutionScreen(
            viewModel: execVm,
            routine: routine,
            preparationSeconds: 5,
            transitionSeconds: settings.transitionCountdownSeconds,
            transitionChime: chimeKey,
            transitionVolume: settings.transitionAlertVolume,
            keepScreenAwake: settings.keepScreenAwake,
            hapticOnTransition: settings.hapticOnTransition,
          ),
        ),
      );
    }

    if (execVm.isFinished) {
      execVm.dispose();
      setState(() {
        _activeExecutionVm = null;
        _activeRoutine = null;
      });
    } else {
      setState(() {});
    }
    await _evolutionVm.loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConfigured) {
      return MaterialApp(
        title: 'Beatly',
        debugShowCheckedModeBanner: false,
        theme: ObsidianTheme.darkTheme,
        home: const AppScaffold(
          title: 'Beatly',
          body: ObsidianCard(
            key: ValueKey('beatly_home_card'),
            child: Text('Beatly — Metrônomo & Rotina de Estudos'),
          ),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Beatly',
      debugShowCheckedModeBanner: false,
      theme: ObsidianTheme.darkTheme,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentTabIndex,
          children: [
            MetronomeScreen(
              viewModel: _metronomeVm,
              challengeViewModel: _challengeVm,
            ),
            RoutineListScreen(
              viewModel: _routineListVm,
              repository: widget.routineRepository!,
              onStartRoutine: _handleStartRoutine,
            ),
            EvolutionMapScreen(viewModel: _evolutionVm),
            SettingsScreen(viewModel: _settingsVm),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_activeExecutionVm != null && !_activeExecutionVm!.isFinished)
              ListenableBuilder(
                listenable: _activeExecutionVm!,
                builder: (context, _) {
                  if (_activeExecutionVm == null ||
                      _activeExecutionVm!.isFinished) {
                    return const SizedBox.shrink();
                  }
                  final state = _activeExecutionVm!.state;
                  final activityDesc = switch (state) {
                    final ExecutionStateRunning r => r.currentActivity.name,
                    final ExecutionStatePaused p =>
                      '${p.currentActivity.name} (Pausado)',
                    final ExecutionStateTransitioning t =>
                      'Transição para ${t.nextActivity.name}',
                    ExecutionStatePreparing _ => 'Preparação inicial',
                    _ => 'Treino em andamento',
                  };

                  return Container(
                    key: const ValueKey('active_routine_banner'),
                    margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.violet, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violet.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: AppColors.violetLight,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _activeRoutine?.name ?? 'Rotina em andamento',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                activityDesc,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          key: const ValueKey('btn_resume_active_routine'),
                          onPressed: () =>
                              _handleStartRoutine(_activeRoutine!),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text('Retomar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.violet,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            Theme(
              data: ThemeData(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                currentIndex: _currentTabIndex,
                onTap: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });
                  if (index == 2) {
                    _evolutionVm.loadMonth();
                  }
                },
                backgroundColor: AppColors.surface,
                selectedItemColor: AppColors.violetLight,
                unselectedItemColor: AppColors.textMuted,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.speed_rounded,
                      key: ValueKey('nav_tab_metronome'),
                    ),
                    label: 'Metrônomo',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.playlist_play_rounded,
                      key: ValueKey('nav_tab_routines'),
                    ),
                    label: 'Rotinas',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.insights_rounded,
                      key: ValueKey('nav_tab_evolution'),
                    ),
                    label: 'Evolução',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.tune_rounded,
                      key: ValueKey('nav_tab_settings'),
                    ),
                    label: 'Ajustes',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
