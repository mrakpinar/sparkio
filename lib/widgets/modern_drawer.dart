import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_strings.dart';
import '../services/task_repository.dart';

const Color _kDrawerBackgroundTop = Color(0xFF0B0F1A);
const Color _kDrawerPrimarySurface = Color(0xFF131A2A);
const Color _kDrawerSecondarySurface = Color(0xFF101726);
const Color _kDrawerTertiarySurface = Color(0xFF0D1422);

enum _DrawerSurfaceLevel { primary, secondary, tertiary }

Color _drawerSurfaceColorFor(_DrawerSurfaceLevel level) {
  switch (level) {
    case _DrawerSurfaceLevel.primary:
      return _kDrawerPrimarySurface;
    case _DrawerSurfaceLevel.secondary:
      return _kDrawerSecondarySurface;
    case _DrawerSurfaceLevel.tertiary:
      return _kDrawerTertiarySurface;
  }
}

const Color _kCreateSparkIconBg = Color(0x1F5DA9FF);
const Color _kCreateSparkIconColor = Color(0xFF5DA9FF);
const Color _kRefreshIconBg = Color(0x1F60A5FA);
const Color _kRefreshIconColor = Color(0xFF60A5FA);
const Color _kBadgesIconBg = Color(0x1FC084FC);
const Color _kBadgesIconColor = Color(0xFFC084FC);
const Color _kWeeklyPlanIconBg = Color(0x1F34D399);
const Color _kWeeklyPlanIconColor = Color(0xFF34D399);
const Color _kChallengeIconBg = Color(0x1F818CF8);
const Color _kChallengeIconColor = Color(0xFF818CF8);
const Color _kPremiumIconBg = Color(0x1FC084FC);
const Color _kPremiumIconColor = Color(0xFFC084FC);
const Color _kReferralIconBg = Color(0x1FF59E0B);
const Color _kReferralIconColor = Color(0xFFF59E0B);
const Color _kTalkToUsIconBg = Color(0x1FF472B6);
const Color _kTalkToUsIconColor = Color(0xFFF472B6);
const Color _kRateUsIconBg = Color(0x1FF59E0B);
const Color _kRateUsIconColor = Color(0xFFFBBF24);
const Color _kLanguageIconBg = Color(0x1F60A5FA);
const Color _kLanguageIconColor = Color(0xFF8FD3FF);

BoxDecoration _drawerNeoGlassDecoration({
  double radius = 16,
  bool showBorder = false,
  bool pressed = false,
  bool withDepth = true,
  _DrawerSurfaceLevel level = _DrawerSurfaceLevel.secondary,
}) {
  final baseSurface = _drawerSurfaceColorFor(level);
  final surface = pressed
      ? Color.alphaBlend(
          const Color(0xFF8B7CFF).withOpacity(0.08),
          baseSurface,
        )
      : baseSurface;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: Color.alphaBlend(
      Colors.white.withOpacity(0.03),
      surface,
    ),
    boxShadow: withDepth
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ]
        : const [],
    border: Border.all(
      color: Colors.white.withOpacity(showBorder ? 0.08 : 0.05),
      width: 1,
    ),
  );
}

BoxDecoration _drawerIconPodDecoration({
  required Color backgroundColor,
  double radius = 10,
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(Colors.white.withOpacity(0.04), backgroundColor),
        backgroundColor,
      ],
    ),
    border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
  );
}

class ModernDrawer extends StatefulWidget {
  const ModernDrawer({
    super.key,
    required this.isDark,
    required this.showDebugTools,
    required this.profileName,
    this.profileAvatar,
    required this.currentStreak,
    required this.totalSparksLit,
    required this.currentLevel,
    required this.totalXp,
    required this.xpInLevel,
    required this.xpToNextLevel,
    required this.earnedBadgeCount,
    required this.badgeGoalCount,
    required this.weeklyDoneCount,
    required this.weeklyGoalCount,
    required this.themeUnlocked,
    required this.themeUnlockLevel,
    required this.onToggleTheme,
    required this.onOpenAddSpark,
    required this.onRefreshTasks,
    required this.onEditProfile,
    required this.onOpenBadges,
    required this.onOpenProfile,
    required this.onOpenReferral,
    required this.onOpenContact,
    required this.onOpenRateUs,
    required this.onSendTestNotification,
    required this.onOpenDailyMoodSheet,
    required this.onOpenWeeklyPlan,
    required this.onOpenChallenges,
    required this.onOpenPremium,
    required this.selectedLocale,
    required this.onOpenLanguagePicker,
  });

