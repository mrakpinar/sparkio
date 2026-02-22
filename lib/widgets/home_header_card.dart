import 'package:flutter/material.dart';

class HomeHeaderCard extends StatefulWidget {
  const HomeHeaderCard({
    super.key,
    required this.userName,
    required this.progress,
    required this.doneCount,
    required this.totalCount,
    required this.todayCompleted,
    required this.streak,
    required this.focusLabel,
    required this.dateLabel,
    required this.onShare,
    required this.onOpenStats,
    required this.adaptiveLabel,
    required this.weeklyDone,
    required this.weeklyTarget,
    required this.onOpenWeeklyPlan,
  });

  final String userName;
  final double progress;
  final int doneCount;
  final int totalCount;
  final int todayCompleted;
  final int streak;
  final String focusLabel;
  final String dateLabel;
  final VoidCallback onShare;
  final VoidCallback onOpenStats;
  final String adaptiveLabel;
  final int weeklyDone;
  final int weeklyTarget;
  final VoidCallback onOpenWeeklyPlan;

  @override
  State<HomeHeaderCard> createState() => _HomeHeaderCardState();
}

class _HomeHeaderCardState extends State<HomeHeaderCard> {
  bool _detailsExpanded = false;

  bool get _hasDetails =>
      widget.focusLabel.isNotEmpty ||
      widget.adaptiveLabel.isNotEmpty ||
      widget.weeklyTarget > 0;

  Color _focusColor(BuildContext context, String label) {
    final value = label.toLowerCase();
    if (value.contains('mind') || value.contains('calm')) {
      return const Color(0xFF8B5CF6);
    }
    if (value.contains('body')) {
      return const Color(0xFF4F7CFF);
    }
    if (value.contains('growth')) {
      return const Color(0xFF22D3EE);
    }
    if (value.contains('health')) {
      return const Color(0xFF60A5FA);
    }
    return Theme.of(context).colorScheme.primary;
  }

