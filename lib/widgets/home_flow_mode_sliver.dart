import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../models/task.dart';
import '../app_strings.dart';
import '../services/task_localizer.dart';

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

  _CategoryVisual _categoryVisual(Task? task, AppLocalizations l10n) {
    final category = task?.category.toLowerCase() ?? 'mind';
    switch (category) {
      case 'health':
        return _CategoryVisual(
          label: l10n.categoryBadgeLabel('health'),
          icon: Icons.favorite_rounded,
          tone: Color(0xFF2FD0B2),
          toneSoft: Color(0xFF1E8E84),
        );
      case 'growth':
        return _CategoryVisual(
          label: l10n.categoryBadgeLabel('growth'),
          icon: Icons.trending_up_rounded,
          tone: Color(0xFF6E8EFF),
          toneSoft: Color(0xFF395BC9),
        );
      case 'body':
        return _CategoryVisual(
          label: l10n.categoryBadgeLabel('body'),
          icon: Icons.fitness_center_rounded,
          tone: Color(0xFF62B3FF),
          toneSoft: Color(0xFF2E6FBD),
        );
      case 'calm':
        return _CategoryVisual(
          label: l10n.categoryBadgeLabel('calm'),
          icon: Icons.spa_rounded,
          tone: Color(0xFF9A84FF),
          toneSoft: Color(0xFF5C4ABB),
        );
      case 'mind':
      default:
        return _CategoryVisual(
          label: l10n.categoryBadgeLabel('mind'),
          icon: Icons.psychology_rounded,
          tone: Color(0xFFB08CFF),
          toneSoft: Color(0xFF684EBD),
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
    return '${l10n.minuteShortLabel(minutes)} $seconds ${l10n.tr('seconds')}';
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
    final title = showMomentumPrompt ? l10n.nice : l10n.yourNextTinyStep;
    final localizedTaskTitle = activeTask == null
        ? null
        : TaskLocalizer.localizeTitle(
            activeTask.title,
            category: activeTask.category,
            taskId: activeTask.id,
          );
    final stepLine = showMomentumPrompt
        ? l10n.youDidIt
        : (localizedTaskTitle ?? l10n.takeOneEasyBreath);
    final safeDailyGoal = dailyGoalCount <= 0 ? 1 : dailyGoalCount;
    final safeDoneToday = completedTodayCount.clamp(0, safeDailyGoal);
    final safeWeeklyTarget = weeklyTargetCount <= 0 ? 1 : weeklyTargetCount;
    final safeWeeklyDone = weeklyDoneCount.clamp(0, safeWeeklyTarget);
    final weeklyProgress = (safeWeeklyDone / safeWeeklyTarget)
        .clamp(0.0, 1.0)
        .toDouble();

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

    final subtitle = showMomentumPrompt
        ? 'Want another?'
        : timerFinished
        ? l10n.tr('Ready to finish')
        : timerActive
        ? l10n.keepYourRhythm
        : l10n.approxNoPressure(_localizedDurationLabel(l10n, activeTask));
    final ctaLabel = showMomentumPrompt
        ? l10n.startSparkNumber((safeDoneToday + 1).clamp(2, 99))
        : timerFinished
        ? l10n.tr('Mark complete')
        : timerPaused
        ? 'Resume'
        : l10n.beginNow;
    final showPrimaryAction = ctaEnabled;
    final showInlineCta =
        !showMomentumPrompt &&
        showPrimaryAction &&
        (timerFinished || !timerActive);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
        child: Material(
          color: Colors.transparent,
          elevation: isDark ? 10 : 4,
          shadowColor: Colors.black.withOpacity(isDark ? 0.26 : 0.12),
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: BoxConstraints(
              minHeight: showMomentumPrompt ? 236 : (timerActive ? 198 : 172),
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Color.alphaBlend(
                          visual.tone.withOpacity(0.10),
                          const Color(0xFF151C2C),
                        ),
                        const Color(0xFF12192A),
                        Color.alphaBlend(
                          visual.tone.withOpacity(0.07),
                          const Color(0xFF101726),
                        ),
                      ]
                    : [
                        Color.alphaBlend(
                          visual.tone.withOpacity(0.10),
                          scheme.surface,
                        ),
                        Color.alphaBlend(
                          visual.tone.withOpacity(0.06),
                          scheme.surface,
                        ),
                        Color.alphaBlend(
                          const Color(0xFF1F2A40).withOpacity(0.06),
                          scheme.surface,
                        ),
                      ],
                stops: const [0.0, 0.52, 1.0],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -24,
                  top: 22,
                  child: IgnorePointer(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            visual.tone.withOpacity(0.14),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
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
                          center: const Alignment(0.0, 0.02),
                          radius: 0.88,
                          colors: [
                            visual.tone.withOpacity(0.06),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                if (showMomentumPrompt)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          l10n.niceYouShowedUp,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: scheme.onSurface.withOpacity(0.94),
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _MomentumMiniRing(
                              progress: (safeDoneToday / safeDailyGoal)
                                  .clamp(0.0, 1.0)
                                  .toDouble(),
                              color: const Color(0xFF8776FF),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.sparksToday(safeDoneToday, safeDailyGoal),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: scheme.onSurface.withOpacity(0.9),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            color: scheme.surface.withOpacity(
                              isDark ? 0.26 : 0.6,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: const Color(0xFF8776FF),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  latestWinTitle ?? l10n.oneSmallWinAdded,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.88),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.weeklyConsistency(
                                  safeWeeklyDone,
                                  safeWeeklyTarget,
                                ),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant.withOpacity(
                                    0.9,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            value: weeklyProgress,
                            color: const Color(0xFF8776FF),
                            backgroundColor: scheme.onSurfaceVariant
                                .withOpacity(0.2),
                          ),
                        ),
                        const SizedBox(height: 14),
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
                      Text(
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant.withOpacity(0.86),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Color.alphaBlend(
                            Colors.white.withOpacity(isDark ? 0.03 : 0.34),
                            scheme.surface.withOpacity(isDark ? 0.24 : 0.72),
                          ),
                          border: Border.all(
                            color: scheme.outline.withOpacity(0.14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CategoryChip(visual: visual),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stepLine,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              color: Colors.white.withOpacity(
                                                0.97,
                                              ),
                                              fontWeight: FontWeight.w800,
                                              height: 1.04,
                                              fontSize: 18,
                                              shadows: [
                                                Shadow(
                                                  color: visual.tone
                                                      .withOpacity(0.18),
                                                  blurRadius: 10,
                                                ),
                                              ],
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _localizedDurationLabel(
                                          l10n,
                                          activeTask,
                                        ),
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: Colors.white.withOpacity(
                                                0.76,
                                              ),
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (showInlineCta) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: _GradientActionButton(
                                  label: ctaLabel,
                                  onTap: onPrimaryAction,
                                  icon: Icons.bolt_rounded,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  l10n.noPressureJustMomentum,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant.withOpacity(
                                      0.74,
                                    ),
                                    fontWeight: FontWeight.w600,
                                    height: 1.08,
                                  ),
                                ),
                              ),
                            ],
                            if (!showInlineCta)
                              const SizedBox(height: 10),
                            if (!timerActive && !showInlineCta)
                              Text(
                                l10n.approxNoPressure(
                                  _localizedDurationLabel(l10n, activeTask),
                                ),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant.withOpacity(
                                    0.84,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (timerRunning || timerPaused) ...[
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
                                color: const Color(0xFF8776FF),
                                backgroundColor: scheme.onSurfaceVariant
                                    .withOpacity(0.2),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  timerPaused ? l10n.paused : subtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.66),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            if (timerFinished) ...[
                              _SparkProgressBar(
                                value: 1,
                                color: const Color(0xFF8776FF),
                                backgroundColor: scheme.onSurfaceVariant
                                    .withOpacity(0.2),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  subtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.66),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
    );
  }
}

class _CategoryVisual {
  const _CategoryVisual({
    required this.label,
    required this.icon,
    required this.tone,
    required this.toneSoft,
  });

  final String label;
  final IconData icon;
  final Color tone;
  final Color toneSoft;
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.visual});

  final _CategoryVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              visual.tone.withOpacity(0.28),
              const Color(0xFF24304A),
            ),
            Color.alphaBlend(
              visual.toneSoft.withOpacity(0.2),
              const Color(0xFF182236),
            ),
          ],
        ),
        border: Border.all(color: visual.tone.withOpacity(0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            visual.icon,
            size: 14,
            color: Color.alphaBlend(Colors.white.withOpacity(0.9), visual.tone),
            shadows: [
              Shadow(color: visual.tone.withOpacity(0.72), blurRadius: 14),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            visual.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Color.alphaBlend(
                Colors.white.withOpacity(0.88),
                visual.tone,
              ),
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.42,
              shadows: [
                Shadow(color: visual.tone.withOpacity(0.72), blurRadius: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF8B7CFF), Color(0xFF6FE3FF)],
            ),
            boxShadow: enabled
                ? const [
                    BoxShadow(
                      color: Color.fromRGBO(120, 90, 255, 0.35),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 15, color: Colors.white.withOpacity(0.96)),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
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
              Text(
                timerLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface.withOpacity(0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _MiniIconButton(
                icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                onTap: onPauseTap,
              ),
              const SizedBox(width: 6),
              _MiniIconButton(icon: Icons.stop_rounded, onTap: onEndTap),
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
  const _MiniIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: scheme.onSurface.withOpacity(0.08),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
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
