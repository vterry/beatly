# Histórico de Evolução do Projeto Beatly

Este documento registra a evolução incremental de cada etapa do projeto **Beatly**, preservando as decisões tomadas e aprovadas pelo **Piloto** sem poluir o contexto.

---

## Status Geral das Etapas de Refinamento

- [x] **Etapa 1: Refinamento de Requisitos (`SPEC.md`)** — *Concluída e Aprovada pelo Piloto (v1.1.0)*
- [x] **Etapa 2: Refinamento de Arquitetura (`ADR.md`)** — *Concluída e Aprovada pelo Piloto (v1.0.0)*
- [x] **Etapa 3: Refinamento da Implementação (`IMPLEMENTATION_MAP.md`)** — *Concluída e Aprovada pelo Piloto (v1.0.0)*
- [x] **Etapa 4: Experiência do Usuário (Exemplos de Telas - Tema Obsidian Dark)** — *Concluída e Aprovada pelo Piloto*
- [x] **Etapa 5: Criação do Logotipo do Aplicativo** — *Aprovada pelo Piloto: opção B ("B" com onda sonora e pêndulo), salva em `assets/logo/beatly_app_logo_final.jpg`*

---

## Registro de Iterações

### Iteração 01 — Refinamento de Requisitos (`SPEC.md`)
- **Data**: 2026-11-08
- **Agente Executor**: `product-spec-analyst` (Modelo: `flash`)
- **Entregável**: `/home/souza/projects/beatly/SPEC.md`
- **Resumo**: Especificação funcional detalhada (Módulos 1 a 4), matriz de casos de borda, critérios BDD/TDD e validações do Piloto (v1.1.0).
- **Status**: Aprovado pelo Piloto.

### Iteração 02 — Refinamento de Arquitetura (`ADR.md`)
- **Data**: 2026-11-08
- **Agente Executor**: `software-architect`
- **Entregável**: `/home/souza/projects/beatly/ADR.md`
- **Resumo do que foi estruturado**:
  - **Arquitetura em Camadas (MVVM + Repository + Domain Puro)**: Aderente à skill oficial Flutter (`flutter-apply-architecture-best-practices`) com injeção explícita por construtor para suporte integral a TDD.
  - **ADR-001 a ADR-008**:
    - **ADR-001**: Arquitetura em camadas e Injeção de Dependências sem framework externo acoplado.
    - **ADR-002**: Driver de áudio nativo de baixa latência Android (`MetronomeAudioPort`, PCM pré-carregado em RAM / AAudio) com `FakeMetronomeAudioPort` para testes determinísticos sem placa de som.
    - **ADR-003**: Máquina de Estados da Rotina (`RoutineExecutionCoordinator`) com relógio monotônico injetável (`ClockPort` / `FakeClockPort`), suportando contagem regressiva inicial de 5s, auto-conclusão ao término, botão **Concluir** (salva progresso parcial e abre Gráfico de Teia) e botão **Cancelar** (descarta todo o progresso).
    - **ADR-004**: Persistência 100% Standalone com **Drift (SQLite)**, modelagem com 5 tabelas relacionais (`routines`, `routine_activities`, `study_sessions`, `session_category_logs`, `app_settings`), queries analíticas para Resumo Mensal e suporte a `NativeDatabase.memory()`.
    - **ADR-005**: Gráfico de Teia (Radar Chart) Pentagonal com cálculo matemático/trigonométrico puro desacoplado em `CalculateRadarGeometryUseCase` (100% de cobertura em testes unitários) e `RadarChartPainter` nativo via `CustomPainter`.
    - **ADR-006**: Wakelock e Android Foreground Service com notificação persistente para resistência em segundo plano e tratamento de `AudioFocus`.
    - **ADR-007**: Pirâmide de testes orientada a TDD (Unitários em Dart puro 70%, Widgets 20%, Integração 10%).
    - **ADR-008**: Design System "Obsidian Dark" (paleta `#0F0F10`, `#1A1A1C`, acentos `#7C3AED` e `#F59E0B`, fontes monoespaçadas para métricas).
  - **Diagramas Mermaid**: Diagrama de Componentes em Camadas, Diagrama Entidade-Relacionamento (`erDiagram`) do Drift e Diagrama de Sequência (`sequenceDiagram`) da rotina completa.
  - **Estrutura de Diretórios**: Mapeamento completo e espelhado de código e testes (`test/unit`, `test/widget`, `test/fakes`, `integration_test`).
- **Status**: Aprovado pelo Piloto.

