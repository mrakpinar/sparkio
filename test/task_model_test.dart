import 'package:flutter_test/flutter_test.dart';
import 'package:sparkio/models/task.dart';

void main() {
  group('Task.fromMap', () {
    test(
      'uses explicit duration written in title when backend minutes conflict',
      () {
        final task = Task.fromMap({
          'id': 'body_balance_1',
          'title': 'Stand on one foot for 30 seconds',
          'category': 'body',
          'difficulty': 'easy',
          'durationMinutes': 4,
        });

        expect(task.totalDurationSeconds, 30);
        expect(task.durationSeconds, 30);
        expect(task.durationMinutes, 1);
      },
    );

    test('uses the last duration mention from the title', () {
      final task = Task.fromMap({
        'id': 'calm_breath_1',
        'title': 'Breathe in for 4 and out for 6 for 2 minutes',
        'category': 'calm',
        'difficulty': 'easy',
        'durationMinutes': 5,
      });

      expect(task.totalDurationSeconds, 120);
      expect(task.durationSeconds, 120);
      expect(task.durationMinutes, 2);
    });

    test('uses hyphenated minute duration from the title', () {
      final task = Task.fromMap({
        'id': 'calm_reset_1',
        'title': '2-minute reset: breathe slowly and relax your shoulders',
        'category': 'calm',
        'difficulty': 'easy',
        'durationMinutes': 3,
      });

      expect(task.totalDurationSeconds, 120);
      expect(task.durationSeconds, 120);
      expect(task.durationMinutes, 2);
    });

    test('keeps backend duration when title has no explicit time', () {
      final task = Task.fromMap({
        'id': 'mind_focus_1',
        'title': 'Write one clear priority for today',
        'category': 'mind',
        'difficulty': 'easy',
        'durationMinutes': 4,
      });

      expect(task.totalDurationSeconds, 240);
      expect(task.durationSeconds, isNull);
      expect(task.durationMinutes, 4);
    });
  });
}
