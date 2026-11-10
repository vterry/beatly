import 'package:flutter/material.dart';

import '../../../../domain/models/practice_category_summary.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/obsidian_card.dart';
import '../view_models/evolution_map_view_model.dart';
import '../widgets/monthly_consistency_calendar.dart';
import '../widgets/radar_chart_painter.dart';

/// Tela principal do Mapa de Evolução e Analytics Local (ADR-004 / RN-06 / RN-09).
class EvolutionMapScreen extends StatefulWidget {
  const EvolutionMapScreen({
    required this.viewModel,
    super.key,
  });

  final EvolutionMapViewModel viewModel;

  @override
  State<EvolutionMapScreen> createState() => _EvolutionMapScreenState();
}

class _EvolutionMapScreenState extends State<EvolutionMapScreen> {
  static const List<String> _monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.viewModel.summary == null && !widget.viewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.viewModel.loadMonth();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mapa de Evolução',
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;
          final summary = vm.summary;
          final monthIndex = (vm.currentMonth - 1).clamp(0, 11);
          final monthLabel =
              '${_monthNames[monthIndex]} ${vm.currentYear}';

          return RefreshIndicator(
            color: AppColors.violetLight,
            backgroundColor: AppColors.surface,
            onRefresh: () => vm.loadMonth(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barra de Seleção de Mês/Ano
                  _buildMonthSelector(vm, monthLabel),
                  const SizedBox(height: AppDimensions.md),

                  if (vm.isLoading && summary == null) ...[
                    const SizedBox(height: 80),
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.violetLight,
                      ),
                    ),
                  ] else ...[
                    // Cards de Métricas Mensais
                    _buildMetricsRow(summary),
                    const SizedBox(height: AppDimensions.md),

                    // Gráfico Pentagonal Consolidado
                    ObsidianCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.md,
                        horizontal: AppDimensions.sm,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Competências Desenvolvidas',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.sm),
                          PentagonRadarChart(
                            key: const ValueKey('session_radar_chart'),
                            categoryDurations: vm.categoryDurations,
                            height: 220,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),

                    // Calendário de Consistência
                    MonthlyConsistencyCalendar(
                      year: vm.currentYear,
                      month: vm.currentMonth,
                      activeDaysOfMonth: summary?.activeDaysOfMonth ?? const {},
                    ),
                    const SizedBox(height: AppDimensions.md),

                    // Breakdown Percentual por Categoria
                    _buildCategoryBreakdown(summary),
                    const SizedBox(height: AppDimensions.lg),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector(EvolutionMapViewModel vm, String monthLabel) {
    return ObsidianCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const ValueKey('btn_prev_month'),
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            tooltip: 'Mês anterior',
            onPressed: vm.isLoading ? null : vm.previousMonth,
          ),
          Text(
            monthLabel,
            key: const ValueKey('evolution_month_label'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            key: const ValueKey('btn_next_month'),
            icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
            tooltip: 'Próximo mês',
            onPressed: vm.isLoading ? null : vm.nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(MonthlyEvolutionSummary? summary) {
    final totalSeconds = summary?.totalDurationSeconds ?? 0;
    final totalSessions = summary?.totalSessionsCount ?? 0;
    final dailyAvgSeconds =
        summary?.dailyAverageSecondsOnActiveDays.round() ?? 0;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Tempo Total',
            value: _formatTotalTime(totalSeconds),
            subtitle: '${(totalSeconds / 60).round()} min',
          ),
        ),
        const SizedBox(width: AppDimensions.xs),
        Expanded(
          child: _MetricCard(
            title: 'Sessões',
            value: '$totalSessions',
            subtitle: 'concluídas',
          ),
        ),
        const SizedBox(width: AppDimensions.xs),
        Expanded(
          child: _MetricCard(
            title: 'Média/Dia Ativo',
            value: _formatDailyAvg(dailyAvgSeconds),
            subtitle: '${summary?.activeDaysCount ?? 0} dias',
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(MonthlyEvolutionSummary? summary) {
    final breakdown = summary?.categoryBreakdown ?? const [];

    return ObsidianCard(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribuição de Estudo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          ...breakdown.map((item) {
            final catColor = AppColors.forCategory(item.category);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: catColor,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Text(
                        item.category.label,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (item.isTopCategory) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.violet.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Foco',
                            style: TextStyle(
                              color: AppColors.violetLight,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '${_formatDuration(item.durationSeconds)} (${item.percentage.toStringAsFixed(1)}%)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: item.percentage > 0 ? item.percentage / 100 : 0.0,
                      backgroundColor: AppColors.elevated,
                      valueColor: AlwaysStoppedAnimation<Color>(catColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _formatTotalTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${seconds}s';
  }

  static String _formatDailyAvg(int seconds) {
    final m = seconds ~/ 60;
    if (m > 0) return '${m}m';
    return '${seconds}s';
  }

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '${m}m';
    return '${s}s';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ObsidianCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
