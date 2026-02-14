import 'package:flutter/material.dart';

class WeeklyPlanSheet extends StatefulWidget {
  const WeeklyPlanSheet({
    super.key,
    required this.initialTargets,
    required this.onSave,
    required this.onSkip,
    this.showSkip = false,
  });

  final Map<String, int> initialTargets;
  final ValueChanged<Map<String, int>> onSave;
  final VoidCallback onSkip;
  final bool showSkip;

  @override
  State<WeeklyPlanSheet> createState() => _WeeklyPlanSheetState();
}

class _WeeklyPlanSheetState extends State<WeeklyPlanSheet> {
  static const _categories = <String>[
    'mind',
    'body',
    'growth',
    'calm',
    'health',
  ];
  late final Map<String, int> _targets = {
    for (final category in _categories)
      category: (widget.initialTargets[category] ?? 0).clamp(0, 20),
  };

  int get _total => _targets.values.fold<int>(0, (sum, value) => sum + value);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: scheme.outline.withOpacity(0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary.withOpacity(0.28),
                          scheme.primary.withOpacity(0.10),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.calendar_view_week_rounded,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan your week',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set category goals for this week.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showSkip)
                    IconButton(
                      onPressed: widget.onSkip,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              for (final category in _categories)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlanRow(
                    category: category,
                    target: _targets[category] ?? 0,
                    onMinus: () {
                      setState(() {
                        final next = (_targets[category] ?? 0) - 1;
                        _targets[category] = next < 0 ? 0 : next;
                      });
                    },
                    onPlus: () {
                      setState(() {
                        final next = (_targets[category] ?? 0) + 1;
                        _targets[category] = next > 20 ? 20 : next;
                      });
                    },
                  ),
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, size: 16, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Weekly goal total: $_total',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.showSkip)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onSkip,
                        child: const Text('Not now'),
                      ),
                    ),
                  if (widget.showSkip) const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => widget.onSave(_targets),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save weekly plan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.category,
    required this.target,
    required this.onMinus,
    required this.onPlus,
  });

  final String category;
  final int target;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _categoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withOpacity(0.35)),
        color: scheme.surface,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_categoryIcon(category), size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _categoryLabel(category),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_rounded),
            visualDensity: VisualDensity.compact,
          ),
          Text(
            '$target',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

String _categoryLabel(String key) {
  switch (key) {
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
      return 'Other';
  }
}

Color _categoryColor(String key) {
  switch (key) {
    case 'body':
      return const Color(0xFFF97316);
    case 'mind':
      return const Color(0xFF8B5CF6);
    case 'growth':
      return const Color(0xFF22C55E);
    case 'calm':
      return const Color(0xFF06B6D4);
    case 'health':
      return const Color(0xFF3B82F6);
    default:
      return const Color(0xFF60A5FA);
  }
}

IconData _categoryIcon(String key) {
  switch (key) {
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
      return Icons.category_rounded;
  }
}
