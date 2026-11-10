import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../domain/models/activity_category.dart';
import '../../../../domain/models/radar_polygon_data.dart';
import '../../../../domain/use_cases/calculate_radar_geometry_use_case.dart';
import '../../../core/constants/app_colors.dart';

/// Painter de alta precisão que renderiza a geometria pentagonal do Radar Chart (ADR-004 / RN-09).
class RadarChartPainter extends CustomPainter {
  const RadarChartPainter({required this.data});

  final RadarPolygonData data;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. Desenha os 4 anéis concêntricos de fundo (25%, 50%, 75%, 100%)
    for (final ring in data.gridRings) {
      if (ring.isEmpty) continue;
      final path = Path()..moveTo(ring[0].x, ring[0].y);
      for (var i = 1; i < ring.length; i++) {
        path.lineTo(ring[i].x, ring[i].y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 2. Desenha as 5 linhas radiais do centro até cada vértice externo
    for (final axis in data.axes) {
      canvas.drawLine(
        Offset(data.center.x, data.center.y),
        Offset(axis.outerVertex.x, axis.outerVertex.y),
        gridPaint,
      );
    }

    // 3. Desenha o polígono de dados preenchido e contornado
    if (data.dataPolygonPoints.isNotEmpty) {
      final dataPath = Path()
        ..moveTo(
          data.dataPolygonPoints[0].x,
          data.dataPolygonPoints[0].y,
        );
      for (var i = 1; i < data.dataPolygonPoints.length; i++) {
        dataPath.lineTo(
          data.dataPolygonPoints[i].x,
          data.dataPolygonPoints[i].y,
        );
      }
      dataPath.close();

      // Preenchimento violeta translúcido (30% alpha)
      final fillPaint = Paint()
        ..color = AppColors.violet.withValues(alpha: 0.30)
        ..style = PaintingStyle.fill;
      canvas.drawPath(dataPath, fillPaint);

      // Borda violeta clara sólida (espessura 2.0)
      final strokePaint = Paint()
        ..color = AppColors.violetLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(dataPath, strokePaint);
    }

    // 4. Desenha os pontos luminosos nos vértices de dados
    final pointBorderPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final axis in data.axes) {
      final pointPaint = Paint()
        ..color = AppColors.forCategory(axis.category)
        ..style = PaintingStyle.fill;

      final pointOffset = Offset(axis.dataVertex.x, axis.dataVertex.y);
      canvas.drawCircle(pointOffset, 4.0, pointPaint);
      canvas.drawCircle(pointOffset, 4.0, pointBorderPaint);
    }

    // 5. Rótulos das categorias nos vértices externos
    for (final axis in data.axes) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: axis.category.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Desloca o rótulo ligeiramente para fora do anel externo
      const offsetDist = 12.0;
      final targetX =
          axis.outerVertex.x + offsetDist * math.cos(axis.angleRadians);
      final targetY =
          axis.outerVertex.y + offsetDist * math.sin(axis.angleRadians);

      final textOffset = Offset(
        targetX - (textPainter.width / 2),
        targetY - (textPainter.height / 2),
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant RadarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

/// Widget amigável do Gráfico Pentagonal de Evolução (RN-09).
class PentagonRadarChart extends StatelessWidget {
  const PentagonRadarChart({
    super.key = const ValueKey('session_radar_chart'),
    required this.categoryDurations,
    this.geometryUseCase = const CalculateRadarGeometryUseCase(),
    this.height = 240,
  });

  final Map<ActivityCategory, int> categoryDurations;
  final CalculateRadarGeometryUseCase geometryUseCase;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : height;

          final centerX = width / 2;
          final centerY = availableHeight / 2;
          final maxRadius = math.max(
            20.0,
            (math.min(width, availableHeight) / 2) - 32.0,
          );

          final polygonData = geometryUseCase.execute(
            categoryDurationsSeconds: categoryDurations,
            centerX: centerX,
            centerY: centerY,
            maxRadius: maxRadius,
          );

          return CustomPaint(
            size: Size(width, availableHeight),
            painter: RadarChartPainter(data: polygonData),
          );
        },
      ),
    );
  }
}
