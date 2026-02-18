import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    required this.userName,
    required this.isDark,
    required this.reminderEnabled,
    required this.refreshing,
    required this.onContact,
    required this.onToggleTheme,
    required this.onToggleReminder,
    required this.onSendTestNotification,
    required this.onRefresh,
    required this.onOpenPerks,
    required this.onOpenMenu,
  });

  final String userName;
  final bool isDark;
  final bool reminderEnabled;
  final bool refreshing;
  final VoidCallback onContact;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleReminder;
  final VoidCallback onSendTestNotification;
  final VoidCallback? onRefresh;
  final VoidCallback onOpenPerks;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final topText = theme.textTheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : (hour < 18 ? 'Good Afternoon' : 'Good Evening');

    return SliverAppBar(
      backgroundColor: scheme.background,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      centerTitle: false,
      toolbarHeight: 88,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withOpacity(0.28),
                  scheme.primary.withOpacity(0.16),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(Icons.bolt_rounded, color: scheme.primary, size: 27),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$greeting, $userName 👋',
                  style: topText.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  "Let's build your streak today ⚡",
                  style: topText.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _ModernIconButton(
          icon: refreshing ? null : Icons.auto_awesome_rounded,
          tooltip: refreshing ? 'Loading...' : 'New tasks',
          onTap: onRefresh,
          isDark: isDark,
          isLoading: refreshing,
          tone: _ActionTone.spark,
          filled: true,
        ),
        const SizedBox(width: 8),
        _ModernIconButton(
          icon: Icons.bookmark_border_rounded,
          tooltip: 'Perks',
          onTap: onOpenPerks,
          isDark: isDark,
          tone: _ActionTone.premium,
          filled: false,
        ),
        const SizedBox(width: 8),
        _ModernIconButton(
          icon: Icons.menu_rounded,
          tooltip: 'Menu',
          onTap: onOpenMenu,
          isDark: isDark,
          tone: _ActionTone.menu,
          filled: false,
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

enum _ActionTone { spark, premium, menu }

class _ModernIconButton extends StatelessWidget {
  const _ModernIconButton({
    this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
    required this.tone,
    this.filled = false,
    this.isLoading = false,
  });

  final IconData? icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isDark;
  final _ActionTone tone;
  final bool filled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = _paletteForTone(tone);

    final backgroundColor = filled
        ? Color.alphaBlend(
            palette.$1.withOpacity(isDark ? 0.28 : 0.2),
            scheme.surface,
          )
        : scheme.surface.withOpacity(isDark ? 0.76 : 1);

    final iconColor = filled ? palette.$1 : scheme.onSurface.withOpacity(0.9);

    final disabledColor = isDark
        ? Colors.white.withOpacity(0.3)
        : scheme.onSurface.withOpacity(0.3);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          splashColor: scheme.primary.withOpacity(0.08),
          highlightColor: scheme.primary.withOpacity(0.03),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          filled
                              ? Colors.white
                              : (isDark ? palette.$1 : scheme.primary),
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      size: 22,
                      color: onTap == null ? disabledColor : iconColor,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color) _paletteForTone(_ActionTone tone) {
    switch (tone) {
      case _ActionTone.spark:
        return (const Color(0xFF3E8BFF), const Color(0xFF3E8BFF));
      case _ActionTone.premium:
        return (const Color(0xFF8B5CF6), const Color(0xFF8B5CF6));
      case _ActionTone.menu:
        return (const Color(0xFF64748B), const Color(0xFF64748B));
    }
  }
}
