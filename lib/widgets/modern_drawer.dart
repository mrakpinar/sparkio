import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show ImageFilter;

class ModernDrawer extends StatefulWidget {
  const ModernDrawer({
    super.key,
    required this.isDark,
    required this.showDebugTools,
    required this.profileName,
    required this.currentStreak,
    required this.currentLevel,
    required this.totalXp,
    required this.xpInLevel,
    required this.xpToNextLevel,
    required this.earnedBadgeCount,
    required this.badgeGoalCount,
    required this.weeklyDoneCount,
    required this.weeklyGoalCount,
    required this.onToggleTheme,
    required this.onOpenAddSpark,
    required this.onEditProfile,
    required this.onOpenBadges,
    required this.onOpenContact,
    required this.onSendTestNotification,
    required this.onOpenDailyMoodSheet,
    required this.onOpenWeeklyPlan,
  });

  final bool isDark;
  final bool showDebugTools;
  final String profileName;
  final int currentStreak;
  final int currentLevel;
  final int totalXp;
  final int xpInLevel;
  final int xpToNextLevel;
  final int earnedBadgeCount;
  final int badgeGoalCount;
  final int weeklyDoneCount;
  final int weeklyGoalCount;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onOpenAddSpark;
  final Future<void> Function() onEditProfile;
  final VoidCallback onOpenBadges;
  final VoidCallback onOpenContact;
  final Future<void> Function() onSendTestNotification;
  final Future<void> Function() onOpenDailyMoodSheet;
  final VoidCallback onOpenWeeklyPlan;

  @override
  State<ModernDrawer> createState() => _ModernDrawerState();
}

