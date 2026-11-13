import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../app_strings.dart';
import '../theme/reward_colors.dart';
import '../theme/home_card_style.dart';

class HomeHeaderCard extends StatefulWidget {
  const HomeHeaderCard({
    super.key,
    required this.doneCount,
    required this.totalCount,
    required this.streakCount,
    required this.weeklyDoneCount,
    required this.weeklyTotalCount,
    this.syncedProgress,
    this.dayKey = '',
    this.dailyCompletions = const {},
    this.celebration = 0,
    this.level = 1,
    this.xpInLevel = 0,
    this.xpToNextLevel = 0,
    required this.onShare,
    required this.onOpenWeekly,
    required this.onStartFirstSpark,
    required this.hasPendingSpark,
    required this.showAction,
  });

  final int doneCount;
  final int totalCount;
  final int streakCount;
  final int weeklyDoneCount;
  final int weeklyTotalCount;
  final double? syncedProgress;
  final String dayKey;
  final Map<String, int> dailyCompletions;
  final int celebration;
  final int level;
  final int xpInLevel;
  final int xpToNextLevel;
  final VoidCallback onShare;
  final VoidCallback onOpenWeekly;
  final VoidCallback? onStartFirstSpark;
  final bool hasPendingSpark;
  final bool showAction;

  @override
  State<HomeHeaderCard> createState() => _HomeHeaderCardState();
}

