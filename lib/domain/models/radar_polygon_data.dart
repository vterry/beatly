import 'activity_category.dart';

/// Coordenada bidimensional pura no plano euclidiano para cálculo da teia do Radar.
class RadarPoint {
  const RadarPoint({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarPoint &&
          runtimeType == other.runtimeType &&
          (x - other.x).abs() < 1e-5 &&
          (y - other.y).abs() < 1e-5;

  @override
  int get hashCode => Object.hash(
        (x * 1000).round(),
        (y * 1000).round(),
      );

  @override
  String toString() =>
      'RadarPoint(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)})';
}

/// Vértice calculado de um dos 5 eixos canônicos do pentágono de evolução.
class RadarAxisVertex {
  const RadarAxisVertex({
    required this.category,
    required this.angleRadians,
    required this.normalizedRatio,
    required this.durationSeconds,
    required this.outerVertex,
    required this.dataVertex,
  });

  final ActivityCategory category;
  final double angleRadians;
  final double normalizedRatio;
  final int durationSeconds;
  final RadarPoint outerVertex;
  final RadarPoint dataVertex;
}

/// Estrutura imutável com a malha geométrica e o polígono de dados de evolução.
class RadarPolygonData {
  RadarPolygonData({
    required this.center,
    required this.maxRadius,
    required this.maxDurationSeconds,
    required List<List<RadarPoint>> gridRings,
    required List<RadarAxisVertex> axes,
    required List<RadarPoint> dataPolygonPoints,
  })  : gridRings = List.unmodifiable(
          gridRings.map((r) => List<RadarPoint>.unmodifiable(r)),
        ),
        axes = List.unmodifiable(axes),
        dataPolygonPoints = List.unmodifiable(dataPolygonPoints);

  final RadarPoint center;
  final double maxRadius;
  final int maxDurationSeconds;

  /// Exatamente 4 anéis concêntricos (níveis 0.25, 0.50, 0.75, 1.0) com 5 vértices cada.
  final List<List<RadarPoint>> gridRings;

  /// Os 5 eixos canônicos ordenados de 0 a 4.
  final List<RadarAxisVertex> axes;

  /// Os vértices ordenados do polígono de dados prontos para desenho.
  final List<RadarPoint> dataPolygonPoints;
}
