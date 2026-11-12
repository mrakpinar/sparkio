import 'task.dart';

enum OnboardingGoal {
  consistency('consistency', 'growth'),
  burnout('burnout', 'calm'),
  focus('focus', 'mind');

  const OnboardingGoal(this.id, this.category);

  final String id;
  final String category;

  static OnboardingGoal? fromId(String? id) {
    for (final goal in values) {
      if (goal.id == id) return goal;
    }
    return null;
  }
}

/// Limits the one-time recommendation to the original first daily selection.
class OnboardingFirstSelection {
  const OnboardingFirstSelection({
    required this.dateKey,
    required this.taskIds,
    this.preferredTaskId,
  });

  final String dateKey;
  final List<String> taskIds;
  final String? preferredTaskId;

  String? preferredTaskFor(List<Task> tasks, String? currentDateKey) {
    if (dateKey != currentDateKey || tasks.length != taskIds.length) {
      return null;
    }
    for (var i = 0; i < tasks.length; i++) {
      if (tasks[i].id != taskIds[i]) return null;
    }
    return tasks.any((task) => task.id == preferredTaskId)
        ? preferredTaskId
        : null;
  }

  Map<String, dynamic> toMap() => {
    'dateKey': dateKey,
    'taskIds': taskIds,
    'preferredTaskId': preferredTaskId,
  };

  factory OnboardingFirstSelection.fromMap(Map<String, dynamic> map) =>
      OnboardingFirstSelection(
        dateKey: map['dateKey'] as String,
        taskIds: (map['taskIds'] as List).map((id) => id as String).toList(),
        preferredTaskId: map['preferredTaskId'] as String?,
      );
}
