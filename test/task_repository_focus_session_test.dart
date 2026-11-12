import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparkio/models/focus_session.dart';
import 'package:sparkio/services/task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('paused sessions preserve remaining time and audio selection', () async {
    final repo = TaskRepository();
    const session = FocusSession(
      taskId: 'a',
      dateKey: '2026-11-10',
      totalSeconds: 60,
      remainingSeconds: 37,
      isPaused: true,
      activeTrack: 'Rain',
    );
    await repo.saveFocusSession(session);
    final restored = await TaskRepository().getFocusSession(
      taskId: 'a',
      dateKey: '2026-11-10',
    );
    expect(restored, isNotNull);
    expect(restored!.remainingAt(DateTime(2026, 11, 10, 23)), 37);
    expect(restored.totalSeconds, 60);
    expect(restored.isPaused, isTrue);
    expect(restored.activeTrack, 'Rain');
  });

  test('running sessions recover from the persisted deadline', () async {
    final repo = TaskRepository();
    final endAt = DateTime(2026, 11, 10, 12, 1);
    await repo.saveFocusSession(
      FocusSession(
        taskId: 'a',
        dateKey: '2026-11-10',
        totalSeconds: 60,
        remainingSeconds: 60,
        isPaused: false,
        endAt: endAt,
      ),
    );
    final restored = await TaskRepository().getFocusSession(
      taskId: 'a',
      dateKey: '2026-11-10',
    );
    expect(
      restored!.remainingAt(endAt.subtract(const Duration(seconds: 17))),
      17,
    );
    expect(restored.remainingAt(endAt.add(const Duration(minutes: 5))), 0);
    expect(
      restored.remainingAt(endAt.subtract(const Duration(minutes: 5))),
      60,
    );
  });

  test('zero remains restorable until explicit completion clears it', () async {
    final repo = TaskRepository();
    await repo.saveFocusSession(
      const FocusSession(
        taskId: 'a',
        dateKey: '2026-11-10',
        totalSeconds: 60,
        remainingSeconds: 0,
        isPaused: true,
      ),
    );
    expect(
      (await repo.getFocusSession(
        taskId: 'a',
        dateKey: '2026-11-10',
      ))!.remainingSeconds,
      0,
    );
    await repo.clearFocusSession(taskId: 'a', dateKey: '2026-11-10');
    expect(
      await repo.getFocusSession(taskId: 'a', dateKey: '2026-11-10'),
      isNull,
    );
  });

  test(
    'task and day isolation leave other sessions and home timer intact',
    () async {
      final repo = TaskRepository();
      for (final id in ['a', 'b']) {
        await repo.saveFocusSession(
          FocusSession(
            taskId: id,
            dateKey: '2026-11-10',
            totalSeconds: 60,
            remainingSeconds: 23,
            isPaused: true,
          ),
        );
      }
      final endAt = DateTime(2026, 11, 10, 15);
      await repo.saveActiveTaskTimer(
        taskId: 'home',
        taskTitle: 'Home task',
        endAt: endAt,
      );
      expect(
        await repo.getFocusSession(taskId: 'a', dateKey: '2026-11-11'),
        isNull,
      );
      await repo.clearFocusSession(taskId: 'a', dateKey: '2026-11-10');
      expect(
        await repo.getFocusSession(taskId: 'b', dateKey: '2026-11-10'),
        isNotNull,
      );
      expect((await repo.getActiveTaskTimer())!.endAt, endAt);
    },
  );

  test('malformed saved session is not restored', () async {
    SharedPreferences.setMockInitialValues({
      'focus_session_v1_2026-11-10_a': '{"remainingSeconds":-1}',
    });
    expect(
      await TaskRepository().getFocusSession(
        taskId: 'a',
        dateKey: '2026-11-10',
      ),
      isNull,
    );
  });
}
