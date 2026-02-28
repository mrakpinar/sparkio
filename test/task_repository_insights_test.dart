import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparkio/models/task.dart';
import 'package:sparkio/services/task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('TaskRepository personal insights', () {
    test(
      'logs completion hour and task insight when task is provided',
      () async {
        final repo = TaskRepository();
        final task = Task(
          id: 't1',
          title: 'Take 3 slow breaths',
          category: 'mind',
          difficulty: 'easy',
          durationMinutes: 2,
        );
        final at = DateTime(2026, 2, 25, 21, 15);

        await repo.incrementCompleted('mind', task: task, completedAt: at);

        final hours = await repo.getCompletionHourCounts();
        final topTasks = await repo.getTopTaskCompletionInsights(limit: 3);

        expect(hours[21], 1);
        expect(topTasks, isNotEmpty);
        expect(topTasks.first.title, 'Take 3 slow breaths');
        expect(topTasks.first.category, 'mind');
        expect(topTasks.first.count, 1);
      },
    );

    test('does not log task insight when task is omitted', () async {
      final repo = TaskRepository();

      await repo.incrementCompleted('mind');

      final hours = await repo.getCompletionHourCounts();
      final topTasks = await repo.getTopTaskCompletionInsights(limit: 3);

      expect(hours, isEmpty);
      expect(topTasks, isEmpty);
    });
  });
}
