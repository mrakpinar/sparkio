import 'package:flutter/material.dart';

class PremiumPerksSheet extends StatelessWidget {
  final bool rewardBusy;
  final bool premiumActive;
  final bool noAdsActive;
  final String premiumStatus;
  final String noAdsStatus;
  final VoidCallback onWatchPremium;
  final VoidCallback onWatchNoAds;
  final VoidCallback onOpenSubscribe;
  final VoidCallback onExtraTask;
  final VoidCallback onRecoverStreak;

  const PremiumPerksSheet({
    super.key,
    required this.rewardBusy,
    required this.premiumActive,
    required this.noAdsActive,
    required this.premiumStatus,
    required this.noAdsStatus,
    required this.onWatchPremium,
    required this.onWatchNoAds,
    required this.onOpenSubscribe,
    required this.onExtraTask,
    required this.onRecoverStreak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1628) : scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : scheme.shadow.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : scheme.onSurface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'Premium & boosts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? Colors.white.withOpacity(0.95)
                    : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Unlock more tasks and remove ads.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PerkCard(
                    title: '30 min free premium',
                    status: premiumStatus,
                    showButton: !premiumActive,
                    onPressed: rewardBusy ? null : onWatchPremium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PerkCard(
                    title: 'No ads 1 day',
                    status: noAdsStatus,
                    showButton: !noAdsActive,
                    onPressed: rewardBusy ? null : onWatchNoAds,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark
                    ? const Color(0xFF0D1B2E)
                    : scheme.surfaceVariant.withOpacity(0.5),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFFBBF24).withOpacity(0.3)
                      : scheme.outline.withOpacity(0.3),
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFBBF24).withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFBBF24,
                      ).withOpacity(isDark ? 0.15 : 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(
                          0xFFFBBF24,
                        ).withOpacity(isDark ? 0.25 : 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 24,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium subscription',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white.withOpacity(0.95)
                                : scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Monthly or yearly access.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onOpenSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBBF24),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Subscribe',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Rewarded actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? Colors.white.withOpacity(0.95)
                    : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Optional boosts if you want them.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: rewardBusy ? null : onExtraTask,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Get one extra task'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFF0D1B2E)
                      : scheme.surface,
                  foregroundColor: isDark
                      ? const Color(0xFF22C55E)
                      : scheme.primary,
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF22C55E).withOpacity(0.3)
                        : scheme.outline.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: rewardBusy ? null : onRecoverStreak,
                icon: const Icon(Icons.local_fire_department_rounded),
                label: const Text('Recover streak'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFF0D1B2E)
                      : scheme.surface,
                  foregroundColor: isDark
                      ? const Color(0xFFF97316)
                      : scheme.error,
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFFF97316).withOpacity(0.3)
                        : scheme.outline.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerkCard extends StatelessWidget {
  final String title;
  final String status;
  final bool showButton;
  final VoidCallback? onPressed;

  const _PerkCard({
    required this.title,
    required this.status,
    required this.showButton,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B2E) : scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E3A5F).withOpacity(0.4)
              : scheme.outline.withOpacity(0.3),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(isDark ? 0.15 : 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.primary.withOpacity(isDark ? 0.25 : 0.3),
                  ),
                ),
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: scheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white.withOpacity(0.95)
                        : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF080F1C) : scheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E3A5F).withOpacity(0.3)
                    : scheme.outline.withOpacity(0.2),
              ),
            ),
            child: Text(
              'Status: $status',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : scheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
          if (showButton) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Watch to unlock',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
