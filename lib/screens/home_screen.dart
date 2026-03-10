import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:sparkio/widgets/modern_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/task.dart';
import '../models/challenge_mode.dart';
import '../models/weekly_plan.dart';
import '../models/level_unlocks.dart';
import '../services/task_engine.dart';
import '../services/task_repository.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';
import '../services/premium_service.dart';
import '../services/theme_service.dart';
import '../services/analytics_service.dart';
import '../services/streak_service.dart';
import '../services/home_widget_service.dart';
import '../services/referral_service.dart';
import '../services/locale_service.dart';
import '../services/task_localizer.dart';
import '../controllers/home_controller.dart';
import '../app_strings.dart';
import 'task_add_sheet.dart';
import 'premium_perks_sheet.dart';
import 'premium_purchase_sheet.dart';
import 'profile_screen.dart';
import 'package:sparkio/screens/stats_screen.dart';
import 'badges_screen.dart';
import '../widgets/banner_ad_bar.dart';
import '../widgets/streak_share_card.dart';
import '../widgets/home_badge_unlock_overlay.dart';
import '../widgets/home_skeleton.dart';
import '../widgets/daily_mood_sheet.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_header_sliver.dart';
import '../widgets/home_flow_mode_sliver.dart';
import '../widgets/home_plan_preview_sliver.dart';
import '../widgets/home_debug_timer_sliver.dart';
import '../widgets/home_pool_error_sliver.dart';
import '../widgets/home_all_done_sliver.dart';
import '../widgets/weekly_plan_sheet.dart';
import '../widgets/weekly_review_share_card.dart';
part 'home_screen_methods.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final bool _showDebugTools = const bool.fromEnvironment(
    'SHOW_DEBUG_TOOLS',
    defaultValue: false,
  );
  final bool _showLegacyHomeExtras = false;
  static const int _badgeGoalCount = 10;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _homeScrollController = ScrollController();
  static final Uri _instagramUri = Uri.parse(
    'https://www.instagram.com/sparkio.app/',
  );
  final _repo = TaskRepository();
  final _engine = TaskEngine();
  final _premium = PremiumService.instance;
  final _referral = ReferralService.instance;
  final _adService = AdService.instance;
  final _notifications = NotificationService.instance;
  final InAppReview _inAppReview = InAppReview.instance;
  late final HomeController _controller = HomeController(
    repo: _repo,
    engine: _engine,
    premium: _premium,
    adService: _adService,
    notifications: _notifications,
  );
  final GlobalKey _sharePreviewKey = GlobalKey();

  bool _loading = true;
  bool _refreshing = false;
  bool _dailyMoodPrompting = false;
  static const int _maxRefreshPerDay = 2;
  static const int _maxSkipsPerDay = 2;
  bool _rewardBusy = false;
  bool _poolErrorShown = false;
  bool _debugInstantComplete = false;
  bool _ratePromptOpen = false;
  bool _endDrawerOpen = false;
  String? _poolError;

  List<Task> _today = [];
  Map<String, bool> _completed = {};
  String? _allDoneShownKey;

  int _streak = 0;
  int _todayCompleted = 0;
  int _totalSparksLit = 0;
  String? _lastCompletedTaskTitle;
  bool _reminderEnabled = false;
  bool _premiumActive = false;
  DateTime? _premiumUntil;
  // ignore: unused_field
  DateTime? _noAdsUntil;
  int _dailyAddCount = 0;
  int _adaptiveDifficultyDelta = 0;
  int _earnedBadgesCount = 0;
  int _totalXp = 0;
  int _level = 1;
  int _xpInLevel = 0;
  int _xpToNextLevel = 40;
  String _profileName = '';
  String? _profileAvatar;
  String _weeklyWeekKey = '';
  Map<String, int> _weeklyTargets = {};
  Map<String, int> _weeklyDone = {};
  ActiveChallenge? _activeChallenge;
  Set<String> _dismissedNudgesToday = <String>{};
  String? _coachMorningIntentionToday;
  bool _coachEveningReviewDoneToday = false;
  String _weeklyReviewShownWeek = '';
  Task? _streakRescueTask;
  int _streakRescueMissedDays = 0;
  String _customCategory = 'mind';
  String _customDifficulty = 'easy';
  int _customDuration = 5;
  Task? _activeTimerTask;
  Duration _activeTimerRemaining = Duration.zero;
  bool _activeTimerFinished = false;
  bool _activeTimerPaused = false;
  bool _awaitingSecondAction = false;
  String? _pendingCompletionChainId;
  String? _pendingCompletionTaskId;
  DateTime? _pendingCompletionAt;
  int _pendingCompletionDoneCount = 0;
  Timer? _activeTimerTicker;
  Timer? _premiumTicker;
  bool _flowModeEnabled = false;
  String? _flowTaskId;
  bool _flowMomentumPrompt = false;
  late final VoidCallback _localeListener = _handleLocaleChanged;

  @override
  void initState() {
    super.initState();
    LocaleService.instance.locale.addListener(_localeListener);
    _startPremiumTicker();
    _bootstrap();
  }

  @override
  void dispose() {
    LocaleService.instance.locale.removeListener(_localeListener);
    _homeScrollController.dispose();
    _activeTimerTicker?.cancel();
    _premiumTicker?.cancel();
    super.dispose();
  }

  // Helper method to allow extensions to update state
  void _updateState(void Function() fn) {
    setState(fn);
  }

  Future<void> _handleLocaleChanged() async {
    final localizedToday = _repo.localizeTasksForCurrentLocale(_today);
    final localizedTimerTask = _activeTimerTask == null
        ? null
        : _repo.localizeTasksForCurrentLocale([_activeTimerTask!]).first;
    final localizedLastTitle = _lastCompletedTaskTitle == null
        ? null
        : _repo.localizeTaskTitleForCurrentLocale(_lastCompletedTaskTitle!);

    if (!mounted) return;
    _updateState(() {
      _today = localizedToday;
      _activeTimerTask = localizedTimerTask;
      _lastCompletedTaskTitle = localizedLastTitle;
    });
    await _repo.saveSelectedTasks(localizedToday);
  }

  Task? _resolveNextPendingTask() {
    final pending = _today.where((task) => _completed[task.id] != true).toList()
      ..sort((a, b) {
        final durationCompare = a.totalDurationSeconds.compareTo(
          b.totalDurationSeconds,
        );
        if (durationCompare != 0) return durationCompare;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    if (pending.isEmpty) return null;
    return pending.first;
  }

  void _enterFlowMode(Task task) {
    _updateState(() {
      _flowModeEnabled = true;
      _flowTaskId = task.id;
      _flowMomentumPrompt = false;
    });
  }

  Future<void> _handleFlowPrimaryAction(Task task) async {
    if (_flowMomentumPrompt) {
      _updateState(() {
        _flowMomentumPrompt = false;
        _flowTaskId = task.id;
      });
      await _toggle(task);
      return;
    }
    final isActiveTask = _activeTimerTask?.id == task.id;
    if (isActiveTask && _activeTimerFinished) {
      final completed = await _completeFinishedTimerFromNudge();
      if (!mounted || !completed) return;
      final nextTask = _resolveNextPendingTask();
      _updateState(() {
        if (nextTask == null) {
          _flowModeEnabled = false;
          _flowTaskId = null;
          _flowMomentumPrompt = false;
        } else {
          _flowTaskId = nextTask.id;
          _flowMomentumPrompt = true;
        }
      });
      return;
    }
    if (isActiveTask && _activeTimerPaused) {
      await _resumeTaskTimer(task);
      return;
    }
    if (isActiveTask) return;
    _updateState(() => _flowTaskId = task.id);
    await _toggle(task);
  }

  Future<void> _toggleFlowTimerPause(Task task) async {
    if (_activeTimerTask?.id != task.id || _activeTimerFinished) return;
    if (_activeTimerPaused) {
      await _resumeTaskTimer(task);
    } else {
      await _pauseTaskTimer(task);
    }
  }

  Future<void> _endFlowTimer(Task task) async {
    if (_activeTimerTask?.id != task.id) return;
    await _cancelTaskTimer(task);
    if (!mounted) return;
    _updateState(() => _flowMomentumPrompt = false);
  }

  void _finishFlowForToday() {
    _updateState(() {
      _flowModeEnabled = false;
      _flowTaskId = null;
      _flowMomentumPrompt = false;
      _awaitingSecondAction = false;
      _pendingCompletionChainId = null;
      _pendingCompletionTaskId = null;
      _pendingCompletionAt = null;
      _pendingCompletionDoneCount = 0;
    });
  }

  Future<void> _startFlowFromHome(Task task) async {
    if (!_flowModeEnabled) {
      _enterFlowMode(task);
    }
    await _handleFlowPrimaryAction(task);
  }

  Future<void> _completeFlowTaskAfterTimer(Task task) async {
    if (!_flowModeEnabled) return;
    if (_completed[task.id] == true) return;
    await _cancelTaskTimer(task);
    if (!mounted) return;
    _updateState(() => _completed[task.id] = true);
    await _repo.saveCompletedMap(_completed);
    await _markTaskDone(task);
    await _applyStreakIfAllDone();
    if (!mounted) return;
    final nextTask = _resolveNextPendingTask();
    _updateState(() {
      if (nextTask == null) {
        _flowModeEnabled = false;
        _flowTaskId = null;
        _flowMomentumPrompt = false;
      } else {
        _flowTaskId = nextTask.id;
        _flowMomentumPrompt = true;
      }
    });
  }

  void _startPremiumTicker() {
    _premiumTicker?.cancel();
    _premiumTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_premiumUntil == null) return;
      final now = DateTime.now();
      final stillActive = _premiumUntil!.isAfter(now);
      if (!stillActive && _premiumActive) {
        unawaited(
          AnalyticsService.instance.logEvent(
            'premium_expired',
            params: {'source': 'timer'},
          ),
        );
        _updateState(() {
          _premiumActive = false;
          _premiumUntil = null;
        });
        return;
      }
      // trigger rebuild so remaining label updates
      _updateState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final doneCount = _today.where((t) => _completed[t.id] == true).length;
    final completedTodayCount = max(doneCount, _todayCompleted);
    final weeklyDoneTotal = _weeklyDoneTotal();
    final weeklyTargetTotal = _weeklyTargetTotal();
    final remainingCount = _today.where((t) => _completed[t.id] != true).length;
    final allDone = _today.isNotEmpty && remainingCount == 0;
    int byShortDuration(Task a, Task b) {
      final durationCompare = a.totalDurationSeconds.compareTo(
        b.totalDurationSeconds,
      );
      if (durationCompare != 0) return durationCompare;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }

    final pendingTasks =
        _today.where((task) => _completed[task.id] != true).toList()
          ..sort(byShortDuration);
    final completedTasks =
        _today.where((task) => _completed[task.id] == true).toList()
          ..sort(byShortDuration);
    final orderedTodayTasks = <Task>[...pendingTasks, ...completedTasks];
    Task? nextSparkTask;
    for (final task in orderedTodayTasks) {
      if (_completed[task.id] != true) {
        nextSparkTask = task;
        break;
      }
    }
    Task? heroTask;
    if (_activeTimerTask != null && _completed[_activeTimerTask!.id] != true) {
      for (final task in orderedTodayTasks) {
        if (task.id == _activeTimerTask!.id) {
          heroTask = task;
          break;
        }
      }
    }
    if (heroTask == null && _flowModeEnabled) {
      if (_flowTaskId != null) {
        for (final task in orderedTodayTasks) {
          if (task.id == _flowTaskId && _completed[task.id] != true) {
            heroTask = task;
            break;
          }
        }
      }
      heroTask ??= nextSparkTask;
    }
    heroTask ??= nextSparkTask;
    final heroTaskHasTimer =
        heroTask != null &&
        _activeTimerTask?.id == heroTask.id &&
        _completed[heroTask.id] != true;
    final heroTaskTimerFinished = heroTaskHasTimer && _activeTimerFinished;
    final heroTaskIsActive =
        heroTaskHasTimer && !_activeTimerPaused && !_activeTimerFinished;
    final heroTaskIsPaused =
        heroTaskHasTimer && _activeTimerPaused && !_activeTimerFinished;
    final heroTimerProgress = heroTaskHasTimer
        ? (() {
            final total = heroTask!.totalDurationSeconds.clamp(1, 360000);
            final remaining = _activeTimerRemaining.inSeconds.clamp(0, total);
            return (1 - (remaining / total)).clamp(0.0, 1.0).toDouble();
          })()
        : null;
    final isDark = theme.brightness == Brightness.dark;
    final homeBaseBackground = isDark
        ? const Color(0xFF0B0F1A)
        : scheme.background;
    final bottomRightAmbient = isDark
        ? const Color.fromRGBO(0, 220, 255, 0.04)
        : scheme.secondary.withOpacity(0.06);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: homeBaseBackground,
      endDrawer: _buildEndDrawer(),
      onEndDrawerChanged: (isOpen) {
        if (_endDrawerOpen == isOpen || !mounted) return;
        setState(() => _endDrawerOpen = isOpen);
      },
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(color: homeBaseBackground),
              ),
            ),
          ),
          Positioned(
            right: -152,
            bottom: -156,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [bottomRightAmbient, Colors.transparent],
                      stops: const [0.0, 0.5],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _loading
              ? const HomeSkeleton()
              : CustomScrollView(
                  controller: _homeScrollController,
                  slivers: [
                    HomeAppBar(
                      userName: _profileName.isEmpty ? 'Friend' : _profileName,
                      isDark: isDark,
                      onOpenProfile: _openProfileScreen,
                      onOpenStats: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StatsScreen(currentLevel: _level),
                        ),
                      ),
                      onOpenMenu: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                    ),
                    HomeHeaderSliver(
                      doneCount: completedTodayCount,
                      totalCount: _today.length,
                      streakCount: _streak,
                      weeklyDoneCount: weeklyDoneTotal,
                      weeklyTotalCount: weeklyTargetTotal,
                      syncedProgress: heroTaskHasTimer
                          ? heroTimerProgress
                          : null,
                      onShare: _openShareSheet,
                      onOpenWeekly: () => unawaited(_openWeeklyPlanSheet()),
                      onStartFirstSpark: nextSparkTask == null
                          ? null
                          : () => _enterFlowMode(nextSparkTask!),
                      hasPendingSpark: nextSparkTask != null,
                      showAction: false,
                    ),
                    if (allDone)
                      const HomeAllDoneSliver()
                    else
                      HomeFlowModeSliver(
                        task: heroTask,
                        completedTodayCount: completedTodayCount,
                        dailyGoalCount: _today.isEmpty
                            ? 3
                            : max(_today.length, completedTodayCount),
                        latestWinTitle: _lastCompletedTaskTitle,
                        weeklyDoneCount: weeklyDoneTotal,
                        weeklyTargetCount: weeklyTargetTotal,
                        timerRunning: heroTaskIsActive,
                        timerPaused: heroTaskIsPaused,
                        timerFinished: heroTaskTimerFinished,
                        timerRemaining: heroTaskHasTimer
                            ? _activeTimerRemaining
                            : null,
                        showMomentumPrompt:
                            _flowModeEnabled &&
                            _flowMomentumPrompt &&
                            heroTask != null &&
                            heroTask.id == _flowTaskId,
                        onPauseAction:
                            heroTaskHasTimer && !heroTaskTimerFinished
                            ? () => _toggleFlowTimerPause(heroTask!)
                            : null,
                        onEndAction: heroTaskHasTimer && !heroTaskTimerFinished
                            ? () => _endFlowTimer(heroTask!)
                            : null,
                        onDoneForToday: _flowModeEnabled && _flowMomentumPrompt
                            ? _finishFlowForToday
                            : null,
                        onPrimaryAction: _flowModeEnabled
                            ? (heroTask == null
                                  ? null
                                  : heroTaskTimerFinished
                                  ? () => unawaited(
                                      _completeFinishedTimerFromNudge(),
                                    )
                                  : heroTaskIsPaused
                                  ? () => unawaited(_resumeTaskTimer(heroTask!))
                                  : heroTaskIsActive
                                  ? null
                                  : () => _handleFlowPrimaryAction(heroTask!))
                            : (nextSparkTask == null
                                  ? null
                                  : heroTaskTimerFinished
                                  ? () => unawaited(
                                      _completeFinishedTimerFromNudge(),
                                    )
                                  : heroTaskIsPaused
                                  ? () => unawaited(_resumeTaskTimer(heroTask!))
                                  : heroTaskIsActive
                                  ? null
                                  : () => _startFlowFromHome(nextSparkTask!)),
                      ),
                    if (!allDone && _today.isNotEmpty)
                      HomePlanPreviewSliver(
                        doneCount: completedTodayCount,
                        nowLabel: heroTask == null
                            ? null
                            : _repo.localizeTaskTitleForCurrentLocale(
                                heroTask.title,
                                category: heroTask.category,
                                taskId: heroTask.id,
                              ),
                        laterCount: max(
                          pendingTasks.length - (heroTask == null ? 0 : 1),
                          0,
                        ),
                        onTap: () => unawaited(
                          _openTodayPlanSheet(
                            doneTasks: completedTasks,
                            nextTask: heroTask,
                            laterTasks: heroTask == null
                                ? pendingTasks
                                : pendingTasks
                                      .where((task) => task.id != heroTask!.id)
                                      .toList(),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 82 + MediaQuery.of(context).padding.bottom,
                      ),
                    ),
                    if (_showLegacyHomeExtras) ...[
                      _buildInAppNudgesSliver(),
                      _buildStreakRescuePlanSliver(),
                      if (_showDebugTools && kDebugMode)
                        HomeDebugTimerSliver(
                          onPressed: _sendTaskTimerTest,
                          onAddThreeTasks: _debugAddThreeTasks,
                          onOpenDailyMood: _openDailyMoodSheetDebug,
                          instantEnabled: _debugInstantComplete,
                          onToggleInstant: (v) =>
                              _updateState(() => _debugInstantComplete = v),
                        ),
                      if (_poolError != null)
                        HomePoolErrorSliver(
                          message: 'Sunucuya baglanilamadi, tekrar dene.',
                          onRetry: _retryLoadPool,
                        ),
                      _buildEndOfDayReviewSliver(),
                    ],
                  ],
                ),
          if (!_loading && !_endDrawerOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BannerAdBar(onOpenRemoveAds: _openSubscribeSheet),
            ),
        ],
      ),
    );
  }
}

enum _RefreshChoice { rewarded, premium, cancel }

enum _SkipChoice { rewarded, premium, cancel }

enum _WeeklyReviewChoice { applySuggestion, later }