  final bool isDark;
  final bool showDebugTools;
  final String profileName;
  final String? profileAvatar;
  final int currentStreak;
  final int totalSparksLit;
  final int currentLevel;
  final int totalXp;
  final int xpInLevel;
  final int xpToNextLevel;
  final int earnedBadgeCount;
  final int badgeGoalCount;
  final int weeklyDoneCount;
  final int weeklyGoalCount;
  final bool themeUnlocked;
  final int themeUnlockLevel;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onOpenAddSpark;
  final Future<void> Function() onRefreshTasks;
  final Future<void> Function() onEditProfile;
  final VoidCallback onOpenBadges;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenReferral;
  final VoidCallback onOpenContact;
  final Future<void> Function() onOpenRateUs;
  final Future<void> Function() onSendTestNotification;
  final Future<void> Function() onOpenDailyMoodSheet;
  final VoidCallback onOpenWeeklyPlan;
  final Future<void> Function() onOpenChallenges;
  final Future<void> Function() onOpenPremium;
  final Locale? selectedLocale;
  final Future<void> Function() onOpenLanguagePicker;

  @override
  State<ModernDrawer> createState() => _ModernDrawerState();
}

class _ModernDrawerState extends State<ModernDrawer>
    with SingleTickerProviderStateMixin {
  static const _entryDurationMs = 320;
  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _entryDurationMs),
  )..forward();
  bool _referralExpanded = false;

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Animation<double> _interval(double start, {double span = 0.34}) {
    final safeStart = start.clamp(0.0, 0.94).toDouble();
    final safeEnd = (safeStart + span).clamp(safeStart + 0.05, 1.0).toDouble();
    return CurvedAnimation(
      parent: _entryController,
      curve: Interval(safeStart, safeEnd, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildStaggeredItem({required int index, required Widget child}) {
    const listStart = 20 / _entryDurationMs;
    const listStep = 0.045;
    return _DrawerEntryReveal(
      animation: _interval(listStart + (index * listStep)),
      beginOffsetY: 12,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final effectiveDark = widget.isDark || theme.brightness == Brightness.dark;
    final activeLocale = Localizations.localeOf(context);
    final safeBadgeGoal = widget.badgeGoalCount <= 0
        ? 1
        : widget.badgeGoalCount;
    final badgeProgress = (widget.earnedBadgeCount / safeBadgeGoal).clamp(
      0.0,
      1.0,
    );
    final badgeFilledDots = (badgeProgress * 5).round().clamp(0, 5);
    const filledDot = '\u25CF';
    const emptyDot = '\u25CB';
    final badgeDots =
        '${filledDot * badgeFilledDots}${emptyDot * (5 - badgeFilledDots)}';
    final languageSubtitle = widget.selectedLocale == null
        ? '${l10n.followSystem} · ${l10n.languageDisplayName(activeLocale.languageCode)}'
        : l10n.languageDisplayName(widget.selectedLocale!.languageCode);

    Future<void> closeDrawer() async {
      final scaffold = Scaffold.maybeOf(context);
      if (scaffold != null && scaffold.isEndDrawerOpen) {
        scaffold.closeEndDrawer();
        await Future<void>.delayed(const Duration(milliseconds: 220));
        return;
      }
      await Navigator.of(context).maybePop();
    }

    Future<void> runMenuAction(VoidCallback action) async {
      await closeDrawer();
      action();
    }

    Future<void> runAsyncMenuAction(Future<void> Function() action) async {
      await closeDrawer();
      await action();
    }

    final drawerItems = <Widget>[
      const SizedBox(height: 16),
      _SectionHeader(title: l10n.yourSpace, icon: Icons.dark_mode_rounded),
      _SectionCard(
        surfaceLevel: _DrawerSurfaceLevel.tertiary,
        children: [
          _ThemeQuickAccessCard(
            isDark: widget.isDark,
            themeUnlocked: widget.themeUnlocked,
            themeUnlockLevel: widget.themeUnlockLevel,
            onToggleTheme: widget.onToggleTheme,
          ),
        ],
      ),
      const SizedBox(height: 16),
      _SectionHeader(title: l10n.thingsYouCanDo, icon: Icons.bolt_rounded),
      _SectionCard(
        surfaceLevel: _DrawerSurfaceLevel.tertiary,
        children: [
          _ModernMenuCard(
            icon: Icons.auto_awesome_rounded,
            iconAsset: 'assets/in_app_icons/sparkle.png',
            iconColor: _kCreateSparkIconColor,
            iconBackgroundColor: _kCreateSparkIconBg,
            title: l10n.createMySpark,
            subtitle: l10n.addACustomHabit,
            isSubtle: true,
            surfaceLevel: _DrawerSurfaceLevel.primary,
            onTap: () => runAsyncMenuAction(widget.onOpenAddSpark),
          ),
          _ModernMenuCard(
            icon: Icons.shuffle_rounded,
            iconColor: _kRefreshIconColor,
            iconBackgroundColor: _kRefreshIconBg,
            title: l10n.refreshTasks,
            subtitle: l10n.loadANewTaskSet,
            isSubtle: true,
            surfaceLevel: _DrawerSurfaceLevel.primary,
            onTap: () => runAsyncMenuAction(widget.onRefreshTasks),
          ),
          _ModernMenuCard(
            icon: Icons.language_rounded,
            iconColor: _kLanguageIconColor,
            iconBackgroundColor: _kLanguageIconBg,
            title: l10n.appLanguage,
            subtitle: languageSubtitle,
            isSubtle: true,
            surfaceLevel: _DrawerSurfaceLevel.primary,
            onTap: () => runAsyncMenuAction(widget.onOpenLanguagePicker),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _SectionHeader(title: l10n.yourJourney, icon: Icons.insights_rounded),
      _SectionCard(
        surfaceLevel: _DrawerSurfaceLevel.tertiary,
        children: [
          _ModernMenuCard(
            icon: Icons.emoji_events_rounded,
            iconAsset: 'assets/in_app_icons/badges.png',
            iconColor: _kBadgesIconColor,
            iconBackgroundColor: _kBadgesIconBg,
            title: l10n.achievements,
            subtitle: l10n.unlockedCount(
              widget.earnedBadgeCount,
              safeBadgeGoal,
            ),
            surfaceLevel: _DrawerSurfaceLevel.secondary,
            meta: _CardMetaPreview(
              text: '$badgeDots  ${widget.earnedBadgeCount}/$safeBadgeGoal',
            ),
            isMuted: true,
            onTap: () => runMenuAction(widget.onOpenBadges),
          ),
          _ModernMenuCard(
            icon: Icons.emoji_events_rounded,
            iconColor: _kChallengeIconColor,
            iconBackgroundColor: _kChallengeIconBg,
            title: l10n.challenges,
            subtitle: l10n.challengeSubtitle,
            surfaceLevel: _DrawerSurfaceLevel.secondary,
            onTap: () => runAsyncMenuAction(widget.onOpenChallenges),
          ),
          _ModernMenuCard(
            icon: Icons.diamond_rounded,
            iconColor: _kPremiumIconColor,
            iconBackgroundColor: _kPremiumIconBg,
            title: l10n.premium,
            subtitle: l10n.premiumSubtitle,
            surfaceLevel: _DrawerSurfaceLevel.secondary,
            onTap: () => runAsyncMenuAction(widget.onOpenPremium),
          ),
          _ModernMenuCard(
            icon: Icons.calendar_view_week_rounded,
            iconAsset: 'assets/in_app_icons/calendar.png',
            iconColor: _kWeeklyPlanIconColor,
            iconBackgroundColor: _kWeeklyPlanIconBg,
            title: l10n.weeklyPlan,
            surfaceLevel: _DrawerSurfaceLevel.secondary,
            subtitle: widget.weeklyGoalCount > 0
                ? l10n.goalsCount(
                    widget.weeklyDoneCount,
                    widget.weeklyGoalCount,
                  )
                : l10n.setGoalsForThisWeek,
            meta: _CardMetaPreview(
              text: widget.weeklyGoalCount > 0
                  ? l10n.goalsCount(
                      widget.weeklyDoneCount,
                      widget.weeklyGoalCount,
                    )
                  : l10n.noGoals,
            ),
            onTap: () => runMenuAction(widget.onOpenWeeklyPlan),
          ),
          _DrawerReferralAccordion(
            expanded: _referralExpanded,
            onToggle: () {
              setState(() => _referralExpanded = !_referralExpanded);
            },
            onOpenReferral: () => runMenuAction(widget.onOpenReferral),
            surfaceLevel: _DrawerSurfaceLevel.tertiary,
          ),
        ],
      ),
      if (widget.showDebugTools && kDebugMode) ...[
        const SizedBox(height: 16),
        _SectionHeader(title: 'Debug', icon: Icons.developer_mode_rounded),
        _SectionCard(
          surfaceLevel: _DrawerSurfaceLevel.tertiary,
          children: [
            _ModernMenuCard(
              icon: Icons.notifications_rounded,
              iconColor: scheme.tertiary,
              title: 'Send test reminder (1 min)',
              subtitle: 'Debug only',
              surfaceLevel: _DrawerSurfaceLevel.tertiary,
              onTap: () => runAsyncMenuAction(widget.onSendTestNotification),
            ),
            _ModernMenuCard(
              icon: Icons.psychology_rounded,
              iconColor: scheme.primary,
              title: 'Open daily mood sheet',
              subtitle: 'Debug only',
              surfaceLevel: _DrawerSurfaceLevel.tertiary,
              onTap: () => runAsyncMenuAction(widget.onOpenDailyMoodSheet),
            ),
          ],
        ),
      ],
      const SizedBox(height: 16),
      _SectionHeader(title: l10n.needHelp, icon: Icons.support_agent_rounded),
      _SectionCard(
        surfaceLevel: _DrawerSurfaceLevel.tertiary,
        children: [
          _ModernMenuCard(
            icon: Icons.star_rounded,
            iconColor: _kRateUsIconColor,
            iconBackgroundColor: _kRateUsIconBg,
            title: l10n.tr('Rate us'),
            subtitle: l10n.tr('Help Sparkio grow with a quick review.'),
            surfaceLevel: _DrawerSurfaceLevel.tertiary,
            onTap: () => runAsyncMenuAction(widget.onOpenRateUs),
          ),
          _ModernMenuCard(
            icon: Icons.mail_outline_rounded,
            iconColor: _kTalkToUsIconColor,
            iconBackgroundColor: _kTalkToUsIconBg,
            title: l10n.talkToUs,
            subtitle: l10n.supportReplyTime,
            surfaceLevel: _DrawerSurfaceLevel.tertiary,
            onTap: () => runMenuAction(widget.onOpenContact),
          ),
        ],
      ),
    ];

    return Drawer(
      width: 326,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _kDrawerBackgroundTop,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -120,
                right: -100,
                child: IgnorePointer(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color.fromRGBO(120, 90, 255, 0.14),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _DrawerEntryReveal(
                      animation: _interval(0.0, span: 0.36),
                      beginOffsetY: 10,
                      child: _DrawerHero(
                        isDark: effectiveDark,
                        profileName: widget.profileName,
                        profileAvatar: widget.profileAvatar,
                        currentStreak: widget.currentStreak,
                        totalSparksLit: widget.totalSparksLit,
                        currentLevel: widget.currentLevel,
                        totalXp: widget.totalXp,
                        xpInLevel: widget.xpInLevel,
                        xpToNextLevel: widget.xpToNextLevel,
                        onOpenProfile: () =>
                            runMenuAction(widget.onOpenProfile),
                        onQuickEdit: () =>
                            runAsyncMenuAction(widget.onEditProfile),
                        onClose: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      children: [
                        for (var i = 0; i < drawerItems.length; i++)
                          _buildStaggeredItem(index: i, child: drawerItems[i]),
                      ],
                    ),
                  ),
                  _DrawerEntryReveal(
                    animation: _interval(0.72, span: 0.2),
                    beginOffsetY: 8,
                    child: const _QuickSettingsCaption(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerEntryReveal extends StatelessWidget {
  const _DrawerEntryReveal({
    required this.animation,
    required this.child,
    this.beginOffsetY = 10,
  });

  final Animation<double> animation;
  final Widget child;
  final double beginOffsetY;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * beginOffsetY),
            child: child,
          ),
        );
      },
    );
  }
}

class _DrawerHero extends StatelessWidget {
  const _DrawerHero({
    required this.isDark,
    required this.profileName,
    this.profileAvatar,
    required this.currentStreak,
    required this.totalSparksLit,
    required this.currentLevel,
    required this.totalXp,
    required this.xpInLevel,
    required this.xpToNextLevel,
    required this.onOpenProfile,
    required this.onQuickEdit,
    required this.onClose,
  });

  final bool isDark;
  final String profileName;
  final String? profileAvatar;
  final int currentStreak;
  final int totalSparksLit;
  final int currentLevel;
  final int totalXp;
  final int xpInLevel;
  final int xpToNextLevel;
  final VoidCallback onOpenProfile;
  final Future<void> Function() onQuickEdit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final cleanedName = TaskRepository.sanitizeProfileName(profileName);
    final name = cleanedName.isEmpty ? l10n.friend : cleanedName;
    final initials = name.characters.first.toUpperCase();
    final avatar = profileAvatar?.trim();
    final isAssetAvatar =
        avatar != null && avatar.isNotEmpty && avatar.startsWith('assets/');
    final isFileAvatar =
        avatar != null &&
        avatar.isNotEmpty &&
        !avatar.startsWith('assets/') &&
        (avatar.contains('/') || avatar.contains('\\'));
    final streakLabel = currentStreak > 0
        ? l10n.dayStreak(currentStreak)
        : l10n.startYourStreakToday;
    final safeLevel = currentLevel <= 0 ? 1 : currentLevel;
    final safeXpToNext = xpToNextLevel <= 0 ? 1 : xpToNextLevel;
    final clampedXpInLevel = xpInLevel.clamp(0, safeXpToNext);
    final xpProgress = (clampedXpInLevel / safeXpToNext).clamp(0.0, 1.0);
    final levelTitle = l10n.levelTitle(safeLevel);
    final streakMiniLabel = l10n.dayStreak(currentStreak);
    final miniStateLabel =
        '🔥 $streakMiniLabel   •   ${l10n.sparksLitCount(totalSparksLit)}';
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onOpenProfile();
      },
      onLongPress: () {
        HapticFeedback.selectionClick();
        onQuickEdit();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Color.alphaBlend(
            Colors.white.withOpacity(0.045),
            const Color(0xFF131A2A),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              spreadRadius: -8,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B6CFF), Color(0xFF8FD3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
              ),
              child: Center(
                child: (avatar == null || avatar.isEmpty)
                    ? Text(
                        initials,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onPrimary,
                        ),
                      )
                    : isAssetAvatar
                    ? ClipOval(
                        child: Image.asset(
                          avatar,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) {
                            return Text(
                              initials,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onPrimary,
                              ),
                            );
                          },
                        ),
                      )
                    : isFileAvatar
                    ? ClipOval(
                        child: Image.file(
                          File(avatar),
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) {
                            return Text(
                              initials,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onPrimary,
                              ),
                            );
                          },
                        ),
                      )
                    : Text(
                        avatar,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                      color: scheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    streakLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(0.74),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.levelLabel(safeLevel, levelTitle),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      value: xpProgress,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF8B7CFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    miniStateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(0.72),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              color: scheme.onSurfaceVariant.withOpacity(0.78),
              tooltip: l10n.tr('Close'),
            ),
          ],
        ),
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
    const sectionLabelColor = Color(0xFF8A93AD);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
      child: Row(
        children: [
          Icon(icon, size: 13, color: sectionLabelColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11.5,
              letterSpacing: 0.18,
              color: sectionLabelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.children,
    this.surfaceLevel = _DrawerSurfaceLevel.tertiary,
  });

  final List<Widget> children;
  final _DrawerSurfaceLevel surfaceLevel;

  @override
  Widget build(BuildContext context) {
    final mergedChildren = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      mergedChildren.add(children[i]);
      if (i != children.length - 1) {
        mergedChildren.add(const SizedBox(height: 12));
      }
    }

    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        padding: EdgeInsets.zero,
        decoration: _drawerNeoGlassDecoration(
          radius: 16,
          withDepth: false,
          level: surfaceLevel,
        ),
        child: Column(children: mergedChildren),
      ),
    );
  }
}

