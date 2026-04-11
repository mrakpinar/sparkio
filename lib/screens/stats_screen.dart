import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_strings.dart';
import '../models/level_unlocks.dart';
import '../services/locale_service.dart';
import '../services/task_localizer.dart';
import '../services/task_repository.dart';
import '../theme/task_category_style.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.currentLevel});
  static const bool _useScreenshotPreset = bool.fromEnvironment(
    'SCREENSHOT_STATS_PRESET',
    defaultValue: false,
  );
  static const bool _forceScreenshotPreset = bool.fromEnvironment(
    'SCREENSHOT_STATS_PRESET_FORCE',
    defaultValue: false,
  );
  final int currentLevel;

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
    final completionHourCounts = await repo.getCompletionHourCounts();
    final topTaskInsights = await repo.getTopTaskCompletionInsights(limit: 5);
    final weekKey = repo.currentWeekKey();
    final weeklyPlan = await repo.getWeeklyPlan(weekKey: weekKey);
    final weeklyProgress = await repo.getWeeklyProgress(weekKey: weekKey);
    final moodHistory = await repo.getMoodHistory();
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
      completionHourCounts: completionHourCounts,
      topTaskInsights: topTaskInsights,
      weeklyDone: weeklyDone,
      weeklyTarget: weeklyTarget,
      weeklyTargets: weeklyTargets,
      weeklyDoneByCategory: weeklyDoneByCategory,
      moodHistory: moodHistory,
    );
  }

  String _favoriteCategory(Map<String, int> counts) {
    if (counts.isEmpty) return '--';
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String _label(String key) {
    return AppLocalizations.lookup(
      LocaleService.instance.effectiveLanguageCode,
      TaskCategoryStyle.label(key),
    );
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F1A) : scheme.background,
      body: Stack(
        children: [
          Positioned.fill(child: _StatsAmbientBackground(scheme: scheme)),
          FutureBuilder<_StatsData>(
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
                currentLevel: currentLevel,
              );
            },
          ),
        ],
      ),
    );
  }
}

BoxDecoration _neoGlassDecoration(
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
    required this.currentLevel,
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
  final int currentLevel;

  @override
  State<_StatsBody> createState() => _StatsBodyState();
}

class _StatsBodyState extends State<_StatsBody> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                      width: 1,
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
            l10n.tr('Your Stats'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              letterSpacing: 0.2,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _StatsTopIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Main stats grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: l10n.tr('Sparks lit'),
                      value: data.total.toString(),
                      icon: Icons.task_alt_rounded,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: l10n.tr('Your rhythm'),
                      value: data.bestStreak.toString(),
                      subtitle: l10n.tr('day streak'),
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFF97316),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Favorite category
              _StatCard(
                title: l10n.tr('Favorite category'),
                value: widget.favoriteLabel,
                icon: widget.favoriteIcon,
                color: widget.favoriteColor,
                isWide: true,
              ),

              if (data.weeklyTarget > 0) ...[
                const SizedBox(height: 12),
                _StatCard(
                  title: l10n.tr('This week'),
                  value: '${data.weeklyDone}/${data.weeklyTarget}',
                  subtitle: l10n.tr('sparks'),
                  icon: Icons.calendar_view_week_rounded,
                  iconAssetPath: 'assets/in_app_icons/calendar.png',
                  color: scheme.primary,
                  isWide: true,
                  onTap: _openWeeklyPlanDialog,
                ),
              ],

              const SizedBox(height: 24),

              // Weekly Activity
              _SectionHeader(
                title: l10n.tr('Weekly Activity'),
                icon: Icons.bar_chart_rounded,
              ),
              const SizedBox(height: 12),
              _BarChart(series: series, maxValue: maxDaily),

              const SizedBox(height: 24),

              // Consistency
              _SectionHeader(
                title: l10n.tr('Consistency'),
                icon: Icons.calendar_today_rounded,
              ),
              const SizedBox(height: 12),
              _HeatRow(series: series, maxValue: maxDaily),

              const SizedBox(height: 24),

              // Mood Flow
              _SectionHeader(
                title: l10n.tr('Mood Flow'),
                icon: Icons.mood_rounded,
              ),
              const SizedBox(height: 12),
              _MoodHeatRow(moodHistory: data.moodHistory),

              const SizedBox(height: 24),

              _SectionHeader(
                title: l10n.tr('Personal Insights'),
                icon: Icons.insights_rounded,
              ),
              const SizedBox(height: 12),
              if (LevelUnlocks.canUseInsightModule(
                level: widget.currentLevel,
                module: InsightUnlockModule.personalInsights,
              ))
                _PersonalInsightsCard(
                  hourCounts: data.completionHourCounts,
                  topTasks: data.topTaskInsights,
                  iconResolver: widget.iconResolver,
                  colorResolver: widget.colorResolver,
                )
              else
                _LockedInsightsCard(
                  requiredLevel: LevelUnlocks.personalInsightsLevel,
                ),

              const SizedBox(height: 24),

              // Category Focus
              _SectionHeader(
                title: l10n.tr('Category Focus'),
                icon: Icons.analytics_rounded,
              ),
              const SizedBox(height: 12),
              if (topCategories.isEmpty)
                _EmptyCard(
                  message: l10n.tr('Your patterns will appear here.'),
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
                title: l10n.tr('Recent Win'),
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
                title: l10n.tr('Badges'),
                icon: Icons.workspace_premium_rounded,
              ),
              const SizedBox(height: 12),
              _MilestoneLane(
                badges: badges,
                emptyMessage: l10n.tr(
                  'Your first milestone is closer than you think.',
                ),
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
    final l10n = context.l10n;
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
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: _neoGlassDecoration(
                    scheme,
                    tint: const Color(0xFF8B7CFF),
                    radius: 24,
                    tintOpacity: 0.08,
                    surfaceOpacity: 1.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/in_app_icons/calendar.png',
                            width: 22,
                            height: 22,
                            color: scheme.primary.withOpacity(0.84),
                            colorBlendMode: BlendMode.srcIn,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1.5,
                            height: 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF8B7CFF).withOpacity(0.95),
                                  const Color(0xFF5DE1FF).withOpacity(0.78),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.tr('Weekly progress'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface.withOpacity(0.9),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: scheme.onSurfaceVariant.withOpacity(0.72),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.tr('This week')}: ${widget.data.weeklyDone}/${widget.data.weeklyTarget}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant.withOpacity(0.76),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
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
        Icon(icon, size: 16, color: scheme.primary.withOpacity(0.88)),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w400,
            color: scheme.onSurface.withOpacity(0.68),
          ),
        ),
      ],
    );
  }
}

