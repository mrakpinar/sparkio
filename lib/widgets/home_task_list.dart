import 'package:flutter/material.dart';

import '../models/task.dart';
import 'task_card.dart';

class HomeTaskListSliver extends StatelessWidget {
  const HomeTaskListSliver({
    super.key,
    required this.tasks,
    required this.completed,
    required this.canSkip,
    required this.onToggle,
    required this.onSkip,
  });

  final List<Task> tasks;
  final Map<String, bool> completed;
  final bool canSkip;
  final void Function(Task task) onToggle;
  final void Function(Task task) onSkip;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
      sliver: SliverList.separated(
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final task = tasks[i];
          final checked = completed[task.id] ?? false;
          return TaskCard(
            task: task,
            checked: checked,
            onTap: () => onToggle(task),
            onSkip: () => onSkip(task),
            canSkip: canSkip,
          );
        },
      ),
    );
  }
}