### Iteração 03 — Refinamento da Implementação (`IMPLEMENTATION_MAP.md`)
- **Data**: 2026-11-08
- **Agente Executor**: `tech-lead-tdd`
- **Entregável**: `/home/souza/projects/beatly/IMPLEMENTATION_MAP.md`
- **Resumo do que foi estruturado**:
  - **Loop de Implementação TDD Estrito**: Mapeamento operacional em 8 passos (Red $\rightarrow$ Green $\rightarrow$ Refactor $\rightarrow$ Widget/Integração $\rightarrow$ DoD Piloto $\rightarrow$ Code Review com `dart analyze` $\rightarrow$ Homologação).
  - **Decomposição em 8 Tarefas Incrementais e Atômicas**:
    - **TASK-01**: Setup do Projeto Flutter (Android Standalone), Tokens Visuais Obsidian Dark, Contratos Base (`ClockPort`, `MetronomeAudioPort`) e Fakes em Memória (`FakeClockPort`, `FakeMetronomeAudioPort`).
    - **TASK-02**: Camada de Persistência Local Standalone com Drift (SQLite) — Tabelas relacionais com FKs CASCADE/NULL, DAOs analíticos e repositórios (`DriftRoutineRepository`, `DriftSessionRepository`, `DriftSettingsRepository`) com suporte a testes em `NativeDatabase.memory()`.
    - **TASK-03**: Motor de Domínio e ViewModel do Metrônomo (BPM 20 a 300, algoritmo de Tap Tempo com média móvel de 4 toques, fórmula de compasso de 1 a 16 batidas, 4 estados cíclicos de ênfase por pulso e LEDs virtuais sincronizados).
    - **TASK-04**: Modo Desafio (Speed Trainer) — `SpeedChallengeCoordinator`, validações de $BPM_{min} < BPM_{max}$, incremento por compassos ou tempo, comportamento no teto (Manter vs Concluir) e UI Bottom Sheet com velocímetro.
    - **TASK-05**: Gestão de Rotinas e Atividades (CRUD) — 5 categorias fechadas e canônicas (`Técnica`, `Velocidade`, `Teoria Musical`, `Improviso`, `Free Style`), cálculo de duração total dinâmica, regra de dependência de BPM para `autoStartMetronome`, reordenação e telas de listagem e editor.
    - **TASK-06**: Máquina de Estados da Execução (`RoutineExecutionCoordinator`) e Tela de Foco — Preparação inicial (5s), transição suave com aviso sonoro (chime zen) e contador (default 5s) com botão "Iniciar Agora", auto-start de metrônomo, **Conclusão Automática**, botão **Concluir** (salva progresso parcial e abre resultados) e botão **Cancelar** (descarta/ignora todo o progresso).
    - **TASK-07**: Mapa de Evolução (Analytics Local) — Cálculo trigonométrico puro desacoplado em `CalculateRadarGeometryUseCase`, `RadarChartPainter` nativo pentagonal via `CustomPainter` minimalista Obsidian Dark, diálogo pós-rotina e Resumo Mensal consolidado com mapa de consistência.
    - **TASK-08**: Configurações Gerais, Motor de Áudio Nativo Android (PCM/AAudio de baixa latência < 5ms de jitter), Wakelock e suíte E2E automatizada (`routine_full_lifecycle_flow_test.dart`).
  - **Diagrama Mermaid de Dependências**: Fluxograma relacionando os pré-requisitos entre as tarefas.
  - **Matriz de Rastreabilidade**: Mapeamento 1:1 entre RFs, RNFs, ADRs, Casos de Borda e as tarefas.
  - **Especificação de Testes**: Lista detalhada de casos de testes unitários (Red) e testes de widget/integração com `ValueKey`s padronizados para cada tarefa.
- **Status**: Aprovado pelo Piloto.

### Iteração 04 — Ciclo 1 do Loop de Implementação (`TASK-01`)
- **Data**: 2026-11-08
- **Entregáveis**:
  - Setup do projeto Flutter Android Standalone (`pubspec.yaml`, `analysis_options.yaml` com strict mode).
  - Modelos/Enums de Domínio: `lib/domain/models/beat_emphasis.dart`, `lib/domain/models/activity_category.dart`.
  - Contratos/Portas de Domínio: `lib/domain/contracts/clock_port.dart`, `lib/domain/contracts/metronome_audio_port.dart`.
  - Fakes determinísticos para TDD: `test/fakes/fake_clock_port.dart`, `test/fakes/fake_metronome_audio_port.dart`.
  - Design System Obsidian Dark: `lib/ui/core/constants/app_colors.dart`, `app_dimensions.dart`, `app_typography.dart`, `lib/ui/core/theme/obsidian_theme.dart`.
  - Componentes Base: `lib/ui/core/widgets/obsidian_button.dart` (incluindo variante `subtleLink` discreta para o botão de cancelar rotina), `obsidian_card.dart`, `app_scaffold.dart`, `lib/app.dart`.
  - Testes Unitários, de Widget e de Integração: 15 testes passando (`test/unit/`, `test/widget/`, `integration_test/task01_smoke_test.dart`) e `dart analyze` sem erros.
- **Status**: Concluído e Aprovado pelo Piloto.

### Iteração 05 — Ciclo 2 do Loop de Implementação (`TASK-02`)
- **Data**: 2026-11-08
- **Entregáveis**:
  - Modelos de Domínio e Contratos de Persistência: `Routine`, `RoutineActivity` (com regra de dependência de BPM para `autoStartMetronome`), `StudySession`, `SessionCategoryLog`, `AppSettings`, `RoutineRepository`, `SessionRepository`, `SettingsRepository`.
  - Camada de Persistência Local Standalone com Drift / SQLite (`lib/data/datasources/local/app_database.dart`):
    - 5 tabelas relacionais (`routines`, `routine_activities`, `study_sessions`, `session_category_logs`, `app_settings`) com `PRAGMA foreign_keys = ON`.
    - Integridade referencial: `ON DELETE CASCADE` para atividades de uma rotina e logs de uma sessão; `ON DELETE SET NULL` em `study_sessions.routine_id` preservando o histórico mensal quando uma rotina é excluída.
    - DAOs parametrizados (100% imunes a SQL Injection): `RoutineDao`, `SessionDao`, `SettingsDao`.
    - Mappers e Repositórios: `DriftRoutineRepository`, `DriftSessionRepository`, `DriftSettingsRepository`.
  - Testes Unitários e de Integração em Memória (`NativeDatabase.memory()`): `26/26` testes passando (`TC-02.01` a `TC-02.09` + DAOs + integração) e `dart analyze` sem erros.
