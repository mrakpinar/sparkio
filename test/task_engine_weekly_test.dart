import 'package:flutter_test/flutter_test.dart';
import 'package:sparkio/models/task.dart';
import 'package:sparkio/services/task_engine.dart';

void main() {
  group('TaskEngine weekly weighting', () {
    final engine = TaskEngine();
    final pool = <Task>[
      const Task(id: 'm1', title: 'm1', category: 'mind'),
      const Task(id: 'm2', title: 'm2', category: 'mind'),
      const Task(id: 'm3', title: 'm3', category: 'mind'),
      const Task(id: 'b1', title: 'b1', category: 'body'),
      const Task(id: 'b2', title: 'b2', category: 'body'),
      const Task(id: 'g1', title: 'g1', category: 'growth'),
    ];

    test('falls back to random when no weekly targets', () {
      final picked = engine.pickDailyTasks(
        pool: pool,
        count: 3,
        seedKey: '2026-02-13',
      );

      expect(picked, hasLength(3));
    });

    test('biases picks toward categories with higher remaining goals', () {
      var mindCount = 0;
      var bodyCount = 0;
      for (var i = 0; i < 120; i++) {
        final picked = engine.pickDailyTasks(
          pool: pool,
          count: 3,
          seedKey: 'seed_$i',
          weeklyTargets: const {'mind': 10, 'body': 2},
          weeklyDone: const {'mind': 1, 'body': 1},
        );
        for (final task in picked) {
          if (task.category == 'mind') mindCount++;
          if (task.category == 'body') bodyCount++;
        }
      }

      expect(mindCount, greaterThan(bodyCount));
    });

    test('still returns tasks when weekly goals are already hit', () {
      final picked = engine.pickDailyTasks(
        pool: pool,
        count: 3,
        seedKey: '2026-02-14',
        weeklyTargets: const {'mind': 1},
        weeklyDone: const {'mind': 1},
      );

      expect(picked, hasLength(3));
    });
  });
}
