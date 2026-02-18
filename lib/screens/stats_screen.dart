import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/task_repository.dart';
import '../theme/task_category_style.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});
  static const bool _useScreenshotPreset = bool.fromEnvironment(
    'SCREENSHOT_STATS_PRESET',
    defaultValue: false,
  );
  static const bool _forceScreenshotPreset = bool.fromEnvironment(
    'SCREENSHOT_STATS_PRESET_FORCE',
    defaultValue: false,
  );

  Future<_StatsData> _load() async {
    final repo = TaskRepository();
    if (_useScreenshotPreset) {
      await repo.applyStatsScreenshotPreset(force: _forceScreenshotPreset);
    }
    final total = await repo.getTotalCompleted();
    final best = await repo.getBestStreak();
    final counts = await repo.getCategoryCounts();
    final dailyHistory = await repo.getDailyHistory(days: 14);
    final lastCompleted = await repo.getLastCompletedTask();
    final weekKey = repo.currentWeekKey();
    final weeklyPlan = await repo.getWeeklyPlan(weekKey: weekKey);
    final weeklyProgress = await repo.getWeeklyProgress(weekKey: weekKey);
    final weeklyTargets = weeklyPlan?.targets ?? const <String, int>{};
    final weeklyDoneByCategory = <String, int>{
      for (final entry in weeklyTargets.entries)
        if (entry.value > 0 && (weeklyProgress.done[entry.key] ?? 0) > 0)
          entry.key: weeklyProgress.done[entry.key]!,
    };
    final weeklyTarget = weeklyTargets.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final weeklyDone = weeklyDoneByCategory.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final favorite = _favoriteCategory(counts);
    return _StatsData(
      total: total,
      bestStreak: best,
      favorite: favorite,
      categoryCounts: counts,
      dailyHistory: dailyHistory,
      lastCompleted: lastCompleted,
      weeklyDone: weeklyDone,
      weeklyTarget: weeklyTarget,
      weeklyTargets: weeklyTargets,
      weeklyDoneByCategory: weeklyDoneByCategory,
    );
  }

  String _favoriteCategory(Map<String, int> counts) {
    if (counts.isEmpty) return '--';
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String _label(String key) {
    return TaskCategoryStyle.label(key);
  }

  Color _categoryColor(BuildContext context, String key) {
    return TaskCategoryStyle.color(
      key,
      fallback: Theme.of(context).colorScheme.primary,
    );
  }

  IconData _categoryIcon(String key) {
    return TaskCategoryStyle.icon(key);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: scheme.background,
      body: FutureBuilder<_StatsData>(
        future: _load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final favoriteLabel = _label(data.favorite);
          final favoriteColor = _categoryColor(context, data.favorite);
          final favoriteIcon = _categoryIcon(data.favorite);

          return _StatsBody(
            scheme: scheme,
            theme: theme,
            data: data,
            favoriteLabel: favoriteLabel,
            favoriteColor: favoriteColor,
            favoriteIcon: favoriteIcon,
            labelResolver: _label,
            iconResolver: _categoryIcon,
            colorResolver: (key) => _categoryColor(context, key),
          );
        },
      ),
    );
  }
}

