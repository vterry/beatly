import 'dart:math' as math;

import '../models/activity_category.dart';
import '../models/radar_polygon_data.dart';

/// Caso de uso matemático puro para cálculo da geometria do Radar Chart pentagonal (ADR-004 / RN-09).
class CalculateRadarGeometryUseCase {
  const CalculateRadarGeometryUseCase();

  /// Ordem canônica dos 5 eixos (índices 0 a 4).
  static const List<ActivityCategory> canonicalAxes = [
    ActivityCategory.tecnica,
    ActivityCategory.velocidade,
    ActivityCategory.teoriaMusical,
    ActivityCategory.improviso,
    ActivityCategory.freeStyle,
  ];

  static const List<double> gridRingLevels = [0.25, 0.50, 0.75, 1.0];

  RadarPolygonData execute({
    required Map<ActivityCategory, int> categoryDurationsSeconds,
    required double centerX,
    required double centerY,
    required double maxRadius,
  }) {
    final center = RadarPoint(x: centerX, y: centerY);

    // Determina a duração máxima registrada entre todas as categorias
    var maxDuration = 0;
    for (final duration in categoryDurationsSeconds.values) {
      if (duration > maxDuration) {
        maxDuration = duration;
      }
    }

    final axes = <RadarAxisVertex>[];
    final dataPolygonPoints = <RadarPoint>[];

    // Calcula os 5 eixos canônicos
    for (var i = 0; i < canonicalAxes.length; i++) {
      final category = canonicalAxes[i];
      final theta = -math.pi / 2 + i * (2 * math.pi / 5);
      final duration = math.max(0, categoryDurationsSeconds[category] ?? 0);

      final cosTheta = _cleanTrig(math.cos(theta));
      final sinTheta = _cleanTrig(math.sin(theta));

      final outerVertex = RadarPoint(
        x: centerX + maxRadius * cosTheta,
        y: centerY + maxRadius * sinTheta,
      );

      final double normalizedRatio;
      final RadarPoint dataVertex;

      if (maxDuration == 0) {
        // Sessão vazia ou 0s: ponto fixado exatamente no centro para evitar divisão por zero (TC-07.03)
        normalizedRatio = 0.0;
        dataVertex = RadarPoint(x: centerX, y: centerY);
      } else {
        normalizedRatio = duration / maxDuration;
        final r = maxRadius * normalizedRatio;
        dataVertex = RadarPoint(
          x: centerX + r * cosTheta,
          y: centerY + r * sinTheta,
        );
      }

      axes.add(
        RadarAxisVertex(
          category: category,
          angleRadians: theta,
          normalizedRatio: normalizedRatio,
          durationSeconds: duration,
          outerVertex: outerVertex,
          dataVertex: dataVertex,
        ),
      );

      dataPolygonPoints.add(dataVertex);
    }

    // Gera os 4 anéis poligonais de fundo (TC-07.04)
    final gridRings = <List<RadarPoint>>[];
    for (final level in gridRingLevels) {
      final ringRadius = maxRadius * level;
      final ringPoints = <RadarPoint>[];
      for (var i = 0; i < canonicalAxes.length; i++) {
        final theta = -math.pi / 2 + i * (2 * math.pi / 5);
        final cosTheta = _cleanTrig(math.cos(theta));
        final sinTheta = _cleanTrig(math.sin(theta));
        ringPoints.add(
          RadarPoint(
            x: centerX + ringRadius * cosTheta,
            y: centerY + ringRadius * sinTheta,
          ),
        );
      }
      gridRings.add(ringPoints);
    }

    return RadarPolygonData(
      center: center,
      maxRadius: maxRadius,
      maxDurationSeconds: maxDuration,
      gridRings: gridRings,
      axes: axes,
      dataPolygonPoints: dataPolygonPoints,
    );
  }

  static double _cleanTrig(double value) {
    if (value.abs() < 1e-12) return 0.0;
    if ((value - 1.0).abs() < 1e-12) return 1.0;
    if ((value + 1.0).abs() < 1e-12) return -1.0;
    return value;
  }
}
