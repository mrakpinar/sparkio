import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    required this.dateLabel,
    required this.isDark,
    required this.reminderEnabled,
    required this.refreshing,
    required this.onOpenStats,
    required this.onContact,
    required this.onToggleTheme,
    required this.onToggleReminder,
    required this.onRefresh,
  });

  final String dateLabel;
  final bool isDark;
  final bool reminderEnabled;
  final bool refreshing;
  final VoidCallback onOpenStats;
  final VoidCallback onContact;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleReminder;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SliverAppBar(
      backgroundColor: scheme.background,
      elevation: 0,
      floating: true,
      snap: true,
      centerTitle: false,
      toolbarHeight: 72,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SPARKIO',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                dateLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _AppBarAction(
          tooltip: 'Stats',
          onTap: onOpenStats,
          child: const Icon(Icons.insights_rounded),
        ),
        _AppBarMenu(tooltip: 'More', onContact: onContact),
        _AppBarAction(
          tooltip: isDark ? 'Dark theme' : 'Light theme',
          onTap: onToggleTheme,
          child: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          ),
        ),
        _AppBarAction(
          tooltip: reminderEnabled ? 'Disable reminder' : 'Enable reminder',
          onTap: onToggleReminder,
          child: Icon(
            reminderEnabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
          ),
        ),
        _AppBarAction(
          tooltip: refreshing ? 'Loading...' : 'New set',
          onTap: onRefresh,
          child: refreshing
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      scheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                )
              : const Icon(Icons.auto_awesome),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.child,
    required this.tooltip,
    required this.onTap,
  });

  final Widget child;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = scheme.surfaceVariant;
    final bg = theme.brightness == Brightness.dark
        ? base.withOpacity(0.6)
        : base.withOpacity(0.9);

    final content = SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: IconTheme(
          data: IconThemeData(
            color: onTap == null
                ? scheme.onSurface.withOpacity(0.4)
                : scheme.onSurface,
          ),
          child: child,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: onTap == null
                ? Opacity(opacity: 0.6, child: content)
                : content,
          ),
        ),
      ),
    );
  }
}

class _AppBarMenu extends StatelessWidget {
  const _AppBarMenu({required this.onContact, required this.tooltip});

  final VoidCallback onContact;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = scheme.surfaceVariant;
    final bg = theme.brightness == Brightness.dark
        ? base.withOpacity(0.6)
        : base.withOpacity(0.9);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'contact') {
                onContact();
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'contact', child: Text('Contact us')),
            ],
            icon: Icon(Icons.more_vert_rounded, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}
