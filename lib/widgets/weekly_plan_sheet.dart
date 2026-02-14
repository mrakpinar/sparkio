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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.surface, scheme.surfaceContainerHighest],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary,
                          scheme.primary.withOpacity(0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.calendar_view_week_rounded,
                      color: scheme.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan Your Week',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Set your goals for this week',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showSkip)
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: widget.onSkip,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Categories
              for (var i = 0; i < _categories.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i < _categories.length - 1 ? 12 : 0,
                  ),
                  child: _PlanRow(
                    category: _categories[i],
                    target: _targets[_categories[i]] ?? 0,
                    onMinus: () {
                      setState(() {
                        final next = (_targets[_categories[i]] ?? 0) - 1;
                        _targets[_categories[i]] = next < 0 ? 0 : next;
                      });
                    },
                    onPlus: () {
                      setState(() {
                        final next = (_targets[_categories[i]] ?? 0) + 1;
                        _targets[_categories[i]] = next > 20 ? 20 : next;
                      });
                    },
                  ),
                ),
              const SizedBox(height: 20),

              // Total badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withOpacity(0.12),
                      scheme.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.flag_rounded,
                        size: 20,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Weekly goal: ',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      '$_total',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  if (widget.showSkip)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onSkip,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: scheme.outline.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'Not now',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (widget.showSkip) const SizedBox(width: 12),
                  Expanded(
                    flex: widget.showSkip ? 1 : 1,
                    child: FilledButton(
                      onPressed: () => widget.onSave(_targets),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: scheme.primary.withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Save plan',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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

class _PlanRow extends StatefulWidget {
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
  State<_PlanRow> createState() => _PlanRowState();
}

class _PlanRowState extends State<_PlanRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTap() {
    _controller.forward().then((_) => _controller.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _categoryColor(widget.category);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: scheme.surface,
          border: Border.all(
            color: scheme.outline.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent.withOpacity(0.2), accent.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withOpacity(0.3), width: 1),
              ),
              child: Icon(
                _categoryIcon(widget.category),
                size: 24,
                color: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _categoryLabel(widget.category),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _animateTap();
                        widget.onMinus();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.remove_rounded,
                          size: 20,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${widget.target}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: accent,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _animateTap();
                        widget.onPlus();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.add_rounded,
                          size: 20,
                          color: scheme.onSurface,
                        ),
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
      return const Color(0xFFF97316); // Orange
    case 'mind':
      return const Color(0xFF8B5CF6); // Purple
    case 'growth':
      return const Color(0xFF22C55E); // Green
    case 'calm':
      return const Color(0xFF06B6D4); // Cyan
    case 'health':
      return const Color(0xFFEF4444); // Red
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
