import 'package:beatly/domain/models/activity_category.dart';
import 'package:beatly/domain/models/routine.dart';
import 'package:beatly/domain/models/routine_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Routine Domain Model (RF-05 / EC-04)', () {
    final now = DateTime.utc(2026, 11, 8, 12);

    test(
      'TC-05.01: rotina com 3 atividades (10m, 15m, 5m) e transição de 5s calcula 30m10s (1810s) (B-RF-05.1)',
      () {
        final routine = Routine(
          id: 'r-1',
          name: 'Treino Completo',
          createdAt: now,
          updatedAt: now,
          activities: [
            RoutineActivity(
              id: 'a-1',
              routineId: 'r-1',
              name: 'Aquecimento',
              category: ActivityCategory.tecnica,
              durationSeconds: 10 * 60,
              orderIndex: 0,
            ),
            RoutineActivity(
              id: 'a-2',
              routineId: 'r-1',
              name: 'Padrões Melódicos',
              category: ActivityCategory.velocidade,
              durationSeconds: 15 * 60,
              orderIndex: 1,
            ),
            RoutineActivity(
              id: 'a-3',
              routineId: 'r-1',
              name: 'Jam Livre',
              category: ActivityCategory.improviso,
              durationSeconds: 5 * 60,
              orderIndex: 2,
            ),
          ],
        );

        expect(routine.activitiesDurationSeconds, equals(1800));
        expect(
          routine.totalEstimatedDurationSeconds(transitionSeconds: 5),
          equals(1810),
        );
      },
    );

    test(
      'TC-05.02: rotina com 1 atividade (10m) calcula 10m (600s) sem tempo de transição adicional (EC-04)',
      () {
        final routine = Routine(
          id: 'r-2',
          name: 'Treino Rápido',
          createdAt: now,
          updatedAt: now,
          activities: [
            RoutineActivity(
              id: 'a-1',
              routineId: 'r-2',
              name: 'Escala Maior',
              category: ActivityCategory.tecnica,
              durationSeconds: 10 * 60,
              orderIndex: 0,
            ),
          ],
        );

        expect(
          routine.totalEstimatedDurationSeconds(transitionSeconds: 5),
          equals(600),
        );
      },
    );
  });
}

