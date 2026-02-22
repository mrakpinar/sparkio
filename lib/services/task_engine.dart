import 'dart:math';
import '../models/task.dart';

class TaskEngine {
  List<Task> pickDailyTasks({
    required List<Task> pool,
    required int count,
    required String seedKey, // yyyy-MM-dd
    Map<String, int>? weeklyTargets,
    Map<String, int>? weeklyDone,
  }) {
    final rng = Random(seedKey.hashCode);
    if (pool.isEmpty || count <= 0) return const [];

    final targets = weeklyTargets ?? const <String, int>{};
    if (targets.isEmpty) {
      final copy = [...pool]..shuffle(rng);
      return copy.take(count).toList();
    }

    final done = weeklyDone ?? const <String, int>{};
    final remaining = <String, int>{};
    final preferredCategories = <String>{};
    for (final entry in targets.entries) {
      if (entry.value > 0) {
        preferredCategories.add(entry.key);
      }
      final left = entry.value - (done[entry.key] ?? 0);
      if (left > 0) {
        remaining[entry.key] = left;
      }
    }

    // Weekly targets may exist but all values can be zero after filtering.
    if (remaining.isEmpty && preferredCategories.isEmpty) {
      final copy = [...pool]..shuffle(rng);
      return copy.take(count).toList();
    }

    final available = [...pool];
    final picked = <Task>[];
    while (available.isNotEmpty && picked.length < count) {
      final chosen = _pickWeightedTask(
        available: available,
        remaining: remaining,
        preferredCategories: preferredCategories,
        rng: rng,
      );
      picked.add(chosen);
      available.remove(chosen);
    }
    return picked;
  }

  Task _pickWeightedTask({
    required List<Task> available,
    required Map<String, int> remaining,
    required Set<String> preferredCategories,
    required Random rng,
  }) {
    var totalWeight = 0.0;
    final weights = List<double>.filled(available.length, 0.0);
    for (var i = 0; i < available.length; i++) {
      final category = available[i].category;
      final left = remaining[category] ?? 0;
      final preferredBoost = preferredCategories.contains(category) ? 0.9 : 0.0;
      final weight = left > 0
          ? (1.0 + preferredBoost + (left * 1.5))
          : (0.35 + preferredBoost);
      weights[i] = weight;
      totalWeight += weight;
    }

    if (totalWeight <= 0) {
      return available[rng.nextInt(available.length)];
    }

    var roll = rng.nextDouble() * totalWeight;
    for (var i = 0; i < available.length; i++) {
      roll -= weights[i];
      if (roll <= 0) {
        return available[i];
      }
    }
    return available.last;
  }
}
