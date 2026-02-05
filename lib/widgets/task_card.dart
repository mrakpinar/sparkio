import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool checked;
  final VoidCallback onTap;
  final VoidCallback? onSkip;
  final bool canSkip;
  final double? progress;
  final String progressLabel;

  const TaskCard({
    super.key,
    required this.task,
    required this.checked,
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
        return const Color(0xFFEF4444); // Red
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final catColor = _colorFor(context, task.category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            scale: checked ? 0.98 : 1.0,
            child: Align(
              heightFactor: checked ? 0 : 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: checked
                        ? (isDark
                              ? const Color(0xFF0D1B2E).withOpacity(0.8)
                              : scheme.surfaceVariant.withOpacity(0.5))
                        : (isDark ? const Color(0xFF0D1B2E) : scheme.surface),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: checked
                          ? scheme.primary.withOpacity(0.35)
                          : (isDark
                                ? const Color(0xFF1E3A5F).withOpacity(0.35)
                                : scheme.outline.withOpacity(0.25)),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: checked
                            ? scheme.primary.withOpacity(0.1)
                            : (isDark
                                  ? Colors.black.withOpacity(0.2)
                                  : scheme.shadow.withOpacity(0.08)),
                        blurRadius: checked ? 12 : 8,
                        offset: Offset(0, checked ? 4 : 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: onTap,
                      splashColor: catColor.withOpacity(0.1),
                      highlightColor: catColor.withOpacity(0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Icon container
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(
                                  isDark ? 0.1 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: catColor.withOpacity(
                                    isDark ? 0.15 : 0.2,
                                  ),
                                  width: 1,
                                ),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      borderRadius: BorderRadius.circular(8),
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
                                          style: textTheme.labelSmall?.copyWith(
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
                                          ? scheme.onSurface.withOpacity(0.5)
                                          : (isDark
                                                ? Colors.white.withOpacity(0.95)
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
                                        icon: Icons.signal_cellular_alt_rounded,
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
                                          icon: Icons.workspace_premium_rounded,
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
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor: canSkip
                                            ? (isDark
                                                  ? const Color(0xFF06B6D4)
                                                  : scheme.secondary)
                                            : (isDark
                                                  ? Colors.white.withOpacity(
                                                      0.4,
                                                    )
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          side: BorderSide(
                                            color: canSkip
                                                ? (isDark
                                                      ? const Color(
                                                          0xFF06B6D4,
                                                        ).withOpacity(0.3)
                                                      : scheme.secondary
                                                            .withOpacity(0.2))
                                                : (isDark
                                                      ? const Color(
                                                          0xFF1E3A5F,
                                                        ).withOpacity(0.3)
                                                      : scheme.outline
                                                            .withOpacity(0.15)),
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
                                          scheme.primary.withOpacity(0.85),
                                        ],
                                      )
                                    : null,
                                color: checked
                                    ? null
                                    : (isDark
                                          ? const Color(
                                              0xFF1E3A5F,
                                            ).withOpacity(0.3)
                                          : scheme.surfaceVariant.withOpacity(
                                              0.4,
                                            )),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: checked
                                      ? scheme.primary
                                      : (isDark
                                            ? const Color(
                                                0xFF3B82F6,
                                              ).withOpacity(0.4)
                                            : scheme.outline.withOpacity(0.3)),
                                  width: checked ? 2 : 1.5,
                                ),
                                boxShadow: checked
                                    ? [
                                        BoxShadow(
                                          color: scheme.primary.withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 8,
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
        color: color.withOpacity(isDark ? 0.1 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(isDark ? 0.2 : 0.25)),
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
