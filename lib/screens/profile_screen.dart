import 'package:flutter/material.dart';

import '../services/task_repository.dart';
import 'badges_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profileName,
    required this.currentStreak,
    required this.currentLevel,
    required this.totalXp,
    required this.xpInLevel,
    required this.xpToNextLevel,
  });

  final String profileName;
  final int currentStreak;
  final int currentLevel;
  final int totalXp;
  final int xpInLevel;
  final int xpToNextLevel;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final TaskRepository _repo = TaskRepository();
  late Future<Set<String>> _earnedFuture;
  late Future<_JourneySnapshot> _journeySnapshotFuture;
  late final AnimationController _xpController;
  late final Animation<double> _xpAnimation;
  late String _profileName;
  late final TextEditingController _nameController;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _profileName = TaskRepository.sanitizeProfileName(widget.profileName);
    _nameController = TextEditingController(text: _profileName);
    _earnedFuture = _repo.getEarnedBadges();
    _journeySnapshotFuture = _loadJourneySnapshot();
    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _xpAnimation = CurvedAnimation(
      parent: _xpController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _xpController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _xpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<_JourneySnapshot> _loadJourneySnapshot() async {
    final earned = await _repo.getEarnedBadges();
    final totalCompleted = await _repo.getTotalCompleted();
    return _JourneySnapshot(
      earnedBadges: earned.length,
      sparksLit: totalCompleted,
    );
  }

  String _levelTitle(int level) {
    if (level >= 20) return 'Flow Master';
    if (level >= 14) return 'Momentum Maker';
    if (level >= 9) return 'Consistency Builder';
    if (level >= 5) return 'Habit Starter';
    return 'First Spark';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cleanedName = TaskRepository.sanitizeProfileName(_profileName);
    final name = cleanedName.isEmpty ? 'Friend' : cleanedName;
    final initials = name.characters.first.toUpperCase();
    final safeLevel = widget.currentLevel <= 0 ? 1 : widget.currentLevel;
    final safeXpToNext = widget.xpToNextLevel <= 0 ? 1 : widget.xpToNextLevel;
    final clampedXpInLevel = widget.xpInLevel.clamp(0, safeXpToNext);
    final levelProgress = (clampedXpInLevel / safeXpToNext).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
                      scheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -130,
            left: -70,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scheme.secondary.withValues(alpha: isDark ? 0.14 : 0.08),
                      scheme.secondary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Profile',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.alphaBlend(
                                scheme.primary.withValues(
                                  alpha: isDark ? 0.1 : 0.06,
                                ),
                                scheme.surface.withValues(
                                  alpha: isDark ? 0.78 : 0.88,
                                ),
                              ),
                              Color.alphaBlend(
                                scheme.secondary.withValues(
                                  alpha: isDark ? 0.08 : 0.05,
                                ),
                                scheme.surface.withValues(
                                  alpha: isDark ? 0.74 : 0.84,
                                ),
                              ),
                            ],
                          ),
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(
                                alpha: isDark ? 0.2 : 0.12,
                              ),
                              blurRadius: 26,
                              spreadRadius: -12,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        scheme.primary.withValues(
                                          alpha: isDark ? 0.86 : 0.92,
                                        ),
                                        scheme.secondary.withValues(
                                          alpha: isDark ? 0.8 : 0.86,
                                        ),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary.withValues(
                                          alpha: isDark ? 0.34 : 0.2,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: -8,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initials,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: scheme.onPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (_isEditingName)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _nameController,
                                                autofocus: true,
                                                maxLength: 24,
                                                textCapitalization:
                                                    TextCapitalization.words,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  counterText: '',
                                                  hintText:
                                                      'Enter your first name',
                                                  hintStyle: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: scheme
                                                            .onSurfaceVariant,
                                                      ),
                                                  border: InputBorder.none,
                                                ),
                                                style: theme
                                                    .textTheme
                                                    .headlineSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                onSubmitted: (_) =>
                                                    _saveInlineName(),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: _saveInlineName,
                                              icon: Icon(
                                                Icons.check_rounded,
                                                color: scheme.primary,
                                                size: 20,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              tooltip: 'Save',
                                            ),
                                            IconButton(
                                              onPressed: _cancelInlineEdit,
                                              icon: Icon(
                                                Icons.close_rounded,
                                                color: scheme.onSurfaceVariant,
                                                size: 20,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              tooltip: 'Cancel',
                                            ),
                                          ],
                                        )
                                      else
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      name,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: theme
                                                          .textTheme
                                                          .headlineMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Icon(
                                                    Icons.bolt_rounded,
                                                    size: 20,
                                                    color: scheme.primary,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            InkWell(
                                              onTap: _startInlineEdit,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 2,
                                                      vertical: 1,
                                                    ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.edit_rounded,
                                                      size: 14,
                                                      color: scheme.primary
                                                          .withValues(
                                                            alpha: 0.9,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Edit',
                                                      style: theme
                                                          .textTheme
                                                          .labelMedium
                                                          ?.copyWith(
                                                            color:
                                                                scheme.primary,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Level $safeLevel - ${_levelTitle(safeLevel)}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "You're just getting started.",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.92,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Keep the rhythm going.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.84,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AnimatedBuilder(
                              animation: _xpAnimation,
                              builder: (context, child) {
                                final animatedProgress =
                                    (levelProgress * _xpAnimation.value).clamp(
                                      0.0,
                                      1.0,
                                    );
                                return Container(
                                  height: 12,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: scheme.surfaceContainerHighest
                                        .withValues(alpha: 0.74),
                                    border: Border.all(
                                      color: scheme.primary.withValues(
                                        alpha: isDark ? 0.24 : 0.2,
                                      ),
                                      width: 0.6,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary.withValues(
                                          alpha: isDark ? 0.24 : 0.16,
                                        ),
                                        blurRadius: 18,
                                        spreadRadius: -8,
                                        offset: const Offset(0, 7),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: animatedProgress,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                scheme.primary,
                                                Color.alphaBlend(
                                                  Colors.white.withValues(
                                                    alpha: isDark ? 0.16 : 0.24,
                                                  ),
                                                  scheme.primary,
                                                ),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: scheme.primary
                                                    .withValues(
                                                      alpha: isDark
                                                          ? 0.55
                                                          : 0.36,
                                                    ),
                                                blurRadius: 8,
                                                spreadRadius: -3,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$clampedXpInLevel / $safeXpToNext XP to Level ${safeLevel + 1}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.totalXp == 0
                                  ? 'Let\'s light your first spark'
                                  : '${widget.totalXp} total XP',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<_JourneySnapshot>(
                        future: _journeySnapshotFuture,
                        builder: (context, snapshot) {
                          final data =
                              snapshot.data ??
                              const _JourneySnapshot(
                                earnedBadges: 0,
                                sparksLit: 0,
                              );
                          final streakLabel = widget.currentStreak == 0
                              ? 'Day 1 is waiting'
                              : '${widget.currentStreak} ${widget.currentStreak == 1 ? 'Day' : 'Days'} Streak';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: scheme.surface.withValues(alpha: 0.74),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _JourneyStatItem(
                                    icon: Icons.local_fire_department_rounded,
                                    color: const Color(0xFFF97316),
                                    label: streakLabel,
                                  ),
                                ),
                                _JourneyStatDivider(
                                  color: scheme.outline.withValues(alpha: 0.22),
                                ),
                                Expanded(
                                  child: _JourneyStatItem(
                                    icon: Icons.emoji_events_rounded,
                                    color: const Color(0xFFF59E0B),
                                    label: '${data.earnedBadges} Badges',
                                  ),
                                ),
                                _JourneyStatDivider(
                                  color: scheme.outline.withValues(alpha: 0.22),
                                ),
                                Expanded(
                                  child: _JourneyStatItem(
                                    icon: Icons.bolt_rounded,
                                    color: scheme.primary,
                                    label: '${data.sparksLit} Sparks Lit',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      FutureBuilder<Set<String>>(
                        future: _earnedFuture,
                        builder: (context, snapshot) {
                          final earned = snapshot.data ?? <String>{};
                          final defs = _allProfileBadges
                              .where((badge) => earned.contains(badge.id))
                              .toList();

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return Container(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: scheme.surface.withValues(alpha: 0.7),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Journey',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (defs.isEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your journey just started.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: scheme.onSurface,
                                              height: 1.35,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Complete a few sparks to unlock it.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                              height: 1.35,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const BadgesScreen(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.emoji_events_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('View badges'),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 0,
                                            vertical: 4,
                                          ),
                                          foregroundColor: scheme.primary,
                                          textStyle: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          minimumSize: Size.zero,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    children: List.generate(defs.length, (
                                      index,
                                    ) {
                                      final badge = defs[index];
                                      return Column(
                                        children: [
                                          _JourneyBadgeRow(badge: badge),
                                          if (index != defs.length - 1)
                                            Divider(
                                              height: 14,
                                              color: scheme.outline.withValues(
                                                alpha: 0.16,
                                              ),
                                            ),
                                        ],
                                      );
                                    }),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startInlineEdit() {
    setState(() {
      _isEditingName = true;
      _nameController.text = TaskRepository.sanitizeProfileName(_profileName);
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nameController.text.length),
      );
    });
  }

  void _cancelInlineEdit() {
    setState(() {
      _isEditingName = false;
      _nameController.text = TaskRepository.sanitizeProfileName(_profileName);
    });
  }

  Future<void> _saveInlineName() async {
    final value = TaskRepository.sanitizeProfileName(_nameController.text);
    if (value.isEmpty) return;
    await _repo.setProfileName(value);
    if (!mounted) return;
    setState(() {
      _profileName = value;
      _nameController.text = value;
      _isEditingName = false;
    });
  }
}

class _JourneySnapshot {
  const _JourneySnapshot({required this.earnedBadges, required this.sparksLit});

  final int earnedBadges;
  final int sparksLit;
}

class _JourneyStatItem extends StatelessWidget {
  const _JourneyStatItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.92),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _JourneyStatDivider extends StatelessWidget {
  const _JourneyStatDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: color,
    );
  }
}

class _JourneyBadgeRow extends StatelessWidget {
  const _JourneyBadgeRow({required this.badge});

  final _ProfileBadge badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: badge.color.withValues(alpha: 0.16),
          ),
          alignment: Alignment.center,
          child: Icon(badge.icon, size: 18, color: badge.color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                badge.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileBadge {
  const _ProfileBadge({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
}

const _allProfileBadges = <_ProfileBadge>[
  _ProfileBadge(
    id: 'total_10',
    label: 'Complete 10 sparks',
    description: 'Build momentum with 10 completed sparks.',
    icon: Icons.bolt_rounded,
    color: Color(0xFF60A5FA),
  ),
  _ProfileBadge(
    id: 'total_50',
    label: 'Build 50 sparks',
    description: 'Keep showing up and reach 50 sparks.',
    icon: Icons.timeline_rounded,
    color: Color(0xFFFBBF24),
  ),
  _ProfileBadge(
    id: 'total_100',
    label: 'Complete 100 sparks',
    description: 'Turn consistency into a 100 spark streak of effort.',
    icon: Icons.auto_graph_rounded,
    color: Color(0xFFFB7185),
  ),
  _ProfileBadge(
    id: 'streak_3',
    label: 'Keep rhythm for 3 days',
    description: 'Show up three days in a row.',
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFF97316),
  ),
  _ProfileBadge(
    id: 'streak_7',
    label: 'Hold a 7-day flow',
    description: 'Keep your rhythm for seven days.',
    icon: Icons.whatshot_rounded,
    color: Color(0xFFEF4444),
  ),
  _ProfileBadge(
    id: 'cat_mind_10',
    label: 'Complete 10 Mind sparks',
    description: 'Give your mind ten focused resets.',
    icon: Icons.psychology_rounded,
    color: Color(0xFF8B5CF6),
  ),
  _ProfileBadge(
    id: 'cat_body_10',
    label: 'Complete 10 Body sparks',
    description: 'Move and recharge with ten body sparks.',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFF97316),
  ),
  _ProfileBadge(
    id: 'cat_growth_10',
    label: 'Complete 10 Growth sparks',
    description: 'Create progress with ten growth sparks.',
    icon: Icons.trending_up_rounded,
    color: Color(0xFF22C55E),
  ),
  _ProfileBadge(
    id: 'cat_calm_10',
    label: 'Complete 10 Calm sparks',
    description: 'Protect calm moments with ten calm sparks.',
    icon: Icons.spa_rounded,
    color: Color(0xFF06B6D4),
  ),
  _ProfileBadge(
    id: 'cat_health_10',
    label: 'Complete 10 Health sparks',
    description: 'Support your energy with ten health sparks.',
    icon: Icons.favorite_rounded,
    color: Color(0xFF3B82F6),
  ),
];