class _DrawerPressableCard extends StatefulWidget {
  const _DrawerPressableCard({
    required this.onTap,
    required this.borderRadius,
    required this.decorationBuilder,
    required this.padding,
    required this.child,
  });

  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final BoxDecoration Function(bool pressed) decorationBuilder;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  State<_DrawerPressableCard> createState() => _DrawerPressableCardState();
}

class _DrawerPressableCardState extends State<_DrawerPressableCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: widget.borderRadius,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.ease,
          scale: _pressed ? 0.98 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.ease,
            padding: widget.padding,
            decoration: widget.decorationBuilder(_pressed),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _ThemeQuickAccessCard extends StatelessWidget {
  const _ThemeQuickAccessCard({
    required this.isDark,
    required this.themeUnlocked,
    required this.themeUnlockLevel,
    required this.onToggleTheme,
  });

  final bool isDark;
  final bool themeUnlocked;
  final int themeUnlockLevel;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final lockMessage = l10n.unlocksAtLevel(themeUnlockLevel);
    const secondaryText = Color(0xFF7C86A2);
    final moonSunColor = isDark
        ? const Color(0xFFA78BFA)
        : const Color(0xFF7DD3FC);
    final moonSunBg = isDark
        ? const Color(0x1FA78BFA)
        : const Color(0x1F7DD3FC);
    void handleToggleRequest() {
      if (!themeUnlocked) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(lockMessage)));
        return;
      }
      onToggleTheme();
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < 420) return;
        HapticFeedback.selectionClick();
        handleToggleRequest();
      },
      child: _DrawerPressableCard(
        onTap: handleToggleRequest,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decorationBuilder: (pressed) => _drawerNeoGlassDecoration(
          radius: 16,
          pressed: pressed,
          level: _DrawerSurfaceLevel.tertiary,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: _drawerIconPodDecoration(
                backgroundColor: moonSunBg,
                radius: 10,
              ),
              child: Center(
                child: Image.asset(
                  isDark
                      ? 'assets/in_app_icons/moon.png'
                      : 'assets/in_app_icons/sun.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  color: moonSunColor,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.darkMode,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: themeUnlocked
                          ? scheme.onSurface
                          : scheme.onSurface.withOpacity(0.72),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (themeUnlocked)
                    Text(
                      l10n.tapOrSwipeToggle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 12,
                          color: secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lockMessage,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: secondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 46,
              child: Transform.scale(
                scale: 0.88,
                child: Switch(
                  value: isDark,
                  onChanged: themeUnlocked ? (_) => onToggleTheme() : null,
                  activeColor: Color.alphaBlend(
                    scheme.primary.withOpacity(0.68),
                    scheme.surface,
                  ),
                  activeTrackColor: scheme.primary.withOpacity(0.24),
                  inactiveTrackColor: scheme.surfaceContainerHighest
                      .withOpacity(0.42),
                  inactiveThumbColor: scheme.onSurfaceVariant.withOpacity(0.72),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardMetaPreview extends StatelessWidget {
  const _CardMetaPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: _drawerNeoGlassDecoration(
        radius: 999,
        withDepth: false,
        level: _DrawerSurfaceLevel.tertiary,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DrawerReferralAccordion extends StatelessWidget {
  const _DrawerReferralAccordion({
    required this.expanded,
    required this.onToggle,
    required this.onOpenReferral,
    this.surfaceLevel = _DrawerSurfaceLevel.secondary,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onOpenReferral;
  final _DrawerSurfaceLevel surfaceLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final referralNeon = _kReferralIconColor;
    return _DrawerPressableCard(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decorationBuilder: (pressed) => _drawerNeoGlassDecoration(
        radius: 16,
        pressed: pressed,
        level: surfaceLevel,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: _drawerIconPodDecoration(
                  backgroundColor: _kReferralIconBg,
                  radius: 10,
                ),
                child: Icon(
                  Icons.group_add_rounded,
                  color: referralNeon,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.referralRewards,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.referralBenefit,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: scheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8, left: 48),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.openProfileToCopyCode,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withOpacity(0.82),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onOpenReferral,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(l10n.open),
                  ),
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _QuickSettingsCaption extends StatelessWidget {
  const _QuickSettingsCaption();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Text(
        l10n.quickSettingsCaption,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant.withOpacity(0.66),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ModernMenuCard extends StatelessWidget {
  const _ModernMenuCard({
    required this.icon,
    this.iconAsset,
    required this.iconColor,
    this.iconBackgroundColor = const Color(0xFF1A243A),
    required this.title,
    required this.subtitle,
    this.meta,
    this.isSubtle = false,
    this.isMuted = false,
    this.surfaceLevel = _DrawerSurfaceLevel.secondary,
    required this.onTap,
  });

  final IconData icon;
  final String? iconAsset;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final String subtitle;
  final Widget? meta;
  final bool isSubtle;
  final bool isMuted;
  final _DrawerSurfaceLevel surfaceLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveIconColor = iconColor.withOpacity(isMuted ? 0.9 : 1);
    final neonIconColor = effectiveIconColor;
    final subtitleOpacity = isSubtle ? 0.8 : 1.0;
    final resolvedSubtitleOpacity = isMuted
        ? subtitleOpacity * 0.78
        : subtitleOpacity;
    final titleOpacity = isMuted ? 0.86 : 1.0;
    final trailingOpacity = isSubtle ? 0.58 : 1.0;
    final resolvedTrailingOpacity = isMuted
        ? trailingOpacity * 0.56
        : trailingOpacity;
    final subtitleYOffset = meta != null ? -2.5 : 0.0;

    return _DrawerPressableCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decorationBuilder: (pressed) => _drawerNeoGlassDecoration(
        radius: 16,
        pressed: pressed,
        level: surfaceLevel,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: _drawerIconPodDecoration(
              backgroundColor: iconBackgroundColor,
              radius: 10,
            ),
            child: iconAsset != null
                ? Center(
                    child: Image.asset(
                      iconAsset!,
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      color: neonIconColor,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  )
                : Icon(icon, color: neonIconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      (isSubtle
                              ? theme.textTheme.bodyMedium
                              : theme.textTheme.titleSmall)
                          ?.copyWith(
                            fontWeight: isSubtle
                                ? FontWeight.w600
                                : FontWeight.w600,
                            color: scheme.onSurface.withOpacity(
                              isSubtle ? titleOpacity * 0.92 : titleOpacity * 0.9,
                            ),
                          ),
                ),
                SizedBox(height: meta != null ? 0 : 2),
                Transform.translate(
                  offset: Offset(0, subtitleYOffset),
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(
                        resolvedSubtitleOpacity * 0.88,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (meta != null) ...[
            const SizedBox(width: 8),
            Opacity(opacity: isMuted ? 0.78 : 1, child: meta!),
          ],
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurfaceVariant.withOpacity(
              resolvedTrailingOpacity * 0.78,
            ),
            size: 20,
          ),
        ],
      ),
    );
  }
}




