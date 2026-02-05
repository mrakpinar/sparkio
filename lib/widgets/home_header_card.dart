import 'package:flutter/material.dart';

class HomeHeaderCard extends StatelessWidget {
  const HomeHeaderCard({
    super.key,
    required this.progress,
    required this.doneCount,
    required this.totalCount,
    required this.todayCompleted,
    required this.streak,
    required this.focusLabel,
    required this.dateLabel,
    required this.onShare,
    required this.onOpenStats,
  });

  final double progress;
  final int doneCount;
  final int totalCount;
  final int todayCompleted;
  final int streak;
  final String focusLabel;
  final String dateLabel;
  final VoidCallback onShare;
  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = (progress * 100).clamp(0, 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              scheme.primary.withOpacity(0.15),
              scheme.secondary.withOpacity(0.08),
              scheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: scheme.outline.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main content section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Sparks",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Small actions. Big change.",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Circular progress indicator
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              scheme.primary.withOpacity(0.1),
                              scheme.secondary.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 4,
                                backgroundColor: scheme.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  scheme.primary,
                                ),
                              ),
                            ),
                            Text(
                              "$percent%",
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      // Completed count
                      Expanded(
                        child: _StatChip(
                          icon: Icons.check_circle_rounded,
                          label: '$doneCount / $totalCount',
                          subtitle: 'Completed',
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Today count
                      Expanded(
                        child: _StatChip(
                          icon: Icons.today_rounded,
                          label: '$todayCompleted',
                          subtitle: 'Today',
                          color: scheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Streak
                      Expanded(
                        child: _StatChip(
                          icon: Icons.local_fire_department_rounded,
                          label: '$streak',
                          subtitle: 'Streak',
                          color: Color(0xFFF97316),
                        ),
                      ),
                    ],
                  ),

                  // Focus label
                  if (focusLabel.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.secondary.withOpacity(0.15),
                            scheme.secondary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _focusIconData(focusLabel),
                            size: 16,
                            color: scheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Today focus: $focusLabel',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action buttons section
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceVariant.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Date label
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Stats button
                  TextButton.icon(
                    onPressed: onOpenStats,
                    icon: Icon(
                      Icons.insights_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                    label: Text(
                      'View stats',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      backgroundColor: scheme.primary.withOpacity(0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Share button
                  IconButton(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _focusIconData(String label) {
  final value = label.toLowerCase();
  if (value.contains('calm') || value.contains('mind')) {
    return Icons.spa_rounded;
  }
  if (value.contains('growth')) return Icons.trending_up_rounded;
  if (value.contains('body')) return Icons.fitness_center_rounded;
  if (value.contains('health')) return Icons.favorite_rounded;
  return Icons.auto_awesome_rounded;
}
