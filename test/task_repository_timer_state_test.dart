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
        dateKey: '2026-02-13',
      );

      final restored = await repo.getActiveTaskTimer();
      expect(restored, isNotNull);
      expect(restored!.taskId, 'task_1');
      expect(restored.taskTitle, 'Breathing break');
      expect(
        restored.endAt.millisecondsSinceEpoch,
        endAt.millisecondsSinceEpoch,
      );
      expect(restored.belongsToDay('2026-02-13'), isTrue);
      expect(restored.belongsToDay('2026-02-14'), isFalse);
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

    test('a timer ending tomorrow still belongs to its start day', () async {
      final repo = TaskRepository();
      await repo.saveActiveTaskTimer(
        taskId: 'same_id',
        taskTitle: 'Task',
        dateKey: '2026-11-10',
        endAt: DateTime(2026, 11, 11, 0, 5),
      );
      final timer = (await repo.getActiveTaskTimer())!;
      expect(timer.belongsToDay('2026-11-10'), isTrue);
      expect(timer.belongsToDay('2026-11-11'), isFalse);
    });

    test(
      'legacy timer without a start day cannot be assigned to today',
      () async {
        SharedPreferences.setMockInitialValues({
          'active_timer_task_id_v1': 'legacy',
          'active_timer_task_title_v1': 'Old task',
          'active_timer_end_at_ms_v1': DateTime(
            2026,
            11,
            11,
            0,
            5,
          ).millisecondsSinceEpoch,
        });
        final repo = TaskRepository();
        final timer = (await repo.getActiveTaskTimer())!;
        expect(timer.dateKey, isNull);
        expect(timer.belongsToDay('2026-11-11'), isFalse);
      },
    );
  });
}
