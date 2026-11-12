import 'package:flutter/material.dart';
import '../app_strings.dart';
import '../theme/reward_colors.dart';

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
    final dailyGoal = (totalCount <= 0 ? 3 : totalCount).clamp(1, 999);
    final boundedDone = doneCount.clamp(0, dailyGoal);
    final safeStreak = streakCount.clamp(0, 999);
    final rewardAccent = RewardColors.accent(scheme);
    final rewardForeground = RewardColors.foreground(scheme);
    final streakColor = safeStreak > 0
        ? rewardForeground
        : Color.lerp(scheme.onSurfaceVariant, scheme.onSurface, 0.3)!;
    final safeWeeklyTotal = weeklyTotalCount <= 0 ? 1 : weeklyTotalCount;
    final safeWeeklyDone = weeklyDoneCount.clamp(0, safeWeeklyTotal);
    final progress =
        syncedProgress?.clamp(0.0, 1.0) ??
        (boundedDone / dailyGoal).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: onShare,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: scheme.surface,
            border: Border.all(color: scheme.outline.withOpacity(0.65)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    l10n.todaySparks(boundedDone, dailyGoal),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: rewardForeground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: rewardAccent,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.dayStreak(safeStreak),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: streakColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // The task card already shows the active timer's progress.
              if (syncedProgress == null) ...[
                const SizedBox(height: 12),
                _HeroMomentumBar(
                  progress: progress,
                  trackColor: scheme.onSurface.withOpacity(0.24),
                ),
              ],
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpenWeekly,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
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
                                color: scheme.onSurfaceVariant,
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
                    ),
                  ),
                ),
              ),
              if (showAction &&
                  hasPendingSpark &&
                  onStartFirstSpark != null) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: onStartFirstSpark,
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

class _HeroMomentumBar extends StatelessWidget {
  const _HeroMomentumBar({required this.progress, required this.trackColor});

  final double progress;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final rewardAccent = RewardColors.accent(Theme.of(context).colorScheme);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          height: 12,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: rewardAccent,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      },
    );
  }
}
