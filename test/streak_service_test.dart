import 'package:flutter_test/flutter_test.dart';
import 'package:sparkio/services/streak_service.dart';

void main() {
  group('StreakService.resolveNextStreak', () {
    test('does not update when last completion is today', () {
      final today = DateTime(2026, 2, 13, 10, 0);
      final result = StreakService.resolveNextStreak(
        currentStreak: 4,
        today: today,
        lastCompletedDate: DateTime(2026, 2, 13, 7, 20),
      );

      expect(result.shouldUpdate, isFalse);
      expect(result.nextStreak, 4);
    });

    test('increments when last completion is yesterday', () {
      final result = StreakService.resolveNextStreak(
        currentStreak: 4,
        today: DateTime(2026, 2, 13),
        lastCompletedDate: DateTime(2026, 2, 12),
      );

      expect(result.shouldUpdate, isTrue);
      expect(result.nextStreak, 5);
    });

    test('resets to 1 when there is a day gap', () {
      final result = StreakService.resolveNextStreak(
        currentStreak: 7,
        today: DateTime(2026, 2, 13),
        lastCompletedDate: DateTime(2026, 2, 10),
      );

      expect(result.shouldUpdate, isTrue);
      expect(result.nextStreak, 1);
    });
  });
}

