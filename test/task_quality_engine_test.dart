import 'package:flutter_test/flutter_test.dart';
import 'package:sparkio/services/task_quality_engine.dart';

void main() {
  group('TaskQualityEngine', () {
    test('normalizes placeholder seed title', () {
      final result = TaskQualityEngine.sanitize(
        rawTitle: 'Seed',
        category: 'mind',
        durationSeconds: 240,
      );

      expect(result.title, contains('Write one tiny intention'));
      expect(result.score, greaterThanOrEqualTo(55));
    });

    test('rejects vague custom input in strict mode', () {
      final result = TaskQualityEngine.sanitize(
        rawTitle: 'task',
        category: 'mind',
        durationSeconds: 300,
        strictUserInput: true,
      );

      expect(result.isValidForCustomInput, isFalse);
      expect(result.feedback, isNotNull);
    });

    test('keeps clear actionable titles', () {
      final result = TaskQualityEngine.sanitize(
        rawTitle: 'Drink one full glass of water',
        category: 'health',
        durationSeconds: 180,
      );

      expect(result.title, 'Drink one full glass of water');
      expect(result.usedFallback, isFalse);
      expect(result.score, greaterThanOrEqualTo(55));
    });
  });
}
