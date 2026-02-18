import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/task_category_style.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.checked,
    this.isTimerActive = false,
    this.timerRemaining,
    this.timerDone = false,
    this.onCancelTimer,
    this.onCompleteTimer,
    required this.onTap,
    this.onSkip,
    this.canSkip = false,
    this.progress,
    this.progressLabel = 'Daily progress',
  });

  final Task task;
  final bool checked;
  final bool isTimerActive;
  final Duration? timerRemaining;
  final bool timerDone;
  final VoidCallback? onCancelTimer;
  final VoidCallback? onCompleteTimer;
  final VoidCallback onTap;
  final VoidCallback? onSkip;
  final bool canSkip;
  final double? progress;
  final String progressLabel;

  String _difficultyLabel(String d) {
    switch (d) {
      case 'hard':
        return 'Hard';
      case 'medium':
        return 'Medium';
      default:
        return 'Easy';
    }
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'hard':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds.clamp(0, 360000);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int _xpReward(Task t) {
    final base = switch (t.difficulty) {
      'hard' => 8,
      'medium' => 6,
      _ => 5,
    };
    return t.isSpecial ? base + 2 : base;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = TaskCategoryStyle.color(
      task.category,
      fallback: scheme.primary,
    );
    const timerAccent = Color(0xFF38BDF8);
    const skipAccent = Color(0xFF22D3EE);

    final hasInlineTimer = timerRemaining != null;
    final timerActive = (isTimerActive || hasInlineTimer) && !checked;
    final remaining = timerRemaining ?? Duration.zero;
    final totalSeconds = (task.durationMinutes * 60).clamp(1, 360000);
    final timerProgress = hasInlineTimer
        ? 1 - (remaining.inSeconds / totalSeconds)
        : 0.0;
    final xp = _xpReward(task);
    final status = checked
        ? _TaskStatusType.done
        : (task.isSpecial
              ? _TaskStatusType.streakBonus
              : _TaskStatusType.pending);

    final background = timerActive
        ? Color.alphaBlend(
            accent.withOpacity(isDark ? 0.14 : 0.08),
            isDark ? const Color(0xFF121A2A) : scheme.surface,
          )
        : Color.alphaBlend(
            (isDark ? const Color(0xFF1D2A44) : scheme.primary).withOpacity(
              isDark ? 0.1 : 0.02,
            ),
            isDark ? const Color(0xFF121A2A) : scheme.surface,
          );

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: checked ? 0.72 : 1,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          offset: checked ? const Offset(0.01, 0) : Offset.zero,
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (timerActive || checked) ? null : onTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 2,
                        bottom: 2,
                        child: Container(
                          width: 3.5,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(checked ? 0.45 : 0.95),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: accent.withOpacity(
                                      isDark ? 0.2 : 0.14,
                                    ),
                                  ),
                                  child: Icon(
                                    TaskCategoryStyle.icon(task.category),
                                    color: accent,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _PillTag(
                                            text: TaskCategoryStyle.label(
                                              task.category,
                                            ).toUpperCase(),
                                            color: accent,
                                          ),
                                          if (timerActive) ...[
                                            const SizedBox(width: 6),
                                            _PillTag(
                                              text: timerDone ? 'DONE' : 'LIVE',
                                              color: timerDone
                                                  ? scheme.tertiary
                                                  : timerAccent,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        task.title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.1,
                                              height: 1.3,
                                              decoration: checked
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.bolt_rounded,
                                            size: 14,
                                            color: checked
                                                ? const Color(0xFF22C55E)
                                                : accent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            checked
                                                ? 'Earned +$xp XP'
                                                : '+$xp XP reward',
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  color: checked
                                                      ? const Color(0xFF22C55E)
                                                      : accent,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          _MetricChip(
                                            icon: Icons.schedule_rounded,
                                            label:
                                                '${task.durationMinutes} min',
                                            color: const Color(0xFF14B8A6),
                                          ),
                                          _MetricChip(
                                            icon: Icons.bolt_rounded,
                                            label: _difficultyLabel(
                                              task.difficulty,
                                            ),
                                            color: _difficultyColor(
                                              task.difficulty,
                                            ),
                                          ),
                                          if (task.aiSuggested)
                                            const _MetaChip(
                                              icon: Icons.auto_awesome_rounded,
                                              label: 'AI',
                                            ),
                                          if (task.isCustom)
                                            const _MetaChip(
                                              icon: Icons.edit_rounded,
                                              label: 'Custom',
                                            ),
                                          if (task.premiumOnly)
                                            const _MetaChip(
                                              icon: Icons
                                                  .workspace_premium_rounded,
                                              label: 'Premium',
                                            ),
                                          if (task.isSpecial)
                                            const _MetaChip(
                                              icon: Icons.star_rounded,
                                              label: 'Special',
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _TaskStatusChip(status: status),
                                    if (!checked &&
                                        !timerActive &&
                                        onSkip != null) ...[
                                      const SizedBox(height: 8),
                                      IconButton(
                                        onPressed: canSkip ? onSkip : null,
                                        tooltip: canSkip
                                            ? 'Skip task'
                                            : 'Skip limit reached',
                                        icon: const Icon(
                                          Icons.fast_forward_rounded,
                                          size: 19,
                                        ),
                                        style: IconButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          foregroundColor: canSkip
                                              ? skipAccent
                                              : scheme.onSurfaceVariant
                                                    .withOpacity(0.6),
                                          backgroundColor: canSkip
                                              ? skipAccent.withOpacity(0.12)
                                              : scheme.surfaceContainerHighest
                                                    .withOpacity(0.18),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            if (timerActive) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Color.alphaBlend(
                                    accent.withOpacity(isDark ? 0.12 : 0.06),
                                    scheme.surface,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                timerDone
                                                    ? 'Timer finished'
                                                    : 'Timer running',
                                                style: theme
                                                    .textTheme
                                                    .labelLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                timerDone
                                                    ? 'You can mark this task complete.'
                                                    : 'Keep going until the timer ends.',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            color: scheme.surface,
                                          ),
                                          child: Text(
                                            timerDone
                                                ? '00:00'
                                                : _formatDuration(remaining),
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: timerDone
                                                      ? scheme.tertiary
                                                      : timerAccent,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (hasInlineTimer) ...[
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: timerProgress.clamp(0.0, 1.0),
                                          minHeight: 8,
                                          backgroundColor: scheme.surfaceVariant
                                              .withOpacity(0.75),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                timerDone
                                                    ? scheme.tertiary
                                                    : timerAccent,
                                              ),
                                        ),
                                      ),
                                    ],
                                    if (!timerDone &&
                                        onCancelTimer != null) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: onCancelTimer,
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                          ),
                                          label: const Text('Stop timer'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFFF59E8B,
                                            ),
                                            backgroundColor: Color.alphaBlend(
                                              const Color(
                                                0xFFFECACA,
                                              ).withOpacity(0.16),
                                              scheme.surfaceContainerHighest
                                                  .withOpacity(0.58),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (timerDone &&
                                        onCompleteTimer != null) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          onPressed: onCompleteTimer,
                                          icon: const Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                          ),
                                          label: const Text('Mark complete'),
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 11,
                                            ),
                                            backgroundColor: scheme.tertiary,
                                            foregroundColor: scheme.onTertiary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _TaskStatusType { pending, done, streakBonus }

class _TaskStatusChip extends StatelessWidget {
  const _TaskStatusChip({required this.status});

  final _TaskStatusType status;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;
    Color color;
    switch (status) {
      case _TaskStatusType.done:
        icon = Icons.check_circle_rounded;
        label = 'Done';
        color = const Color(0xFF22C55E);
      case _TaskStatusType.streakBonus:
        icon = Icons.local_fire_department_rounded;
        label = 'Streak bonus';
        color = const Color(0xFFF59E0B);
      case _TaskStatusType.pending:
        icon = Icons.hourglass_top_rounded;
        label = 'Pending';
        color = const Color(0xFF7C83FF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: scheme.surfaceContainerHighest.withOpacity(0.24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.16),
            ),
            child: Icon(icon, size: 10, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: Color.alphaBlend(
                color.withOpacity(0.12),
                scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.14),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}
