import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    required this.dateLabel,
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

  final String dateLabel;
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
    const logoBlue = Color(0xFF5DB2FF);

    return SliverAppBar(
      backgroundColor: isDark ? const Color(0xFF081423) : scheme.surface,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      centerTitle: false,
      toolbarHeight: 72,
      titleSpacing: 20,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [logoBlue, const Color(0xFF4A7BE3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: logoBlue.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 30,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : scheme.outline.withOpacity(0.45),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SPARKIO',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    fontSize: 19,
                    color: isDark ? Colors.white : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.white.withOpacity(0.62)
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
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
          filled: false,
        ),
        const SizedBox(width: 8),
        _ModernIconButton(
          icon: Icons.workspace_premium_rounded,
          tooltip: 'Perks',
          onTap: onOpenPerks,
          isDark: isDark,
          tone: _ActionTone.premium,
          filled: true,
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
        const SizedBox(width: 16),
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

    final backgroundGradient = filled
        ? LinearGradient(
            colors: isDark
                ? [palette.$1.withOpacity(0.88), palette.$2.withOpacity(0.82)]
                : [palette.$1, palette.$2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF10253E).withOpacity(0.66),
                    const Color(0xFF0E2037).withOpacity(0.62),
                  ]
                : [scheme.surface, scheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final borderColor = filled
        ? (isDark ? palette.$1.withOpacity(0.28) : palette.$1.withOpacity(0.55))
        : (isDark
              ? palette.$1.withOpacity(0.22)
              : scheme.outline.withOpacity(0.55));

    final iconColor = filled
        ? Colors.white
        : (isDark ? Colors.white.withOpacity(0.92) : scheme.onSurface);

    final disabledColor = isDark
        ? Colors.white.withOpacity(0.3)
        : scheme.onSurface.withOpacity(0.3);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: isDark
              ? const Color(0xFF3B82F6).withOpacity(0.14)
              : scheme.primary.withOpacity(0.07),
          highlightColor: isDark
              ? const Color(0xFF3B82F6).withOpacity(0.06)
              : scheme.primary.withOpacity(0.03),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: backgroundGradient,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: isDark
                            ? palette.$1.withOpacity(0.14)
                            : palette.$1.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
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
        return (const Color(0xFF6DB6FF), const Color(0xFF2E8EF7));
      case _ActionTone.premium:
        return (const Color(0xFF6B8EFF), const Color(0xFF4363D8));
      case _ActionTone.menu:
        return (const Color(0xFF6CA2D8), const Color(0xFF3E5E8D));
    }
  }
}