class _StatsBody extends StatefulWidget {
  const _StatsBody({
    required this.scheme,
    required this.theme,
    required this.data,
    required this.favoriteLabel,
    required this.favoriteColor,
    required this.favoriteIcon,
    required this.labelResolver,
    required this.iconResolver,
    required this.colorResolver,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final _StatsData data;
  final String favoriteLabel;
  final Color favoriteColor;
  final IconData favoriteIcon;
  final String Function(String) labelResolver;
  final IconData Function(String) iconResolver;
  final Color Function(String) colorResolver;

  @override
  State<_StatsBody> createState() => _StatsBodyState();
}

class _StatsBodyState extends State<_StatsBody> {
  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final theme = widget.theme;
    final data = widget.data;
    final series = _buildDailySeries(data.dailyHistory, days: 7);
    final maxDaily = series.isEmpty
        ? 0
        : series.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final topCategories = _topCategories(data.categoryCounts, limit: 4);
    final badges = _buildBadges(
      data.total,
      data.bestStreak,
      data.categoryCounts,
    );

    return CustomScrollView(
      slivers: [
        // Modern App Bar
        SliverAppBar(
          toolbarHeight: 64,
          pinned: true,
          elevation: 0,
          backgroundColor: scheme.background,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            'Your Stats',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Main stats grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Completed',
                      value: data.total.toString(),
                      icon: Icons.task_alt_rounded,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Best streak',
                      value: data.bestStreak.toString(),
                      subtitle: 'days',
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFF97316),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Favorite category
              _StatCard(
                title: 'Favorite category',
                value: widget.favoriteLabel,
                icon: widget.favoriteIcon,
                color: widget.favoriteColor,
                isWide: true,
              ),

              if (data.weeklyTarget > 0) ...[
                const SizedBox(height: 12),
                _StatCard(
                  title: 'Weekly plan',
                  value: '${data.weeklyDone}/${data.weeklyTarget}',
                  subtitle: 'done',
                  icon: Icons.calendar_view_week_rounded,
                  color: scheme.primary,
                  isWide: true,
                  onTap: _openWeeklyPlanDialog,
                ),
              ],

              const SizedBox(height: 24),

              // Weekly Activity
              _SectionHeader(
                title: 'Weekly Activity',
                icon: Icons.bar_chart_rounded,
              ),
              const SizedBox(height: 12),
              _BarChart(series: series, maxValue: maxDaily),

              const SizedBox(height: 24),

              // Consistency
              _SectionHeader(
                title: 'Consistency',
                icon: Icons.calendar_today_rounded,
              ),
              const SizedBox(height: 12),
              _HeatRow(series: series, maxValue: maxDaily),

              const SizedBox(height: 24),

              // Category Focus
              _SectionHeader(
                title: 'Category Focus',
                icon: Icons.analytics_rounded,
              ),
              const SizedBox(height: 12),
              if (topCategories.isEmpty)
                _EmptyCard(
                  message: 'Complete tasks to see your focus areas.',
                  icon: Icons.auto_awesome_rounded,
                )
              else
                ...topCategories.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CategoryBar(
                      label: widget.labelResolver(entry.key),
                      value: entry.value,
                      color: widget.colorResolver(entry.key),
                      icon: widget.iconResolver(entry.key),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Recent Win
              _SectionHeader(
                title: 'Recent Win',
                icon: Icons.emoji_events_rounded,
              ),
              const SizedBox(height: 12),
              _RecentWinCard(
                item: data.lastCompleted,
                color: widget.favoriteColor,
                labelResolver: widget.labelResolver,
                iconResolver: widget.iconResolver,
              ),

              const SizedBox(height: 24),

              // Badges
              _SectionHeader(
                title: 'Badges',
                icon: Icons.workspace_premium_rounded,
              ),
              const SizedBox(height: 12),
              if (badges.isEmpty)
                _EmptyCard(
                  message: 'Keep going to earn your first badge!',
                  icon: Icons.emoji_events_rounded,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: badges.map((badge) {
                    return _BadgeChip(
                      label: badge.label,
                      icon: badge.icon,
                      color: badge.color,
                    );
                  }).toList(),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _openWeeklyPlanDialog() async {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final targets =
        widget.data.weeklyTargets.entries
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    if (targets.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_view_week_rounded,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Weekly progress',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${widget.data.weeklyDone}/${widget.data.weeklyTarget}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final entry in targets)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _WeeklyProgressRow(
                                label: widget.labelResolver(entry.key),
                                color: widget.colorResolver(entry.key),
                                done:
                                    widget.data.weeklyDoneByCategory[entry
                                        .key] ??
                                    0,
                                target: entry.value,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
    required this.icon,
    this.isWide = false,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final IconData icon;
  final bool isWide;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.68), color.withOpacity(0.9)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        TweenAnimationBuilder<int>(
                          tween: IntTween(
                            begin: 0,
                            end: int.tryParse(value) ?? 0,
                          ),
                          duration: const Duration(milliseconds: 600),
                          builder: (context, val, child) {
                            final displayValue = int.tryParse(value) != null
                                ? val.toString()
                                : value;
                            return Text(
                              displayValue,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            );
                          },
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyProgressRow extends StatelessWidget {
  const _WeeklyProgressRow({
    required this.label,
    required this.color,
    required this.done,
    required this.target,
  });

  final String label;
  final Color color;
  final int done;
  final int target;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safeDone = done.clamp(0, target);
    final progress = target <= 0 ? 0.0 : safeDone / target;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '$safeDone / $target',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatefulWidget {
  const _BarChart({required this.series, required this.maxValue});

  final List<_DayStat> series;
  final int maxValue;

  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final series = widget.series;
    if (series.isEmpty) {
      return _EmptyCard(
        message: 'No activity this week yet. Start today!',
        icon: Icons.bar_chart_rounded,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(series.length, (i) {
          final day = series[i];
          final selected = _selectedIndex == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _selectedIndex = selected ? null : i;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: selected
                          ? Text(
                              '${day.count}',
                              key: ValueKey('val_$i'),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                            )
                          : const SizedBox(height: 0),
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: widget.maxValue == 0
                            ? 0
                            : day.count / widget.maxValue,
                      ),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        final height = 80 * value;
                        return Container(
                          height: height.clamp(8, 80),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                scheme.primary.withOpacity(0.45),
                                scheme.primary.withOpacity(0.82),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      day.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _HeatRow extends StatelessWidget {
  const _HeatRow({required this.series, required this.maxValue});

  final List<_DayStat> series;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (series.isEmpty) {
      return _EmptyCard(
        message: 'Build a streak to see your consistency.',
        icon: Icons.bolt_rounded,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: series.map((day) {
          final intensity = maxValue == 0
              ? 0.1
              : 0.2 + 0.8 * (day.count / maxValue);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: [
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(intensity),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    day.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: 0.7 * value,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentWinCard extends StatelessWidget {
  const _RecentWinCard({
    required this.item,
    required this.color,
    required this.labelResolver,
    required this.iconResolver,
  });

  final LastCompletedTask? item;
  final Color color;
  final String Function(String) labelResolver;
  final IconData Function(String) iconResolver;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (item == null) {
      return _EmptyCard(
        message: 'Your latest achievement will appear here.',
        icon: Icons.emoji_events_rounded,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.68), color.withOpacity(0.88)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              iconResolver(item!.category),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item!.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${labelResolver(item!.category)} • ${DateFormat('MMM d').format(item!.completedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: color, size: 24),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.10), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: scheme.primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Data classes and helper functions remain the same
class _StatsData {
  final int total;
  final int bestStreak;
  final String favorite;
  final Map<String, int> categoryCounts;
  final Map<String, int> dailyHistory;
  final LastCompletedTask? lastCompleted;
  final int weeklyDone;
  final int weeklyTarget;
  final Map<String, int> weeklyTargets;
  final Map<String, int> weeklyDoneByCategory;

  const _StatsData({
    required this.total,
    required this.bestStreak,
    required this.favorite,
    required this.categoryCounts,
    required this.dailyHistory,
    required this.lastCompleted,
    required this.weeklyDone,
    required this.weeklyTarget,
    required this.weeklyTargets,
    required this.weeklyDoneByCategory,
  });
}

class _DayStat {
  final DateTime date;
  final String label;
  final int count;

  const _DayStat({
    required this.date,
    required this.label,
    required this.count,
  });
}

class _Badge {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({required this.label, required this.icon, required this.color});
}

List<_DayStat> _buildDailySeries(Map<String, int> history, {int days = 7}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final labels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final list = <_DayStat>[];
  for (var i = days - 1; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    final key = DateFormat('yyyy-MM-dd').format(date);
    final weekdayIndex = (date.weekday - 1).clamp(0, 6);
    list.add(
      _DayStat(
        date: date,
        label: labels[weekdayIndex],
        count: history[key] ?? 0,
      ),
    );
  }
  return list;
}

List<MapEntry<String, int>> _topCategories(
  Map<String, int> counts, {
  int limit = 4,
}) {
  if (counts.isEmpty) return [];
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(limit).toList();
}

List<_Badge> _buildBadges(
  int total,
  int bestStreak,
  Map<String, int> categoryCounts,
) {
  final badges = <_Badge>[];
  if (total >= 10) {
    badges.add(
      const _Badge(
        label: '10 tasks',
        icon: Icons.bolt_rounded,
        color: Color(0xFF60A5FA),
      ),
    );
  }
  if (total >= 50) {
    badges.add(
      const _Badge(
        label: '50 tasks',
        icon: Icons.emoji_events_rounded,
        color: Color(0xFFFBBF24),
      ),
    );
  }
  if (total >= 100) {
    badges.add(
      const _Badge(
        label: '100 tasks',
        icon: Icons.workspace_premium_rounded,
        color: Color(0xFFFB7185),
      ),
    );
  }
  if (bestStreak >= 3) {
    badges.add(
      const _Badge(
        label: '3-day streak',
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFF97316),
      ),
    );
  }
  if (bestStreak >= 7) {
    badges.add(
      const _Badge(
        label: '7-day streak',
        icon: Icons.whatshot_rounded,
        color: Color(0xFFEF4444),
      ),
    );
  }
  if ((categoryCounts['mind'] ?? 0) >= 10) {
    badges.add(
      const _Badge(
        label: 'Mind x10',
        icon: Icons.psychology_rounded,
        color: Color(0xFF8B5CF6),
      ),
    );
  }
  if ((categoryCounts['body'] ?? 0) >= 10) {
    badges.add(
      const _Badge(
        label: 'Body x10',
        icon: Icons.fitness_center_rounded,
        color: Color(0xFFF97316),
      ),
    );
  }
  if ((categoryCounts['growth'] ?? 0) >= 10) {
    badges.add(
      const _Badge(
        label: 'Growth x10',
        icon: Icons.trending_up_rounded,
        color: Color(0xFF22C55E),
      ),
    );
  }
  if ((categoryCounts['calm'] ?? 0) >= 10) {
    badges.add(
      const _Badge(
        label: 'Calm x10',
        icon: Icons.spa_rounded,
        color: Color(0xFF06B6D4),
      ),
    );
  }
  if ((categoryCounts['health'] ?? 0) >= 10) {
    badges.add(
      const _Badge(
        label: 'Health x10',
        icon: Icons.favorite_rounded,
        color: Color(0xFF3B82F6),
      ),
    );
  }
  return badges;
}
