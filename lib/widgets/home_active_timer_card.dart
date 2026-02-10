import 'package:flutter/material.dart';

import '../models/task.dart';

class HomeActiveTimerCard extends StatelessWidget {
  const HomeActiveTimerCard({
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

  String _format(Duration d) {
    final totalSeconds = d.inSeconds.clamp(0, 360000);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalSeconds = (task.durationMinutes * 60).clamp(1, 360000);
    final progress = 1 - (remaining.inSeconds.clamp(0, 360000) / totalSeconds);

    // Adaptive colors for light/dark mode
    final cardColor = isDark
        ? scheme.surfaceContainer
        : scheme.surfaceContainerHighest;

    final timerBgColor = isDark
        ? scheme.primaryContainer
        : scheme.primaryContainer.withOpacity(0.5);

    final progressBgColor = isDark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(isDark ? 0.3 : 0.5),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: scheme.shadow.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and task info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: done
                        ? [
                            scheme.tertiary.withOpacity(0.2),
                            scheme.tertiary.withOpacity(0.1),
                          ]
                        : [
                            scheme.primary.withOpacity(0.2),
                            scheme.primary.withOpacity(0.1),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  done ? Icons.check_circle_rounded : Icons.timer_rounded,
                  color: done ? scheme.tertiary : scheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done ? 'Time is up!' : 'Active Timer',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Large timer display
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: timerBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: done
                      ? scheme.tertiary.withOpacity(0.3)
                      : scheme.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: done ? scheme.tertiary : scheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    done ? '00:00' : _format(remaining),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: done ? scheme.tertiary : scheme.primary,
                      fontFeatures: [const FontFeature.tabularFigures()],
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(progress * 100).clamp(0, 100).toInt()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: progressBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: done
                                ? [
                                    scheme.tertiary,
                                    scheme.tertiary.withOpacity(0.7),
                                  ]
                                : [
                                    scheme.primary,
                                    scheme.primary.withOpacity(0.7),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: (done ? scheme.tertiary : scheme.primary)
                                  .withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: scheme.outline.withOpacity(isDark ? 0.5 : 0.7),
                    ),
                    foregroundColor: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onComplete,
                  icon: Icon(
                    done ? Icons.check_rounded : Icons.play_arrow_rounded,
                    size: 20,
                  ),
                  label: Text(done ? 'Complete' : 'Continue'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: done ? scheme.tertiary : scheme.primary,
                    foregroundColor: done
                        ? scheme.onTertiary
                        : scheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
