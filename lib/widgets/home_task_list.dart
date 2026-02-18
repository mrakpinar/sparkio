import 'package:flutter/material.dart';

import '../models/task.dart';
import 'task_card.dart';

class HomeTaskListSliver extends StatelessWidget {
  const HomeTaskListSliver({
    super.key,
    required this.tasks,
    required this.completed,
    this.dimmed = false,
    this.activeTimerTaskId,
    this.activeTimerRemaining,
    this.activeTimerDone = false,
    this.onCancelTimer,
    this.onCompleteTimer,
    required this.canSkip,
    required this.onToggle,
    required this.onSkip,
  });

  final List<Task> tasks;
  final Map<String, bool> completed;
  final bool dimmed;
  final String? activeTimerTaskId;
  final Duration? activeTimerRemaining;
  final bool activeTimerDone;
  final void Function(Task task)? onCancelTimer;
  final void Function(Task task)? onCompleteTimer;
  final bool canSkip;
  final void Function(Task task) onToggle;
  final void Function(Task task) onSkip;

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    final done = tasks.where((task) => completed[task.id] ?? false).length;
    final progress = total == 0 ? null : done / total;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 2, 16, 104 + bottomInset),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, i) {
          final task = tasks[i];
          final checked = completed[task.id] ?? false;
          final isActive = activeTimerTaskId == task.id;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            opacity: dimmed ? 0.95 : 1.0,
            child: TaskCard(
              key: ValueKey(task.id),
              task: task,
              checked: checked,
              onTap: () => onToggle(task),
              onSkip: () => onSkip(task),
              canSkip: canSkip,
              progress: progress,
              isTimerActive: isActive,
              timerRemaining: isActive ? activeTimerRemaining : null,
              timerDone: isActive ? activeTimerDone : false,
              onCancelTimer: isActive && onCancelTimer != null
                  ? () => onCancelTimer!(task)
                  : null,
              onCompleteTimer: isActive && onCompleteTimer != null
                  ? () => onCompleteTimer!(task)
                  : null,
            ),
          );
        }, childCount: tasks.length),
      ),
    );
  }
}
