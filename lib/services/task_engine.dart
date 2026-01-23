import 'dart:math';
import '../models/task.dart';

class TaskEngine {
  List<Task> pickDailyTasks({
    required List<Task> pool,
    required int count,
    required String seedKey, // yyyy-MM-dd
  }) {
    final rng = Random(seedKey.hashCode);
    final copy = [...pool]..shuffle(rng);
    return copy.take(count).toList();
  }
}
