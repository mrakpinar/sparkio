import 'package:flutter/material.dart';

import '../app_strings.dart';
import '../models/task.dart';
import '../services/task_localizer.dart';

class HomeMomentumReinforcementSliver extends StatelessWidget {
  const HomeMomentumReinforcementSliver({
    super.key,
    required this.doneCount,
    required this.totalCompletedSeconds,
    required this.hasPendingNext,
    required this.completedTasks,
    required this.weeklyDoneCount,
    required this.weeklyTargetCount,
  });

  final int doneCount;
  final int totalCompletedSeconds;
  final bool hasPendingNext;
  final List<Task> completedTasks;
  final int weeklyDoneCount;
  final int weeklyTargetCount;

  String _formatTotalDuration(BuildContext context, int seconds) {
    final l10n = context.l10n;
    final safe = seconds.clamp(0, 360000);
    if (safe < 60) return '$safe ${l10n.tr('seconds')}';
    final mins = safe ~/ 60;
    if (mins == 1) return '1 ${l10n.tr('minute')}';
    return '$mins ${l10n.tr('minutes')}';
  }

  String _formatTaskDuration(BuildContext context, Task task) {
    final l10n = context.l10n;
    final sec = task.totalDurationSeconds.clamp(1, 360000);
    if (sec < 60) return '$sec ${l10n.tr('seconds')}';
    if (sec % 60 == 0) {
      final mins = sec ~/ 60;
      return mins == 1 ? '1 ${l10n.tr('min')}' : '$mins ${l10n.tr('min')}';
    }
    final mins = sec ~/ 60;
    final rest = sec % 60;
    return '$mins ${l10n.tr('min')} $rest ${l10n.tr('seconds')}';
  }

  Widget _statusRow({
    required BuildContext context,
    required bool active,
    required String text,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          active
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: active
              ? const Color(0xFF8776FF)
              : scheme.onSurfaceVariant.withOpacity(0.62),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: active
                  ? scheme.onSurface.withOpacity(0.9)
                  : scheme.onSurfaceVariant.withOpacity(0.8),
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final history = completedTasks.take(3).toList(growable: false);
    final weeklyTargetSafe = weeklyTargetCount.clamp(0, 999);
    final weeklyDoneSafe = weeklyDoneCount.clamp(0, weeklyTargetSafe);
    final weeklyProgress = weeklyTargetSafe == 0
        ? 0.0
        : (weeklyDoneSafe / weeklyTargetSafe).clamp(0.0, 1.0).toDouble();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: scheme.surface.withOpacity(isDark ? 0.76 : 0.9),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tr('Momentum'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface.withOpacity(0.88),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _statusRow(
                    context: context,
                    active: doneCount > 0,
                    text: l10n.tr('You showed up today.'),
                  ),
                  const SizedBox(height: 6),
                  _statusRow(
                    context: context,
                    active: totalCompletedSeconds > 0,
                    text: l10n.trf('{duration} done', {
                      'duration': _formatTotalDuration(
                        context,
                        totalCompletedSeconds,
                      ),
                    }),
                  ),
                  const SizedBox(height: 6),
                  _statusRow(
                    context: context,
                    active: !hasPendingNext && doneCount > 0,
                    text: l10n.tr('Next builds consistency'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: scheme.surface.withOpacity(isDark ? 0.74 : 0.88),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tr("Today's tiny wins"),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface.withOpacity(0.88),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (history.isEmpty)
                    Text(
                      l10n.tr(
                        'No sparks yet. Your first one starts the story.',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant.withOpacity(0.78),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    ...history.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Color(0xFF8776FF),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${TaskLocalizer.localizeTitle(task.title, category: task.category, taskId: task.id)} - ${_formatTaskDuration(context, task)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: scheme.surface.withOpacity(isDark ? 0.72 : 0.86),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tr('Weekly arc'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface.withOpacity(0.88),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tr("This week you're training consistency."),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    weeklyTargetSafe > 0
                        ? l10n.trf('{done} of {total} sparks done.', {
                            'done': weeklyDoneSafe,
                            'total': weeklyTargetSafe,
                          })
                        : l10n.tr(
                            'Set a weekly spark target to start your arc.',
                          ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(0.84),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      value: weeklyProgress,
                      color: const Color(0xFF8776FF),
                      backgroundColor: scheme.onSurfaceVariant.withOpacity(
                        0.22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
