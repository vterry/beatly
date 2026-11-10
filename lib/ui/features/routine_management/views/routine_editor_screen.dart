import 'package:flutter/material.dart';

import '../../../../domain/models/routine.dart';
import '../../../../domain/models/routine_activity.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/obsidian_button.dart';
import '../../../core/widgets/obsidian_card.dart';
import '../view_models/routine_editor_view_model.dart';
import '../widgets/activity_list_tile.dart';
import '../widgets/category_picker.dart';

/// Tela de criação e edição de Rotinas e suas Atividades no tema Obsidian Dark (RF-05 / RF-06).
class RoutineEditorScreen extends StatefulWidget {
  const RoutineEditorScreen({
    required this.viewModel,
    this.onSaved,
    super.key,
  });

  final RoutineEditorViewModel viewModel;
  final ValueChanged<Routine>? onSaved;

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  late final TextEditingController _routineNameCtrl;
  late final TextEditingController _activityNameCtrl;
  late final TextEditingController _durationMinutesCtrl;
  late final TextEditingController _bpmCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final vm = widget.viewModel;
    _routineNameCtrl = TextEditingController(text: vm.routineName);
    _activityNameCtrl = TextEditingController(text: vm.draftActivityName);
    _durationMinutesCtrl = TextEditingController(
      text: (vm.draftDurationSeconds ~/ 60).toString(),
    );
    _bpmCtrl = TextEditingController(
      text: vm.draftBpm != null ? vm.draftBpm.toString() : '',
    );
    _notesCtrl = TextEditingController(text: vm.draftNotes);
  }

  @override
  void dispose() {
    _routineNameCtrl.dispose();
    _activityNameCtrl.dispose();
    _durationMinutesCtrl.dispose();
    _bpmCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final saved = await widget.viewModel.saveRoutine();
    if (saved == null || !mounted) return;
    widget.onSaved?.call(saved);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(saved);
    }
  }

  void _handleAddOrSaveActivity() {
    final added = widget.viewModel.commitDraftActivity();
    if (added) {
      _activityNameCtrl.clear();
      _durationMinutesCtrl.text = '5';
      _bpmCtrl.clear();
      _notesCtrl.clear();
    }
  }

  void _handleStartEdit(RoutineActivity activity) {
    widget.viewModel.startEditingActivity(activity);
    _activityNameCtrl.text = activity.name;
    _durationMinutesCtrl.text = (activity.durationSeconds ~/ 60).toString();
    _bpmCtrl.text = activity.bpm != null ? activity.bpm.toString() : '';
    _notesCtrl.text = activity.notes;
  }

  void _handleCancelEdit() {
    widget.viewModel.cancelEditingActivity();
    _activityNameCtrl.clear();
    _durationMinutesCtrl.text = '5';
    _bpmCtrl.clear();
    _notesCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final totalSecs = vm.totalEstimatedDurationSeconds();

        return AppScaffold(
          title: 'Editor de Rotina',
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.sm),
              child: ObsidianButton(
                key: const ValueKey('routine_btn_save'),
                label: 'Salvar',
                icon: Icons.check_rounded,
                onPressed: vm.isValid ? _handleSave : null,
              ),
            ),
          ],
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabeçalho da rotina: Nome + Duração total estimada
                ObsidianCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'NOME DA ROTINA',
                            style: AppTypography.caption,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.violet.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Total: ${ActivityListTile.formatDuration(totalSecs)}',
                              key: const ValueKey('routine_total_duration_text'),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.violetLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      TextField(
                        key: const ValueKey('routine_input_name'),
                        controller: _routineNameCtrl,
                        style: AppTypography.heading,
                        decoration: const InputDecoration(
                          hintText: 'Ex.: Treino Diário de Técnica',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: vm.setRoutineName,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                // Card de adição ou edição de atividade
                ObsidianCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            vm.isEditingActivity
                                ? 'Editar Atividade'
                                : 'Nova Atividade',
                            style: AppTypography.heading.copyWith(
                              color: vm.isEditingActivity
                                  ? AppColors.violetLight
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (vm.isEditingActivity)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.violet.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.violet.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Text(
                                'Modo Edição',
                                style: TextStyle(
                                  color: AppColors.violetLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      TextField(
                        key: const ValueKey('activity_input_name'),
                        controller: _activityNameCtrl,
                        style: AppTypography.body,
                        decoration: const InputDecoration(
                          labelText: 'Nome da atividade',
                          hintText: 'Ex.: Escala Pentatônica em 5 regiões',
                        ),
                        onChanged: vm.setDraftActivityName,
                      ),
                      const SizedBox(height: AppDimensions.md),
                      const Text(
                        'Categoria Canônica',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      CategoryPicker(
                        selectedCategory: vm.draftCategory,
                        onCategorySelected: vm.setDraftCategory,
                      ),
                      const SizedBox(height: AppDimensions.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const ValueKey('activity_input_duration'),
                              controller: _durationMinutesCtrl,
                              keyboardType: TextInputType.number,
                              style: AppTypography.body,
                              decoration: const InputDecoration(
                                labelText: 'Duração (min)',
                              ),
                              onChanged: (v) {
                                final trimmed = v.trim();
                                if (trimmed.endsWith('s')) {
                                  final secs = int.tryParse(
                                    trimmed.substring(0, trimmed.length - 1),
                                  );
                                  if (secs != null && secs > 0) {
                                    vm.setDraftDurationSeconds(secs);
                                  }
                                } else {
                                  final mins = int.tryParse(trimmed);
                                  if (mins != null && mins > 0) {
                                    vm.setDraftDurationSeconds(mins * 60);
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: TextField(
                              key: const ValueKey('activity_input_bpm'),
                              controller: _bpmCtrl,
                              keyboardType: TextInputType.number,
                              style: AppTypography.body,
                              decoration: const InputDecoration(
                                labelText: 'BPM (Opcional)',
                                hintText: '20 - 300',
                              ),
                              onChanged: (v) {
                                if (v.trim().isEmpty) {
                                  vm.setDraftBpm(null);
                                } else {
                                  vm.setDraftBpm(int.tryParse(v.trim()));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Iniciar metrônomo automaticamente (requer BPM)',
                              style: AppTypography.caption.copyWith(
                                color: vm.canEnableDraftAutoStart
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                          Switch(
                            key: const ValueKey('activity_switch_autostart'),
                            value: vm.draftAutoStartMetronome,
                            onChanged: vm.canEnableDraftAutoStart
                                ? vm.setDraftAutoStartMetronome
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      TextField(
                        key: const ValueKey('activity_input_notes'),
                        controller: _notesCtrl,
                        maxLength: 100,
                        maxLines: 2,
                        style: AppTypography.body,
                        decoration: const InputDecoration(
                          labelText: 'Notas / Instruções (até 100 caracteres)',
                          hintText: 'Ex.: Foco na postura e palhetada alternada constante',
                          alignLabelWithHint: true,
                        ),
                        onChanged: vm.setDraftNotes,
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      if (vm.isEditingActivity)
                        Row(
                          children: [
                            Expanded(
                              child: ObsidianButton(
                                key: const ValueKey('activity_btn_cancel_edit'),
                                label: 'Cancelar',
                                variant: ObsidianButtonVariant.subtleLink,
                                onPressed: _handleCancelEdit,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.sm),
                            Expanded(
                              flex: 2,
                              child: ObsidianButton(
                                key: const ValueKey('activity_btn_save_edit'),
                                label: 'Salvar Alterações',
                                icon: Icons.check_rounded,
                                variant: ObsidianButtonVariant.primary,
                                onPressed: vm.draftActivityName.trim().isNotEmpty
                                    ? _handleAddOrSaveActivity
                                    : null,
                              ),
                            ),
                          ],
                        )
                      else
                        ObsidianButton(
                          key: const ValueKey('activity_btn_add'),
                          label: 'Adicionar Atividade',
                          icon: Icons.add_rounded,
                          variant: ObsidianButtonVariant.secondary,
                          onPressed: vm.draftActivityName.trim().isNotEmpty
                              ? _handleAddOrSaveActivity
                              : null,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                // Lista reordenável de atividades adicionadas
                Text(
                  'Atividades da Rotina (${vm.activities.length})',
                  style: AppTypography.heading,
                ),
                const SizedBox(height: AppDimensions.sm),
                if (vm.activities.isEmpty)
                  const ObsidianCard(
                    child: Text(
                      'Nenhuma atividade adicionada ainda.',
                      style: AppTypography.caption,
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: vm.activities.length,
                    onReorder: vm.reorderActivity,
                    itemBuilder: (context, index) {
                      final activity = vm.activities[index];
                      return ActivityListTile(
                        key: ValueKey('activity_tile_${activity.id}'),
                        activity: activity,
                        index: index,
                        isEditing: vm.editingActivityId == activity.id,
                        onEdit: () => _handleStartEdit(activity),
                        onDelete: () {
                          if (vm.editingActivityId == activity.id) {
                            _handleCancelEdit();
                          }
                          vm.removeActivity(activity.id);
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

