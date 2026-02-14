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

  String _categoryLabel(String key) {
    switch (key) {
      case 'mind':
        return 'Mind';
      case 'body':
        return 'Body';
      case 'growth':
        return 'Growth';
      case 'calm':
        return 'Calm';
      case 'health':
        return 'Health';
      default:
        return 'Focus';
    }
  }

  Color _categoryColor(String key) {
    switch (key) {
      case 'mind':
        return const Color(0xFF8B5CF6);
      case 'body':
        return const Color(0xFFF97316);
      case 'growth':
        return const Color(0xFF22C55E);
      case 'calm':
        return const Color(0xFF06B6D4);
      case 'health':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _difficultyLabel(String value) {
    if (value.isEmpty) return 'Easy';
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

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
    final totalSeconds = (task.durationMinutes * 60)
        .clamp(1, 360000)
        .toDouble();
    final progress = 1 - (remaining.inSeconds.clamp(0, 360000) / totalSeconds);
    final categoryColor = _categoryColor(task.category);
    final primary = done ? const Color(0xFF22C55E) : scheme.primary;
    final secondary = done ? const Color(0xFF2DD4BF) : const Color(0xFF38BDF8);
    final subtitleColor = scheme.onSurface.withOpacity(isDark ? 0.72 : 0.62);
    final leftSeconds = remaining.inSeconds.clamp(0, 360000);
    final statusGlow = Color.lerp(primary, secondary, 0.35) ?? primary;
    final surfaceGradient = isDark
        ? [
            const Color(0xFF071534),
            const Color(0xFF0A1D3F),
            Color.alphaBlend(
              statusGlow.withOpacity(0.12),
              const Color(0xFF0C2651),
            ),
          ]
        : [
            const Color(0xFFF5F9FF),
            const Color(0xFFEAF4FF),
            Color.alphaBlend(
              statusGlow.withOpacity(0.08),
              const Color(0xFFE3F0FF),
            ),
          ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: surfaceGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusGlow.withOpacity(isDark ? 0.45 : 0.22),
          width: done ? 1.7 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusGlow.withOpacity(isDark ? 0.22 : 0.12),
            blurRadius: isDark ? 24 : 14,
            spreadRadius: isDark ? 1.1 : 0.2,
            offset: const Offset(0, 8),
          ),
          if (isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -22,
            child: IgnorePointer(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      statusGlow.withOpacity(isDark ? 0.28 : 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primary.withOpacity(0.35),
                          secondary.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      done ? Icons.check_circle_rounded : Icons.timer_rounded,
                      color: done
                          ? const Color(0xFF34D399)
                          : const Color(0xFF60A5FA),
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
                            color: subtitleColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusGlow.withOpacity(isDark ? 0.28 : 0.16),
                          statusGlow.withOpacity(isDark ? 0.14 : 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusGlow.withOpacity(0.42)),
                      boxShadow: [
                        BoxShadow(
                          color: statusGlow.withOpacity(isDark ? 0.24 : 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      done ? 'DONE' : 'LIVE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: done ? const Color(0xFF86EFAC) : statusGlow,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    icon: Icons.sell_rounded,
                    label: _categoryLabel(task.category),
                    color: categoryColor,
                  ),
                  _MetaChip(
                    icon: Icons.schedule_rounded,
                    label: '${task.durationMinutes} min',
                    color: scheme.primary,
                  ),
                  _MetaChip(
                    icon: Icons.bar_chart_rounded,
                    label: _difficultyLabel(task.difficulty),
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primary.withOpacity(isDark ? 0.28 : 0.16),
                        secondary.withOpacity(isDark ? 0.2 : 0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primary.withOpacity(0.35),
                      width: 1.3,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule_rounded, color: primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        done ? '00:00' : _format(remaining),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: primary,
                          fontFeatures: [const FontFeature.tabularFigures()],
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                done
                    ? 'Ready to mark as completed.'
                    : 'Keep focus - $leftSeconds sec left',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 12),
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
                          color: primary,
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
                            color: Colors.white.withOpacity(
                              isDark ? 0.18 : 0.32,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primary, secondary],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                          color: Colors.white.withOpacity(isDark ? 0.35 : 0.6),
                        ),
                        foregroundColor: scheme.onSurface.withOpacity(0.95),
                        backgroundColor: Colors.white.withOpacity(
                          isDark ? 0.04 : 0.35,
                        ),
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
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
