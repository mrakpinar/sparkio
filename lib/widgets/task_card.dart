import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
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

  IconData _iconFor(String c) {
    switch (c) {
      case 'body':
        return Icons.fitness_center_rounded;
      case 'mind':
        return Icons.psychology_rounded;
      case 'growth':
        return Icons.trending_up_rounded;
      case 'calm':
        return Icons.spa_rounded;
      case 'health':
        return Icons.favorite_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _labelFor(String c) {
    switch (c) {
      case 'body':
        return 'Body';
      case 'mind':
        return 'Mind';
      case 'growth':
        return 'Growth';
      case 'calm':
        return 'Calm';
      case 'health':
        return 'Health';
      default:
        return 'Task';
    }
  }

  Color _colorFor(BuildContext context, String c) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (c) {
      case 'body':
        return const Color(0xFFF97316); // Orange
      case 'mind':
        return const Color(0xFF8B5CF6); // Violet
      case 'growth':
        return const Color(0xFF22C55E); // Green
      case 'calm':
        return const Color(0xFF06B6D4); // Cyan
      case 'health':
        return const Color(0xFF3B82F6); // Blue
      default:
        return isDark ? scheme.primary : scheme.primary;
    }
  }

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

  String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds.clamp(0, 360000);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final catColor = _colorFor(context, task.category);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasInlineTimer = timerRemaining != null;
    final timerActive = (isTimerActive || hasInlineTimer) && !checked;
    final inlineRemaining = timerRemaining ?? Duration.zero;
    final totalSeconds = (task.durationMinutes * 60).clamp(1, 360000);
    final inlineProgress = hasInlineTimer
        ? 1 - (inlineRemaining.inSeconds / totalSeconds)
        : 0.0;
    final activeAccent = Color.lerp(catColor, scheme.primary, 0.4) ?? catColor;
    final cardRadius = BorderRadius.circular(24);
    final inactiveGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF091326), Color(0xFF0D1A2E), Color(0xFF0F1F33)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              scheme.surface,
              Color.lerp(scheme.surface, scheme.surfaceContainerHigh, 0.35) ??
                  scheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final activeGradient = isDark
        ? LinearGradient(
            colors: [
              const Color(0xFF0B1930),
              Color.alphaBlend(
                activeAccent.withOpacity(0.18),
                const Color(0xFF10223D),
              ),
              Color.alphaBlend(
                activeAccent.withOpacity(0.12),
                const Color(0xFF122944),
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              Color.alphaBlend(
                activeAccent.withOpacity(0.08),
                const Color(0xFFF6FAFF),
              ),
              Color.alphaBlend(
                activeAccent.withOpacity(0.06),
                const Color(0xFFEDF5FF),
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: checked ? 0 : 1,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          offset: checked ? const Offset(0.03, -0.02) : Offset.zero,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            scale: checked ? 0.98 : (timerActive ? 1.01 : 1.0),
            child: Align(
              heightFactor: checked ? 0 : 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: checked
                        ? null
                        : (timerActive ? activeGradient : inactiveGradient),
                    color: checked
                        ? (isDark
                              ? const Color(0xFF0D1B2E).withOpacity(0.82)
                              : scheme.surfaceVariant.withOpacity(0.5))
                        : null,
                    borderRadius: cardRadius,
                    border: Border.all(
                      color: checked
                          ? scheme.primary.withOpacity(0.35)
                          : timerActive
                          ? activeAccent.withOpacity(isDark ? 0.78 : 0.55)
                          : (isDark
                                ? const Color(0xFF2C4A7A).withOpacity(0.48)
                                : scheme.outline.withOpacity(0.35)),
                      width: timerActive ? 1.8 : 1,
                    ),
                    boxShadow: [
                      if (timerActive)
                        BoxShadow(
                          color: activeAccent.withOpacity(isDark ? 0.22 : 0.14),
                          blurRadius: isDark ? 24 : 16,
                          spreadRadius: isDark ? 1.2 : 0.4,
                          offset: const Offset(0, 10),
                        ),
                      if (isDark || timerActive)
                        BoxShadow(
                          color: checked
                              ? scheme.primary.withOpacity(0.1)
                              : Colors.black.withOpacity(
                                  timerActive ? 0.34 : 0.22,
                                ),
                          blurRadius: checked ? 10 : (timerActive ? 18 : 12),
                          offset: Offset(
                            0,
                            checked ? 3 : (timerActive ? 10 : 6),
                          ),
                        ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: cardRadius,
                      onTap: timerActive ? null : onTap,
                      splashColor: catColor.withOpacity(0.1),
                      highlightColor: catColor.withOpacity(0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (timerActive) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: activeAccent.withOpacity(
                                    isDark ? 0.18 : 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: activeAccent.withOpacity(
                                      isDark ? 0.55 : 0.4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      timerDone
                                          ? Icons.check_circle_rounded
                                          : Icons.bolt_rounded,
                                      size: 16,
                                      color: timerDone
                                          ? scheme.tertiary
                                          : activeAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      timerDone
                                          ? 'Timer finished'
                                          : 'Timer active',
                                      style: textTheme.labelMedium?.copyWith(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.95)
                                            : scheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      timerDone
                                          ? 'Ready to complete'
                                          : (hasInlineTimer
                                                ? _formatDuration(
                                                    inlineRemaining,
                                                  )
                                                : 'LIVE'),
                                      style: textTheme.labelMedium?.copyWith(
                                        color: timerDone
                                            ? scheme.tertiary
                                            : activeAccent,
                                        fontWeight: FontWeight.w800,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Row(
                              children: [
                                // Icon container
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(
                                      timerActive
                                          ? (isDark ? 0.18 : 0.2)
                                          : (isDark ? 0.1 : 0.12),
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: timerActive
                                          ? activeAccent.withOpacity(
                                              isDark ? 0.6 : 0.45,
                                            )
                                          : catColor.withOpacity(
                                              isDark ? 0.15 : 0.2,
                                            ),
                                      width: timerActive ? 1.4 : 1,
                                    ),
                                    boxShadow: timerActive
                                        ? [
                                            BoxShadow(
                                              color: activeAccent.withOpacity(
                                                isDark ? 0.28 : 0.16,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    _iconFor(task.category),
                                    size: 26,
                                    color: catColor,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Category badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: catColor.withOpacity(
                                            isDark ? 0.12 : 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: catColor.withOpacity(
                                              isDark ? 0.25 : 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: catColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _labelFor(
                                                task.category,
                                              ).toUpperCase(),
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: catColor,
                                                    letterSpacing: 1.1,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // Title
                                      Text(
                                        task.title,
                                        style: textTheme.titleMedium?.copyWith(
                                          decoration: checked
                                              ? TextDecoration.lineThrough
                                              : null,
                                          decorationColor: scheme.onSurface
                                              .withOpacity(0.5),
                                          decorationThickness: 2,
                                          color: checked
                                              ? scheme.onSurface.withOpacity(
                                                  0.5,
                                                )
                                              : (isDark
                                                    ? Colors.white.withOpacity(
                                                        0.95,
                                                      )
                                                    : scheme.onSurface),
                                          fontWeight: FontWeight.w700,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // Meta chips
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          _ModernMetaChip(
                                            icon: Icons.schedule_rounded,
                                            label: '${task.durationMinutes}m',
                                            color: const Color(0xFF3B82F6),
                                          ),
                                          _ModernMetaChip(
                                            icon: Icons
                                                .signal_cellular_alt_rounded,
                                            label: _difficultyLabel(
                                              task.difficulty,
                                            ),
                                            color: const Color(0xFF10B981),
                                          ),
                                          if (task.aiSuggested)
                                            _ModernMetaChip(
                                              icon: Icons.auto_awesome_rounded,
                                              label: 'AI',
                                              color: const Color(0xFF8B5CF6),
                                            ),
                                          if (task.premiumOnly)
                                            _ModernMetaChip(
                                              icon: Icons
                                                  .workspace_premium_rounded,
                                              label: 'Premium',
                                              color: const Color(0xFFFBBF24),
                                            ),
                                          if (task.isSpecial)
                                            _ModernMetaChip(
                                              icon: Icons.star_rounded,
                                              label: 'Special',
                                              color: const Color(0xFFF97316),
                                            ),
                                        ],
                                      ),

                                      // Inline timer
                                      if (hasInlineTimer) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(
                                                    0xFF0D1B2E,
                                                  ).withOpacity(0.6)
                                                : scheme.surfaceVariant
                                                      .withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color:
                                                  (timerDone
                                                          ? scheme.tertiary
                                                          : scheme.primary)
                                                      .withOpacity(0.4),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    colors: timerDone
                                                        ? [
                                                            scheme.tertiary,
                                                            scheme.tertiary
                                                                .withOpacity(
                                                                  0.6,
                                                                ),
                                                          ]
                                                        : [
                                                            scheme.primary,
                                                            scheme.primary
                                                                .withOpacity(
                                                                  0.6,
                                                                ),
                                                          ],
                                                  ),
                                                ),
                                                child: Icon(
                                                  timerDone
                                                      ? Icons.check_rounded
                                                      : Icons.timer_rounded,
                                                  color: scheme.onPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      timerDone
                                                          ? 'Time is up'
                                                          : 'Counting down',
                                                      style: textTheme
                                                          .labelMedium
                                                          ?.copyWith(
                                                            color: scheme
                                                                .onSurfaceVariant,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      timerDone
                                                          ? '00:00'
                                                          : _formatDuration(
                                                              inlineRemaining,
                                                            ),
                                                      style: textTheme
                                                          .titleLarge
                                                          ?.copyWith(
                                                            fontFeatures: const [
                                                              FontFeature.tabularFigures(),
                                                            ],
                                                            letterSpacing: 1.2,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: timerDone
                                                                ? scheme
                                                                      .tertiary
                                                                : scheme
                                                                      .primary,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: LinearProgressIndicator(
                                            minHeight: 8,
                                            value: inlineProgress.clamp(
                                              0.0,
                                              1.0,
                                            ),
                                            backgroundColor: scheme
                                                .outlineVariant
                                                .withOpacity(0.3),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  timerDone
                                                      ? scheme.tertiary
                                                      : scheme.primary,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: onCancelTimer,
                                                icon: const Icon(
                                                  Icons.stop_circle_rounded,
                                                  size: 18,
                                                ),
                                                label: const Text(
                                                  'Cancel timer',
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  foregroundColor:
                                                      scheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: FilledButton.icon(
                                                onPressed: timerDone
                                                    ? onCompleteTimer
                                                    : null,
                                                icon: Icon(
                                                  timerDone
                                                      ? Icons.check_rounded
                                                      : Icons.hourglass_bottom,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  timerDone
                                                      ? 'Mark complete'
                                                      : 'Running',
                                                ),
                                                style: FilledButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  backgroundColor: timerDone
                                                      ? scheme.tertiary
                                                      : scheme
                                                            .surfaceContainerHigh,
                                                  foregroundColor: timerDone
                                                      ? scheme.onTertiary
                                                      : scheme.onSurface,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],

                                      // Skip button
                                      if (!checked && onSkip != null) ...[
                                        const SizedBox(height: 10),
                                        TextButton.icon(
                                          onPressed: canSkip ? onSkip : null,
                                          icon: Icon(
                                            Icons.fast_forward_rounded,
                                            size: 16,
                                          ),
                                          label: Text(
                                            canSkip
                                                ? 'Skip this task'
                                                : 'Skip limit reached',
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            foregroundColor: canSkip
                                                ? (isDark
                                                      ? const Color(0xFF06B6D4)
                                                      : scheme.secondary)
                                                : (isDark
                                                      ? Colors.white
                                                            .withOpacity(0.4)
                                                      : scheme.onSurfaceVariant
                                                            .withOpacity(0.5)),
                                            backgroundColor: canSkip
                                                ? (isDark
                                                      ? const Color(
                                                          0xFF06B6D4,
                                                        ).withOpacity(0.12)
                                                      : scheme.secondary
                                                            .withOpacity(0.08))
                                                : (isDark
                                                      ? const Color(
                                                          0xFF1E3A5F,
                                                        ).withOpacity(0.2)
                                                      : scheme.surfaceVariant
                                                            .withOpacity(0.3)),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              side: BorderSide(
                                                color: canSkip
                                                    ? (isDark
                                                          ? const Color(
                                                              0xFF06B6D4,
                                                            ).withOpacity(0.3)
                                                          : scheme.secondary
                                                                .withOpacity(
                                                                  0.2,
                                                                ))
                                                    : (isDark
                                                          ? const Color(
                                                              0xFF1E3A5F,
                                                            ).withOpacity(0.3)
                                                          : scheme.outline
                                                                .withOpacity(
                                                                  0.15,
                                                                )),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Checkbox
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: checked
                                        ? LinearGradient(
                                            colors: [
                                              scheme.primary,
                                              scheme.primary.withOpacity(0.75),
                                            ],
                                          )
                                        : null,
                                    color: checked
                                        ? null
                                        : (isDark
                                              ? const Color(
                                                  0xFF1E3A5F,
                                                ).withOpacity(0.3)
                                              : scheme.surfaceVariant
                                                    .withOpacity(0.4)),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: checked
                                          ? scheme.primary
                                          : timerActive
                                          ? activeAccent.withOpacity(0.8)
                                          : (isDark
                                                ? const Color(
                                                    0xFF3B82F6,
                                                  ).withOpacity(0.4)
                                                : scheme.outline.withOpacity(
                                                    0.3,
                                                  )),
                                      width: checked
                                          ? 2
                                          : (timerActive ? 1.8 : 1.5),
                                    ),
                                    boxShadow: checked || timerActive
                                        ? <BoxShadow>[
                                            BoxShadow(
                                              color:
                                                  (checked
                                                          ? scheme.primary
                                                          : activeAccent)
                                                      .withOpacity(0.3),
                                              blurRadius: timerActive ? 12 : 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 160),
                                    scale: checked ? 1.0 : 0.0,
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: scheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _ModernMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ModernMetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(isDark ? 0.16 : 0.14),
            color.withOpacity(isDark ? 0.08 : 0.07),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(isDark ? 0.26 : 0.28)),
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
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
