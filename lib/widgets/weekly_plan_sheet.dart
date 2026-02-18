import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _WeeklyPlanSheetState extends State<WeeklyPlanSheet>
    with SingleTickerProviderStateMixin {
  static const _categories = <String>[
    'mind',
    'body',
    'growth',
    'calm',
    'health',
  ];
  late final Map<String, int> _targets = {
    for (final category in _categories)
      category: _normalizeTarget(widget.initialTargets[category] ?? 0),
  };

  int get _total => _targets.values.fold<int>(0, (sum, value) => sum + value);
  _PlanFeedback get _feedback {
    final total = _total;
    final activeCategories = _targets.values.where((v) => v > 0).length;

    if (total == 0) {
      return const _PlanFeedback(
        title: 'Start with one spark.',
        subtitle: 'Pick a pace that feels sustainable.',
      );
    }
    if (total <= 5) {
      return _PlanFeedback(
        title: 'A light week. Keep it easy.',
        subtitle: '$total sparks planned',
      );
    }
    if (total <= 11 && activeCategories >= 3) {
      return _PlanFeedback(
        title: 'Perfect balance',
        subtitle: '$total sparks planned',
      );
    }
    if (total <= 17) {
      return _PlanFeedback(
        title: 'Steady momentum',
        subtitle: '$total sparks planned',
      );
    }
    if (total <= 21) {
      return _PlanFeedback(
        title: 'Strong week ahead',
        subtitle: '$total sparks planned',
      );
    }
    return _PlanFeedback(
      title: 'Ambitious week. Pace yourself.',
      subtitle: '$total sparks planned',
    );
  }

  int _normalizeTarget(int raw) {
    if (raw <= 5) return raw.clamp(0, 5);
    return (raw / 4).round().clamp(0, 5);
  }

  late final AnimationController _heroBreathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _heroBreathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final feedback = _feedback;
    final summaryT = (_total / (_categories.length * 5)).clamp(0.0, 1.0);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      child: Container(
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
              mainAxisSize: MainAxisSize.max,
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
                AnimatedBuilder(
                  animation: _heroBreathe,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(_heroBreathe.value);
                    final haloOpacity = 0.07 + (0.08 * t);
                    final iconGlow = 0.22 + (0.2 * t);
                    final iconScale = 0.985 + (0.03 * t);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: -28,
                          right: -28,
                          top: -12,
                          height: 126,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(-0.7, -0.95),
                                  radius: 1.12,
                                  colors: [
                                    scheme.primary.withOpacity(haloOpacity),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                scheme.primary.withOpacity(0.08 + (0.04 * t)),
                                scheme.primary.withOpacity(0.03),
                              ],
                            ),
                            border: Border.all(
                              color: scheme.primary.withOpacity(
                                0.14 + (0.08 * t),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Transform.scale(
                                scale: iconScale,
                                child: Container(
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
                                        color: scheme.primary.withOpacity(
                                          iconGlow,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: -6,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.calendar_view_week_rounded,
                                    color: scheme.onPrimary,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Plan Your Week',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Set your goals for this week',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
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
                                    color: scheme.surfaceContainerHighest
                                        .withOpacity(0.85),
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
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Categories
                        for (var i = 0; i < _categories.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: i < _categories.length - 1 ? 16 : 0,
                            ),
                            child: _PlanRow(
                              category: _categories[i],
                              target: _targets[_categories[i]] ?? 0,
                              onChanged: (next) {
                                setState(() {
                                  _targets[_categories[i]] = next.clamp(0, 5);
                                });
                              },
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Dynamic summary
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                scheme.primary.withOpacity(
                                  0.06 + (0.1 * summaryT),
                                ),
                                scheme.primary.withOpacity(
                                  0.02 + (0.06 * summaryT),
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: scheme.primary.withOpacity(
                                0.12 + (0.24 * summaryT),
                              ),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withOpacity(
                                  0.06 + (0.14 * summaryT),
                                ),
                                blurRadius: 18,
                                spreadRadius: -8,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withOpacity(
                                    0.12 + (0.2 * summaryT),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: scheme.primary.withOpacity(
                                      0.14 + (0.2 * summaryT),
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, anim) {
                                        final slide = Tween<Offset>(
                                          begin: const Offset(0, 0.12),
                                          end: Offset.zero,
                                        ).animate(anim);
                                        return FadeTransition(
                                          opacity: anim,
                                          child: SlideTransition(
                                            position: slide,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        feedback.title,
                                        key: ValueKey(feedback.title),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.1,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      feedback.subtitle,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant
                                                .withOpacity(0.88),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withOpacity(
                                    0.1 + (0.2 * summaryT),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: scheme.primary.withOpacity(
                                      0.14 + (0.24 * summaryT),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '$_total',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                              'Start this week',
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
      ),
    );
  }
}

class _PlanFeedback {
  const _PlanFeedback({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class _PlanRow extends StatefulWidget {
  const _PlanRow({
    required this.category,
    required this.target,
    required this.onChanged,
  });

  final String category;
  final int target;
  final ValueChanged<int> onChanged;

  @override
  State<_PlanRow> createState() => _PlanRowState();
}

class _PlanRowState extends State<_PlanRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.0,
        end: 1.012,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 42,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.012,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 58,
    ),
  ]).animate(_pulseController);

  @override
  void didUpdateWidget(covariant _PlanRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleDotTap(int dotLevel, int currentLevel) {
    final next = dotLevel == currentLevel ? 0 : dotLevel;
    if (next == currentLevel) return;
    HapticFeedback.selectionClick();
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _categoryColor(widget.category);
    final level = widget.target.clamp(0, 5);
    final levelT = level / 5;
    final emphasis = Curves.easeOutCubic.transform(levelT);
    final cardTop = 0.03 + (0.16 * emphasis);
    final cardBottom = 0.01 + (0.08 * emphasis);
    final borderOpacity = 0.1 + (0.32 * emphasis);
    final glowOpacity = 0.05 + (0.24 * emphasis);
    final iconTop = 0.16 + (0.22 * emphasis);
    final iconBottom = 0.06 + (0.14 * emphasis);
    final iconBorder = 0.14 + (0.22 * emphasis);
    final levelTextColor = level == 0
        ? scheme.onSurfaceVariant.withOpacity(0.72)
        : accent.withOpacity(0.92);

    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(accent.withOpacity(cardTop), scheme.surface),
              Color.alphaBlend(accent.withOpacity(cardBottom), scheme.surface),
            ],
          ),
          border: Border.all(
            color: accent.withOpacity(borderOpacity),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(glowOpacity),
              blurRadius: 18 + (6 * emphasis),
              spreadRadius: -9 + (2 * emphasis),
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withOpacity(iconTop),
                        accent.withOpacity(iconBottom),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accent.withOpacity(iconBorder),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _categoryIcon(widget.category),
                    size: 26,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _categoryLabel(widget.category),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _categoryHint(widget.category),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withOpacity(0.84),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _levelLabel(level),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: levelTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(5, (index) {
                final dotLevel = index + 1;
                final isActive = dotLevel <= level;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 4 ? 0 : 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleDotTap(dotLevel, level),
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? accent.withOpacity(0.56)
                                : scheme.onSurfaceVariant.withOpacity(0.12),
                            border: Border.all(
                              color: isActive
                                  ? accent.withOpacity(0.72)
                                  : scheme.outline.withOpacity(0.22),
                              width: 1,
                            ),
                            boxShadow: [
                              if (isActive)
                                BoxShadow(
                                  color: accent.withOpacity(0.24),
                                  blurRadius: 10,
                                  spreadRadius: -4,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Light',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withOpacity(0.74),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Stronger',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withOpacity(0.74),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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

String _categoryHint(String key) {
  switch (key) {
    case 'body':
      return 'Move a little, feel better.';
    case 'mind':
      return 'Clear your head with small resets.';
    case 'growth':
      return 'Make room for one small improvement.';
    case 'calm':
      return 'Protect your calm moments this week.';
    case 'health':
      return 'Support your energy and wellbeing.';
    default:
      return 'Pick a pace that feels sustainable.';
  }
}

String _levelLabel(int level) {
  if (level <= 1) return 'Low';
  if (level <= 3) return 'Medium';
  return 'High';
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
