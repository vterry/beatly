import 'package:beatly/app.dart';
import 'package:beatly/data/repositories/drift_routine_repository.dart';
import 'package:beatly/data/repositories/drift_session_repository.dart';
import 'package:beatly/data/repositories/drift_settings_repository.dart';
import 'package:beatly/ui/features/evolution_map/widgets/radar_chart_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_clock_port.dart';
import '../fakes/fake_metronome_audio_port.dart';
import '../fakes/in_memory_app_database.dart';

void main() {
  final initialDateTime = DateTime.utc(2026, 11, 8, 10, 0, 0);

  testWidgets(
    'ITC-08.01: Fluxo E2E Completo do Aplicativo (Criar rotina -> Executar com metrônomo -> Transição -> Concluir -> Mapa de Evolução)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Inicia BeatlyApp conectado ao Drift em memória, FakeClockPort e FakeMetronomeAudioPort
      final db = createInMemoryAppDatabase();
      final routineRepo = DriftRoutineRepository(database: db);
      final sessionRepo = DriftSessionRepository(database: db);
      final settingsRepo = DriftSettingsRepository(database: db);
      final clockPort = FakeClockPort(initialTime: initialDateTime);
      final audioPort = FakeMetronomeAudioPort();

      await tester.pumpWidget(
        BeatlyApp(
          routineRepository: routineRepo,
          sessionRepository: sessionRepo,
          settingsRepository: settingsRepo,
          clockPort: clockPort,
          audioPort: audioPort,
        ),
      );
      await tester.pumpAndSettle();

      // 2. Navega para a aba Rotinas
      final routinesTab = find.byKey(const ValueKey('nav_tab_routines'));
      expect(routinesTab, findsOneWidget);
      await tester.tap(routinesTab);
      await tester.pumpAndSettle();

      // 3. Cria uma nova rotina "Treino Diário" com 2 atividades
      await tester.tap(find.byKey(const ValueKey('routine_btn_create')));
      await tester.pumpAndSettle();

      // Nome da Rotina
      await tester.enterText(
        find.byKey(const ValueKey('routine_input_name')),
        'Treino Diário',
      );

      // Atividade 1: Aquecimento, Técnica, 15s, 120 BPM, autoStartMetronome: true
      await tester.enterText(
        find.byKey(const ValueKey('activity_input_name')),
        'Aquecimento',
      );
      await tester.enterText(
        find.byKey(const ValueKey('activity_input_duration')),
        '15s',
      );
      await tester.enterText(
        find.byKey(const ValueKey('activity_input_bpm')),
        '120',
      );
      await tester.pump();

      final autostartSwitch = find.byKey(
        const ValueKey('activity_switch_autostart'),
      );
      await tester.ensureVisible(autostartSwitch);
      await tester.tap(autostartSwitch);
      await tester.pump();

      final addActivityBtn = find.byKey(
        const ValueKey('activity_btn_add'),
      );
      await tester.ensureVisible(addActivityBtn);
      await tester.tap(addActivityBtn);
      await tester.pumpAndSettle();

      // Atividade 2: Velocidade Extrema, Velocidade, 10s, 160 BPM, autoStartMetronome: true
      await tester.enterText(
        find.byKey(const ValueKey('activity_input_name')),
        'Velocidade Extrema',
      );

      // Seleciona Categoria Velocidade
      final catVelocidadeChip = find.byKey(
        const ValueKey('category_chip_velocidade'),
      );
      await tester.ensureVisible(catVelocidadeChip);
      await tester.tap(catVelocidadeChip);
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey('activity_input_duration')),
        '10s',
      );
      await tester.enterText(
        find.byKey(const ValueKey('activity_input_bpm')),
        '160',
      );
      await tester.pump();

      await tester.ensureVisible(autostartSwitch);
      await tester.tap(autostartSwitch);
      await tester.pump();

      await tester.ensureVisible(addActivityBtn);
      await tester.tap(addActivityBtn);
      await tester.pumpAndSettle();

      // Salva a rotina
      await tester.tap(find.byKey(const ValueKey('routine_btn_save')));
      await tester.pumpAndSettle();

      expect(find.text('Treino Diário'), findsOneWidget);

      // 4. Inicia a rotina
      final startRoutineBtn = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('routine_start_'),
      );
      expect(startRoutineBtn, findsOneWidget);
      await tester.tap(startRoutineBtn);
      await tester.pumpAndSettle();

      // 5. Verifica PreparationOverlay (5s)
      expect(
        find.byKey(const ValueKey('execution_prep_overlay')),
        findsOneWidget,
      );

      // Avança 5s no fakeClock
      clockPort.advance(const Duration(seconds: 5));
      await tester.pump();

      // 6. Valida execução da Atividade 1 com metrônomo ativo (120 BPM)
      expect(find.text('Aquecimento'), findsOneWidget);
      expect(audioPort.isPlaying, isTrue);
      expect(audioPort.currentBpm, equals(120));

      // 7. Avança 15s no FakeClockPort e valida TransitionCountdownOverlay + disparo do chime
      clockPort.advance(const Duration(seconds: 15));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('execution_transition_overlay')),
        findsOneWidget,
      );
      expect(audioPort.playedChimesCount, greaterThanOrEqualTo(1));

      // 8. Clica em transition_btn_skip_now para iniciar Atividade 2 imediatamente
      await tester.tap(find.byKey(const ValueKey('transition_btn_skip_now')));
      await tester.pump();

      expect(find.text('Velocidade Extrema'), findsOneWidget);
      expect(audioPort.isPlaying, isTrue);
      expect(audioPort.currentBpm, equals(160));

      // 9. Avança 10s no FakeClockPort e valida auto-conclusão e Gráfico de Teia pentagonal
      clockPort.advance(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('execution_completed_view')),
        findsOneWidget,
      );
      expect(find.byType(PentagonRadarChart), findsOneWidget);

      // 10. Fecha a tela de conclusão e navega para a aba Evolução
      await tester.tap(
        find.byKey(const ValueKey('execution_completed_btn_close')),
      );
      await tester.pumpAndSettle();

      final evolutionTab = find.byKey(const ValueKey('nav_tab_evolution'));
      expect(evolutionTab, findsOneWidget);
      await tester.tap(evolutionTab);
      await tester.pumpAndSettle();

      // Valida resumo mensal com 1 sessão concluída e 25s totais praticados
      expect(find.text('1'), findsWidgets);
      expect(find.text('25s'), findsWidgets);

      clockPort.dispose();
      await db.close();
    },
  );
}

