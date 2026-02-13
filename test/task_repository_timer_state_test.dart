import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparkio/services/task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('TaskRepository active timer state', () {
    test('saves and restores active timer', () async {
      final repo = TaskRepository();
      final endAt = DateTime(2026, 2, 13, 9, 30);

      await repo.saveActiveTaskTimer(
        taskId: 'task_1',
        taskTitle: 'Breathing break',
        endAt: endAt,
      );

      final restored = await repo.getActiveTaskTimer();
      expect(restored, isNotNull);
      expect(restored!.taskId, 'task_1');
      expect(restored.taskTitle, 'Breathing break');
      expect(restored.endAt.millisecondsSinceEpoch, endAt.millisecondsSinceEpoch);
    });

    test('clears active timer state', () async {
      final repo = TaskRepository();
      await repo.saveActiveTaskTimer(
        taskId: 'task_2',
        taskTitle: 'Short walk',
        endAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      await repo.clearActiveTaskTimer();
      final restored = await repo.getActiveTaskTimer();
      expect(restored, isNull);
    });

    test('returns null when timer state is incomplete', () async {
      SharedPreferences.setMockInitialValues({
        'active_timer_task_id_v1': 'task_3',
      });
      final repo = TaskRepository();
      final restored = await repo.getActiveTaskTimer();
      expect(restored, isNull);
    });
  });
}

