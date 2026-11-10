import 'dart:math' as math;

import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/use_cases/calculate_radar_geometry_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = CalculateRadarGeometryUseCase();
  const centerX = 150.0;
  const centerY = 150.0;
  const maxRadius = 100.0;

  group('CalculateRadarGeometryUseCase Tests (TASK-07)', () {
    test(
      'TC-07.01: O vértice 0 (Técnica) deve estar posicionado rigorosamente no topo vertical (theta = -pi/2, x = Cx, y = Cy - Rmax)',
      () {
        final result = useCase.execute(
          categoryDurationsSeconds: {
            ActivityCategory.tecnica: 1000,
          },
          centerX: centerX,
          centerY: centerY,
          maxRadius: maxRadius,
        );

        final vertex0 = result.axes.firstWhere(
          (a) => a.category == ActivityCategory.tecnica,
        );

        expect(vertex0.angleRadians, closeTo(-math.pi / 2, 1e-9));
        expect(vertex0.outerVertex.x, closeTo(centerX, 1e-5));
        expect(vertex0.outerVertex.y, closeTo(centerY - maxRadius, 1e-5));
      },
    );

    test(
      'TC-07.02: Com tempos Técnica 1200s, Velocidade 900s, Teoria 600s, Improviso 0s, Free Style 0s: '
      'maxDuration deve ser 1200s, e razões normalizadas 1.0, 0.75, 0.50 e 0.0',
      () {
        final durations = {
          ActivityCategory.tecnica: 1200,
          ActivityCategory.velocidade: 900,
          ActivityCategory.teoriaMusical: 600,
          ActivityCategory.improviso: 0,
          ActivityCategory.freeStyle: 0,
        };

        final result = useCase.execute(
          categoryDurationsSeconds: durations,
          centerX: centerX,
          centerY: centerY,
          maxRadius: maxRadius,
        );

        expect(result.maxDurationSeconds, equals(1200));

        final ratioTecnica = result.axes
            .firstWhere((a) => a.category == ActivityCategory.tecnica)
            .normalizedRatio;
        final ratioVelocidade = result.axes
            .firstWhere((a) => a.category == ActivityCategory.velocidade)
            .normalizedRatio;
        final ratioTeoria = result.axes
            .firstWhere((a) => a.category == ActivityCategory.teoriaMusical)
            .normalizedRatio;
        final ratioImproviso = result.axes
            .firstWhere((a) => a.category == ActivityCategory.improviso)
            .normalizedRatio;
        final ratioFreeStyle = result.axes
            .firstWhere((a) => a.category == ActivityCategory.freeStyle)
            .normalizedRatio;

        expect(ratioTecnica, closeTo(1.0, 1e-5));
        expect(ratioVelocidade, closeTo(0.75, 1e-5));
        expect(ratioTeoria, closeTo(0.50, 1e-5));
        expect(ratioImproviso, closeTo(0.0, 1e-5));
        expect(ratioFreeStyle, closeTo(0.0, 1e-5));
      },
    );

    test(
      'TC-07.03: Para sessão com 0s em todas as categorias, deve retornar vértices de dados exatamente no centro (Cx, Cy) com ratio 0.0 sem NaN ou Infinity',
      () {
        final zeroDurations = {
          ActivityCategory.tecnica: 0,
          ActivityCategory.velocidade: 0,
          ActivityCategory.teoriaMusical: 0,
          ActivityCategory.improviso: 0,
          ActivityCategory.freeStyle: 0,
        };

        final result = useCase.execute(
          categoryDurationsSeconds: zeroDurations,
          centerX: centerX,
          centerY: centerY,
          maxRadius: maxRadius,
        );

        expect(result.maxDurationSeconds, equals(0));

        for (final axis in result.axes) {
          expect(axis.normalizedRatio, equals(0.0));
          expect(axis.dataVertex.x, closeTo(centerX, 1e-5));
          expect(axis.dataVertex.y, closeTo(centerY, 1e-5));
          expect(axis.dataVertex.x.isNaN, isFalse);
          expect(axis.dataVertex.x.isInfinite, isFalse);
          expect(axis.dataVertex.y.isNaN, isFalse);
          expect(axis.dataVertex.y.isInfinite, isFalse);
        }

        for (final pt in result.dataPolygonPoints) {
          expect(pt.x, closeTo(centerX, 1e-5));
          expect(pt.y, closeTo(centerY, 1e-5));
        }
      },
    );

    test(
      'TC-07.04: As grelhas poligonais de fundo (gridRings) devem gerar exatamente 4 níveis concêntricos (25%, 50%, 75%, 100%) de 5 vértices cada',
      () {
        final result = useCase.execute(
          categoryDurationsSeconds: const {},
          centerX: centerX,
          centerY: centerY,
          maxRadius: maxRadius,
        );

        expect(result.gridRings.length, equals(4));

        final expectedLevels = [0.25, 0.50, 0.75, 1.0];
        for (var ringIdx = 0; ringIdx < 4; ringIdx++) {
          final ring = result.gridRings[ringIdx];
          expect(ring.length, equals(5));

          final level = expectedLevels[ringIdx];
          final expectedRadius = maxRadius * level;

          // Vértice 0 (topo vertical, theta = -pi/2)
          final topVertex = ring[0];
          expect(topVertex.x, closeTo(centerX, 1e-5));
          expect(topVertex.y, closeTo(centerY - expectedRadius, 1e-5));
        }
      },
    );
  });
}
