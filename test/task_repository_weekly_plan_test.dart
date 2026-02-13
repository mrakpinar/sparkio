import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparkio/models/weekly_plan.dart';
import 'package:sparkio/services/task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('TaskRepository weekly plan', () {
    test('saves and loads weekly plan for current week', () async {
      final repo = TaskRepository();
      const weekKey = '2026-02-09';
      const plan = WeeklyPlan(
        weekKey: weekKey,
        targets: {'mind': 8, 'body': 5},
      );

      await repo.saveWeeklyPlan(plan);
      final loaded = await repo.getWeeklyPlan(weekKey: weekKey);

      expect(loaded, isNotNull);
      expect(loaded!.weekKey, weekKey);
      expect(loaded.targets['mind'], 8);
      expect(loaded.targets['body'], 5);
    });

    test(
      'returns null when requested week differs from saved plan week',
      () async {
        final repo = TaskRepository();
        await repo.saveWeeklyPlan(
          const WeeklyPlan(weekKey: '2026-02-09', targets: {'mind': 6}),
        );

        final loaded = await repo.getWeeklyPlan(weekKey: '2026-02-16');
        expect(loaded, isNull);
      },
    );

    test('weekly progress resets for a new week key', () async {
      final repo = TaskRepository();
      await repo.saveWeeklyProgress(
        const WeeklyProgress(weekKey: '2026-02-09', done: {'mind': 3}),
      );

      final oldWeek = await repo.getWeeklyProgress(weekKey: '2026-02-09');
      final newWeek = await repo.getWeeklyProgress(weekKey: '2026-02-16');

      expect(oldWeek.done['mind'], 3);
      expect(newWeek.done, isEmpty);
      expect(newWeek.weekKey, '2026-02-16');
    });

    test('incrementWeeklyProgress increases selected category count', () async {
      final repo = TaskRepository();
      const weekKey = '2026-02-09';

      final first = await repo.incrementWeeklyProgress(
        weekKey: weekKey,
        category: 'growth',
      );
      final second = await repo.incrementWeeklyProgress(
        weekKey: weekKey,
        category: 'growth',
      );

      expect(first.done['growth'], 1);
      expect(second.done['growth'], 2);
    });
  });
}
