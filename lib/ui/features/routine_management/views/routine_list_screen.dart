import 'package:flutter/material.dart';

import '../../../../domain/contracts/routine_repository.dart';
import '../../../../domain/models/routine.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/obsidian_button.dart';
import '../../../core/widgets/obsidian_card.dart';
import '../view_models/routine_editor_view_model.dart';
import '../view_models/routine_list_view_model.dart';
import '../widgets/activity_list_tile.dart';
import 'routine_editor_screen.dart';

/// Tela inicial da pasta de estudos com listagem, busca, duplicação e exclusão de Rotinas (RF-05).
class RoutineListScreen extends StatelessWidget {
  const RoutineListScreen({
    required this.viewModel,
    required this.repository,
    this.onStartRoutine,
    super.key,
  });

  final RoutineListViewModel viewModel;
  final RoutineRepository repository;
  final ValueChanged<Routine>? onStartRoutine;

  Future<void> _openEditor(
    BuildContext context, {
    Routine? existingRoutine,
  }) async {
    final editorVm = RoutineEditorViewModel(
      repository: repository,
      initialRoutine: existingRoutine,
    );
    await Navigator.of(context).push<Routine>(
      MaterialPageRoute(
        builder: (_) => RoutineEditorScreen(viewModel: editorVm),
      ),
    );
    editorVm.dispose();
    await viewModel.loadRoutines();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final routines = viewModel.routines;

        return AppScaffold(
          title: 'Rotinas de Estudo',
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.sm),
              child: ObsidianButton(
                key: const ValueKey('routine_btn_create'),
                label: 'Nova Rotina',
                icon: Icons.add_rounded,
                onPressed: () => _openEditor(context),
              ),
            ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ObsidianCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: TextField(
                  key: const ValueKey('routine_search_input'),
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    hintText: 'Buscar rotina...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: viewModel.setSearchQuery,
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              Expanded(
                child: routines.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma rotina cadastrada. Crie sua primeira rotina!',
                          style: AppTypography.caption,
                        ),
                      )
                    : ListView.separated(
                        itemCount: routines.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppDimensions.sm),
                        itemBuilder: (context, index) {
                          final routine = routines[index];
                          final totalSecs =
                              routine.totalEstimatedDurationSeconds();

                          return ObsidianCard(
                            key: ValueKey('routine_card_${routine.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _openEditor(
                                          context,
                                          existingRoutine: routine,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              routine.name,
                                              style: AppTypography.heading,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${routine.activities.length} atividades • ${ActivityListTile.formatDuration(totalSecs)}',
                                              style: AppTypography.caption,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      key: ValueKey(
                                        'routine_duplicate_${routine.id}',
                                      ),
                                      onPressed: () =>
                                          viewModel.duplicateRoutine(routine.id),
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        size: 18,
                                        color: AppColors.textSecondary,
                                      ),
                                      tooltip: 'Duplicar rotina',
                                    ),
                                    IconButton(
                                      key: ValueKey(
                                        'routine_delete_${routine.id}',
                                      ),
                                      onPressed: () =>
                                          viewModel.deleteRoutine(routine.id),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                        color: AppColors.textMuted,
                                      ),
                                      tooltip: 'Excluir rotina',
                                    ),
                                  ],
                                ),
                                if (onStartRoutine != null) ...[
                                  const SizedBox(height: AppDimensions.sm),
                                  ObsidianButton(
                                    key: ValueKey(
                                      'routine_start_${routine.id}',
                                    ),
                                    label: 'Iniciar Treino',
                                    icon: Icons.play_arrow_rounded,
                                    onPressed: () => onStartRoutine!(routine),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

