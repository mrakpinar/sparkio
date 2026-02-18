import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show ImageFilter;

class ModernDrawer extends StatelessWidget {
  const ModernDrawer({
    super.key,
    required this.isDark,
    required this.showDebugTools,
    required this.profileName,
    required this.currentStreak,
    required this.earnedBadgeCount,
    required this.badgeGoalCount,
    required this.weeklyDoneCount,
    required this.weeklyGoalCount,
    required this.onToggleTheme,
    required this.onEditProfile,
    required this.onOpenBadges,
    required this.onOpenContact,
    required this.onSendTestNotification,
    required this.onOpenWeeklyPlan,
  });

  final bool isDark;
  final bool showDebugTools;
  final String profileName;
  final int currentStreak;
  final int earnedBadgeCount;
  final int badgeGoalCount;
  final int weeklyDoneCount;
  final int weeklyGoalCount;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onEditProfile;
  final VoidCallback onOpenBadges;
  final VoidCallback onOpenContact;
  final Future<void> Function() onSendTestNotification;
  final VoidCallback onOpenWeeklyPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveDark = isDark || theme.brightness == Brightness.dark;
    final safeBadgeGoal = badgeGoalCount <= 0 ? 1 : badgeGoalCount;
    final badgeProgress = (earnedBadgeCount / safeBadgeGoal).clamp(0.0, 1.0);
    final badgeFilledDots = (badgeProgress * 5).round().clamp(0, 5);
    final badgeDots = '${'●' * badgeFilledDots}${'○' * (5 - badgeFilledDots)}';

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
                child: _DrawerHero(
                  isDark: effectiveDark,
                  profileName: profileName,
                  currentStreak: currentStreak,
                  onQuickEdit: () => runAsyncMenuAction(onEditProfile),
                  onClose: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  children: [
                    _SectionHeader(
                      title: 'Appearance',
                      icon: Icons.dark_mode_rounded,
                    ),
                    const SizedBox(height: 8),
                    _SectionCard(
                      children: [
                        _ThemeQuickAccessCard(
                          isDark: isDark,
                          onToggleTheme: onToggleTheme,
                        ),
                      ],
                    ),
                    const _SectionDivider(),
                    _SectionHeader(
                      title: 'Profile',
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 8),
                    _SectionCard(
                      children: [
                        _ModernMenuCard(
                          icon: Icons.account_circle_rounded,
                          iconColor: scheme.primary,
                          title: profileName.isEmpty
                              ? 'Set your name'
                              : profileName,
                          subtitle: 'Edit your profile name',
                          onTap: () => runAsyncMenuAction(onEditProfile),
                        ),
                      ],
                    ),
                    const _SectionDivider(),
                    _SectionHeader(
                      title: 'Progress',
                      icon: Icons.insights_rounded,
                    ),
                    const SizedBox(height: 8),
                    _SectionCard(
                      children: [
                        _ModernMenuCard(
                          icon: Icons.emoji_events_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Badges',
                          subtitle: '$earnedBadgeCount/$safeBadgeGoal unlocked',
                          meta: _CardMetaPreview(
                            text:
                                '$badgeDots  $earnedBadgeCount/$safeBadgeGoal',
                          ),
                          onTap: () => runMenuAction(onOpenBadges),
                        ),
                        const SizedBox(height: 10),
                        _ModernMenuCard(
                          icon: Icons.calendar_view_week_rounded,
                          iconColor: scheme.primary,
                          title: 'Weekly plan',
                          subtitle: weeklyGoalCount > 0
                              ? '$weeklyDoneCount/$weeklyGoalCount goals'
                              : 'Set goals for this week',
                          meta: _CardMetaPreview(
                            text: weeklyGoalCount > 0
                                ? '$weeklyDoneCount/$weeklyGoalCount goals'
                                : 'No goals',
                          ),
                          onTap: () => runMenuAction(onOpenWeeklyPlan),
                        ),
                      ],
                    ),
                    if (showDebugTools && kDebugMode) ...[
                      const _SectionDivider(),
                      _SectionHeader(
                        title: 'Debug',
                        icon: Icons.developer_mode_rounded,
                      ),
                      const SizedBox(height: 8),
                      _SectionCard(
                        children: [
                          _ModernMenuCard(
                            icon: Icons.notifications_rounded,
                            iconColor: scheme.tertiary,
                            title: 'Send test reminder (1 min)',
                            subtitle: 'Debug only',
                            onTap: () =>
                                runAsyncMenuAction(onSendTestNotification),
                          ),
                        ],
                      ),
                    ],
                    const _SectionDivider(),
                    _SectionHeader(
                      title: 'Support',
                      icon: Icons.support_agent_rounded,
                    ),
                    const SizedBox(height: 8),
                    _SectionCard(
                      children: [
                        _ModernMenuCard(
                          icon: Icons.mail_outline_rounded,
                          iconColor: scheme.secondary,
                          title: 'Talk to us',
                          subtitle: 'We reply in <24h',
                          onTap: () => runMenuAction(onOpenContact),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _QuickSettingsHintBar(isDark: effectiveDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerHero extends StatelessWidget {
  const _DrawerHero({
    required this.isDark,
    required this.profileName,
    required this.currentStreak,
    required this.onQuickEdit,
    required this.onClose,
  });

  final bool isDark;
  final String profileName;
  final int currentStreak;
  final Future<void> Function() onQuickEdit;
  final VoidCallback onClose;

  ({int level, String badge}) _levelInfo() {
    if (currentStreak >= 21) {
      return (level: 5, badge: 'Elite Spark');
    }
    if (currentStreak >= 10) {
      return (level: 4, badge: 'Momentum Maker');
    }
    if (currentStreak >= 5) {
      return (level: 3, badge: 'Consistent Builder');
    }
    if (currentStreak >= 2) {
      return (level: 2, badge: 'Habit Starter');
    }
    return (level: 1, badge: 'First Spark');
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
    final level = _levelInfo();
    final surface = Color.alphaBlend(
      scheme.primary.withOpacity(0.08),
      scheme.surface,
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
          color: surface,
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
                    scheme.primary.withOpacity(isDark ? 0.45 : 0.32),
                    scheme.secondary.withOpacity(isDark ? 0.38 : 0.24),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Color.alphaBlend(
                        scheme.primary.withOpacity(isDark ? 0.2 : 0.12),
                        scheme.surface,
                      ),
                    ),
                    child: Text(
                      'Level ${level.level} • ${level.badge}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(children: children),
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
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap or swipe horizontally to toggle',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Transform.scale(
                  scale: 1.04,
                  child: Switch(
                    value: isDark,
                    onChanged: (_) => onToggleTheme(),
                    activeColor: scheme.primary,
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

class _QuickSettingsHintBar extends StatefulWidget {
  const _QuickSettingsHintBar({required this.isDark});

  final bool isDark;

  @override
  State<_QuickSettingsHintBar> createState() => _QuickSettingsHintBarState();
}

class _QuickSettingsHintBarState extends State<_QuickSettingsHintBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final iconColor = scheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = 0.85 + (_controller.value * 0.35);
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: widget.isDark
                  ? [
                      Color.alphaBlend(
                        scheme.primary.withOpacity(0.18),
                        scheme.surface,
                      ),
                      Color.alphaBlend(
                        scheme.secondary.withOpacity(0.1),
                        scheme.surface,
                      ),
                    ]
                  : [
                      Color.alphaBlend(
                        scheme.primary.withOpacity(0.12),
                        scheme.surface,
                      ),
                      Color.alphaBlend(
                        scheme.secondary.withOpacity(0.08),
                        scheme.surface,
                      ),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(widget.isDark ? 0.16 : 0.1),
                blurRadius: 14 + (pulse * 3),
                spreadRadius: 0.2 + (pulse * 0.2),
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Transform.rotate(
                angle: (_controller.value - 0.5) * 0.08,
                child: Transform.scale(
                  scale: 0.95 + (_controller.value * 0.12),
                  child: Icon(Icons.tune_rounded, size: 18, color: iconColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quick settings and progress controls.',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
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

class _ModernMenuCard extends StatelessWidget {
  const _ModernMenuCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.meta,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cardColor = Color.alphaBlend(
      scheme.primary.withOpacity(0.03),
      scheme.surface,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: cardColor,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color.alphaBlend(
                    iconColor.withOpacity(0.16),
                    scheme.surface,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (meta != null) ...[const SizedBox(width: 8), meta!],
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
