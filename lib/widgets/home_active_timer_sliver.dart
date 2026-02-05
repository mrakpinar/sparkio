import 'package:flutter/material.dart';

import '../models/task.dart';
import 'home_active_timer_card.dart';

class HomeActiveTimerSliver extends StatelessWidget {
  const HomeActiveTimerSliver({
    super.key,
    required this.task,
    required this.remaining,
    required this.done,
    required this.onCancel,
    this.onComplete,
  });

  final Task task;
  final Duration remaining;
  final bool done;
  final VoidCallback onCancel;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: HomeActiveTimerCard(
          task: task,
          remaining: remaining,
          done: done,
          onCancel: onCancel,
          onComplete: onComplete,
        ),
      ),
    );
  }
}
