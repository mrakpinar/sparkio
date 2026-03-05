import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_strings.dart';
import '../models/task.dart';
import '../services/locale_service.dart';
import '../services/task_localizer.dart';
import '../theme/task_category_style.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.checked,
    this.isTimerActive = false,
    this.timerRemaining,
    this.timerDone = false,
    this.onCancelTimer,
    this.onCompleteTimer,
    required this.onTap,
    this.onSkip,
    this.canSkip = false,
    this.progress,
    this.progressLabel = 'Daily progress',
  });

  final Task task;
  final bool checked;
  final bool isTimerActive;
  final Duration? timerRemaining;
  final bool timerDone;
  final VoidCallback? onCancelTimer;
  final VoidCallback? onCompleteTimer;
  final VoidCallback onTap;
  final VoidCallback? onSkip;
  final bool canSkip;
  final double? progress;
  final String progressLabel;

  String _difficultyLabel(BuildContext context, String d) {
    final l10n = context.l10n;
    switch (d) {
      case 'hard':
        return l10n.tr('Hard');
      case 'medium':
        return l10n.tr('Medium');
      default:
        return l10n.tr('Easy');
    }
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'hard':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds.clamp(0, 360000);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int _xpReward(Task t) {
    final base = switch (t.difficulty) {
      'hard' => 8,
      'medium' => 6,
      _ => 5,
    };
    return t.isSpecial ? base + 2 : base;
  }

  String _invitationHeadline(BuildContext context, Task t) {
    final l10n = context.l10n;
    var text = TaskLocalizer.localizeTitle(
      t.title,
      category: t.category,
      taskId: t.id,
    ).trim();
    const durationUnits =
        r'(?:seconds?|secs?|sec|minutes?|mins?|min|saniye|dakika|segundos?|minutos?|sekunden|minute?n?)';
    text = text.replaceFirst(
      RegExp(
        '\\b(?:for|during|in|durante|f(?:u|\\u00fc)r)\\s+\\d+(?:\\s*-\\s*|\\s+)$durationUnits(?:\\s+(?:lang|lange))?\\b',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceFirst(
      RegExp(
        '\\b\\d+(?:\\s*-\\s*|\\s+)$durationUnits(?:\\s+(?:boyunca|durante|lang|lange))?\\b',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    text = text.replaceAll(RegExp(r'[.!]+$'), '').trim();
    if (text.isEmpty) {
      text = TaskLocalizer.localizeTitle(
        t.title,
        category: t.category,
        taskId: t.id,
      ).trim();
    }
    if (text.isEmpty) return l10n.tr('Start your spark');
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  String _invitationDuration(Task t) {
    final code = LocaleService.instance.effectiveLanguageCode;
    final totalSeconds = t.totalDurationSeconds;
    if (totalSeconds < 60) {
      return '$totalSeconds ${AppLocalizations.lookup(code, 'seconds')}. ${AppLocalizations.lookup(code, "That's it.")}';
    }
    if (totalSeconds % 60 == 0) {
      final mins = (totalSeconds ~/ 60).clamp(1, 120);
      final unit = mins == 1
          ? AppLocalizations.lookup(code, 'minute')
          : AppLocalizations.lookup(code, 'minutes');
      return '$mins $unit. ${AppLocalizations.lookup(code, "That's it.")}';
    }
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '$mins ${AppLocalizations.lookup(code, 'min')} $secs ${AppLocalizations.lookup(code, 'seconds')}. ${AppLocalizations.lookup(code, "That's it.")}';
  }

  String _durationChipLabel(Task t) {
    final code = LocaleService.instance.effectiveLanguageCode;
    final totalSeconds = t.totalDurationSeconds;
    if (totalSeconds < 60) {
      return '$totalSeconds ${AppLocalizations.lookup(code, 'seconds')}';
    }
    if (totalSeconds % 60 == 0) {
      return '${totalSeconds ~/ 60} ${AppLocalizations.lookup(code, 'min')}';
    }
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '$mins ${AppLocalizations.lookup(code, 'min')} $secs ${AppLocalizations.lookup(code, 'seconds')}';
  }

  String _invitationFooter(
    BuildContext context, {
    required bool checked,
    required bool timerActive,
  }) {
    final l10n = context.l10n;
    if (checked) return '';
    if (timerActive) return '';
    return l10n.tr('Ready when you are.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = TaskCategoryStyle.color(
      task.category,
      fallback: scheme.primary,
    );
    const timerAccent = Color(0xFF38BDF8);

    final hasInlineTimer = timerRemaining != null;
    final timerActive = (isTimerActive || hasInlineTimer) && !checked;
    final remaining = timerRemaining ?? Duration.zero;
    final totalSeconds = task.totalDurationSeconds.toDouble();
    final timerProgress = hasInlineTimer
        ? 1 - (remaining.inSeconds / totalSeconds)
        : 0.0;
    final xp = _xpReward(task);
    final invitationHeadline = _invitationHeadline(context, task);
    final invitationDuration = _invitationDuration(task);
    final invitationFooter = _invitationFooter(
      context,
      checked: checked,
      timerActive: timerActive,
    );
    final status = checked
        ? _TaskStatusType.done
        : (task.isSpecial
              ? _TaskStatusType.streakBonus
              : _TaskStatusType.pending);

    const doneTint = Color(0xFFF59E0B);
    final baseSurface = isDark ? const Color(0xFF030812) : scheme.surface;
    final flatSurface = isDark
        ? const Color(0xFF0A1321)
        : Color.alphaBlend(Colors.black.withOpacity(0.05), scheme.surface);
    final matteSurface = isDark
        ? const Color(0xFF0A111C)
        : Color.alphaBlend(Colors.black.withOpacity(0.02), scheme.surface);
    final background = checked
        ? Color.alphaBlend(
            doneTint.withOpacity(isDark ? 0.03 : 0.02),
            matteSurface,
          )
        : timerActive
        ? Color.alphaBlend(
            timerAccent.withOpacity(isDark ? 0.14 : 0.1),
            baseSurface,
          )
        : flatSurface;

    if (checked) {
      return _CompletedTaskRow(title: invitationHeadline, xp: xp);
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: checked ? 0.92 : 1,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          offset: Offset.zero,
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: EdgeInsets.only(bottom: checked ? 15 : 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (timerActive || checked)
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onTap();
                      },
                borderRadius: BorderRadius.circular(18),
                child: _LiveCardShell(
                  timerActive: timerActive,
                  checked: checked,
                  accent: timerAccent,
                  background: background,
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _LiveIconOrb(
                                  category: task.category,
                                  accent: accent,
                                  live: timerActive && !checked,
                                  checked: checked,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _PillTag(
                                            text: TaskCategoryStyle.label(
                                              task.category,
                                            ).toUpperCase(),
                                            color: checked
                                                ? Color.alphaBlend(
                                                    accent.withOpacity(0.16),
                                                    scheme.onSurfaceVariant
                                                        .withOpacity(0.28),
                                                  )
                                                : accent,
                                          ),
                                          if (checked) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              context.l10n.tr(
                                                'Completed today',
                                              ),
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: scheme
                                                        .onSurfaceVariant
                                                        .withOpacity(0.74),
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.15,
                                                  ),
                                            ),
                                          ],
                                          if (timerActive && timerDone) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              context.l10n.tr(
                                                'Ready to finish',
                                              ),
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: timerDone
                                                        ? scheme.tertiary
                                                        : timerAccent,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.28,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        checked
                                            ? invitationHeadline
                                            : '-> $invitationHeadline',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: checked
                                                  ? FontWeight.w600
                                                  : FontWeight.w700,
                                              color: checked
                                                  ? scheme.onSurface
                                                        .withOpacity(0.85)
                                                  : null,
                                              letterSpacing: 0.1,
                                              height: 1.3,
                                            ),
                                      ),
                                      if (!checked) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          invitationDuration,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                      if (!checked &&
                                          invitationFooter.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          invitationFooter,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant
                                                    .withOpacity(0.86),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                      const SizedBox(height: 7),
                                      if (checked)
                                        Text(
                                          '+$xp XP earned',
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                color: Color.alphaBlend(
                                                  const Color(
                                                    0xFF22C55E,
                                                  ).withOpacity(0.42),
                                                  scheme.onSurfaceVariant
                                                      .withOpacity(0.9),
                                                ),
                                                fontWeight: FontWeight.w400,
                                              ),
                                        )
                                      else ...[
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _XpRewardBadge(
                                              xp: xp,
                                              checked: checked,
                                              accent: timerActive
                                                  ? timerAccent
                                                  : Color.alphaBlend(
                                                      scheme.primary
                                                          .withOpacity(0.28),
                                                      scheme.onSurfaceVariant
                                                          .withOpacity(0.8),
                                                    ),
                                            ),
                                            if (status ==
                                                _TaskStatusType.streakBonus)
                                              _TaskStatusChip(status: status),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _MetricChip(
                                              icon: Icons.schedule_rounded,
                                              label: _durationChipLabel(task),
                                              color: timerActive
                                                  ? const Color(0xFF14B8A6)
                                                  : Color.alphaBlend(
                                                      const Color(
                                                        0xFF14B8A6,
                                                      ).withOpacity(0.22),
                                                      scheme.onSurfaceVariant
                                                          .withOpacity(0.78),
                                                    ),
                                            ),
                                            _MetricChip(
                                              icon: Icons.bolt_rounded,
                                              label: _difficultyLabel(
                                                context,
                                                task.difficulty,
                                              ),
                                              color: timerActive
                                                  ? _difficultyColor(
                                                      task.difficulty,
                                                    )
                                                  : Color.alphaBlend(
                                                      _difficultyColor(
                                                        task.difficulty,
                                                      ).withOpacity(0.2),
                                                      scheme.onSurfaceVariant
                                                          .withOpacity(0.78),
                                                    ),
                                            ),
                                            if (task.aiSuggested)
                                              const _MetaChip(
                                                icon:
                                                    Icons.auto_awesome_rounded,
                                                label: 'AI',
                                              ),
                                            if (task.premiumOnly)
                                              _MetaChip(
                                                icon: Icons
                                                    .workspace_premium_rounded,
                                                iconAsset:
                                                    'assets/in_app_icons/premium.png',
                                                label: context.l10n.tr(
                                                  'Premium',
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!checked && !timerActive) ...[
                                      const SizedBox(height: 8),
                                      _TaskStartCtaButton(
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          onTap();
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            if (timerActive) ...[
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (hasInlineTimer)
                                    Expanded(
                                      child: _CalmTimerProgressBar(
                                        progress: timerProgress.clamp(0.0, 1.0),
                                        color: timerDone
                                            ? scheme.tertiary
                                            : timerAccent,
                                        live: !timerDone,
                                        timerLabel: timerDone
                                            ? '00:00'
                                            : _formatDuration(remaining),
                                      ),
                                    )
                                  else
                                    Text(
                                      timerDone
                                          ? '00:00'
                                          : _formatDuration(remaining),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: timerDone
                                                ? scheme.tertiary
                                                : timerAccent,
                                            letterSpacing: 0.2,
                                          ),
                                    ),
                                ],
                              ),
                              if (!timerDone && onCancelTimer != null) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: onCancelTimer,
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      context.l10n.tr('Cancel timer'),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      foregroundColor: scheme.onSurfaceVariant
                                          .withOpacity(0.88),
                                      side: BorderSide(
                                        color: scheme.onSurfaceVariant
                                            .withOpacity(0.22),
                                      ),
                                      backgroundColor: scheme.surface
                                          .withOpacity(0.08),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      textStyle: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                              if (timerDone && onCompleteTimer != null) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.icon(
                                    onPressed: onCompleteTimer,
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      context.l10n.tr('Mark complete'),
                                    ),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      backgroundColor: scheme.tertiary,
                                      foregroundColor: scheme.onTertiary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _TaskStatusType { pending, done, streakBonus }

class _TaskStartCtaButton extends StatelessWidget {
  const _TaskStartCtaButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primaryBlend = Color.alphaBlend(
      scheme.primary.withOpacity(0.9),
      const Color(0xFF8B5CF6),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.28),
            blurRadius: 14,
            spreadRadius: -1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(11),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryBlend.withOpacity(0.96),
                  primaryBlend.withOpacity(0.82),
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 3),
                Text(
                  context.l10n.tr('Start'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveCardShell extends StatefulWidget {
  const _LiveCardShell({
    required this.timerActive,
    required this.checked,
    required this.accent,
    required this.background,
    required this.child,
  });

  final bool timerActive;
  final bool checked;
  final Color accent;
  final Color background;
  final Widget child;

  @override
  State<_LiveCardShell> createState() => _LiveCardShellState();
}

class _LiveCardShellState extends State<_LiveCardShell>
    with TickerProviderStateMixin {
  late final AnimationController _liveController;
  late final AnimationController _settleController;

  @override
  void initState() {
    super.initState();
    _liveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
      lowerBound: 0,
      upperBound: 1,
    );
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1,
    );
    if (widget.timerActive && !widget.checked) {
      _liveController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _LiveCardShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldAnimate = widget.timerActive && !widget.checked;
    final wasAnimating = oldWidget.timerActive && !oldWidget.checked;
    if (shouldAnimate && !wasAnimating) {
      _liveController.repeat(reverse: true);
    } else if (!shouldAnimate && wasAnimating) {
      _liveController
        ..stop()
        ..value = 0;
    }

    if (!oldWidget.checked && widget.checked) {
      _settleController.forward(from: 0);
    } else if (oldWidget.checked && !widget.checked) {
      _settleController.value = 1;
    }
  }

  @override
  void dispose() {
    _liveController.dispose();
    _settleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_liveController, _settleController]),
      builder: (context, _) {
        final active = widget.timerActive && !widget.checked;
        final t = Curves.easeInOut.transform(_liveController.value);
        final settleT = Curves.easeOutCubic.transform(_settleController.value);
        final pulse = active ? t : 0.0;
        final settleScale = widget.checked ? ((1 - settleT) * 0.01) : 0.0;
        final scale = 1 + (pulse * 0.0045) + settleScale;
        final ambientOpacity = active ? (0.05 + (pulse * 0.07)) : 0.0;
        final settleOverlayOpacity = widget.checked
            ? ((1 - settleT) * 0.1)
            : 0.0;
        final shellColor = active
            ? widget.background.withOpacity(0.82)
            : widget.checked
            ? Color.lerp(
                Color.alphaBlend(
                  widget.accent.withOpacity(0.09),
                  widget.background,
                ),
                widget.background,
                settleT,
              )!
            : widget.background;
        final driftCenter = Alignment(
          -0.9 + (pulse * 0.25),
          -1 + (pulse * 0.2),
        );

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              color: active ? null : shellColor,
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(
                          const Color(0xFF34D5FF).withOpacity(0.22),
                          shellColor,
                        ),
                        Color.alphaBlend(
                          const Color(0xFF8B5CF6).withOpacity(0.24),
                          shellColor,
                        ),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.checked
                    ? Colors.white.withOpacity(0.06)
                    : (active
                          ? widget.accent.withOpacity(0.22)
                          : Colors.white.withOpacity(0.07)),
                width: 0.8,
              ),
            ),
            child: Stack(
              children: [
                if (widget.checked && settleOverlayOpacity > 0.001)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.accent.withOpacity(settleOverlayOpacity),
                              widget.accent.withOpacity(
                                settleOverlayOpacity * 0.45,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (active)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: RadialGradient(
                            center: Alignment(
                              driftCenter.x - 0.06,
                              driftCenter.y - 0.08,
                            ),
                            radius: 1.04,
                            colors: [
                              widget.accent.withOpacity(ambientOpacity * 1.6),
                              widget.accent.withOpacity(ambientOpacity * 0.58),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.38, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (active)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.accent.withOpacity(0.1 + (pulse * 0.08)),
                              widget.accent.withOpacity(0.03),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.44, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (active)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const RadialGradient(
                            center: Alignment(1.05, -0.95),
                            radius: 1.05,
                            colors: [Color(0x1AFFFFFF), Colors.transparent],
                            stops: [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (active)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                          child: Container(
                            color: Colors.white.withOpacity(0.02),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (active)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _NoiseGrainLayer(
                          color: widget.accent.withOpacity(0.09),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: widget.child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiveIconOrb extends StatefulWidget {
  const _LiveIconOrb({
    required this.category,
    required this.accent,
    required this.live,
    required this.checked,
  });

  final String category;
  final Color accent;
  final bool live;
  final bool checked;

  @override
  State<_LiveIconOrb> createState() => _LiveIconOrbState();
}

class _LiveIconOrbState extends State<_LiveIconOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );
    if (widget.live) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _LiveIconOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.live && !oldWidget.live) {
      _controller.repeat(reverse: true);
    } else if (!widget.live && oldWidget.live) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final fillOpacity = (isDark ? 0.16 : 0.12) + (widget.live ? 0.05 : 0.0);
        final orbBase = Color.alphaBlend(
          Colors.black.withOpacity(isDark ? 0.52 : 0.2),
          scheme.surface.withOpacity(isDark ? 0.92 : 0.96),
        );
        final passiveOrb = Color.alphaBlend(
          Colors.black.withOpacity(isDark ? 0.46 : 0.14),
          scheme.surface.withOpacity(isDark ? 0.9 : 0.97),
        );
        final doneFill = Color.alphaBlend(
          scheme.surfaceVariant.withOpacity(isDark ? 0.54 : 0.62),
          scheme.surface.withOpacity(isDark ? 0.92 : 0.97),
        );
        final iconColor = widget.checked
            ? scheme.onSurfaceVariant.withOpacity(0.58)
            : widget.accent.withOpacity(widget.live ? 1 : 0.92);
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: (!widget.checked && !widget.live) ? passiveOrb : null,
            gradient: (widget.checked || widget.live)
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.checked
                        ? [doneFill, doneFill]
                        : [
                            Color.alphaBlend(
                              const Color(
                                0xFF34D5FF,
                              ).withOpacity(fillOpacity + 0.04),
                              orbBase,
                            ),
                            Color.alphaBlend(
                              const Color(
                                0xFF8B5CF6,
                              ).withOpacity(fillOpacity + 0.06),
                              orbBase,
                            ),
                          ],
                  )
                : null,
            border: Border.all(
              color: widget.checked
                  ? Colors.white.withOpacity(0.08)
                  : (widget.live
                        ? Colors.white.withOpacity(0.16)
                        : Colors.white.withOpacity(0.08)),
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: TaskCategoryStyle.iconWidget(
                  widget.category,
                  size: 22,
                  color: iconColor,
                ),
              ),
              if (widget.checked)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surfaceVariant.withOpacity(0.72),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 10,
                      color: scheme.onSurfaceVariant.withOpacity(0.66),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CalmTimerProgressBar extends StatefulWidget {
  const _CalmTimerProgressBar({
    required this.progress,
    required this.color,
    required this.live,
    required this.timerLabel,
  });

  final double progress;
  final Color color;
  final bool live;
  final String timerLabel;

  @override
  State<_CalmTimerProgressBar> createState() => _CalmTimerProgressBarState();
}

class _CalmTimerProgressBarState extends State<_CalmTimerProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flowController;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );
    if (widget.live) _flowController.repeat();
  }

  @override
  void didUpdateWidget(covariant _CalmTimerProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.live && !oldWidget.live) {
      _flowController.repeat();
    } else if (!widget.live && oldWidget.live) {
      _flowController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 22,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: AnimatedBuilder(
          animation: _flowController,
          builder: (context, _) {
            final progress = widget.progress.clamp(0.0, 1.0);
            final flow = widget.live ? _flowController.value : 0.0;
            return LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final fillWidth = maxWidth * progress;
                final beamWidth = math.max(12.0, maxWidth * 0.22);
                final beamLeft = (fillWidth + beamWidth) * flow - beamWidth;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.14),
                        ),
                      ),
                    ),
                    if (fillWidth > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: fillWidth,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.color.withOpacity(0.72),
                                widget.color.withOpacity(0.94),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (widget.live && fillWidth > 16)
                      Positioned(
                        left: beamLeft.clamp(
                          0.0,
                          math.max(0.0, fillWidth - beamWidth),
                        ),
                        top: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: Container(
                            width: beamWidth,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.0),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Color.alphaBlend(
                                widget.color.withOpacity(0.16),
                                Colors.black.withOpacity(0.12),
                              ),
                            ),
                            child: Text(
                              widget.timerLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withOpacity(0.92),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NoiseGrainLayer extends StatelessWidget {
  const _NoiseGrainLayer({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NoiseGrainPainter(color: color),
      size: Size.infinite,
    );
  }
}

class _NoiseGrainPainter extends CustomPainter {
  const _NoiseGrainPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const step = 9.0;
    final maxX = size.width;
    final maxY = size.height;
    for (double y = 0; y < maxY; y += step) {
      for (double x = 0; x < maxX; x += step) {
        final noise = _hash(x, y);
        if (noise < 0.72) continue;
        final opacity = ((noise - 0.72) / 0.28).clamp(0.0, 1.0) * 0.2;
        paint.color = color.withOpacity(opacity);
        final dotSize = noise > 0.92 ? 1.4 : 1.0;
        canvas.drawRect(Rect.fromLTWH(x, y, dotSize, dotSize), paint);
      }
    }
  }

  double _hash(double x, double y) {
    final v = math.sin((x * 12.9898) + (y * 78.233) + 37.719) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _NoiseGrainPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _TaskStatusChip extends StatelessWidget {
  const _TaskStatusChip({required this.status});

  final _TaskStatusType status;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;
    Color color;
    switch (status) {
      case _TaskStatusType.done:
        icon = Icons.check_circle_rounded;
        label = 'Done';
        color = const Color(0xFF22C55E);
      case _TaskStatusType.streakBonus:
        icon = Icons.local_fire_department_rounded;
        label = 'Streak bonus';
        color = const Color(0xFFF59E0B);
      case _TaskStatusType.pending:
        icon = Icons.hourglass_top_rounded;
        label = 'Pending';
        color = const Color(0xFF7C83FF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedTaskRow extends StatelessWidget {
  const _CompletedTaskRow({required this.title, required this.xp});

  final String title;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rowSurface = Color.alphaBlend(
      Colors.white.withOpacity(0.025),
      scheme.surface.withOpacity(0.25),
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      opacity: 0.92,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: rowSurface,
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_rounded,
                size: 15,
                color: const Color(0xFF34D399).withOpacity(0.9),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(0.82),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '+$xp XP',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withOpacity(0.72),
                  fontWeight: FontWeight.w600,
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
  const _MetaChip({required this.icon, required this.label, this.iconAsset});

  final IconData icon;
  final String label;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: LinearGradient(
          colors: [
            scheme.surfaceContainerHighest.withOpacity(0.26),
            scheme.surfaceContainerHighest.withOpacity(0.16),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconAsset != null
              ? Image.asset(
                  iconAsset!,
                  width: 12,
                  height: 12,
                  fit: BoxFit.contain,
                  color: scheme.onSurfaceVariant,
                  colorBlendMode: BlendMode.srcIn,
                )
              : Icon(icon, size: 12, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.24), color.withOpacity(0.14)],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.18),
            ),
            child: Icon(icon, size: 9, color: color.withOpacity(0.78)),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color.alphaBlend(
                color.withOpacity(0.16),
                scheme.onSurfaceVariant.withOpacity(0.74),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.38), color.withOpacity(0.22)],
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _XpRewardBadge extends StatefulWidget {
  const _XpRewardBadge({
    required this.xp,
    required this.checked,
    required this.accent,
  });

  final int xp;
  final bool checked;
  final Color accent;

  @override
  State<_XpRewardBadge> createState() => _XpRewardBadgeState();
}

class _XpRewardBadgeState extends State<_XpRewardBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burstController;

  @override
  void initState() {
    super.initState();
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _XpRewardBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.checked && widget.checked) {
      _burstController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall;

    return AnimatedBuilder(
      animation: _burstController,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_burstController.value);
        final burst = widget.checked ? math.sin(math.pi * t) : 0.0;
        final scale = 1 + (burst * 0.08);
        final sparkOpacity = widget.checked ? (1 - t).clamp(0.0, 1.0) : 0.0;

        final baseTextColor = widget.checked
            ? const Color(0xFF22C55E).withOpacity(0.92)
            : Color.alphaBlend(
                widget.accent.withOpacity(0.2),
                scheme.onSurfaceVariant.withOpacity(0.76),
              );
        final baseIconColor = widget.checked
            ? const Color(0xFF22C55E).withOpacity(0.92)
            : widget.accent.withOpacity(0.62);

        return Transform.scale(
          scale: scale,
          alignment: Alignment.centerLeft,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: widget.checked
                      ? const Color(0xFF22C55E).withOpacity(0.1)
                      : widget.accent.withOpacity(0.1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 12, color: baseIconColor),
                    const SizedBox(width: 4),
                    Text(
                      widget.checked
                          ? 'Earned +${widget.xp} XP'
                          : '+${widget.xp} XP reward',
                      style: textStyle?.copyWith(
                        fontSize: 11,
                        color: baseTextColor,
                        fontWeight: widget.checked
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (sparkOpacity > 0.01)
                Positioned(
                  left: -8 + (burst * -6),
                  top: -8 + (burst * -8),
                  child: _XpSpark(
                    icon: Icons.auto_awesome_rounded,
                    opacity: sparkOpacity,
                    color: const Color(0xFF34D399),
                    size: 11,
                  ),
                ),
              if (sparkOpacity > 0.01)
                Positioned(
                  left: 14 + (burst * 10),
                  top: -10 + (burst * -10),
                  child: _XpSpark(
                    icon: Icons.bolt_rounded,
                    opacity: sparkOpacity * 0.92,
                    color: const Color(0xFF6EE7B7),
                    size: 9,
                  ),
                ),
              if (sparkOpacity > 0.01)
                Positioned(
                  left: -4 + (burst * -4),
                  top: 18 + (burst * 9),
                  child: _XpSpark(
                    icon: Icons.circle,
                    opacity: sparkOpacity * 0.84,
                    color: const Color(0xFFA7F3D0),
                    size: 5,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _XpSpark extends StatelessWidget {
  const _XpSpark({
    required this.icon,
    required this.opacity,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final double opacity;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Icon(icon, size: size, color: color),
    );
  }
}