- **Status**: Concluído e Aprovado pelo Piloto.

### Iteração 06 — Ciclo 3 do Loop de Implementação (`TASK-03`)
- **Data**: 2026-11-08
- **Entregáveis**:
  - Domínio e Use Case do Metrônomo: [`CalculateTapTempoUseCase`](file:///home/souza/projects/beatly/lib/domain/use_cases/calculate_tap_tempo_use_case.dart) (média móvel de 4 toques, janela 200ms–3000ms) e [`MetronomeConfig`](file:///home/souza/projects/beatly/lib/domain/models/metronome_config.dart) (BPM 20–300, compasso 1–16 / 2,4,8,16, subdivisões 1x–4x e padrão de pulsos).
  - ViewModel reativo: [`MetronomeViewModel`](file:///home/souza/projects/beatly/lib/ui/features/metronome/view_models/metronome_view_model.dart) integrado com `MetronomeAudioPort` e `ClockPort` para sincronismo visual de LEDs.
  - Widgets e Tela do Metrônomo no Tema Obsidian Dark:
    - [`RotaryBpmDial`](file:///home/souza/projects/beatly/lib/ui/features/metronome/widgets/rotary_bpm_dial.dart): Roda giratória central interativa + 4 botões nos cantos (`|◀`, `▶|`, `▶/⏸`, `TAP`) conforme imagem de referência do Piloto.
    - [`TimeDivisionPanel`](file:///home/souza/projects/beatly/lib/ui/features/metronome/widgets/time_division_panel.dart): Painel unificado de Compasso (numerador 1–16 e denominador 2/4/8/16) e 4 cartões visuais de Subdivisão (`Pulso`, `Colcheias`, `Tercina`, `Semicol.`).
    - [`BeatStripSelector`](file:///home/souza/projects/beatly/lib/ui/features/metronome/widgets/beat_strip_selector.dart) e [`PulseLedIndicator`](file:///home/souza/projects/beatly/lib/ui/core/widgets/pulse_led_indicator.dart): Colunas de volume por pulso (`Forte`, `Normal`, `Fraco`, `Mudo`), pontinhos de subdivisão, atalhos `Padrão`/`Mudo` e LED sincronizado.
    - [`MetronomeScreen`](file:///home/souza/projects/beatly/lib/ui/features/metronome/views/metronome_screen.dart).
  - Testes Unitários, de Widget e de Integração: `42/42` testes passando (`TC-03.01` a `TC-03.11`, `WTC-03.01` a `WTC-03.05`, `ITC-03.01`) e `dart analyze` sem erros.
- **Status**: Concluído e Aprovado pelo Piloto.

### Iteração 07 — Ciclo 4 do Loop de Implementação (`TASK-04`)
- **Data**: 2026-11-08
- **Entregáveis**:
  - Domínio e Use Case do Modo Desafio (Speed Trainer):
    - [`SpeedChallengeConfig`](file:///home/souza/projects/beatly/lib/domain/models/speed_challenge_config.dart): Configuração imutável com `startBpm`, `targetBpm`, `bpmStep`, `triggerMode` (`byBars` / `byDuration`), `everyBars`, `everySeconds` e `onTargetReached` (`keepRunning` / `stopAndChime`).
    - [`ValidateSpeedChallengeUseCase`](file:///home/souza/projects/beatly/lib/domain/use_cases/validate_speed_challenge_use_case.dart): Validação pura de limites (`EC-01`: $BPM_{min} < BPM_{max}$, $\Delta BPM > 0$ e $\Delta BPM \le BPM_{max} - BPM_{min}$).
    - [`SpeedChallengeCoordinator`](file:///home/souza/projects/beatly/lib/domain/state_machines/speed_challenge_coordinator.dart): Máquina de estados de progressão rítmica integrada ao `MetronomeAudioPort` e `ClockPort`, aplicando travamento exato no teto (`EC-02`) e comportamento configurável ao atingir a meta (`keepRunning` ou `stopAndChime` com chime suave).
  - ViewModel e UI no Tema Obsidian Dark:
    - [`SpeedChallengeViewModel`](file:///home/souza/projects/beatly/lib/ui/features/metronome/view_models/speed_challenge_view_model.dart): Gerenciamento reativo do formulário, cálculo de `progressRatio` e controle de início/parada.
    - [`SpeedChallengeBottomSheet`](file:///home/souza/projects/beatly/lib/ui/features/metronome/views/speed_challenge_bottom_sheet.dart) e integração de cabeçalho na [`MetronomeScreen`](file:///home/souza/projects/beatly/lib/ui/features/metronome/views/metronome_screen.dart).
  - Testes Unitários, de Widget e de Integração: `52/52` testes passando na suíte completa (`TC-04.01` a `TC-04.07`, `WTC-04.01`, `WTC-04.02`, `task04_speed_challenge_integration_test.dart`) e `dart analyze` sem erros.
- **Status**: Concluído e Aprovado pelo Piloto.

### Iteração 08 — Ciclo 5 do Loop de Implementação (`TASK-05`)
- **Data**: 2026-11-08
- **Entregáveis**:
  - Domínio e Utilitários:
    - [`IdGenerator`](file:///home/souza/projects/beatly/lib/domain/use_cases/id_generator.dart): Gerador puro de UUID v4 RFC-4122 sem dependências externas.
    - [`Routine`](file:///home/souza/projects/beatly/lib/domain/models/routine.dart) e [`RoutineActivity`](file:///home/souza/projects/beatly/lib/domain/models/routine_activity.dart): Cálculo dinâmico de `totalEstimatedDurationSeconds` ($\sum \text{atividades} + (N-1) \times \text{transições}$, respeitando `EC-04` para 1 atividade) e regra obrigatória de BPM para `autoStartMetronome` (`EC-03`).
  - ViewModels:
    - [`RoutineListViewModel`](file:///home/souza/projects/beatly/lib/ui/features/routine_management/view_models/routine_list_view_model.dart): Carregamento, busca instantânea, duplicação rápida e exclusão de rotinas.
    - [`RoutineEditorViewModel`](file:///home/souza/projects/beatly/lib/ui/features/routine_management/view_models/routine_editor_view_model.dart): Formulário de rotina e rascunho de atividade, reordenação ordinal (`reorderActivity`), desativação automática de `autoStartMetronome` ao limpar BPM e persistência via `RoutineRepository`.
  - Widgets e Telas no Tema Obsidian Dark:
    - [`CategoryPicker`](file:///home/souza/projects/beatly/lib/ui/features/routine_management/widgets/category_picker.dart): Seletor fechado com exclusivamente as 5 categorias canônicas (`Técnica`, `Velocidade`, `Teoria Musical`, `Improviso`, `Free Style`).
    - [`ActivityListTile`](file:///home/souza/projects/beatly/lib/ui/features/routine_management/widgets/activity_list_tile.dart): Card com alça `ReorderableDragStartListener`, cor da categoria, duração formatada e badge de BPM/Auto.
    - [`RoutineListScreen`](file:///home/souza/projects/beatly/lib/ui/features/routine_management/views/routine_list_screen.dart) e [`RoutineEditorScreen`](file:///home/souza/projects/beatly/lib/ui/features/routine_management/views/routine_editor_screen.dart).
  - Testes Unitários, de Widget e de Integração: `64/64` testes passando na suíte acumulada (`TC-05.01` a `TC-05.07`, `WTC-05.01` a `WTC-05.03`, `category_picker_test.dart`, `routine_list_screen_test.dart`, `task05_routine_crud_integration_test.dart`) e `dart analyze` sem erros.
- **Status**: Concluído, aguardando aprovação do Piloto para iniciar a `TASK-06`.





### Iteração 09 — Loop de Implementação: TASK-06 (Máquina de Estados da Execução de Rotina e Tela de Foco)
- **Data/Hora**: 2026-11-08
- **Etapa**: Loop de Implementação — `TASK-06`
- **Ações Realizadas**:
  - **Roteamento de Modelos (Otimização de Tokens)**:
    - Passos 3, 4 e 5 executados pelo subagente `tdd-builder` (`Model: "flash"`).
    - Passos 6 e 7 executados pelo subagente `senior-code-reviewer` (`Model: "pro"`).
  - **Passo 3 (RED) & Passo 4 (GREEN)**:
    - Hierarquia selada de estados imutáveis em `lib/domain/models/routine_execution_state.dart` (`ExecutionStateIdle`, `ExecutionStatePreparing`, `ExecutionStateRunning`, `ExecutionStatePaused`, `ExecutionStateTransitioning`, `ExecutionStateCompleted`, `ExecutionStateCanceled`).
    - Coordenador desacoplado em `lib/domain/state_machines/routine_execution_coordinator.dart` implementando preparação inicial (5s), auto-start condicional do metrônomo (`EC-03`), transição suave com chime (`EC-07`), auto-conclusão ao término (`isCompletedEarly = false`, `EC-04`), conclusão manual antecipada via botão **"Concluir"** (`isCompletedEarly = true`, `EC-06`) e cancelamento com descarte total (**"Cancelar"**, zero persistência em `SessionRepository`, `EC-06`).
    - ViewModel reativa em `lib/ui/features/routine_execution/view_models/routine_execution_view_model.dart`.
    - Overlays e componentes Obsidian Dark: `preparation_overlay.dart`, `transition_countdown_overlay.dart`, `execution_controls_bar.dart` (com botão discreto `ObsidianButtonVariant.subtleLink` para cancelar) e `routine_execution_screen.dart` (com diálogo de confirmação onde `"Continuar treino"` é a ação primária em evidência).
  - **Passo 5 (Widget & Integration Tests)**:
    - Testes unitários em `test/unit/domain/state_machines/routine_execution_coordinator_test.dart` (`TC-06.01` a `TC-06.08`, `EC-03`, `EC-04`, `EC-06`, `EC-07`) e `test/unit/ui/view_models/routine_execution_view_model_test.dart`.
    - Testes de widget em `test/widget/routine_execution/routine_execution_screen_test.dart` (`WTC-06.01` a `WTC-06.04`).
    - Teste de integração ponta a ponta com SQLite Drift em `integration_test/task06_routine_execution_integration_test.dart`.
  - **Passos 6 e 7 (Verificação & Code Review Sênior)**:
    - Refatoração pontual de pattern matching e uso seguro de `BuildContext` em `routine_execution_screen.dart`.
    - `analyze_files`: **0 erros e 0 warnings**.
    - `run_tests`: **89/89 testes aprovados** (25 novos testes da `TASK-06` + 64 anteriores).
- **Decisões do Piloto**: Aguardando homologação da `TASK-06` para avançar para a `TASK-07`.
- **Status**: `TASK-06` 100% implementada, testada e revisada.


### Iteração 10 — Loop de Implementação: TASK-07 (Mapa de Evolução: Analytics Local & Radar Chart)
- **Data/Hora**: 2026-11-08
- **Etapa**: Loop de Implementação — `TASK-07`
- **Ações Realizadas**:
  - **Roteamento de Modelos (Otimização de Tokens)**:
    - Passos 3, 4 e 5 executados pelo subagente `tdd-builder` (`Model: "flash"`).
    - Passos 6 e 7 executados pelo subagente `senior-code-reviewer` (`Model: "pro"`).
  - **Passo 3 (RED) & Passo 4 (GREEN)**:
    - Modelos matemáticos puros em `lib/domain/models/radar_polygon_data.dart` (`RadarPoint`, `RadarAxisVertex`, `RadarPolygonData`) e DTOs analíticos em `lib/domain/models/practice_category_summary.dart` (`PracticeCategorySummary`, `MonthlyEvolutionSummary`) com zero dependência de `dart:ui` ou `package:flutter` (`ADR-005`).
    - Use Case trigonométrico puro `lib/domain/use_cases/calculate_radar_geometry_use_case.dart` projetando os 5 eixos canônicos ($\theta_i = -\frac{\pi}{2} + i \cdot \frac{2\pi}{5}$), 4 anéis concêntricos (25%, 50%, 75%, 100%) e proteção contra divisão por zero (`TC-07.03`).
    - Use Case de agregação mensal `lib/domain/use_cases/calculate_monthly_summary_use_case.dart` com cálculo de tempo total, sessões concluídas, dias ativos e média diária considerando os dias com prática (`TC-07.05`, `TC-07.06`).
    - Componentes visuais Obsidian Dark: `radar_chart_painter.dart` (`RadarChartPainter` + `PentagonRadarChart`), `monthly_consistency_calendar.dart`, `evolution_map_view_model.dart`, `session_completed_dialog.dart` e `evolution_map_screen.dart` (além da integração do `PentagonRadarChart` na tela de conclusão de rotina `routine_execution_screen.dart`).
  - **Passo 5 (Widget & Integration Tests)**:
    - Testes unitários: `calculate_radar_geometry_use_case_test.dart` (`TC-07.01` a `TC-07.04`), `calculate_monthly_summary_use_case_test.dart` (`TC-07.05`, `TC-07.06`) e `evolution_map_view_model_test.dart`.
    - Testes de widget: `session_completed_dialog_test.dart` (`WTC-07.01`, `WTC-07.02`), `evolution_map_screen_test.dart` (`WTC-07.03`), `radar_chart_widget_test.dart` e `monthly_consistency_calendar_test.dart`.
    - Teste de integração ponta a ponta com SQLite Drift: `integration_test/task07_evolution_map_integration_test.dart`.
  - **Passos 6 e 7 (Verificação & Code Review Sênior)**:
    - Padronização de datas em UTC no `CalculateMonthlySummaryUseCase` e cobertura adicional de widgets para o Radar Chart e Calendário de Consistência.
    - `analyze_files`: **0 erros e 0 warnings**.
    - `run_tests`: **106/106 testes aprovados** (17 novos testes da `TASK-07` + 89 anteriores, 0 regressões).
- **Decisões do Piloto**: Aguardando homologação da `TASK-07` para avançar para a última tarefa (`TASK-08`).
- **Status**: `TASK-07` 100% implementada, testada e revisada.


### Iteração 11 — Loop de Implementação: TASK-08 (Configurações Gerais, Serviços Nativos, Shell Principal e Suíte E2E Completa)
- **Data/Hora**: 2026-11-08
- **Etapa**: Loop de Implementação — `TASK-08` (Etapa Final)
- **Ações Realizadas**:
  - **Roteamento de Modelos (Otimização de Tokens)**:
    - Passos 3, 4 e 5 executados pelo subagente `tdd-builder` (`Model: "flash"`).
    - Passos 6 e 7 executados pelo subagente `senior-code-reviewer` (`Model: "pro"`) e validados com `analyze_files` e `run_tests`.
  - **Passo 3 (RED) & Passo 4 (GREEN)**:
    - Serviço de relógio monotônico real em `lib/data/services/clock/system_monotonic_clock_service.dart` (`Stopwatch`, imune a alterações no relógio/fuso horário do SO — `EC-08`, `TC-08.03`).
    - Gerador e pool em RAM de amostras WAV/PCM 16-bit 44.1kHz em `lib/data/services/audio/pcm_sound_cache.dart` (`click_wood_high`, `click_wood_mid`, `click_wood_low`, `chime_tibetan_bowl`, `chime_marimba`, `chime_gong`).
    - Motor de áudio nativo em `lib/data/services/audio/android_metronome_audio_service.dart` com tratamento de `AudioFocus` (`EC-05`).
    - Serviços de sistema Android em `lib/data/services/system/wakelock_service.dart` e `lib/data/services/system/android_foreground_service.dart`, além das permissões em `android/app/src/main/AndroidManifest.xml`.
    - Módulo de Ajustes Gerais em `lib/ui/features/settings/view_models/settings_view_model.dart` e `lib/ui/features/settings/views/settings_screen.dart` (transição de 0s a 60s `EC-07`, seleção de chime e wakelock).
    - Shell completo com 4 abas (`Metrônomo`, `Rotinas`, `Evolução`, `Ajustes`) em `lib/app.dart` e bootstrap de produção em `lib/main.dart`.
  - **Passo 5 (Widget & Integration Tests E2E)**:
    - Testes unitários: `system_monotonic_clock_service_test.dart` (`TC-08.03`), `pcm_sound_cache_test.dart` (`EC-05`), `settings_view_model_test.dart` (`TC-08.01`, `TC-08.02`).
    - Testes de widget: `settings_screen_test.dart`.
    - Teste de integração ponta a ponta completo (`ITC-08.01`): `integration_test/routine_full_lifecycle_flow_test.dart` e `test/integration/routine_full_lifecycle_flow_test.dart`.
  - **Passos 6 e 7 (Verificação & Code Review Sênior Final)**:
    - Correção de navegação raiz em `lib/app.dart` via `GlobalKey<NavigatorState>()`.
    - Sincronização determinística de streams em `FakeClockPort` e `RoutineExecutionCoordinator`.
    - `analyze_files`: **0 erros e 0 warnings** em todo o projeto.
    - `run_tests`: **119/119 testes aprovados em `test/`** (incluindo o fluxo E2E completo `ITC-08.01` com SQLite Drift em memória).
- **Decisões do Piloto**: Aguardando validação e homologação final do projeto Beatly v1.0.0.
- **Status**: Todas as 8 tarefas (`TASK-01` a `TASK-08`) 100% concluídas, testadas e aprovadas.


### Iteração 12 — Release Build Oficial: Beatly v1.0.0 (APK Instalável e Funcional)
- **Data/Hora**: 2026-11-08
- **Etapa**: Fechamento do Plano de Release (`release_plan.md`)
- **Ações Realizadas**:
  - **Fase 1 (Motor de Áudio Nativo & Baixa Latência)**:
    - Implementado `BeatlyAudioEngine.kt` em Kotlin com `AudioTrack` mono PCM 16-bit 44.1kHz de prioridade urgente de áudio (`THREAD_PRIORITY_URGENT_AUDIO`).
    - Agendamento com precisão de amostra (sample-accurate: `(44100 * 60) / (bpm * subdivision)` samples por pulso) para eliminação total de jitter.
    - Mixer polifônico integrado com pool de vozes para cliques (`click_high`, `click_mid`, `click_low`) e chimes (`chime_zen`, `chime_marimba`, `chime_gong`).
    - Tratamento de `AudioFocus` na `MainActivity.kt` com pausa automática em chamadas telefônicas (`EC-05`).
  - **Fase 2 (Ajustes Reais, Wakelock e Haptic)**:
    - Implementado canal nativo de Wakelock na `MainActivity.kt` via `FLAG_KEEP_SCREEN_ON` para manter a tela sempre ligada durante treinos.
    - Integração de `SettingsViewModel` na `RoutineExecutionScreen` e `RoutineExecutionCoordinator` com repasse de timbre e volume do chime selecionado nos Ajustes.
    - Disparo de `HapticFeedback.selectionClick()` durante a contagem regressiva da transição suave.
  - **Fase 3 (Identidade do Aplicativo)**:
    - Pacote configurado como `com.souza.beatly` (`namespace` e `applicationId`).
    - Nome do app definido como `Beatly` no `AndroidManifest.xml`.
    - Ícones de launcher (`ic_launcher.png`) gerados em todas as resoluções (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) a partir do logotipo oficial [beatly_app_logo_final.jpg](file:///home/souza/projects/beatly/assets/logo/beatly_app_logo_final.jpg).
    - Splash background configurado no preto nativo Obsidian `#0F0F10`.
  - **Fase 4 (Portão de Qualidade)**:
    - `analyze_files`: **0 erros e 0 warnings**.
    - `run_tests`: **123/123 testes aprovados** (100% GREEN).
  - **Fase 5 (Build do APK)**:
    - Compilado com sucesso: `build/app/outputs/flutter-apk/app-release.apk` (58.3MB).
    - Copiado para a pasta de downloads do Windows em `C:\Users\Victor\Downloads\beatly.apk`.
- **Status**: APK pronto para instalação física no aparelho do Piloto.

### Iteração 13 — Ajustes Visuais, Sincronização, Ajuste de Treino e Prévia de Sons
- **Data/Hora**: 2026-11-08
- **Etapa**: Refinamentos Pós-Teste no Aparelho
- **Ações Realizadas**:
  - **1. Metrônomo**:
    - **Ícones Modernos**: Substituídos caracteres ASCII antigos (`|◀`, `▶|`, `▶`/`⏸`) por ícones Material arredondados e elegantes (`Icons.remove_rounded`, `Icons.add_rounded`, `Icons.play_arrow_rounded` / `Icons.pause_rounded`) com botão primário em destaque violeta.
    - **Modo Desafio**: Corrigido avanço de velocidade no modo por compassos (`byBars`) através do cálculo de compasso `(60000.0 / bpm) * beatsPerBar` e callback `onBpmChanged` conectado ao ViewModel do Metrônomo em tempo real.
    - **Progresso do Desafio**: Adicionada barra de progresso visual com porcentagem e banner informativo no topo da tela do metrônomo (`_ChallengeActiveBanner`), além de contador de progresso detalhado no bottom sheet ("Compasso X de Y" / "Xs restantes").
    - **Sincronismo Áudio-Visual**: Eliminado o lag e drift visual do LED piscante substituindo contadores de intervalo periódico por cálculo exato com `Stopwatch` absoluto a 25ms sincronizado com a fase do motor de áudio.
    - **Centralização Visual**: Pulsos e barras de volume centralizados horizontalmente no card através de alinhamento com `Wrap` centralizado.
  - **2. Rotinas e Treino (Ajuste de BPM On-the-Fly)**:
    - Adicionado controle dinâmico de BPM em `RoutineExecutionCoordinator` (`updateBpm`, `stepBpm`) e exposto em `RoutineExecutionViewModel`.
    - Interface de execução (`RoutineExecutionScreen`) atualizada com controles completos de velocidade do metrônomo: botões rápidos de `-5`, `-1`, display central de `$bpm BPM`, `+1`, `+5` e botão de ligar/desligar áudio em tempo real durante o exercício.
  - **3. Configurações (Prévia Sonora)**:
    - Adicionada função `previewSound(TransitionAlertSound)` no `SettingsViewModel` com injeção de `MetronomeAudioPort`.
    - Ao selecionar uma opção de aviso sonoro na tela de Ajustes, o som é reproduzido imediatamente para demonstração; adicionado também botão dedicado com ícone de alto-falante / vibração ao lado de cada opção para ouvir a prévia a qualquer momento.
  - **4. Portão de Qualidade & Testes**:
    - `analyze_files`: **0 erros e 0 warnings**.
    - `run_tests`: **125/125 testes aprovados** (100% GREEN, incluindo novos testes unitários e de widget).
- **Status**: Concluído e compilado em release APK.

### Iteração 14 — Correções de Áudio Nativo, Retomada de Rotina, Layout do Desafio e Edição de Atividades
- **Data/Hora**: 2026-11-09
- **Etapa**: Correção e Refinamento Pós-Testes Físicos (Plano `bugfix_refinement_plan.md`)
- **Ações Realizadas**:
  - **1. Metrônomo (Subdivisões e Estabilidade Isócrona)**:
    - **Sincronismo de Subdivisões**: Separado o contador de batidas do compasso (`currentBeatIndex`) do contador de subdivisões internas (`currentSubdivisionIndex`) tanto em `BeatlyAudioEngine.kt` quanto em `AndroidMetronomeAudioService.dart`. Agora, a cabeça de cada tempo sempre toca a acentuação exata do pulso (`Forte`, `Normal`, `Fraco`, `Mudo`), enquanto contratempos, tercinas e semicolcheias tocam cliques suaves sem deslocar o compasso.
    - **Estabilidade e Volume sem Variação**: Adicionada flag de reset atômica (`resetRequested`), resincronização contra jitter em caso de atraso da thread do SO (eliminando rajadas de som sobrepostas e congelamentos de buffer), e proteção com reinicialização automática de `AudioTrack` em caso de erro de hardware.
  - **2. Rotinas (Isolamento em Background & Banner de Retomada)**:
    - Corrigido vazamento de background garantindo que `RoutineExecutionViewModel.dispose()` chame `_coordinator.dispose()`, cancelando os timers e silenciando o motor de áudio.
    - Implementada persistência da sessão ativa no `BeatlyAppState` com banner flutuante no app: o usuário pode sair da tela e retornar ao treino em andamento a qualquer momento com 1 clique no botão **"Retomar"**.
  - **3. Desafio (Layout Responsivo)**:
    - Reestruturado o card de comportamento no teto ("Manter" vs "Parar + Chime") em `SpeedChallengeBottomSheet` com layout vertical (`Column`), eliminando sobreposição e quebra em qualquer resolução de tela.
  - **4. Atividades (Edição & Notas)**:
    - Implementado fluxo completo de edição de atividades em `RoutineEditorViewModel` (`startEditingActivity`, `commitDraftActivity`, `cancelEditingActivity`).
    - Adicionado campo de notas de até 100 caracteres no formulário de atividade e exibição de notas no `ActivityListTile` e na tela de treino (`RoutineExecutionScreen`).
  - **5. Portão de Qualidade**:
    - `analyze_files`: **0 erros e 0 warnings**.
    - `run_tests`: **130/130 testes aprovados** (100% GREEN).
- **Status**: Concluído e compilado em release APK.

### Iteração 15 — Eliminação de Scroll no Metrônomo, Roda de BPM 1:1 e Ajustes de Volumes/Divisões nas Rotinas
- **Data/Hora**: 2026-11-09
- **Etapa**: Correções de UX e Interatividade Solicitadas pelo Piloto
- **Ações Realizadas**:
  - **1. Metrônomo (Eliminação do Scroll Indesejado)**:
    - Compactados os paddings internos de `RotaryBpmDial`, `TimeDivisionPanel` e `BeatStripSelector` de 12px para 8px verticais.
    - Otimizada a altura do disco giratório de 170px para 152px e raio da roda de 144px para 136px.
    - Substituído o scroll solto por `LayoutBuilder` com `ConstrainedBox(minHeight: maxHeight)` e `ClampingScrollPhysics` com margens de 8px, garantindo que todo o conteúdo ocupe ~520px e caiba perfeitamente no viewport de qualquer smartphone sem disparar scroll vertical.
  - **2. Roda Giratória de BPM (Gesto e Rastreamento 1:1)**:
    - Refatorado `RotaryBpmDial` para rastrear o ângulo contínuo do dedo (`_handlePanStart`, `_handlePanUpdate`, `_handlePanEnd` com `_accumulatedDelta`).
    - Durante o arraste, o marcador roxo fica cravado exatamente sob a ponta do dedo do usuário em tempo real (`_isDragging`), eliminando o descompasso e a perda de sensibilidade angular ao girar rápido.
  - **3. Rotinas e Treino (Volumes dos Pulsos e Subdivisões On-the-Fly)**:
    - Expandido `RoutineExecutionCoordinator` e `RoutineExecutionViewModel` com controle de `activeSubdivision`, `activePattern`, `updateSubdivision()`, `cycleBeatEmphasis()`, `resetBeatPatternToDefault()` e `muteAllBeats()`, comunicando em tempo real com o motor de áudio.
    - Adicionado botão de ajustes (`Icons.tune_rounded`) na barra do metrônomo de `RoutineExecutionScreen`.
    - Implementado modal bottom sheet Obsidian Dark permitindo alternar instantaneamente subdivisões (1x Pulso, 2x Colcheia, 3x Tercina, 4x Semicolcheia) e tocar em cada barra de pulso para ciclar sua ênfase (Forte, Normal, Fraco, Mudo), com atalhos para restaurar padrão ou silenciar tudo.
  - **4. Portão de Qualidade & Testes**:
    - `analyze_files`: **0 erros e 0 warnings** em todo o código Dart.
    - `run_tests`: **132/132 testes aprovados** (100% GREEN), incluindo novos testes unitários e de widget para ajustes do metrônomo no treino.
- **Status**: Concluído e pronto para compilação do APK Release.

### Iteração 16 — Sincronismo do Tempo Forte em Novos Compassos e Expansão Ergonômica da Divisão de Tempo
- **Data/Hora**: 2026-11-09
- **Etapa**: Correção de Deslocamento do Tempo Forte e Ampliação da Caixa de Divisão de Tempo
- **Ações Realizadas**:
  - **1. Metrônomo (Preservação Absoluta da Referência do Tempo Forte)**:
    - **Causa Raiz**: Ao alterar `beatsPerBar` (ex.: de 4 para 5 ou 6 pulsos), o áudio nativo (`BeatlyAudioEngine.kt`) mantinha o `currentBeatIndex` correndo no meio do compasso sem reiniciar a cabeça do ciclo, e o `_pulseStopwatch` do Flutter calculava o índice pelo tempo total acumulado (`elapsed / msPerBeat % newBeats`), gerando dessincronia sonora e visual onde o tempo forte (clique agudo) tocava fora do tempo 1.
    - **Solução no Motor Nativo**: Adicionado parâmetro `resetCycle` e detecção automática de mudança de tamanho (`pattern.size != activePattern.size`) em `BeatlyAudioEngine.kt`. O ciclo é imediatamente zerado (`currentBeatIndex = 0`, `currentSubdivisionIndex = 0`, `resetRequested = true`), garantindo que o próximo clique soado seja obrigatoriamente o **tempo forte (tempo 1)**.
    - **Solução no ViewModel**: Em `MetronomeViewModel.setBeatsPerBar(int count)` e `resetBeatPatternToDefault()`, o cronômetro visual `_pulseStopwatch` é reiniciado e `_activeBeatIndex` é cravado em `0`, mantendo o LED âmbar do tempo forte e o áudio nativo 100% em fase.
  - **2. Caixa de Divisão de Tempo (Ergonomia Ampla e Fácil Navegação)**:
    - **Botões de Passo do Compasso**: Aumentados de 28x28px para 38x38px com ícones Material `remove_rounded` e `add_rounded`, com touch target confortável e display central mono de 44px de largura.
    - **Denominadores (/2, /4, /8, /16)**: Organizados em caixas proporcionais de 38px de altura com cantos arredondados e contraste luminoso no item selecionado.
    - **Subdivisões de Tempo**: Cartões visuais ampliados para altura generosa com espaçamento harmônico, eliminando qualquer aperto ou corte de texto/ícone.
  - **3. Fita de Pulsos (BeatStripSelector)**:
    - Substituído `Wrap` por `SingleChildScrollView(scrollDirection: Axis.horizontal)`, mantendo a sequência de tempos (1 a N) sempre linear e sem quebras de linha desalinhadas para 5/4, 6/4 ou mais tempos.
    - Destaque visual permanente para o **Tempo 1**: borda âmbar sutil, tipografia dourada e indicador "Forte", garantindo que a referência do compasso nunca se perca de vista.
  - **4. Portão de Qualidade & Testes**:
    - `analyze_files`: **0 erros e 0 warnings**.
    - `run_tests`: **133/133 testes aprovados** (100% GREEN), incluindo novo teste unitário `TC-03.12` validando sincronização do tempo forte ao alterar fórmulas de compasso durante a execução.
- **Status**: Concluído e pronto para compilação do APK Release.
