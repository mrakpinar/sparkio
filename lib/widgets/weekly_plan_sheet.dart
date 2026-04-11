import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_strings.dart';
import '../theme/task_category_style.dart';

BoxDecoration _weeklyPlanSurface(
  ColorScheme scheme, {
  Color? tint,
  double radius = 16,
  double tintOpacity = 0.08,
  double surfaceOpacity = 0.98,
}) {
  final activeTint = tint ?? scheme.onSurface;
  final base = Color.alphaBlend(
    Colors.white.withOpacity(0.02),
    const Color(0xFF0E1523).withOpacity(surfaceOpacity),
  );
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(activeTint.withOpacity(tintOpacity * 0.8), base),
        Color.alphaBlend(scheme.surface.withOpacity(0.18), base),
      ],
    ),
    border: Border.all(color: Colors.white.withOpacity(0.06)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.18),
        blurRadius: 20,
        spreadRadius: -8,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

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
  _PlanFeedback _feedback(AppLocalizations l10n) {
    final total = _total;
    final activeCategories = _targets.values.where((v) => v > 0).length;

    if (total == 0) {
      return _PlanFeedback(
        title: l10n.tr('Start with one spark.'),
        subtitle: l10n.tr('Pick a pace that feels sustainable.'),
      );
    }
    if (total <= 5) {
      return _PlanFeedback(
        title: l10n.tr('A light week. Keep it easy.'),
        subtitle: l10n.trf('{count} sparks planned', {'count': total}),
      );
    }
    if (total <= 11 && activeCategories >= 3) {
      return _PlanFeedback(
        title: l10n.tr('Perfect balance'),
        subtitle: l10n.trf('{count} sparks planned', {'count': total}),
      );
    }
    if (total <= 17) {
      return _PlanFeedback(
        title: l10n.tr('Steady momentum'),
        subtitle: l10n.trf('{count} sparks planned', {'count': total}),
      );
    }
    if (total <= 21) {
      return _PlanFeedback(
        title: l10n.tr('Strong week ahead'),
        subtitle: l10n.trf('{count} sparks planned', {'count': total}),
      );
    }
    return _PlanFeedback(
      title: l10n.tr('Ambitious week. Pace yourself.'),
      subtitle: l10n.trf('{count} sparks planned', {'count': total}),
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
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final feedback = _feedback(l10n);
    final summaryT = (_total / (_categories.length * 5)).clamp(0.0, 1.0);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Container(
        decoration:
            _weeklyPlanSurface(
              scheme,
              radius: 32,
              tintOpacity: 0.06,
              surfaceOpacity: 0.99,
            ).copyWith(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Drag handle
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),

                // Header
                AnimatedBuilder(
                  animation: _heroBreathe,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(_heroBreathe.value);
                    final haloOpacity = 0.07 + (0.08 * t);
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
                          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                          decoration: _weeklyPlanSurface(
                            scheme,
                            radius: 20,
                            tintOpacity: 0.06 + (0.03 * t),
                            surfaceOpacity: 0.98,
                          ),
                          child: Row(
                            children: [
                              Transform.scale(
                                scale: iconScale,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: _weeklyPlanSurface(
                                    scheme,
                                    radius: 13,
                                    tintOpacity: 0.18,
                                    surfaceOpacity: 0.96,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/in_app_icons/calendar.png',
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.contain,
                                      color: scheme.onPrimary,
                                      colorBlendMode: BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.tr('Plan Your Week'),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                            color: Colors.white.withOpacity(
                                              0.96,
                                            ),
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.tr('Set your goals for this week'),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant
                                                .withOpacity(0.72),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12.5,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.showSkip)
                                Container(
                                  decoration: _weeklyPlanSurface(
                                    scheme,
                                    radius: 999,
                                    tintOpacity: 0.05,
                                    surfaceOpacity: 0.96,
                                  ),
                                  child: IconButton(
                                    onPressed: widget.onSkip,
                                    icon: const Icon(Icons.close_rounded),
                                    tooltip: l10n.tr('Close'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Categories
                        for (var i = 0; i < _categories.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: i < _categories.length - 1 ? 10 : 0,
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
                        const SizedBox(height: 14),

                        // Dynamic summary
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: _weeklyPlanSurface(
                            scheme,
                            radius: 16,
                            tintOpacity: 0.05 + (0.06 * summaryT),
                            surfaceOpacity: 0.98,
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.all(8),
                                decoration: _weeklyPlanSurface(
                                  scheme,
                                  radius: 12,
                                  tintOpacity: 0.12 + (0.1 * summaryT),
                                  surfaceOpacity: 0.96,
                                ),
                                child: Image.asset(
                                  'assets/in_app_icons/sparkle.png',
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.contain,
                                  color: scheme.primary,
                                  colorBlendMode: BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 10),
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
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      scheme.onSurface.withOpacity(0.9),
                                      scheme.onSurface,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF8B7CFF,
                                      ).withOpacity(0.18 + (0.18 * summaryT)),
                                      blurRadius: 14,
                                      spreadRadius: -5,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '$_total',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: scheme.onPrimary,
                                    letterSpacing: -0.2,
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
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    if (widget.showSkip)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onSkip,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF101726),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            l10n.tr('Not now'),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface.withOpacity(0.86),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: scheme.onSurface,
                          foregroundColor: scheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l10n.tr('Start this week'),
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

  void _handleSliderChanged(double rawValue, int currentLevel) {
    final next = rawValue.round().clamp(0, 5);
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
    final toneStrength = Curves.easeInCubic.transform(levelT);
    final levelTextColor = level == 0
        ? scheme.onSurfaceVariant.withOpacity(0.72)
        : accent.withOpacity(0.92);

    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: _weeklyPlanSurface(
          scheme,
          tint: accent,
          radius: 16,
          tintOpacity: 0.04 + (0.09 * toneStrength),
          surfaceOpacity: 0.98,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: _weeklyPlanSurface(
                    scheme,
                    tint: accent,
                    radius: 12,
                    tintOpacity: 0.1 + (0.08 * emphasis),
                    surfaceOpacity: 0.96,
                  ),
                  child: Center(
                    child: TaskCategoryStyle.iconWidget(
                      widget.category,
                      size: 20,
                      color: Color.alphaBlend(
                        Colors.white.withOpacity(0.16 + (0.18 * emphasis)),
                        accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _categoryLabel(context, widget.category),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: Colors.white.withOpacity(0.94),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _categoryHint(context, widget.category),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withOpacity(0.74),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _levelLabel(context, level),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: levelTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                activeTrackColor: accent.withOpacity(
                  0.42 + (0.38 * toneStrength),
                ),
                inactiveTrackColor: scheme.onSurfaceVariant.withOpacity(0.16),
                thumbColor: Color.alphaBlend(
                  Colors.white.withOpacity(0.18 + (0.18 * emphasis)),
                  accent,
                ),
                overlayColor: accent.withOpacity(0.12 + (0.1 * toneStrength)),
                thumbShape: _WeeklyPlanThumbShape(
                  color: accent,
                  emphasis: emphasis,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                trackShape: const RoundedRectSliderTrackShape(),
                tickMarkShape: SliderTickMarkShape.noTickMark,
              ),
              child: Slider(
                value: level.toDouble(),
                min: 0,
                max: 5,
                divisions: 5,
                onChanged: (value) => _handleSliderChanged(value, level),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  context.l10n.tr('Light'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withOpacity(0.74),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  context.l10n.tr('Stronger'),
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

class _WeeklyPlanThumbShape extends SliderComponentShape {
  const _WeeklyPlanThumbShape({required this.color, required this.emphasis});

  final Color color;
  final double emphasis;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(22, 22);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final glowPaint = Paint()
      ..color = color.withOpacity(0.18 + (0.18 * emphasis))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final outerPaint = Paint()
      ..color = Color.alphaBlend(
        Colors.white.withOpacity(0.18 + (0.16 * emphasis)),
        color,
      );
    final innerPaint = Paint()..color = Colors.white.withOpacity(0.96);

    canvas.drawCircle(center, 9, glowPaint);
    canvas.drawCircle(center, 8.5, outerPaint);
    canvas.drawCircle(center, 3.2, innerPaint);
  }
}

String _categoryLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  switch (key) {
    case 'body':
      return l10n.tr('Body');
    case 'mind':
      return l10n.tr('Mind');
    case 'growth':
      return l10n.tr('Growth');
    case 'calm':
      return l10n.tr('Calm');
    case 'health':
      return l10n.tr('Health');
    default:
      return l10n.tr('Other');
  }
}

String _categoryHint(BuildContext context, String key) {
  final l10n = context.l10n;
  switch (key) {
    case 'body':
      return l10n.tr('Move a little, feel better.');
    case 'mind':
      return l10n.tr('Clear your head with small resets.');
    case 'growth':
      return l10n.tr('Make room for one small improvement.');
    case 'calm':
      return l10n.tr('Protect your calm moments this week.');
    case 'health':
      return l10n.tr('Support your energy and wellbeing.');
    default:
      return l10n.tr('Pick a pace that feels sustainable.');
  }
}

String _levelLabel(BuildContext context, int level) {
  final l10n = context.l10n;
  if (level <= 1) return l10n.tr('Low');
  if (level <= 3) return l10n.tr('Medium');
  return l10n.tr('High');
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




