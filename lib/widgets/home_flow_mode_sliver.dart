import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../models/task.dart';
import '../app_strings.dart';
import '../services/task_localizer.dart';
import '../theme/reward_colors.dart';

class HomeFlowModeSliver extends StatelessWidget {
  const HomeFlowModeSliver({
    super.key,
    required this.task,
    required this.completedTodayCount,
    required this.dailyGoalCount,
    required this.latestWinTitle,
    required this.weeklyDoneCount,
    required this.weeklyTargetCount,
    required this.timerRunning,
    required this.timerPaused,
    required this.timerFinished,
    required this.timerRemaining,
    required this.showMomentumPrompt,
    required this.onPrimaryAction,
    this.onDoneForToday,
    this.onPauseAction,
    this.onEndAction,
    this.focusSessionAvailable = false,
  });

  final Task? task;
  final int completedTodayCount;
  final int dailyGoalCount;
  final String? latestWinTitle;
  final int weeklyDoneCount;
  final int weeklyTargetCount;
  final bool timerRunning;
  final bool timerPaused;
  final bool timerFinished;
  final Duration? timerRemaining;
  final bool showMomentumPrompt;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onDoneForToday;
  final VoidCallback? onPauseAction;
  final VoidCallback? onEndAction;
  final bool focusSessionAvailable;

  _CategoryVisual _categoryVisual(Task? task, AppLocalizations l10n) {
    final category = task?.category.toLowerCase() ?? 'mind';
    switch (category) {
      case 'health':
        return _CategoryVisual(
          label: l10n.categoryBadgeLabel('health'),
          icon: Icons.favorite_rounded,
          tone: Color(0xFF2FD0B2),
        );
      case 'growth':
        return _CategoryVisual(
          label: l10n.categoryBadgeLabel('growth'),
          icon: Icons.trending_up_rounded,
          tone: Color(0xFF6E8EFF),
        );
      case 'body':
        return _CategoryVisual(
          label: l10n.categoryBadgeLabel('body'),
          icon: Icons.fitness_center_rounded,
          tone: Color(0xFF62B3FF),
        );
      case 'calm':
        return _CategoryVisual(
          label: l10n.categoryBadgeLabel('calm'),
          icon: Icons.spa_rounded,
          tone: Color(0xFF9A84FF),
        );
      case 'mind':
      default:
        return _CategoryVisual(
          label: l10n.categoryBadgeLabel('mind'),
          icon: Icons.psychology_rounded,
          tone: Color(0xFFB08CFF),
        );
    }
  }

  String _localizedDurationLabel(AppLocalizations l10n, Task? task) {
    if (task == null) return l10n.secondsLabel(60);
    final totalSeconds = task.totalDurationSeconds.clamp(1, 360000);
    if (totalSeconds < 60) return l10n.secondsLabel(totalSeconds);
    if (totalSeconds % 60 == 0) return l10n.minutesLabel(totalSeconds ~/ 60);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${l10n.minuteShortLabel(minutes)} ${l10n.secondsLabel(seconds)}';
  }

