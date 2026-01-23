import 'package:flutter/material.dart';

class PremiumPerksSheet extends StatelessWidget {
  final bool rewardBusy;
  final String premiumStatus;
  final String noAdsStatus;
  final VoidCallback onWatchPremium;
  final VoidCallback onWatchNoAds;
  final VoidCallback onSkipTask;
  final VoidCallback onExtraTask;
  final VoidCallback onRecoverStreak;

  const PremiumPerksSheet({
    super.key,
    required this.rewardBusy,
    required this.premiumStatus,
    required this.noAdsStatus,
    required this.onWatchPremium,
    required this.onWatchNoAds,
    required this.onSkipTask,
    required this.onExtraTask,
    required this.onRecoverStreak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unlock premium perks',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Watch a short video to unlock benefits.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PerkCard(
                    title: '30 min free premium',
                    status: premiumStatus,
                    onPressed: rewardBusy ? null : onWatchPremium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PerkCard(
                    title: 'No ads 1 day',
                    status: noAdsStatus,
                    onPressed: rewardBusy ? null : onWatchNoAds,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Rewarded actions',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Optional boosts if you want them.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: rewardBusy ? null : onSkipTask,
                icon: const Icon(Icons.fast_forward_rounded),
                label: const Text('Skip this task'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: rewardBusy ? null : onExtraTask,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Get one extra task'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: rewardBusy ? null : onRecoverStreak,
                icon: const Icon(Icons.local_fire_department_rounded),
                label: const Text('Recover streak'),
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
  final VoidCallback? onPressed;

  const _PerkCard({
    required this.title,
    required this.status,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: $status',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              child: const Text('Watch to unlock'),
            ),
          ),
        ],
      ),
    );
  }
}
