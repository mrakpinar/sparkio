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
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SliverAppBar(
      backgroundColor: isDark ? const Color(0xFF0A1929) : scheme.surface,
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
          // App Icon with gradient
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
          // Title and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SPARKIO',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontSize: 20,
                    color: isDark ? Colors.white : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.white.withOpacity(0.6)
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
        // Refresh button
        _ModernIconButton(
          icon: refreshing ? null : Icons.auto_awesome_rounded,
          tooltip: refreshing ? 'Loading...' : 'New tasks',
          onTap: onRefresh,
          isDark: isDark,
          isLoading: refreshing,
        ),
        const SizedBox(width: 8),
        // Menu button
        _ModernIconButton(
          icon: Icons.menu_rounded,
          tooltip: 'Menu',
          onTap: onOpenMenu,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _ModernIconButton extends StatelessWidget {
  const _ModernIconButton({
    this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
    this.isLoading = false,
  });

  final IconData? icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isDark;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Colors based on theme
    final backgroundColor = isDark
        ? const Color(0xFF1E3A5F).withOpacity(0.6)
        : scheme.primaryContainer.withOpacity(0.3);

    final borderColor = isDark
        ? const Color(0xFF3B82F6).withOpacity(0.2)
        : scheme.primary.withOpacity(0.15);

    final iconColor = isDark ? Colors.white.withOpacity(0.9) : scheme.onSurface;

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
              ? const Color(0xFF3B82F6).withOpacity(0.2)
              : scheme.primary.withOpacity(0.1),
          highlightColor: isDark
              ? const Color(0xFF3B82F6).withOpacity(0.1)
              : scheme.primary.withOpacity(0.05),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: scheme.shadow.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? const Color(0xFF60A5FA) : scheme.primary,
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
}