class _ModernDrawerState extends State<ModernDrawer>
    with SingleTickerProviderStateMixin {
  static const _entryDurationMs = 320;
  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _entryDurationMs),
  )..forward();

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Animation<double> _interval(double start, {double span = 0.34}) {
    final safeStart = start.clamp(0.0, 0.94).toDouble();
    final safeEnd = (safeStart + span).clamp(safeStart + 0.05, 1.0).toDouble();
    return CurvedAnimation(
      parent: _entryController,
      curve: Interval(safeStart, safeEnd, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildStaggeredItem({required int index, required Widget child}) {
    const listStart = 20 / _entryDurationMs;
    const listStep = 0.045;
    return _DrawerEntryReveal(
      animation: _interval(listStart + (index * listStep)),
      beginOffsetY: 12,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveDark = widget.isDark || theme.brightness == Brightness.dark;
    final safeBadgeGoal = widget.badgeGoalCount <= 0
        ? 1
        : widget.badgeGoalCount;
    final badgeProgress = (widget.earnedBadgeCount / safeBadgeGoal).clamp(
      0.0,
      1.0,
    );
    final badgeFilledDots = (badgeProgress * 5).round().clamp(0, 5);
    const filledDot = '\u25CF';
    const emptyDot = '\u25CB';
    final badgeDots =
        '${filledDot * badgeFilledDots}${emptyDot * (5 - badgeFilledDots)}';

    Future<void> closeDrawer() async {
      final scaffold = Scaffold.maybeOf(context);
      if (scaffold != null && scaffold.isEndDrawerOpen) {
        scaffold.closeEndDrawer();
        await Future<void>.delayed(const Duration(milliseconds: 220));
        return;
      }
      await Navigator.of(context).maybePop();
    }

    Future<void> runMenuAction(VoidCallback action) async {
      await closeDrawer();
      action();
    }

    Future<void> runAsyncMenuAction(Future<void> Function() action) async {
      await closeDrawer();
      await action();
    }

    final drawerItems = <Widget>[
      _SectionHeader(title: 'Your space', icon: Icons.dark_mode_rounded),
      const SizedBox(height: 8),
      _SectionCard(
        children: [
          _ThemeQuickAccessCard(
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          ),
        ],
      ),
      const _SectionDivider(),
      _SectionHeader(title: 'You', icon: Icons.person_rounded),
      const SizedBox(height: 8),
      _SectionCard(
        children: [
          _ModernMenuCard(
            icon: Icons.account_circle_rounded,
            iconColor: scheme.primary,
            title: widget.profileName.isEmpty
                ? 'Set your name'
                : widget.profileName,
            subtitle: 'Edit your profile name',
            onTap: () => runAsyncMenuAction(widget.onEditProfile),
          ),
        ],
      ),
      const _SectionDivider(),
      _SectionHeader(title: 'Things you can do', icon: Icons.bolt_rounded),
      const SizedBox(height: 8),
      _SectionCard(
        children: [
          _ModernMenuCard(
            icon: Icons.auto_awesome_rounded,
            iconColor: scheme.tertiary,
            title: 'Create my spark',
            subtitle: 'Add a custom habit',
            isSubtle: true,
            onTap: () => runAsyncMenuAction(widget.onOpenAddSpark),
          ),
        ],
      ),
      const _SectionDivider(),
      _SectionHeader(title: 'Your journey', icon: Icons.insights_rounded),
      const SizedBox(height: 8),
      _SectionCard(
        children: [
          _ModernMenuCard(
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Badges',
            subtitle: '${widget.earnedBadgeCount}/$safeBadgeGoal unlocked',
            meta: _CardMetaPreview(
              text: '$badgeDots  ${widget.earnedBadgeCount}/$safeBadgeGoal',
            ),
            isMuted: true,
            onTap: () => runMenuAction(widget.onOpenBadges),
          ),
          _ModernMenuCard(
            icon: Icons.calendar_view_week_rounded,
            iconColor: scheme.primary,
            title: 'Weekly plan',
            subtitle: widget.weeklyGoalCount > 0
                ? '${widget.weeklyDoneCount}/${widget.weeklyGoalCount} goals'
                : 'Set goals for this week',
            meta: _CardMetaPreview(
              text: widget.weeklyGoalCount > 0
                  ? '${widget.weeklyDoneCount}/${widget.weeklyGoalCount} goals'
                  : 'No goals',
            ),
            onTap: () => runMenuAction(widget.onOpenWeeklyPlan),
          ),
        ],
      ),
      if (widget.showDebugTools && kDebugMode) ...[
        const _SectionDivider(),
        _SectionHeader(title: 'Debug', icon: Icons.developer_mode_rounded),
        const SizedBox(height: 8),
        _SectionCard(
          children: [
            _ModernMenuCard(
              icon: Icons.notifications_rounded,
              iconColor: scheme.tertiary,
              title: 'Send test reminder (1 min)',
              subtitle: 'Debug only',
              onTap: () => runAsyncMenuAction(widget.onSendTestNotification),
            ),
            _ModernMenuCard(
              icon: Icons.psychology_rounded,
              iconColor: scheme.primary,
              title: 'Open daily mood sheet',
              subtitle: 'Debug only',
              onTap: () => runAsyncMenuAction(widget.onOpenDailyMoodSheet),
            ),
          ],
        ),
      ],
      const _SectionDivider(),
      _SectionHeader(title: 'Need help?', icon: Icons.support_agent_rounded),
      const SizedBox(height: 8),
      _SectionCard(
        children: [
          _ModernMenuCard(
            icon: Icons.mail_outline_rounded,
            iconColor: scheme.secondary,
            title: 'Talk to us',
            subtitle: 'We reply in <24h',
            onTap: () => runMenuAction(widget.onOpenContact),
          ),
        ],
      ),
    ];

    return Drawer(
      width: 326,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      child: Container(
        decoration: BoxDecoration(color: scheme.background),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: _DrawerEntryReveal(
                  animation: _interval(0.0, span: 0.36),
                  beginOffsetY: 10,
                  child: _DrawerHero(
                    isDark: effectiveDark,
                    profileName: widget.profileName,
                    currentStreak: widget.currentStreak,
                    currentLevel: widget.currentLevel,
                    totalXp: widget.totalXp,
                    xpInLevel: widget.xpInLevel,
                    xpToNextLevel: widget.xpToNextLevel,
                    onQuickEdit: () => runAsyncMenuAction(widget.onEditProfile),
                    onClose: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  children: [
                    for (var i = 0; i < drawerItems.length; i++)
                      _buildStaggeredItem(index: i, child: drawerItems[i]),
                  ],
                ),
              ),
              _DrawerEntryReveal(
                animation: _interval(0.72, span: 0.2),
                beginOffsetY: 8,
                child: const _QuickSettingsCaption(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerEntryReveal extends StatelessWidget {
  const _DrawerEntryReveal({
    required this.animation,
    required this.child,
    this.beginOffsetY = 10,
  });

  final Animation<double> animation;
  final Widget child;
  final double beginOffsetY;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * beginOffsetY),
            child: child,
          ),
        );
      },
    );
  }
}

class _DrawerHero extends StatelessWidget {
  const _DrawerHero({
    required this.isDark,
    required this.profileName,
    required this.currentStreak,
    required this.currentLevel,
    required this.totalXp,
    required this.xpInLevel,
    required this.xpToNextLevel,
    required this.onQuickEdit,
    required this.onClose,
  });

  final bool isDark;
  final String profileName;
  final int currentStreak;
  final int currentLevel;
  final int totalXp;
  final int xpInLevel;
  final int xpToNextLevel;
  final Future<void> Function() onQuickEdit;
  final VoidCallback onClose;

  String _levelTitle(int level) {
    if (level >= 20) return 'Flow Master';
    if (level >= 14) return 'Momentum Maker';
    if (level >= 9) return 'Consistency Builder';
    if (level >= 5) return 'Habit Starter';
    return 'First Spark';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = profileName.trim().isEmpty ? 'Friend' : profileName.trim();
    final initials = name.characters.first.toUpperCase();
    final streakLabel = currentStreak > 0
        ? '$currentStreak-day streak 🔥'
        : 'Start your streak today 🔥';
    final safeLevel = currentLevel <= 0 ? 1 : currentLevel;
    final safeXpToNext = xpToNextLevel <= 0 ? 1 : xpToNextLevel;
    final clampedXpInLevel = xpInLevel.clamp(0, safeXpToNext);
    final levelTitle = _levelTitle(safeLevel);
    final surfaceStart = Color.alphaBlend(
      scheme.primary.withOpacity(isDark ? 0.045 : 0.03),
      scheme.surface.withOpacity(isDark ? 0.96 : 0.99),
    );
    final surfaceEnd = Color.alphaBlend(
      scheme.secondary.withOpacity(isDark ? 0.02 : 0.012),
      scheme.surface.withOpacity(isDark ? 0.95 : 0.985),
    );
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.selectionClick();
        onQuickEdit();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [surfaceStart, surfaceEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withOpacity(isDark ? 0.3 : 0.22),
                    scheme.secondary.withOpacity(isDark ? 0.2 : 0.14),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: scheme.outline.withOpacity(isDark ? 0.2 : 0.12),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimary,
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
                    '$name ⚡',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    streakLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Level $safeLevel - $levelTitle',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$clampedXpInLevel/$safeXpToNext XP · $totalXp total XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(0.68),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Long press for quick edit',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              style: IconButton.styleFrom(
                backgroundColor: scheme.surfaceContainerHighest.withOpacity(
                  0.35,
                ),
                foregroundColor: scheme.onSurfaceVariant,
              ),
              tooltip: 'Close',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Color.alphaBlend(
              scheme.primary.withOpacity(0.1),
              scheme.surface.withOpacity(0.7),
            ),
            border: Border.all(color: scheme.outline.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: scheme.primary.withOpacity(0.9)),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Opacity(
        opacity: 0.22,
        child: Divider(height: 1, thickness: 0.8, color: scheme.outline),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mergedChildren = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      mergedChildren.add(children[i]);
      if (i != children.length - 1) {
        mergedChildren.add(const SizedBox(height: 6));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Color.alphaBlend(
            scheme.primary.withOpacity(0.028),
            scheme.surface.withOpacity(0.94),
          ),
        ),
        child: Column(children: mergedChildren),
      ),
    );
  }
}

class _ThemeQuickAccessCard extends StatelessWidget {
  const _ThemeQuickAccessCard({
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cardColor = Color.alphaBlend(
      scheme.primary.withOpacity(0.055),
      scheme.surface,
    );

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() < 420) return;
          HapticFeedback.selectionClick();
          onToggleTheme();
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onToggleTheme,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: cardColor,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color.alphaBlend(
                      scheme.primary.withOpacity(0.18),
                      scheme.surface,
                    ),
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: scheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dark Mode',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap or swipe horizontally to toggle',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withOpacity(0.82),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Transform.scale(
                  scale: 0.98,
                  child: Switch(
                    value: isDark,
                    onChanged: (_) => onToggleTheme(),
                    activeColor: Color.alphaBlend(
                      scheme.primary.withOpacity(0.68),
                      scheme.surface,
                    ),
                    activeTrackColor: scheme.primary.withOpacity(0.24),
                    inactiveTrackColor: scheme.surfaceContainerHighest
                        .withOpacity(0.42),
                    inactiveThumbColor: scheme.onSurfaceVariant.withOpacity(
                      0.72,
                    ),
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

class _CardMetaPreview extends StatelessWidget {
  const _CardMetaPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Color.alphaBlend(
          scheme.primary.withOpacity(0.12),
          scheme.surface,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuickSettingsCaption extends StatelessWidget {
  const _QuickSettingsCaption();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Text(
        'Quick settings and progress controls.',
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant.withOpacity(0.66),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ModernMenuCard extends StatelessWidget {
  const _ModernMenuCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.meta,
    this.isSubtle = false,
    this.isMuted = false,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? meta;
  final bool isSubtle;
  final bool isMuted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveIconColor = isMuted
        ? iconColor.withOpacity(0.72)
        : iconColor;
    final iconSurfaceOpacity = isSubtle ? 0.1 : 0.16;
    final resolvedIconSurfaceOpacity = isMuted
        ? (iconSurfaceOpacity * 0.62)
        : iconSurfaceOpacity;
    final subtitleOpacity = isSubtle ? 0.8 : 1.0;
    final resolvedSubtitleOpacity = isMuted
        ? subtitleOpacity * 0.78
        : subtitleOpacity;
    final titleOpacity = isMuted ? 0.86 : 1.0;
    final trailingOpacity = isSubtle ? 0.58 : 1.0;
    final resolvedTrailingOpacity = isMuted
        ? trailingOpacity * 0.56
        : trailingOpacity;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: isSubtle ? 8 : 10,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color.alphaBlend(
                    iconColor.withOpacity(resolvedIconSurfaceOpacity),
                    scheme.surface,
                  ),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          (isSubtle
                                  ? theme.textTheme.bodyMedium
                                  : theme.textTheme.titleSmall)
                              ?.copyWith(
                                fontWeight: isSubtle
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                                color: scheme.onSurface.withOpacity(
                                  titleOpacity,
                                ),
                              ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withOpacity(
                          resolvedSubtitleOpacity,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (meta != null) ...[
                const SizedBox(width: 8),
                Opacity(opacity: isMuted ? 0.78 : 1, child: meta!),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant.withOpacity(
                  resolvedTrailingOpacity,
                ),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
