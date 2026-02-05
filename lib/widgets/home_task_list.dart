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
    final total = tasks.length;
    final done = tasks.where((task) => completed[task.id] ?? false).length;
    final progress = total == 0 ? null : done / total;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final task = tasks[i];
            final checked = completed[task.id] ?? false;
            return TaskCard(
              key: ValueKey(task.id),
              task: task,
              checked: checked,
              onTap: () => onToggle(task),
              onSkip: () => onSkip(task),
              canSkip: canSkip,
              progress: progress,
            );
          },
          childCount: tasks.length,
        ),
      ),
    );
  }
}
