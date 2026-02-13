class StreakResolution {
  const StreakResolution({
    required this.nextStreak,
    required this.shouldUpdate,
  });

  final int nextStreak;
  final bool shouldUpdate;
}

class StreakService {
  static StreakResolution resolveNextStreak({
    required int currentStreak,
    required DateTime today,
    DateTime? lastCompletedDate,
  }) {
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedLast = lastCompletedDate == null
        ? null
        : DateTime(
            lastCompletedDate.year,
            lastCompletedDate.month,
            lastCompletedDate.day,
          );

    if (normalizedLast != null) {
      final diffDays = normalizedToday.difference(normalizedLast).inDays;
      if (diffDays == 0) {
        return StreakResolution(nextStreak: currentStreak, shouldUpdate: false);
      }
      if (diffDays == 1 || diffDays < 0) {
        return StreakResolution(
          nextStreak: currentStreak + 1,
          shouldUpdate: true,
        );
      }
      return const StreakResolution(nextStreak: 1, shouldUpdate: true);
    }

    if (currentStreak > 0) {
      return StreakResolution(nextStreak: currentStreak + 1, shouldUpdate: true);
    }
    return const StreakResolution(nextStreak: 1, shouldUpdate: true);
  }
}

