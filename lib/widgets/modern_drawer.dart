import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ModernDrawer extends StatelessWidget {
  const ModernDrawer({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.onOpenBadges,
    required this.onOpenContact,
    required this.onSendTestNotification,
    required this.onOpenWeeklyPlan,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onOpenBadges;
  final VoidCallback onOpenContact;
  final Future<void> Function() onSendTestNotification;
  final VoidCallback onOpenWeeklyPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveDark = isDark || theme.brightness == Brightness.dark;

    void runMenuAction(VoidCallback action) {
      Navigator.of(context).maybePop();
      action();
    }

    Future<void> runAsyncMenuAction(Future<void> Function() action) async {
      Navigator.of(context).maybePop();
      await action();
    }

    return Drawer(
      width: 326,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: effectiveDark
                ? const [
                    Color(0xFF081325),
                    Color(0xFF0B172A),
                    Color(0xFF0F1D31),
                  ]
                : [
                    scheme.surface,
                    const Color(0xFFF8FBFF),
                    const Color(0xFFF2F7FF),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: _DrawerHero(
                  isDark: effectiveDark,
                  onClose: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  children: [
                    _SectionHeader(
                      title: 'Appearance',
                      icon: Icons.palette_rounded,
                    ),
                    const SizedBox(height: 8),
                    _SectionCard(
                      children: [
                        _ModernSettingCard(
                          icon: Icons.dark_mode_rounded,
                          iconColor: scheme.primary,
                          title: 'Dark theme',
                          subtitle: 'Switch between light and dark mode',
                          trailing: Switch(
                            value: isDark,
                            onChanged: (_) => onToggleTheme(),
                            activeColor: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                          subtitle: 'View earned badges and goals',
                          onTap: () => runMenuAction(onOpenBadges),
                        ),
                        const SizedBox(height: 10),
                        _ModernMenuCard(
                          icon: Icons.calendar_view_week_rounded,
                          iconColor: scheme.primary,
                          title: 'Weekly plan',
                          subtitle: 'Set category goals for this week',
                          onTap: () => runMenuAction(onOpenWeeklyPlan),
                        ),
                      ],
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                          title: 'Contact us',
                          subtitle: 'Get in touch with our team',
                          onTap: () => runMenuAction(onOpenContact),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withOpacity(effectiveDark ? 0.18 : 0.12),
                      scheme.secondary.withOpacity(effectiveDark ? 0.12 : 0.07),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: scheme.primary.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quick settings and progress controls.',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerHero extends StatelessWidget {
  const _DrawerHero({required this.isDark, required this.onClose});

  final bool isDark;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF10233B), Color(0xFF0E1F35)]
              : [scheme.surface, const Color(0xFFF1F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3B82F6).withOpacity(0.35)
              : scheme.outline.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
              ),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Customize your Sparkio experience',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : scheme.surfaceContainerHighest.withOpacity(0.45),
              foregroundColor: scheme.onSurfaceVariant,
            ),
            tooltip: 'Close',
          ),
        ],
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
    return Row(
      children: [
        Icon(icon, size: 15, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surface.withOpacity(0.88),
        border: Border.all(color: scheme.outline.withOpacity(0.28)),
      ),
      child: Column(children: children),
    );
  }
}

class _ModernSettingCard extends StatelessWidget {
  const _ModernSettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [iconColor.withOpacity(0.12), iconColor.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
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
          const SizedBox(width: 6),
          trailing,
        ],
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
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [scheme.surface, scheme.surface.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: scheme.outline.withOpacity(0.24)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: iconColor.withOpacity(0.14),
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
