import 'package:flutter/material.dart';
import '../services/task_repository.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: FutureBuilder<_BadgeProgressData>(
        future: _loadBadges(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final earned = data?.earned ?? <String>{};
          final totalBadges = _allBadges.length;
          final earnedCount = earned.length;
          final progress = earnedCount / totalBadges;

          return CustomScrollView(
            slivers: [
              // Modern App Bar
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withOpacity(0.15),
                        scheme.secondary.withOpacity(0.08),
                        scheme.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button and title row
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: scheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: scheme.outline.withOpacity(0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.shadow.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                  tooltip: 'Back',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Badges',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Track your achievements',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Progress card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  scheme.primary.withOpacity(0.15),
                                  scheme.secondary.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: scheme.outline.withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.shadow.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Trophy icon
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            scheme.primary.withOpacity(0.2),
                                            scheme.primary.withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.emoji_events_rounded,
                                        color: scheme.primary,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Your Progress',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$earnedCount / $totalBadges badges',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: scheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Circular progress
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            scheme.primary.withOpacity(0.1),
                                            scheme.secondary.withOpacity(0.05),
                                          ],
                                        ),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SizedBox(
                                            width: 56,
                                            height: 56,
                                            child: CircularProgressIndicator(
                                              value: progress,
                                              strokeWidth: 4,
                                              backgroundColor:
                                                  scheme.surfaceVariant,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    scheme.primary,
                                                  ),
                                            ),
                                          ),
                                          Text(
                                            '${(progress * 100).round()}%',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: scheme.surfaceVariant
                                        .withOpacity(0.5),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      scheme.primary,
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
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (earnedCount > 0) ...[
                      const SizedBox(height: 8),
                      _SectionHeader(
                        title: 'Unlocked',
                        count: earnedCount,
                        icon: Icons.stars_rounded,
                      ),
                      const SizedBox(height: 12),
                      _BadgeGrid(
                        badges: _allBadges
                            .where((b) => earned.contains(b.id))
                            .toList(),
                        progress: data,
                        emptyMessage:
                            'Complete tasks to earn your first badge.',
                      ),
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 8),
                    _SectionHeader(
                      title: 'Locked',
                      count: totalBadges - earnedCount,
                      icon: Icons.lock_rounded,
                    ),
                    const SizedBox(height: 12),
                    _BadgeGrid(
                      badges: _allBadges
                          .where((b) => !earned.contains(b.id))
                          .toList(),
                      progress: data,
                      emptyMessage: 'All badges unlocked! 🎉',
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
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surfaceVariant,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
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
        final spacing = 14.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 0.80,
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
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final tint = badge.color;
    final current = progress == null ? 0 : _progressForBadge(badge, progress!);
    final target = badge.target;
    final ratio = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: locked
            ? null
            : LinearGradient(
                colors: [tint.withOpacity(0.08), scheme.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: locked ? scheme.surface : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: locked
              ? scheme.outline.withOpacity(0.3)
              : tint.withOpacity(0.3),
          width: locked ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: locked
                ? scheme.shadow.withOpacity(0.04)
                : tint.withOpacity(0.15),
            blurRadius: locked ? 8 : 16,
            offset: Offset(0, locked ? 2 : 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and status
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: locked
                          ? null
                          : LinearGradient(
                              colors: [
                                tint.withOpacity(0.25),
                                tint.withOpacity(0.15),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: locked
                          ? scheme.surfaceVariant.withOpacity(0.5)
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: locked
                          ? null
                          : [
                              BoxShadow(
                                color: tint.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Icon(
                      badge.icon,
                      color: locked
                          ? scheme.onSurfaceVariant.withOpacity(0.4)
                          : tint,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: locked
                          ? null
                          : LinearGradient(
                              colors: [
                                tint.withOpacity(0.2),
                                tint.withOpacity(0.1),
                              ],
                            ),
                      color: locked
                          ? scheme.surfaceVariant.withOpacity(0.5)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          locked
                              ? Icons.lock_rounded
                              : Icons.check_circle_rounded,
                          size: 14,
                          color: locked
                              ? scheme.onSurfaceVariant.withOpacity(0.6)
                              : tint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          locked ? 'Locked' : 'Earned',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: locked
                                ? scheme.onSurfaceVariant.withOpacity(0.6)
                                : tint,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Title
              Text(
                badge.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: locked
                      ? scheme.onSurfaceVariant.withOpacity(0.7)
                      : scheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                badge.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withOpacity(
                    locked ? 0.6 : 0.8,
                  ),
                  height: 1.4,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 14),

              // Progress section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: locked
                      ? scheme.surfaceVariant.withOpacity(0.3)
                      : tint.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: locked
                        ? scheme.outline.withOpacity(0.2)
                        : tint.withOpacity(0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          locked ? 'Progress' : 'Completed',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          locked ? '$current / $target' : '$target / $target',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: locked ? scheme.onSurfaceVariant : tint,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: locked
                            ? scheme.surfaceVariant.withOpacity(0.5)
                            : tint.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          locked
                              ? scheme.onSurfaceVariant.withOpacity(0.5)
                              : tint,
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withOpacity(0.08),
            scheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withOpacity(0.15),
                  scheme.secondary.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: scheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BadgeDef {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final int target;

  const _BadgeDef({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.target,
  });
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
    color: Color(0xFFEF4444),
    target: 10,
  ),
];

class _BadgeProgressData {
  final Set<String> earned;
  final int totalCompleted;
  final int bestStreak;
  final Map<String, int> categoryCounts;

  const _BadgeProgressData({
    required this.earned,
    required this.totalCompleted,
    required this.bestStreak,
    required this.categoryCounts,
  });
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