  String _weekdayName() {
    const names = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final index = DateTime.now().weekday - 1;
    return names[index.clamp(0, names.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dayLine = '${_weekdayName()} is yours.';
    final hasUnlockedStats = widget.doneCount > 0;
    final baseCardColor = Color.alphaBlend(
      Colors.black.withOpacity(
        theme.brightness == Brightness.dark ? 0.24 : 0.06,
      ),
      scheme.surface,
    );
    final cardColor = Color.alphaBlend(
      scheme.primary.withOpacity(
        theme.brightness == Brightness.dark ? 0.08 : 0.04,
      ),
      baseCardColor,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 22,
            right: 22,
            bottom: -22,
            height: 44,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.95),
                    radius: 1.15,
                    colors: [
                      scheme.primary.withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: cardColor,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dayLine,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.93),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 26,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Let's start with one spark.",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant.withOpacity(
                                      0.6,
                                    ),
                                    fontWeight: FontWeight.w400,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _ProgressRing(progress: widget.progress),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _AnimatedGradientProgressBar(
                        progress: widget.progress,
                        glowColor: const Color(0xFF7C83FF),
                      ),
                      const SizedBox(height: 4),
                      _StreakSpotlight(
                        streak: widget.streak,
                        doneCount: widget.doneCount,
                        onTap: widget.onOpenStats,
                      ),
                      if (hasUnlockedStats) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 8,
                              child: _StatTile(
                                icon: Icons.check_circle_rounded,
                                label:
                                    '${widget.doneCount} / ${widget.totalCount}',
                                subtitle: 'Completed',
                                color: const Color(0xFF7C83FF),
                                emphasis: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 4,
                              child: _StatTile(
                                icon: Icons.calendar_today_rounded,
                                label: '${widget.todayCompleted}',
                                subtitle: 'Today',
                                color: const Color(0xFF4F7CFF),
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_hasDetails) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(
                                () => _detailsExpanded = !_detailsExpanded,
                              );
                            },
                            icon: Icon(
                              _detailsExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _detailsExpanded
                                  ? 'Hide details'
                                  : 'Show details',
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: scheme.onSurfaceVariant,
                              backgroundColor: scheme.surfaceContainerHighest
                                  .withOpacity(0.24),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          child: _detailsExpanded
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (widget.focusLabel.isNotEmpty) ...[
                                        _InfoPill(
                                          iconAsset:
                                              'assets/in_app_icons/focus.png',
                                          text:
                                              'Today focus: ${widget.focusLabel}',
                                          color: _focusColor(
                                            context,
                                            widget.focusLabel,
                                          ),
                                        ),
                                      ],
                                      if (widget.adaptiveLabel.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        _InfoPill(
                                          icon: Icons.tune_rounded,
                                          text: widget.adaptiveLabel,
                                          color: const Color(0xFF21D4FD),
                                        ),
                                      ],
                                      if (widget.weeklyTarget > 0) ...[
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: widget.onOpenWeeklyPlan,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: _InfoPill(
                                            iconAsset:
                                                'assets/in_app_icons/calendar.png',
                                            text:
                                                'This week: ${widget.weeklyDone}/${widget.weeklyTarget}',
                                            color: const Color(0xFF8B5CF6),
                                            trailing: const Icon(
                                              Icons.edit_rounded,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.22),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.dateLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (hasUnlockedStats) ...[
                        TextButton.icon(
                          onPressed: widget.onOpenStats,
                          icon: const Icon(Icons.insights_rounded, size: 16),
                          label: const Text('View stats'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFFFFFF),
                            backgroundColor: const Color(
                              0xFF9D65FF,
                            ).withOpacity(0.14),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        onPressed: widget.onShare,
                        icon: const Icon(Icons.share_rounded, size: 18),
                        style: IconButton.styleFrom(
                          foregroundColor: scheme.onSurfaceVariant,
                          backgroundColor: scheme.surface.withOpacity(0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surface.withOpacity(0.8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 3.5,
              backgroundColor: scheme.surfaceVariant.withOpacity(0.8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF3E8BFF),
              ),
            ),
          ),
          Image.asset(
            'assets/in_app_icons/rocket.png',
            width: 18,
            height: 18,
            fit: BoxFit.contain,
            color: scheme.onSurfaceVariant.withOpacity(0.5),
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.rocket_launch_rounded,
              size: 18,
              color: scheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.emphasis = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool emphasis;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tileColor = Color.alphaBlend(
      color.withOpacity(emphasis ? 0.22 : 0.16),
      scheme.surface,
    );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 9 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: tileColor,
      ),
      child: Column(
        children: [
          Icon(icon, size: compact ? 15 : (emphasis ? 19 : 17), color: color),
          SizedBox(height: compact ? 3 : 4),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 21 / 1.6 : (emphasis ? 25 / 1.6 : 22 / 1.6),
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakSpotlight extends StatelessWidget {
  const _StreakSpotlight({
    required this.streak,
    required this.doneCount,
    required this.onTap,
  });

  final int streak;
  final int doneCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = streak > 0;
    const target = 3;
    final ignited = doneCount.clamp(0, target);
    final progress = ignited / target;
    final title = active ? 'Keep your streak alive' : 'Your first spark today';
    final subtitle = active
        ? 'Takes less than 2 minutes to keep momentum.'
        : 'Takes less than 2 minutes';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  (active ? const Color(0xFF22D3EE) : const Color(0xFF7C83FF))
                      .withOpacity(0.2),
                  scheme.surface,
                ),
                Color.alphaBlend(
                  (active ? const Color(0xFF4F7CFF) : const Color(0xFF22D3EE))
                      .withOpacity(0.1),
                  scheme.surface,
                ),
              ],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.16,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 14,
                          color: scheme.primary.withOpacity(0.92),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View stats',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary.withOpacity(0.94),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: scheme.primary.withOpacity(0.9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 5.2,
                          backgroundColor: scheme.surfaceVariant.withOpacity(
                            0.7,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF22D3EE),
                          ),
                        ),
                        Text(
                          '$ignited/$target',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
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

class _AnimatedGradientProgressBar extends StatefulWidget {
  const _AnimatedGradientProgressBar({
    required this.progress,
    required this.glowColor,
  });

  final double progress;
  final Color glowColor;

  @override
  State<_AnimatedGradientProgressBar> createState() =>
      _AnimatedGradientProgressBarState();
}

class _AnimatedGradientProgressBarState
    extends State<_AnimatedGradientProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = widget.progress.clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shift = (_controller.value * 2) - 1;
        return Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: scheme.surfaceVariant.withOpacity(0.78),
            boxShadow: progress <= 0
                ? null
                : [
                    BoxShadow(
                      color: widget.glowColor.withOpacity(0.34),
                      blurRadius: 12,
                      offset: const Offset(0, 0),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + shift, 0),
                      end: Alignment(1 + shift, 0),
                      colors: const [
                        Color(0xFF7C83FF),
                        Color(0xFF4F7CFF),
                        Color(0xFF22D3EE),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    this.icon,
    this.iconAsset,
    required this.text,
    required this.color,
    this.trailing,
  }) : assert(icon != null || iconAsset != null);

  final IconData? icon;
  final String? iconAsset;
  final String text;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color.alphaBlend(color.withOpacity(0.14), surface),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconAsset != null
              ? Image.asset(
                  iconAsset!,
                  width: 15,
                  height: 15,
                  fit: BoxFit.contain,
                  color: color,
                  colorBlendMode: BlendMode.srcIn,
                )
              : Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            IconTheme(
              data: IconThemeData(color: color),
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}
