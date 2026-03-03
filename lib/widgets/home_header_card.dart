import 'package:flutter/material.dart';
import '../app_strings.dart';

class HomeHeaderCard extends StatelessWidget {
  const HomeHeaderCard({
    super.key,
    required this.doneCount,
    required this.totalCount,
    required this.streakCount,
    required this.weeklyDoneCount,
    required this.weeklyTotalCount,
    this.syncedProgress,
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
  final VoidCallback onShare;
  final VoidCallback onOpenWeekly;
  final VoidCallback? onStartFirstSpark;
  final bool hasPendingSpark;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final dailyGoal = (totalCount <= 0 ? 3 : totalCount).clamp(1, 999);
    final boundedDone = doneCount.clamp(0, dailyGoal);
    final safeStreak = streakCount.clamp(0, 999);
    final safeWeeklyTotal = weeklyTotalCount <= 0 ? 1 : weeklyTotalCount;
    final safeWeeklyDone = weeklyDoneCount.clamp(0, safeWeeklyTotal);
    final weeklyProgress = (safeWeeklyDone / safeWeeklyTotal)
        .clamp(0.0, 1.0)
        .toDouble();
    final progress =
        syncedProgress?.clamp(0.0, 1.0) ??
        (boundedDone / dailyGoal).clamp(0.0, 1.0).toDouble();

    final gradientStart = isDark
        ? const Color(0xFF1B2236)
        : Color.alphaBlend(
            const Color(0xFF24324A).withOpacity(0.12),
            scheme.surface,
          );
    final gradientEnd = isDark
        ? const Color(0xFF141B2D)
        : Color.alphaBlend(
            const Color(0xFF1F2A40).withOpacity(0.1),
            scheme.surface,
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 182),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              gradientStart,
              Color.alphaBlend(
                const Color(0xFF202944).withOpacity(isDark ? 0.22 : 0.08),
                gradientStart,
              ),
              gradientEnd,
            ],
            stops: const [0.0, 0.48, 1.0],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, -0.9),
                      radius: 1.0,
                      colors: [
                        const Color.fromRGBO(120, 90, 255, 0.08),
                        const Color.fromRGBO(0, 210, 255, 0.03),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.44, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, 1.0),
                      radius: 1.15,
                      colors: [
                        const Color.fromRGBO(93, 225, 255, 0.018),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: onShare,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeHeroTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white.withOpacity(0.92),
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.1,
                        letterSpacing: -0.2,
                        shadows: const [
                          Shadow(
                            color: Color.fromRGBO(10, 16, 32, 0.28),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          l10n.todaySparks(boundedDone, dailyGoal),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.84),
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: scheme.surface.withOpacity(
                              isDark ? 0.22 : 0.58,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 11,
                                color: const Color(
                                  0xFFFFC06A,
                                ).withOpacity(0.98),
                                shadows: const [
                                  Shadow(
                                    color: Color.fromRGBO(255, 169, 90, 0.82),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 3),
                              Text(
                                l10n.dayCount(safeStreak),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurface.withOpacity(
                                    isDark ? 0.68 : 0.76,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.oneTinyStepIsEnough,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.74),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HeroMomentumBar(
                      progress: progress,
                      trackColor: Colors.white.withOpacity(0.12),
                    ),
                    if (weeklyTotalCount > 0) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: onOpenWeekly,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color.alphaBlend(
                                  const Color(
                                    0xFF8B7CFF,
                                  ).withOpacity(isDark ? 0.07 : 0.06),
                                  isDark
                                      ? const Color(
                                          0xFF101726,
                                        ).withOpacity(0.92)
                                      : Color.alphaBlend(
                                          Colors.white.withOpacity(0.72),
                                          scheme.surface,
                                        ),
                                ),
                                Color.alphaBlend(
                                  const Color(
                                    0xFF5DE1FF,
                                  ).withOpacity(isDark ? 0.05 : 0.04),
                                  isDark
                                      ? const Color(
                                          0xFF101726,
                                        ).withOpacity(0.86)
                                      : Color.alphaBlend(
                                          Colors.white.withOpacity(0.54),
                                          scheme.surfaceVariant,
                                        ),
                                ),
                              ],
                            ),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.07)
                                  : scheme.outline.withOpacity(0.22),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isDark
                                            ? Colors.black
                                            : const Color(0xFF8B92A8))
                                        .withOpacity(isDark ? 0.12 : 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                                spreadRadius: -8,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_view_week_rounded,
                                size: 14,
                                color: const Color(
                                  0xFF8B7CFF,
                                ).withOpacity(0.92),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.weekly,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.88)
                                      : scheme.onSurface.withOpacity(0.88),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    minHeight: 4,
                                    value: weeklyProgress,
                                    color: const Color(0xFF8B7CFF),
                                    backgroundColor: isDark
                                        ? Colors.white.withOpacity(0.14)
                                        : scheme.onSurface.withOpacity(0.08),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$safeWeeklyDone/$safeWeeklyTotal',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.86)
                                      : scheme.onSurface.withOpacity(0.86),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 15,
                                color: isDark
                                    ? Colors.white.withOpacity(0.64)
                                    : scheme.onSurfaceVariant.withOpacity(0.78),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMomentumBar extends StatelessWidget {
  const _HeroMomentumBar({required this.progress, required this.trackColor});

  final double progress;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Container(
      height: 7,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF8B7CFF), Color(0xFF5DE1FF)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(120, 90, 255, 0.2),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
