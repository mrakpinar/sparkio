import 'package:flutter/material.dart';

import '../models/task.dart';

class HomeReflectionSliver extends StatelessWidget {
  const HomeReflectionSliver({
    super.key,
    required this.doneCount,
    required this.completedTasks,
    required this.weeklyDoneCount,
    required this.weeklyTargetCount,
  });

  final int doneCount;
  final List<Task> completedTasks;
  final int weeklyDoneCount;
  final int weeklyTargetCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'One tiny step is enough.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withOpacity(0.84),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Start now - keep it light.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'No pressure, just momentum.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withOpacity(0.72),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
