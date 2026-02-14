import 'package:flutter/material.dart';

import '../services/task_repository.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      body: FutureBuilder<_BadgeProgressData>(
        future: _loadBadges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Unable to load badges right now.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final earned = data.earned;
          final totalBadges = _allBadges.length;
          final earnedCount = earned.length;
          final progress = totalBadges == 0 ? 0.0 : earnedCount / totalBadges;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 55,
                backgroundColor: scheme.surface,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                centerTitle: true,
                title: const Text('Badges'),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withOpacity(0.12),
                          scheme.primaryContainer.withOpacity(0.1),
                          scheme.surface,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _SummaryCard(
                    earnedCount: earnedCount,
                    totalBadges: totalBadges,
                    progress: progress,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (earnedCount > 0) ...[
                      _SectionHeader(
                        title: 'Unlocked',
                        count: earnedCount,
                        icon: Icons.stars_rounded,
                      ),
                      const SizedBox(height: 12),
                      _BadgeGrid(
                        badges: _allBadges
                            .where((badge) => earned.contains(badge.id))
                            .toList(),
                        progress: data,
                        emptyMessage:
                            'Complete tasks to earn your first badge.',
                      ),
                      const SizedBox(height: 24),
                    ],
                    _SectionHeader(
                      title: 'Locked',
                      count: totalBadges - earnedCount,
                      icon: Icons.lock_rounded,
                    ),
                    const SizedBox(height: 12),
                    _BadgeGrid(
                      badges: _allBadges
                          .where((badge) => !earned.contains(badge.id))
                          .toList(),
                      progress: data,
                      emptyMessage: 'All badges unlocked!',
                      locked: true,
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_BadgeProgressData> _loadBadges() async {
    final repo = TaskRepository();
    final total = await repo.getTotalCompleted();
    final best = await repo.getBestStreak();
    final counts = await repo.getCategoryCounts();
    await repo.awardBadges(
      totalCompleted: total,
      bestStreak: best,
      categoryCounts: counts,
    );
    final earned = await repo.getEarnedBadges();
    return _BadgeProgressData(
      earned: earned,
      totalCompleted: total,
      bestStreak: best,
      categoryCounts: counts,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.earnedCount,
    required this.totalBadges,
    required this.progress,
  });

  final int earnedCount;
  final int totalBadges;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            scheme.primary.withOpacity(0.14),
            scheme.primaryContainer.withOpacity(0.09),
            scheme.surface.withOpacity(0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.outline.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: scheme.primary.withOpacity(0.18),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: scheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$earnedCount / $totalBadges badges unlocked',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
  });

  final String title;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: scheme.surfaceVariant.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outline.withOpacity(0.6)),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({
    required this.badges,
    required this.emptyMessage,
    required this.progress,
    this.locked = false,
  });

  final List<_BadgeDef> badges;
  final String emptyMessage;
  final _BadgeProgressData? progress;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return _EmptyCard(message: emptyMessage);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 600 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            return _BadgeCard(
              badge: badges[index],
              locked: locked,
              progress: progress,
            );
          },
        );
      },
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.locked,
    required this.progress,
  });

  final _BadgeDef badge;
  final bool locked;
  final _BadgeProgressData? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = badge.color;
    final current = progress == null ? 0 : _progressForBadge(badge, progress!);
    final target = badge.target;
    final ratio = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: locked
              ? [scheme.surface, scheme.surface]
              : [tint.withOpacity(0.08), scheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: locked
              ? scheme.outline.withOpacity(0.7)
              : tint.withOpacity(0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: locked
                        ? scheme.surfaceVariant.withOpacity(0.5)
                        : tint.withOpacity(0.16),
                  ),
                  child: Icon(
                    badge.icon,
                    color: locked ? scheme.onSurfaceVariant : tint,
                    size: 22,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: locked
                        ? scheme.surfaceVariant.withOpacity(0.5)
                        : tint.withOpacity(0.14),
                    border: Border.all(
                      color: locked
                          ? scheme.outline.withOpacity(0.6)
                          : tint.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        locked ? Icons.lock_rounded : Icons.check_rounded,
                        size: 12,
                        color: locked ? scheme.onSurfaceVariant : tint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        locked ? 'Locked' : 'Earned',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: locked ? scheme.onSurfaceVariant : tint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              badge.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withOpacity(0.9),
                height: 1.35,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  locked ? 'Progress' : 'Complete',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  locked ? '$current / $target' : '$target / $target',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: locked ? scheme.onSurfaceVariant : tint,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: scheme.surfaceVariant.withOpacity(0.8),
                valueColor: AlwaysStoppedAnimation<Color>(
                  locked ? scheme.onSurfaceVariant.withOpacity(0.7) : tint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: scheme.primary.withOpacity(0.14),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: scheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeDef {
  const _BadgeDef({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.target,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final int target;
}

const _allBadges = <_BadgeDef>[
  _BadgeDef(
    id: 'total_10',
    label: '10 tasks',
    description: 'Complete 10 total tasks.',
    icon: Icons.bolt_rounded,
    color: Color(0xFF60A5FA),
    target: 10,
  ),
  _BadgeDef(
    id: 'total_50',
    label: '50 tasks',
    description: 'Complete 50 total tasks.',
    icon: Icons.emoji_events_rounded,
    color: Color(0xFFFBBF24),
    target: 50,
  ),
  _BadgeDef(
    id: 'total_100',
    label: '100 tasks',
    description: 'Complete 100 total tasks.',
    icon: Icons.workspace_premium_rounded,
    color: Color(0xFFFB7185),
    target: 100,
  ),
  _BadgeDef(
    id: 'streak_3',
    label: '3-day streak',
    description: 'Finish tasks 3 days in a row.',
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFF97316),
    target: 3,
  ),
  _BadgeDef(
    id: 'streak_7',
    label: '7-day streak',
    description: 'Keep a 7 day streak.',
    icon: Icons.whatshot_rounded,
    color: Color(0xFFEF4444),
    target: 7,
  ),
  _BadgeDef(
    id: 'cat_mind_10',
    label: 'Mind x10',
    description: 'Complete 10 Mind tasks.',
    icon: Icons.psychology_rounded,
    color: Color(0xFF8B5CF6),
    target: 10,
  ),
  _BadgeDef(
    id: 'cat_body_10',
    label: 'Body x10',
    description: 'Complete 10 Body tasks.',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFF97316),
    target: 10,
  ),
  _BadgeDef(
    id: 'cat_growth_10',
    label: 'Growth x10',
    description: 'Complete 10 Growth tasks.',
    icon: Icons.trending_up_rounded,
    color: Color(0xFF22C55E),
    target: 10,
  ),
  _BadgeDef(
    id: 'cat_calm_10',
    label: 'Calm x10',
    description: 'Complete 10 Calm tasks.',
    icon: Icons.spa_rounded,
    color: Color(0xFF06B6D4),
    target: 10,
  ),
  _BadgeDef(
    id: 'cat_health_10',
    label: 'Health x10',
    description: 'Complete 10 Health tasks.',
    icon: Icons.favorite_rounded,
    color: Color(0xFF3B82F6),
    target: 10,
  ),
];

class _BadgeProgressData {
  const _BadgeProgressData({
    required this.earned,
    required this.totalCompleted,
    required this.bestStreak,
    required this.categoryCounts,
  });

  final Set<String> earned;
  final int totalCompleted;
  final int bestStreak;
  final Map<String, int> categoryCounts;
}

int _progressForBadge(_BadgeDef badge, _BadgeProgressData data) {
  switch (badge.id) {
    case 'total_10':
    case 'total_50':
    case 'total_100':
      return data.totalCompleted;
    case 'streak_3':
    case 'streak_7':
      return data.bestStreak;
    case 'cat_mind_10':
      return data.categoryCounts['mind'] ?? 0;
    case 'cat_body_10':
      return data.categoryCounts['body'] ?? 0;
    case 'cat_growth_10':
      return data.categoryCounts['growth'] ?? 0;
    case 'cat_calm_10':
      return data.categoryCounts['calm'] ?? 0;
    case 'cat_health_10':
      return data.categoryCounts['health'] ?? 0;
    default:
      return 0;
  }
}
