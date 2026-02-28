import 'package:flutter/material.dart';

import '../app_strings.dart';

class HomeActionBar extends StatelessWidget {
  const HomeActionBar({
    super.key,
    required this.onAddTask,
    required this.onUnlockPerks,
    required this.premiumActive,
    required this.premiumRemaining,
    required this.onStatusTap,
  });

  final VoidCallback onAddTask;
  final VoidCallback onUnlockPerks;
  final bool premiumActive;
  final String premiumRemaining;
  final VoidCallback? onStatusTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              l10n.tr('Quick actions'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  title: l10n.tr('Add a custom task'),
                  subtitle: l10n.tr('Personalize your list'),
                  icon: Icons.add_rounded,
                  tint: isDark ? const Color(0xFF3B82F6) : scheme.primary,
                  onTap: onAddTask,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: premiumActive
                    ? _StatusTile(
                        title: l10n.tr('Premium active'),
                        subtitle: premiumRemaining,
                        icon: Icons.verified_rounded,
                        tint: isDark
                            ? const Color(0xFF06B6D4)
                            : scheme.secondary,
                        onTap: onStatusTap,
                      )
                    : _ActionTile(
                        title: l10n.tr('Unlock perks'),
                        subtitle: l10n.tr('Boosts & no-ads'),
                        icon: Icons.workspace_premium_rounded,
                        iconAsset: 'assets/in_app_icons/premium.png',
                        tint: isDark
                            ? const Color(0xFF06B6D4)
                            : scheme.secondary,
                        onTap: onUnlockPerks,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconAsset,
    required this.tint,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? iconAsset;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: tint.withOpacity(0.1),
        highlightColor: tint.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF080F1C) : theme.colorScheme.surface,
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1E3A5F).withOpacity(0.35)
                  : theme.colorScheme.outline.withOpacity(0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint.withOpacity(isDark ? 0.1 : 0.12),
                  border: Border.all(
                    color: tint.withOpacity(isDark ? 0.15 : 0.2),
                    width: 1,
                  ),
                ),
                child: iconAsset != null
                    ? Center(
                        child: Image.asset(
                          iconAsset!,
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                          color: tint,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      )
                    : Icon(icon, color: tint, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withOpacity(0.95)
                      : theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              _StatusBadge(text: subtitle, tint: tint),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.tint});

  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withOpacity(isDark ? 0.1 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withOpacity(isDark ? 0.2 : 0.25)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: tint,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: tint.withOpacity(0.1),
        highlightColor: tint.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF080F1C) : theme.colorScheme.surface,
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1E3A5F).withOpacity(0.35)
                  : theme.colorScheme.outline.withOpacity(0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint.withOpacity(isDark ? 0.1 : 0.12),
                  border: Border.all(
                    color: tint.withOpacity(isDark ? 0.15 : 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: tint, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withOpacity(0.95)
                      : theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? Colors.white.withOpacity(0.6)
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




