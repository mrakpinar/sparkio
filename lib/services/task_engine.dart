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
    for (final entry in targets.entries) {
      final left = entry.value - (done[entry.key] ?? 0);
      if (left > 0) {
        remaining[entry.key] = left;
      }
    }

    // Weekly plan is set but all goals are already hit -> fallback to random.
    if (remaining.isEmpty) {
      final copy = [...pool]..shuffle(rng);
      return copy.take(count).toList();
    }

    final available = [...pool];
    final picked = <Task>[];
    while (available.isNotEmpty && picked.length < count) {
      final chosen = _pickWeightedTask(
        available: available,
        remaining: remaining,
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
    required Random rng,
  }) {
    var totalWeight = 0.0;
    final weights = List<double>.filled(available.length, 0.0);
    for (var i = 0; i < available.length; i++) {
      final category = available[i].category;
      final left = remaining[category] ?? 0;
      final weight = left > 0 ? (1.0 + (left * 1.5)) : 0.35;
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