  String _formatCountdown(Duration remaining) {
    final total = remaining.inSeconds.clamp(0, 360000);
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final activeTask = task;
    final visual = _categoryVisual(activeTask, l10n);
    final timerActive = timerRunning || timerPaused || timerFinished;
    final ctaEnabled = showMomentumPrompt || activeTask != null;
    final localizedTaskTitle = activeTask == null
        ? null
        : TaskLocalizer.localizeTitle(
            activeTask.title,
            localeCode: Localizations.localeOf(context).languageCode,
            category: activeTask.category,
            taskId: activeTask.id,
          );
    final stepLine = localizedTaskTitle ?? l10n.takeOneEasyBreath;
    final safeDailyGoal = dailyGoalCount <= 0 ? 1 : dailyGoalCount;
    final safeDoneToday = completedTodayCount.clamp(0, safeDailyGoal);
    final totalSeconds = activeTask?.totalDurationSeconds ?? 60;
    final remainingSeconds = (timerRemaining ?? Duration.zero).inSeconds.clamp(
      0,
      totalSeconds,
    );
    final timerProgress = totalSeconds <= 0
        ? 0.0
        : (1 - (remainingSeconds / totalSeconds)).clamp(0.0, 1.0).toDouble();
    final timerLabel = l10n.timeLeft(
      _formatCountdown(timerRemaining ?? Duration.zero),
    );

    final xpLabel = activeTask == null ? null : '+${activeTask.xpReward} XP';
    final ctaLabel = focusSessionAvailable
        ? l10n.tr('Continue')
        : showMomentumPrompt
        ? l10n.startSparkNumber((safeDoneToday + 1).clamp(2, 99))
        : timerFinished
        ? l10n.tr('Mark complete')
        : timerPaused
        ? l10n.tr('Resume timer')
        : l10n.beginNow;
    final showPrimaryAction = ctaEnabled;
    final showInlineCta =
        !showMomentumPrompt &&
        showPrimaryAction &&
        (focusSessionAvailable || timerFinished || !timerActive);
    final taskSummary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.yourNextTinyStep,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stepLine,
          softWrap: true,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _FlowMetaPill(icon: visual.icon, label: visual.label),
            _FlowMetaPill(
              icon: Icons.schedule_rounded,
              label: _localizedDurationLabel(l10n, activeTask),
            ),
            if (activeTask != null)
              _FlowMetaPill(
                icon: Icons.signal_cellular_alt_rounded,
                label: l10n.tr(switch (activeTask.difficulty) {
                  'hard' => 'Hard',
                  'medium' => 'Medium',
                  _ => 'Easy',
                }),
              ),
            if (xpLabel != null) _FlowXpBadge(label: xpLabel),
          ],
        ),
      ],
    );
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: _HomeFlowCardShell(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14.5),
            clipBehavior: Clip.antiAlias,
            child: Container(
              constraints: BoxConstraints(
                minHeight: showMomentumPrompt ? 192 : (timerActive ? 184 : 152),
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.5),
                color: scheme.surface,
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -14,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 3,
                        color: visual.tone.withOpacity(isDark ? 0.7 : 0.6),
                      ),
                    ),
                  ),
                  if (showMomentumPrompt)
                    Padding(
                      padding: EdgeInsets.zero,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _MomentumMiniRing(
                                progress: (safeDoneToday / safeDailyGoal)
                                    .clamp(0.0, 1.0)
                                    .toDouble(),
                                color: RewardColors.accent(scheme),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.niceYouShowedUp,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: scheme.onSurface.withOpacity(
                                              0.94,
                                            ),
                                            fontWeight: FontWeight.w800,
                                            height: 1.1,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.sparksToday(
                                        safeDoneToday,
                                        safeDailyGoal,
                                      ),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: RewardColors.foreground(
                                              scheme,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          taskSummary,
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: _GradientActionButton(
                              label: ctaLabel,
                              onTap: onPrimaryAction,
                            ),
                          ),
                          TextButton(
                            onPressed: onDoneForToday,
                            child: Text(l10n.iAmDoneForToday),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              taskSummary,
                              if (showInlineCta) ...[
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: _GradientActionButton(
                                    label: ctaLabel,
                                    onTap: onPrimaryAction,
                                    useLightPrimary: !timerFinished,
                                    icon: timerFinished && !focusSessionAvailable
                                        ? Icons.check_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                                ),
                              ],
                              if (!showInlineCta) const SizedBox(height: 10),
                              if (focusSessionAvailable && !timerFinished) ...[
                                const SizedBox(height: 12),
                                Text(
                                  timerLabel,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _SparkProgressBar(
                                  value: timerProgress,
                                  color: scheme.onSurface,
                                  backgroundColor: scheme.onSurfaceVariant
                                      .withOpacity(0.2),
                                ),
                              ],
                              if (!focusSessionAvailable &&
                                  (timerRunning || timerPaused)) ...[
                                _ActiveTimerControlBar(
                                  timerLabel: timerLabel,
                                  running: timerRunning,
                                  paused: timerPaused,
                                  onPauseTap: onPauseAction,
                                  onEndTap: onEndAction,
                                ),
                                const SizedBox(height: 10),
                                _SparkProgressBar(
                                  value: timerProgress,
                                  color: scheme.onSurface,
                                  backgroundColor: scheme.onSurfaceVariant
                                      .withOpacity(0.2),
                                ),
                              ],
                              if (timerFinished) ...[
                                if (focusSessionAvailable) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.tr('Timer finished'),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                _SparkProgressBar(
                                  value: 1,
                                  color: scheme.onSurface,
                                  backgroundColor: scheme.onSurfaceVariant
                                      .withOpacity(0.2),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlowXpBadge extends StatelessWidget {
  const _FlowXpBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rewardAccent = RewardColors.accent(scheme);
    final rewardForeground = RewardColors.foreground(scheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: RewardColors.background(scheme),
        border: Border.all(color: rewardAccent.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 12, color: rewardAccent),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: rewardForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowMetaPill extends StatelessWidget {
  const _FlowMetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.onSurface.withOpacity(0.04),
        border: Border.all(color: scheme.outline.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: scheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryVisual {
  const _CategoryVisual({
    required this.label,
    required this.icon,
    required this.tone,
  });

  final String label;
  final IconData icon;
  final Color tone;
}

class _MomentumMiniRing extends StatelessWidget {
  const _MomentumMiniRing({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 3.6,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: color.withOpacity(0.2),
          ),
          Icon(Icons.auto_awesome_rounded, size: 13, color: color),
        ],
      ),
    );
  }
}

class _GradientActionButton extends StatefulWidget {
  const _GradientActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.useLightPrimary = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool useLightPrimary;

  @override
  State<_GradientActionButton> createState() => _GradientActionButtonState();
}

class _GradientActionButtonState extends State<_GradientActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onTap != null;
    final lightPrimary = widget.useLightPrimary &&
        scheme.brightness == Brightness.light;
    final primaryColor = Color.alphaBlend(
      Colors.black.withOpacity(0.15),
      scheme.primary,
    );
    final foregroundColor = lightPrimary
        ? (enabled ? scheme.onPrimary : scheme.onSurfaceVariant)
        : scheme.surface;
    return Opacity(
      opacity: enabled || lightPrimary ? 1 : 0.5,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: lightPrimary
                  ? (enabled ? primaryColor : scheme.surfaceContainerHighest)
                  : scheme.onSurface,
            ),
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: enabled
                  ? (_) => setState(() => _pressed = true)
                  : null,
              onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
              onTapCancel: enabled
                  ? () => setState(() => _pressed = false)
                  : null,
              borderRadius: BorderRadius.circular(13),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20, color: foregroundColor),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: foregroundColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveTimerControlBar extends StatelessWidget {
  const _ActiveTimerControlBar({
    required this.timerLabel,
    required this.running,
    required this.paused,
    required this.onPauseTap,
    required this.onEndTap,
  });

  final String timerLabel;
  final bool running;
  final bool paused;
  final VoidCallback? onPauseTap;
  final VoidCallback? onEndTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: scheme.surface.withOpacity(isDark ? 0.36 : 0.66),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              _AnimatedPulseDot(active: running),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  timerLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurface.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _MiniIconButton(
                icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                label: l10n.tr(paused ? 'Resume timer' : 'Pause timer'),
                onTap: onPauseTap,
              ),
              const SizedBox(width: 6),
              _MiniIconButton(
                icon: Icons.stop_rounded,
                label: l10n.tr('Stop timer'),
                onTap: onEndTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparkProgressBar extends StatelessWidget {
  const _SparkProgressBar({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final double value;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const knob = 12.0;
          final left = (constraints.maxWidth - knob) * clamped;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: clamped,
                    color: color,
                    backgroundColor: backgroundColor,
                  ),
                ),
              ),
              Positioned(
                left: left,
                top: -3,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: knob,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 48,
      child: IconButton(
        onPressed: onTap,
        tooltip: label,
        iconSize: 17,
        padding: const EdgeInsets.all(10),
        visualDensity: VisualDensity.standard,
        icon: Ink(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: scheme.onSurface.withOpacity(0.08),
          ),
          child: Icon(
            icon,
            size: 17,
            color: scheme.onSurface.withOpacity(0.88),
          ),
        ),
      ),
    );
  }
}

class _AnimatedPulseDot extends StatefulWidget {
  const _AnimatedPulseDot({required this.active});

  final bool active;

  @override
  State<_AnimatedPulseDot> createState() => _AnimatedPulseDotState();
}

class _AnimatedPulseDotState extends State<_AnimatedPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF8776FF);
    final idleColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.3);
    if (!widget.active) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: idleColor, shape: BoxShape.circle),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = 0.82 + (_controller.value * 0.18);
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: activeColor.withOpacity(t),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: activeColor.withOpacity(0.45 * _controller.value),
                blurRadius: 7,
                spreadRadius: 1.2,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeFlowCardShell extends StatelessWidget {
  const _HomeFlowCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.65)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: child,
      ),
    );
  }
}
