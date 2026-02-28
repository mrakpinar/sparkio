import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../app_strings.dart';
import '../services/task_repository.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen>
    with SingleTickerProviderStateMixin {
  static const _timelineMs = 500;
  static const _itemRevealMs = 180;
  static const _rowStaggerMs = 20;

  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _timelineMs),
  )..forward();

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F1A) : scheme.background,
      body: Stack(
        children: [
          Positioned.fill(child: _MilestonesAmbientBackground(scheme: scheme)),
          FutureBuilder<_BadgeProgressData>(
            future: _loadBadges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Text(
                    l10n.tr('Unable to load badges right now.'),
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
              final progress = totalBadges == 0
                  ? 0.0
                  : earnedCount / totalBadges;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    toolbarHeight: 68,
                    pinned: false,
                    floating: true,
                    snap: true,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    scrolledUnderElevation: 0,
                    centerTitle: false,
                    titleSpacing: 16,
                    flexibleSpace: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(11, 15, 26, 0.82),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.25),
                                  blurRadius: 22,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      l10n.tr('Milestones'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        letterSpacing: 0.2,
                      ),
                    ),
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _MilestonesTopIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: _SummaryCard(
                        earnedCount: earnedCount,
                        totalBadges: totalBadges,
                        progress: progress,
                        revealAnimation: _entryController,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (earnedCount > 0) ...[
                          _SectionHeader(
                            title: l10n.tr('Completed milestones'),
                            count: earnedCount,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          _BadgeGrid(
                            badges: _allBadges
                                .where((badge) => earned.contains(badge.id))
                                .toList(),
                            progress: data,
                            revealAnimation: _entryController,
                            progressAnimation: _entryController,
                            revealStart: 0.18,
                            emptyMessage:
                                l10n.tr(
                                  'Complete tasks to unlock your first milestone.',
                                ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        _SectionHeader(
                          title: l10n.tr('Next milestones'),
                          icon: Icons.schedule_rounded,
                        ),
                        const SizedBox(height: 16),
                        _BadgeGrid(
                          badges: _allBadges
                              .where((badge) => !earned.contains(badge.id))
                              .toList(),
                          progress: data,
                          revealAnimation: _entryController,
                          progressAnimation: _entryController,
                          revealStart: earnedCount > 0 ? 0.42 : 0.2,
                          emptyMessage: l10n.tr('All milestones unlocked!'),
                          locked: true,
                        ),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
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
    required this.revealAnimation,
  });

  final int earnedCount;
  final int totalBadges;
  final double progress;
  final Animation<double> revealAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    const barSpan = 300 / _BadgesScreenState._timelineMs;
    final barReveal = CurvedAnimation(
      parent: revealAnimation,
      curve: const Interval(0.0, barSpan, curve: Curves.easeOut),
    );

    return _StaggeredFadeInUp(
      animation: revealAnimation,
      start: 0.0,
      end: _BadgesScreenState._itemRevealMs / _BadgesScreenState._timelineMs,
      offsetY: 6,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _milestonesGlassDecoration(
          scheme,
          tint: const Color(0xFF8B7CFF),
          radius: 20,
          tintOpacity: 0.08,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.trf('{earned} of {total} milestones', {
                      'earned': earnedCount,
                      'total': totalBadges,
                    }),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: scheme.onSurface.withOpacity(0.92),
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.52),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: AnimatedBuilder(
                animation: barReveal,
                builder: (context, _) {
                  return _SoftProgressBar(
                    value: progress * barReveal.value,
                    height: 6,
                    radius: 999,
                    trackOpacity: 0.12,
                    fillOpacity: 0.92,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaggeredFadeInUp extends StatelessWidget {
  const _StaggeredFadeInUp({
    required this.animation,
    required this.start,
    required this.end,
    required this.child,
    this.offsetY = 6,
  });

  final Animation<double> animation;
  final double start;
  final double end;
  final Widget child;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    final boundedStart = start.clamp(0.0, 0.95).toDouble();
    final boundedEnd = end.clamp(boundedStart + 0.05, 1.0).toDouble();
    final reveal = CurvedAnimation(
      parent: animation,
      curve: Interval(boundedStart, boundedEnd, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: reveal,
      child: child,
      builder: (context, child) {
        final t = reveal.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * offsetY),
            child: child,
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count, required this.icon});

  final String title;
  final int? count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 17, color: scheme.primary.withOpacity(0.84)),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: scheme.onSurface.withOpacity(0.76),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withOpacity(0.45),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({
    required this.badges,
    required this.emptyMessage,
    required this.progress,
    required this.revealAnimation,
    required this.progressAnimation,
    required this.revealStart,
    this.locked = false,
  });

  final List<_BadgeDef> badges;
  final String emptyMessage;
  final _BadgeProgressData? progress;
  final Animation<double> revealAnimation;
  final Animation<double> progressAnimation;
  final double revealStart;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return _StaggeredFadeInUp(
        animation: revealAnimation,
        start: revealStart,
        end:
            (revealStart +
                    (_BadgesScreenState._itemRevealMs /
                        _BadgesScreenState._timelineMs))
                .clamp(0.0, 1.0),
        offsetY: 6,
        child: _EmptyCard(message: emptyMessage),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 20,
            childAspectRatio: 0.82,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final rowIndex = index ~/ 2;
            final rowStep =
                _BadgesScreenState._rowStaggerMs /
                _BadgesScreenState._timelineMs;
            final duration =
                _BadgesScreenState._itemRevealMs /
                _BadgesScreenState._timelineMs;
            final start = (revealStart + (rowIndex * rowStep)).clamp(0.0, 0.9);
            final end = (start + duration).clamp(start + 0.05, 1.0);
            return _StaggeredFadeInUp(
              animation: revealAnimation,
              start: start,
              end: end,
              offsetY: 6,
              child: _BadgeCard(
                badge: badges[index],
                locked: locked,
                progress: progress,
                progressAnimation: progressAnimation,
              ),
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
    required this.progressAnimation,
  });

  final _BadgeDef badge;
  final bool locked;
  final _BadgeProgressData? progress;
  final Animation<double> progressAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = progress == null ? 0 : _progressForBadge(badge, progress!);
    final target = badge.target;
    final ratio = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    const barSpan = 300 / _BadgesScreenState._timelineMs;
    final barReveal = CurvedAnimation(
      parent: progressAnimation,
      curve: const Interval(0.0, barSpan, curve: Curves.easeOut),
    );

    return Container(
      decoration: _milestonesGlassDecoration(
        scheme,
        tint: locked ? const Color(0xFF8B7CFF) : const Color(0xFF5DE1FF),
        radius: 16,
        tintOpacity: locked ? 0.06 : 0.08,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Opacity(
                  opacity: locked ? 0.4 : 1,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: _milestonesGlassDecoration(
                      scheme,
                      tint: const Color(0xFF8B7CFF),
                      radius: 12,
                      tintOpacity: locked ? 0.06 : 0.12,
                    ),
                    child: Icon(
                      badge.icon,
                      color: scheme.primary.withOpacity(locked ? 0.6 : 0.9),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.tr(badge.label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: scheme.onSurface.withOpacity(locked ? 0.62 : 0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.tr(badge.description),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: scheme.onSurface.withOpacity(locked ? 0.52 : 0.64),
                height: 16 / 12,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Spacer(),
                Text(
                  locked ? '$current / $target' : '$target / $target',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: scheme.onSurface.withOpacity(0.48),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: AnimatedBuilder(
                animation: barReveal,
                builder: (context, _) {
                  return _SoftProgressBar(
                    value: ratio * barReveal.value,
                    height: 4,
                    radius: 999,
                    trackOpacity: 0.12,
                    fillOpacity: locked ? 0.72 : 0.92,
                  );
                },
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
      decoration: _milestonesGlassDecoration(
        scheme,
        tint: const Color(0xFF8B7CFF),
        radius: 16,
        tintOpacity: 0.06,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: scheme.primary.withOpacity(0.12),
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

class _SoftProgressBar extends StatelessWidget {
  const _SoftProgressBar({
    required this.value,
    required this.height,
    required this.radius,
    required this.trackOpacity,
    required this.fillOpacity,
  });

  final double value;
  final double height;
  final double radius;
  final double trackOpacity;
  final double fillOpacity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = value.clamp(0.0, 1.0);

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: scheme.onSurface.withOpacity(trackOpacity)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped.toDouble(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0.0, 0.28, 1.0],
                    colors: [
                      const Color(0xFF8B7CFF).withOpacity(fillOpacity * 0.56),
                      const Color(0xFF8B7CFF).withOpacity(fillOpacity),
                      const Color(0xFF5DE1FF).withOpacity(fillOpacity * 0.96),
                    ],
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

class _BadgeDef {
  const _BadgeDef({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.target,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final int target;
}

const _allBadges = <_BadgeDef>[
  _BadgeDef(
    id: 'total_10',
    label: 'Complete 10 sparks',
    description: 'Build momentum with 10 completed sparks.',
    icon: Icons.bolt_rounded,
    target: 10,
  ),
  _BadgeDef(
    id: 'total_50',
    label: 'Build 50 sparks',
    description: 'Keep showing up and reach 50 sparks.',
    icon: Icons.timeline_rounded,
    target: 50,
  ),
  _BadgeDef(
    id: 'total_100',
    label: 'Complete 100 sparks',
    description: 'Turn consistency into a 100 spark streak of effort.',
    icon: Icons.auto_graph_rounded,
    target: 100,
  ),
  _BadgeDef(
    id: 'streak_3',
    label: 'Keep rhythm for 3 days',
    description: 'Show up three days in a row.',
    icon: Icons.local_fire_department_rounded,
    target: 3,
  ),
  _BadgeDef(
    id: 'streak_7',
    label: 'Hold a 7-day flow',
    description: 'Keep your rhythm for seven days.',
    icon: Icons.whatshot_rounded,
    target: 7,
  ),
  _BadgeDef(
    id: 'cat_mind_10',
    label: 'Complete 10 Mind sparks',
    description: 'Give your mind ten focused resets.',
    icon: Icons.psychology_rounded,
    target: 10,
  ),
  _BadgeDef(
    id: 'cat_body_10',
    label: 'Complete 10 Body sparks',
    description: 'Move and recharge with ten body sparks.',
    icon: Icons.fitness_center_rounded,
    target: 10,
  ),
  _BadgeDef(
    id: 'cat_growth_10',
    label: 'Complete 10 Growth sparks',
    description: 'Create progress with ten growth sparks.',
    icon: Icons.trending_up_rounded,
    target: 10,
  ),
  _BadgeDef(
    id: 'cat_calm_10',
    label: 'Complete 10 Calm sparks',
    description: 'Protect calm moments with ten calm sparks.',
    icon: Icons.spa_rounded,
    target: 10,
  ),
  _BadgeDef(
    id: 'cat_health_10',
    label: 'Complete 10 Health sparks',
    description: 'Support your energy with ten health sparks.',
    icon: Icons.favorite_rounded,
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

BoxDecoration _milestonesGlassDecoration(
  ColorScheme scheme, {
  Color tint = const Color(0xFF34D5FF),
  double radius = 16,
  double tintOpacity = 0.1,
  double surfaceOpacity = 1.0,
}) {
  final base = Color.alphaBlend(
    Colors.white.withOpacity(0.02),
    const Color(0xFF0E1523).withOpacity(surfaceOpacity),
  );
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(tint.withOpacity(tintOpacity * 0.72), base),
        Color.alphaBlend(const Color(0xFF8B7CFF).withOpacity(0.045), base),
        Color.alphaBlend(const Color(0xFF101726).withOpacity(0.18), base),
      ],
      stops: const [0.0, 0.52, 1.0],
    ),
    border: Border.all(color: Colors.white.withOpacity(0.05)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.16),
        blurRadius: 18,
        spreadRadius: -6,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

class _MilestonesTopIconButton extends StatelessWidget {
  const _MilestonesTopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: scheme.onSurface.withOpacity(0.92), size: 18),
      ),
    );
  }
}

class _MilestonesAmbientBackground extends StatelessWidget {
  const _MilestonesAmbientBackground({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF0B0F1A),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -90,
            child: _MilestonesBlurGlow(
              size: 260,
              color: Color.fromRGBO(120, 90, 255, 0.18),
            ),
          ),
          Positioned(
            right: -110,
            bottom: -120,
            child: _MilestonesBlurGlow(
              size: 280,
              color: Color.fromRGBO(0, 220, 255, 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestonesBlurGlow extends StatelessWidget {
  const _MilestonesBlurGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}