class _StatsTopIconButton extends StatelessWidget {
  const _StatsTopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: scheme.primary.withOpacity(0.08),
        highlightColor: scheme.primary.withOpacity(0.03),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 18,
            color: scheme.onSurface.withOpacity(0.86),
          ),
        ),
      ),
    );
  }
}

class _StatsAmbientBackground extends StatelessWidget {
  const _StatsAmbientBackground({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF0B0F1A)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -150,
              bottom: -150,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color.fromRGBO(0, 220, 255, 0.04),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.5],
                    ),
                  ),
                ),
              ),
            ),
            CustomPaint(
              painter: _NoisePainter(
                opacity: 0.018,
                lightColor: Colors.white,
                darkColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  const _NoisePainter({
    required this.opacity,
    required this.lightColor,
    required this.darkColor,
  });

  final double opacity;
  final Color lightColor;
  final Color darkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(24);
    final dotCount = (size.width * size.height / 760).round().clamp(260, 900);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < dotCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.22 + (random.nextDouble() * 0.85);
      final alpha = opacity * (0.42 + (random.nextDouble() * 0.58));
      final color = random.nextBool()
          ? lightColor.withOpacity(alpha * 0.58)
          : darkColor.withOpacity(alpha * 0.5);
      paint.color = color;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) {
    return oldDelegate.opacity != opacity ||
        oldDelegate.lightColor != lightColor ||
        oldDelegate.darkColor != darkColor;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
    required this.icon,
    this.iconAssetPath,
    this.isWide = false,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final IconData icon;
  final String? iconAssetPath;
  final bool isWide;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isRhythmCard = subtitle == 'day streak';
    final rhythmValue = int.tryParse(value) ?? 0;
    final streakBoost = isRhythmCard
        ? (rhythmValue.clamp(0, 14) / 14).toDouble()
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: _neoGlassDecoration(
            scheme,
            tint: color,
            radius: 16,
            surfaceOpacity: 1.0,
            tintOpacity: isRhythmCard
                ? (0.16 + (streakBoost * 0.22)).clamp(0.16, 0.38)
                : 0.07,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.9, -1.0),
                          radius: 1.28,
                          colors: [
                            color.withOpacity(
                              isRhythmCard
                                  ? (0.22 + (streakBoost * 0.24)).clamp(
                                      0.22,
                                      0.46,
                                    )
                                  : 0.1,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(
                                isRhythmCard
                                    ? (0.48 + (streakBoost * 0.2)).clamp(
                                        0.48,
                                        0.68,
                                      )
                                    : 0.22,
                              ),
                              color.withOpacity(
                                isRhythmCard
                                    ? (0.82 + (streakBoost * 0.16)).clamp(
                                        0.82,
                                        0.98,
                                      )
                                    : 0.42,
                              ),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isRhythmCard
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(
                                      (0.48 + (streakBoost * 0.24)).clamp(
                                        0.48,
                                        0.72,
                                      ),
                                    ),
                                    blurRadius: 20 + (streakBoost * 8),
                                    spreadRadius: -4,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: iconAssetPath != null
                            ? Image.asset(
                                iconAssetPath!,
                                width: 24,
                                height: 24,
                                color: Colors.white,
                                colorBlendMode: BlendMode.srcIn,
                              )
                            : Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant.withOpacity(
                                  0.74,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _AnimatedMetricValue(
                                  value: value,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                        shadows: subtitle == 'day streak'
                                            ? [
                                                Shadow(
                                                  color: color.withOpacity(
                                                    (0.6 + (streakBoost * 0.25))
                                                        .clamp(0.6, 0.85),
                                                  ),
                                                  blurRadius:
                                                      13 + (streakBoost * 5),
                                                ),
                                              ]
                                            : null,
                                      ),
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
              ],
            ),
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
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF111A2B),
            Color.alphaBlend(color.withOpacity(0.08), const Color(0xFF0E1523)),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withOpacity(0.84),
                  ),
                ),
              ),
              Text(
                '$safeDone / $target',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color.withOpacity(0.92),
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
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedMetricValue extends StatelessWidget {
  const _AnimatedMetricValue({required this.value, required this.style});

  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final parsed = int.tryParse(value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        final display = parsed == null
            ? value
            : (parsed * t).round().clamp(0, parsed).toString();
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 6),
            child: Text(display, style: style),
          ),
        );
      },
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

