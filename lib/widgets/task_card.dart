import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool checked;
  final VoidCallback onTap;
  final VoidCallback? onSkip;
  final bool canSkip;

  const TaskCard({
    super.key,
    required this.task,
    required this.checked,
    required this.onTap,
    this.onSkip,
    this.canSkip = false,
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
    switch (c) {
      case 'body':
        return scheme.primary;
      case 'mind':
        return scheme.secondary;
      case 'growth':
        return scheme.primary;
      case 'calm':
        return scheme.secondaryContainer;
      case 'health':
        return scheme.error;
      default:
        return scheme.primary;
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: checked ? scheme.primary : scheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: checked
                      ? catColor.withOpacity(0.16)
                      : catColor.withOpacity(0.22),
                ),
                child: Icon(_iconFor(task.category), size: 22, color: catColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _labelFor(task.category).toUpperCase(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.title,
                      style: textTheme.titleMedium?.copyWith(
                        decoration: checked ? TextDecoration.lineThrough : null,
                        color: checked
                            ? scheme.onSurface.withOpacity(0.6)
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                          label:
                              '${_difficultyLabel(task.difficulty)} • ${task.durationMinutes}m',
                          color: scheme.primary,
                        ),
                        if (task.aiSuggested)
                          _MetaChip(label: 'AI', color: scheme.secondary),
                        if (task.premiumOnly)
                          _MetaChip(
                            label: 'Premium',
                            color: scheme.secondaryContainer,
                          ),
                        if (task.isSpecial)
                          _MetaChip(
                            label: 'Special',
                            color: scheme.primaryContainer,
                          ),
                      ],
                    ),
                    if (!checked && onSkip != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: canSkip ? onSkip : null,
                          icon: const Icon(
                            Icons.fast_forward_rounded,
                            size: 18,
                          ),
                          label: Text(
                            canSkip ? 'Skip this task' : 'Skip limit',
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            visualDensity: VisualDensity.compact,
                            foregroundColor: canSkip
                                ? scheme.secondary
                                : scheme.onSurfaceVariant,
                            backgroundColor: scheme.secondary.withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                              side: BorderSide(
                                color: scheme.secondary.withOpacity(0.2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedScale(
                duration: const Duration(milliseconds: 160),
                scale: checked ? 1.05 : 1.0,
                child: Icon(
                  checked ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 26,
                  color: checked
                      ? scheme.primary
                      : scheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