class _HomeHeaderCardState extends State<HomeHeaderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 1,
  );

  @override
  void didUpdateWidget(covariant HomeHeaderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dayKey != widget.dayKey) {
      _burst.stop();
      _burst.value = 1;
    } else if (widget.celebration > oldWidget.celebration &&
        !MediaQuery.disableAnimationsOf(context)) {
      // Only a committed task completion changes this token. Loading saved
      // progress or switching language must never replay a celebration.
      _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final dailyGoal = (widget.totalCount <= 0 ? 3 : widget.totalCount)
        .clamp(1, 999);
    final boundedDone = widget.doneCount.clamp(0, dailyGoal);
    final safeStreak = widget.streakCount.clamp(0, 999);
    final rewardAccent = RewardColors.accent(scheme);
    final rewardForeground = RewardColors.foreground(scheme);
    final xpForeground = Color.lerp(
      scheme.primary,
      scheme.onSurface,
      scheme.brightness == Brightness.dark ? 0.3 : 0.25,
    )!;
    final safeWeeklyTotal = widget.weeklyTotalCount <= 0
        ? 1 : widget.weeklyTotalCount;
    final safeWeeklyDone = widget.weeklyDoneCount.clamp(0, safeWeeklyTotal);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final streakLabel = safeStreak > 0
        ? l10n.dayStreak(safeStreak)
        : l10n.tr(boundedDone == 0
            ? 'Light your first spark today.'
            : 'Keep your spark going.');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: widget.onShare,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: HomeCardStyle.decoration(scheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: Duration(milliseconds: reduceMotion ? 0 : 280),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  l10n.todaySparks(boundedDone, dailyGoal),
                  key: ValueKey('${widget.dayKey}:$boundedDone'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: boundedDone == 0
                        ? HomeCardStyle.brandForeground(scheme)
                        : rewardForeground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _burst,
                  builder: (context, _) => Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < dailyGoal; i++)
                        CustomPaint(
                          foregroundPainter: i == boundedDone - 1
                              ? _SparkBurstPainter(
                                  progress: _burst.value,
                                  color: rewardAccent,
                                  secondary: scheme.primary,
                                )
                              : null,
                          child: Transform.scale(
                            scale: i == boundedDone - 1
                                ? 1 + 0.12 * math.sin(_burst.value * math.pi)
                                : 1,
                            child: AnimatedContainer(
                              duration: Duration(
                                milliseconds: reduceMotion ? 0 : 220,
                              ),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < boundedDone
                                    ? RewardColors.background(scheme)
                                    : scheme.primary.withOpacity(0.04),
                                border: Border.all(
                                  color: i < boundedDone
                                      ? rewardAccent.withOpacity(0.35)
                                      : HomeCardStyle.brandForeground(scheme)
                                          .withOpacity(0.40),
                                ),
                              ),
                              child: Icon(
                                i < boundedDone
                                    ? Icons.auto_awesome_rounded
                                    : Icons.auto_awesome_outlined,
                                size: 24,
                                color: i < boundedDone
                                    ? rewardAccent
                                    : HomeCardStyle.brandForeground(scheme)
                                        .withOpacity(0.80),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _burst,
                    builder: (context, child) => Transform.scale(
                      scale: 1 + 0.1 * math.sin(_burst.value * math.pi),
                      child: child,
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      size: 19,
                      color: safeStreak > 0 || boundedDone > 0
                          ? rewardAccent
                          : HomeCardStyle.brandForeground(scheme),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      streakLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: safeStreak > 0
                            ? rewardForeground
                            : HomeCardStyle.secondaryForeground(scheme),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onOpenWeekly,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_view_week_rounded,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${l10n.weekly} · $safeWeeklyDone/$safeWeeklyTotal',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _WeekActivityRow(
                          dayKey: widget.dayKey,
                          completions: widget.dailyCompletions,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.xpToNextLevel > 0) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.trf('Lv {level} · {current}/{target} XP', {
                    'level': widget.level,
                    'current': widget.xpInLevel,
                    'target': widget.xpToNextLevel,
                  }),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: xpForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  key: ValueKey(widget.level),
                  tween: Tween<double>(
                    begin: 0,
                    end: (widget.xpInLevel / widget.xpToNextLevel)
                        .clamp(0.0, 1.0).toDouble(),
                  ),
                  duration: Duration(milliseconds: reduceMotion ? 0 : 260),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: reduceMotion
                          ? (widget.xpInLevel / widget.xpToNextLevel)
                              .clamp(0.0, 1.0).toDouble()
                          : value,
                      minHeight: 4,
                      color: rewardAccent,
                      backgroundColor: Color.alphaBlend(
                        xpForeground.withOpacity(0.38), scheme.surface,
                      ),
                      semanticsLabel: l10n.trf(
                        'XP to Level {level}', {'level': widget.level + 1},
                      ),
                    ),
                  ),
                ),
              ],
              if (widget.showAction && widget.hasPendingSpark &&
                  widget.onStartFirstSpark != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: widget.onStartFirstSpark,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(l10n.beginNow),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekActivityRow extends StatelessWidget {
  const _WeekActivityRow({required this.dayKey, required this.completions});

  final String dayKey;
  final Map<String, int> completions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final materialL10n = MaterialLocalizations.of(context);
    final markerSize = math.max(
      20.0,
      MediaQuery.textScalerOf(context).scale(11) * 1.2 + 4,
    );
    final today = DateUtils.dateOnly(DateTime.tryParse(dayKey) ?? DateTime.now());
    final monday = DateTime(today.year, today.month, today.day - today.weekday + 1);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: List.generate(7, (index) {
        final day = DateTime(monday.year, monday.month, monday.day + index);
        final key = day.toIso8601String().split('T').first;
        final future = day.isAfter(today);
        final count = future ? 0 : (completions[key] ?? 0).clamp(0, 999);
        final active = count > 0;
        final current = DateUtils.isSameDay(day, today);
        final label = '${materialL10n.formatMediumDate(day)}: '
            '${l10n.trf('Completed sparks: {count}', {'count': count})}';
        return SizedBox.square(
          dimension: markerSize,
          child: Semantics(
            label: label,
            child: Tooltip(
              message: label,
              excludeFromSemantics: true,
              child: ExcludeSemantics(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: markerSize),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? RewardColors.background(scheme)
                              : current
                              ? scheme.primary.withOpacity(0.06)
                              : future
                              ? Colors.transparent
                              : scheme.onSurfaceVariant.withOpacity(0.06),
                          border: Border.all(
                            color: current
                                ? HomeCardStyle.brandForeground(scheme)
                                : active
                                ? RewardColors.accent(scheme).withOpacity(0.6)
                                : future
                                ? scheme.outline
                                : scheme.onSurfaceVariant.withOpacity(0.20),
                            width: current ? 1.8 : 1,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            materialL10n.narrowWeekdays[day.weekday % 7],
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              height: 1.2,
                              color: active
                                  ? RewardColors.foreground(scheme)
                                  : current
                                  ? HomeCardStyle.brandForeground(scheme)
                                  : HomeCardStyle.secondaryForeground(scheme),
                              fontWeight: current || active
                                  ? FontWeight.w700
                                  : FontWeight.w400,
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
      }),
    );
  }
}

class _SparkBurstPainter extends CustomPainter {
  const _SparkBurstPainter({
    required this.progress, required this.color, required this.secondary,
  });

  final double progress;
  final Color color;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = size.center(Offset.zero);
    final distance = 10 + 18 * Curves.easeOut.transform(progress);
    final fade = (1 - progress) * 0.8;
    for (var i = 0; i < 10; i++) {
      final angle = i * math.pi * 2 / 10 - math.pi / 2;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final paint = Paint()
        ..color = (i.isEven ? color : secondary).withOpacity(fade)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      final radius = (1 - progress) * 2;
      if (i.isEven) {
        canvas.drawLine(point - Offset(radius, 0), point + Offset(radius, 0), paint);
        canvas.drawLine(point - Offset(0, radius), point + Offset(0, radius), paint);
      } else {
        canvas.drawCircle(point, radius * 0.65, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparkBurstPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color ||
      secondary != oldDelegate.secondary;
}