class _BarChartState extends State<_BarChart>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late final AnimationController _shimmerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7600),
  )..repeat();

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

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
      decoration: _neoGlassDecoration(
        scheme,
        tint: const Color(0xFF34D5FF),
        radius: 20,
        tintOpacity: 0.14,
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
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, _) {
                        final shimmerT =
                            (_shimmerController.value + (i * 0.13)) % 1.0;
                        final shimmerY = -1.2 + (shimmerT * 2.4);
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: widget.maxValue == 0
                                ? 0
                                : day.count / widget.maxValue,
                          ),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            final normalized = value.clamp(0.0, 1.0);
                            final barHeight = day.count <= 0
                                ? 8.0
                                : (18 + (62 * math.sqrt(normalized)))
                                      .clamp(18, 80)
                                      .toDouble();
                            final glowOpacity =
                                (0.12 +
                                        (normalized * 0.22) +
                                        (selected ? 0.1 : 0.0))
                                    .clamp(0.0, 0.4)
                                    .toDouble();
                            return SizedBox(
                              height: 84,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white.withOpacity(0.11),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.06),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 24,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          scheme.primary.withOpacity(0.82),
                                          Color.alphaBlend(
                                            const Color(
                                              0xFF22D3EE,
                                            ).withOpacity(0.36),
                                            scheme.primary,
                                          ),
                                          const Color(0xFF9BE7FF),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: scheme.primary.withOpacity(
                                            glowOpacity,
                                          ),
                                          blurRadius: 16 + (normalized * 12),
                                          spreadRadius: -4 + (normalized * 2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Align(
                                          alignment: Alignment.topCenter,
                                          child: Container(
                                            height: 10,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.white.withOpacity(
                                                    0.42,
                                                  ),
                                                  Colors.white.withOpacity(0.0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              gradient: LinearGradient(
                                                begin: Alignment(
                                                  0,
                                                  shimmerY - 0.32,
                                                ),
                                                end: Alignment(
                                                  0,
                                                  shimmerY + 0.32,
                                                ),
                                                colors: [
                                                  Colors.white.withOpacity(0.0),
                                                  Colors.white.withOpacity(
                                                    0.14,
                                                  ),
                                                  Colors.white.withOpacity(0.0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      day.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected
                            ? scheme.onSurface.withOpacity(0.9)
                            : scheme.onSurfaceVariant.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                        letterSpacing: 0.12,
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

class _HeatRow extends StatefulWidget {
  const _HeatRow({required this.series, required this.maxValue});

  final List<_DayStat> series;
  final int maxValue;

  @override
  State<_HeatRow> createState() => _HeatRowState();
}

class _HeatRowState extends State<_HeatRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breatheController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (widget.series.isEmpty) {
      return _EmptyCard(
        message: 'Build a streak to see your consistency.',
        icon: Icons.bolt_rounded,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _neoGlassDecoration(
        scheme,
        tint: const Color(0xFF8B5CF6),
        radius: 20,
        tintOpacity: 0.12,
      ),
      child: AnimatedBuilder(
        animation: _breatheController,
        builder: (context, _) {
          final breathe = Curves.easeInOut.transform(_breatheController.value);
          return Row(
            children: List.generate(widget.series.length, (index) {
              final day = widget.series[index];
              final normalized = widget.maxValue == 0
                  ? 0.0
                  : (day.count / widget.maxValue);
              final isActive = day.count > 0;
              final phase = (breathe + (index * 0.11)) % 1.0;
              final pulse = (math.sin(phase * math.pi * 2) * 0.5) + 0.5;
              final fillOpacity = isActive
                  ? (0.24 + (0.64 * normalized) + (pulse * 0.06))
                        .clamp(0.24, 0.9)
                        .toDouble()
                  : (0.08 + (pulse * 0.02)).toDouble();
              final glowOpacity = isActive
                  ? (0.14 + (0.2 * normalized) + (pulse * 0.08))
                        .clamp(0.14, 0.36)
                        .toDouble()
                  : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: scheme.outline.withOpacity(0.16),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6.5),
                                  color: scheme.onSurfaceVariant.withOpacity(
                                    0.06,
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6.5),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      scheme.primary.withOpacity(
                                        (fillOpacity + 0.08).clamp(0.0, 1.0),
                                      ),
                                      scheme.primary.withOpacity(fillOpacity),
                                    ],
                                  ),
                                  boxShadow: [
                                    if (isActive)
                                      BoxShadow(
                                        color: scheme.primary.withOpacity(
                                          glowOpacity,
                                        ),
                                        blurRadius: 10 + (normalized * 6),
                                        spreadRadius: -3 + (normalized * 1.6),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        day.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isActive
                              ? scheme.onSurface.withOpacity(0.82)
                              : scheme.onSurfaceVariant.withOpacity(0.66),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _MoodHeatRow extends StatelessWidget {
  const _MoodHeatRow({required this.moodHistory});
  
  final Map<String, int> moodHistory;

  String _moodEmoji(int? mood) {
    switch (mood) {
      case 1: return '😖';
      case 2: return '😕';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '🤩';
      default: return '';
    }
  }

  Color _moodColor(int? mood) {
    switch (mood) {
      case 1: return const Color(0xFFF43F5E); // Red
      case 2: return const Color(0xFFF59E0B); // Amber
      case 3: return const Color(0xFF10B981); // Green
      case 4: return const Color(0xFF3B82F6); // Blue
      case 5: return const Color(0xFF8B5CF6); // Purple
      default: return Colors.white12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    // Generate the last 7 days keys
    final keys = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateFormat('yyyy-MM-dd').format(d);
    });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _neoGlassDecoration(
        scheme,
        tint: const Color(0xFF10B981),
        radius: 20,
        tintOpacity: 0.08,
      ),
      child: Row(
        children: keys.map((dateKey) {
          final val = moodHistory[dateKey];
          final emoji = _moodEmoji(val);
          final col = _moodColor(val);
          final label = dateKey.substring(8, 10); // get DD
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: [
                  Container(
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: val == null ? scheme.onSurfaceVariant.withOpacity(0.06) : col.withOpacity(0.2),
                      border: Border.all(
                        color: val == null ? scheme.outline.withOpacity(0.16) : col.withOpacity(0.4),
                      ),
                      boxShadow: val != null ? [
                        BoxShadow(
                          color: col.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: -2,
                        ),
                      ] : [],
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(0.66),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
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
      decoration: _neoGlassDecoration(
        scheme,
        tint: color,
        radius: 16,
        tintOpacity: 0.14,
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

  String _localizedCompletedDate(DateTime value) {
    final code = LocaleService.instance.effectiveLanguageCode;
    switch (code) {
      case 'tr':
        return DateFormat('d MMM', 'tr').format(value);
      case 'es':
        return DateFormat('d MMM', 'es').format(value);
      case 'de':
        return DateFormat('d. MMM', 'de').format(value);
      default:
        return DateFormat('MMM d', 'en').format(value);
    }
  }

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
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              color.withOpacity(0.18),
              Color.alphaBlend(
                Colors.black.withOpacity(0.22),
                scheme.surface.withOpacity(0.94),
              ),
            ),
            Color.alphaBlend(
              const Color(0xFF8B5CF6).withOpacity(0.12),
              Color.alphaBlend(
                Colors.black.withOpacity(0.22),
                scheme.surface.withOpacity(0.94),
              ),
            ),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color.withOpacity(0.92)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              iconResolver(item!.category),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TaskLocalizer.localizeTitle(
                    item!.title,
                    localeCode: LocaleService.instance.effectiveLanguageCode,
                    category: item!.category,
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${labelResolver(item!.category)} - ${_localizedCompletedDate(item!.completedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.tr('You showed up yesterday.'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withOpacity(0.86),
                    fontWeight: FontWeight.w600,
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

class _LockedInsightsCard extends StatelessWidget {
  const _LockedInsightsCard({required this.requiredLevel});

  final int requiredLevel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _neoGlassDecoration(
        scheme,
        tint: const Color(0xFF8B5CF6),
        radius: 20,
        tintOpacity: 0.1,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: scheme.surfaceContainerHighest.withOpacity(0.54),
            ),
            child: Icon(
              Icons.lock_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.tr('Personal Insights locked'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.trf(
                    'Reach Level {level} to unlock this module.',
                    {'level': requiredLevel},
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalInsightsCard extends StatelessWidget {
  const _PersonalInsightsCard({
    required this.hourCounts,
    required this.topTasks,
    required this.iconResolver,
    required this.colorResolver,
  });

  final Map<int, int> hourCounts;
  final List<TaskCompletionInsight> topTasks;
  final IconData Function(String) iconResolver;
  final Color Function(String) colorResolver;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    if (hourCounts.isEmpty && topTasks.isEmpty) {
      return _EmptyCard(
        message: context.l10n.tr(
          'Complete more sparks to unlock personal insights.',
        ),
        icon: Icons.insights_rounded,
      );
    }

    final peakHour = _peakHour(hourCounts);
    final windows = _buildHourWindows(hourCounts);
    final maxWindowCount = windows.isEmpty
        ? 0
        : windows.map((item) => item.count).reduce((a, b) => a > b ? a : b);
    final safeTopTasks = topTasks.take(3).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _neoGlassDecoration(
        scheme,
        tint: const Color(0xFF34D5FF),
        radius: 20,
        tintOpacity: 0.1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.tr('Best completion time'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          if (peakHour == null)
            Text(
              context.l10n.tr(
                'We need a few more completions to detect your peak hour.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  '${_hourLabel(peakHour)} • ${_timeWindowLabel(peakHour)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          if (windows.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: windows.map((window) {
                final ratio = maxWindowCount <= 0
                    ? 0.0
                    : (window.count / maxWindowCount).clamp(0.0, 1.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: scheme.surfaceContainerHighest.withOpacity(0.42),
                        border: Border.all(
                          color: scheme.outline.withOpacity(0.18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            window.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: ratio,
                              backgroundColor: scheme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                scheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: scheme.outline.withOpacity(0.2), height: 1),
          const SizedBox(height: 12),
          Text(
            context.l10n.tr('Tasks that work best'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (safeTopTasks.isEmpty)
            Text(
              context.l10n.tr(
                'We will suggest your best tasks once you complete more sparks.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            ...safeTopTasks.map((item) {
              final color = colorResolver(item.category);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color.alphaBlend(
                      color.withOpacity(0.08),
                      scheme.surface,
                    ),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(iconResolver(item.category), size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          TaskLocalizer.localizeTitle(
                            item.title,
                            localeCode:
                                LocaleService.instance.effectiveLanguageCode,
                            category: item.category,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.count}x',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (safeTopTasks.isNotEmpty)
            Text(
              context.l10n.tr('Based on completed sparks only.'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withOpacity(0.86),
                fontWeight: FontWeight.w600,
              ),
            ),
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

class _MilestoneLane extends StatelessWidget {
  const _MilestoneLane({required this.badges, required this.emptyMessage});

  final List<_Badge> badges;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEmpty = badges.isEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _neoGlassDecoration(
        scheme,
        tint: const Color(0xFF8B5CF6),
        radius: 20,
        tintOpacity: 0.1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emptyMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (isEmpty)
            Row(
              children: [
                _ComingSoonMilestone(
                  icon: Icons.bolt_rounded,
                  label: context.l10n.tr('First spark'),
                ),
                const SizedBox(width: 8),
                _ComingSoonMilestone(
                  icon: Icons.local_fire_department_rounded,
                  label: context.l10n.tr('3-day rhythm'),
                ),
                const SizedBox(width: 8),
                _ComingSoonMilestone(
                  icon: Icons.emoji_events_rounded,
                  label: context.l10n.tr('10 sparks'),
                ),
                const SizedBox(width: 8),
                _ComingSoonMilestone(
                  icon: Icons.workspace_premium_rounded,
                  label: context.l10n.tr('Momentum'),
                ),
              ],
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: badges.map((badge) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _BadgeChip(
                      label: context.l10n.tr(badge.label),
                      icon: badge.icon,
                      color: badge.color,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ComingSoonMilestone extends StatelessWidget {
  const _ComingSoonMilestone({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: scheme.surfaceVariant.withOpacity(0.28),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: scheme.onSurfaceVariant.withOpacity(0.7),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
      decoration: _neoGlassDecoration(
        scheme,
        tint: const Color(0xFF34D5FF),
        radius: 20,
        tintOpacity: 0.12,
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
  final Map<int, int> completionHourCounts;
  final List<TaskCompletionInsight> topTaskInsights;
  final int weeklyDone;
  final int weeklyTarget;
  final Map<String, int> weeklyTargets;
  final Map<String, int> weeklyDoneByCategory;
  final Map<String, int> moodHistory;

  const _StatsData({
    required this.total,
    required this.bestStreak,
    required this.favorite,
    required this.categoryCounts,
    required this.dailyHistory,
    required this.lastCompleted,
    required this.completionHourCounts,
    required this.topTaskInsights,
    required this.weeklyDone,
    required this.weeklyTarget,
    required this.weeklyTargets,
    required this.weeklyDoneByCategory,
    required this.moodHistory,
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

class _HourWindowStat {
  const _HourWindowStat({required this.label, required this.count});

  final String label;
  final int count;
}

class _Badge {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({required this.label, required this.icon, required this.color});
}

int? _peakHour(Map<int, int> hourCounts) {
  if (hourCounts.isEmpty) return null;
  final sorted = hourCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.first.key;
}

String _hourLabel(int hour) {
  final safeHour = hour.clamp(0, 23);
  return '${safeHour.toString().padLeft(2, '0')}:00';
}

String _timeWindowLabel(int hour) {
  final safeHour = hour.clamp(0, 23);
  final code = LocaleService.instance.effectiveLanguageCode;
  if (safeHour >= 5 && safeHour <= 11) {
    return AppLocalizations.lookup(code, 'Morning');
  }
  if (safeHour >= 12 && safeHour <= 16) {
    return AppLocalizations.lookup(code, 'Afternoon');
  }
  if (safeHour >= 17 && safeHour <= 21) {
    return AppLocalizations.lookup(code, 'Evening');
  }
  return AppLocalizations.lookup(code, 'Night');
}

List<_HourWindowStat> _buildHourWindows(Map<int, int> hourCounts) {
  int countRange(int start, int end) {
    var total = 0;
    for (var h = start; h <= end; h++) {
      total += hourCounts[h] ?? 0;
    }
    return total;
  }

  final night = countRange(0, 4) + countRange(22, 23);
  final code = LocaleService.instance.effectiveLanguageCode;
  return <_HourWindowStat>[
    _HourWindowStat(
      label: AppLocalizations.lookup(code, 'Morning'),
      count: countRange(5, 11),
    ),
    _HourWindowStat(
      label: AppLocalizations.lookup(code, 'Afternoon'),
      count: countRange(12, 16),
    ),
    _HourWindowStat(
      label: AppLocalizations.lookup(code, 'Evening'),
      count: countRange(17, 21),
    ),
    _HourWindowStat(
      label: AppLocalizations.lookup(code, 'Night'),
      count: night,
    ),
  ];
}

List<_DayStat> _buildDailySeries(Map<String, int> history, {int days = 7}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final code = LocaleService.instance.effectiveLanguageCode;
  final labels = [
    AppLocalizations.lookup(code, 'Mon'),
    AppLocalizations.lookup(code, 'Tue'),
    AppLocalizations.lookup(code, 'Wed'),
    AppLocalizations.lookup(code, 'Thu'),
    AppLocalizations.lookup(code, 'Fri'),
    AppLocalizations.lookup(code, 'Sat'),
    AppLocalizations.lookup(code, 'Sun'),
  ];
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
