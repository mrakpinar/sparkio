import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:sparkio/widgets/modern_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/task.dart';
import '../models/weekly_plan.dart';
import '../services/task_engine.dart';
import '../services/task_repository.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';
import '../services/premium_service.dart';
import '../services/theme_service.dart';
import '../services/analytics_service.dart';
import '../services/streak_service.dart';
import '../services/home_widget_service.dart';
import '../controllers/home_controller.dart';
import 'task_add_sheet.dart';
import 'premium_perks_sheet.dart';
import 'premium_purchase_sheet.dart';
import 'package:sparkio/screens/stats_screen.dart';
import 'badges_screen.dart';
import '../widgets/banner_ad_bar.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_task_list.dart';
import '../widgets/streak_share_card.dart';
import '../widgets/home_badge_unlock_overlay.dart';
import '../widgets/home_skeleton.dart';
import '../widgets/daily_mood_sheet.dart';
import '../widgets/home_header_sliver.dart';
import '../widgets/home_debug_timer_sliver.dart';
import '../widgets/home_pool_error_sliver.dart';
import '../widgets/home_all_done_sliver.dart';
import '../widgets/weekly_plan_sheet.dart';
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
  static const bool _useStatsScreenshotPreset = bool.fromEnvironment(
    'SCREENSHOT_STATS_PRESET',
    defaultValue: false,
  );
  static const bool _useHomeScreenshotPreset = bool.fromEnvironment(
    'SCREENSHOT_HOME_PRESET',
    defaultValue: false,
  );
  static const int _headerPresetDoneCount = 2;
  static const int _headerPresetTotalCount = 3;
  static const int _headerPresetTodayCompleted = 3;
  static const int _headerPresetStreak = 6;
  static const int _headerPresetWeeklyDone = 3;
  static const int _headerPresetWeeklyTarget = 5;
  static const String _headerPresetFocusLabel = 'Calm';
  static const String _headerPresetAdaptiveLabel = 'Adaptive mode: easier';
  static const int _badgeGoalCount = 10;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static final Uri _instagramUri = Uri.parse(
    'https://www.instagram.com/sparkio.app/',
  );
  final _repo = TaskRepository();
  final _engine = TaskEngine();
  final _premium = PremiumService.instance;
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
  String? _poolError;

  List<Task> _today = [];
  Map<String, bool> _completed = {};
  String? _allDoneShownKey;

  int _streak = 0;
  int _todayCompleted = 0;
  bool _reminderEnabled = false;
  bool _premiumActive = false;
  DateTime? _premiumUntil;
  DateTime? _noAdsUntil;
  int _dailyAddCount = 0;
  int _adaptiveDifficultyDelta = 0;
  int _earnedBadgesCount = 0;
  String _profileName = '';
  String _weeklyWeekKey = '';
  Map<String, int> _weeklyTargets = {};
  Map<String, int> _weeklyDone = {};
  String _customCategory = 'mind';
  String _customDifficulty = 'easy';
  int _customDuration = 5;
  Task? _activeTimerTask;
  Duration _activeTimerRemaining = Duration.zero;
  bool _activeTimerFinished = false;
  Timer? _activeTimerTicker;
  Timer? _premiumTicker;

  @override
  void initState() {
    super.initState();
    _startPremiumTicker();
    _bootstrap();
  }

  @override
  void dispose() {
    _activeTimerTicker?.cancel();
    _premiumTicker?.cancel();
    super.dispose();
  }

  // Helper method to allow extensions to update state
  void _updateState(void Function() fn) {
    setState(fn);
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
    final doneCount = _today.where((t) => _completed[t.id] == true).length;
    final remainingCount = _today.where((t) => _completed[t.id] != true).length;
    final allDone = _today.isNotEmpty && remainingCount == 0;
    final dateLabel = DateFormat('EEE, MMM d').format(DateTime.now());
    final focus = _controller.focusHint(_today);
    final weeklyDone = _weeklyDone.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final weeklyTarget = _weeklyTargets.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final screenshotHeaderMode =
        _useHomeScreenshotPreset || _useStatsScreenshotPreset;
    final headerDoneCount = screenshotHeaderMode
        ? _headerPresetDoneCount
        : doneCount;
    final headerTotalCount = screenshotHeaderMode
        ? _headerPresetTotalCount
        : _today.length;
    final headerProgress = screenshotHeaderMode
        ? (_headerPresetDoneCount / _headerPresetTotalCount)
        : _progress;
    final headerTodayCompleted = screenshotHeaderMode
        ? _headerPresetTodayCompleted
        : _todayCompleted;
    final headerStreak = screenshotHeaderMode ? _headerPresetStreak : _streak;
    final headerFocusLabel = screenshotHeaderMode
        ? _headerPresetFocusLabel
        : focus;
    final headerAdaptiveLabel = screenshotHeaderMode
        ? _headerPresetAdaptiveLabel
        : _adaptiveDifficultyLabel();
    final headerWeeklyDone = screenshotHeaderMode
        ? _headerPresetWeeklyDone
        : weeklyDone;
    final headerWeeklyTarget = screenshotHeaderMode
        ? _headerPresetWeeklyTarget
        : weeklyTarget;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      bottomNavigationBar: BannerAdBar(onOpenRemoveAds: _openSubscribeSheet),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-add-task',
        onPressed: () {
          HapticFeedback.lightImpact();
          _openAddTaskSheet();
        },
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: const Color(0xFF06B6D4),
        splashColor: const Color(0xFF67E8F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, size: 24, color: Colors.white),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Spark',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            Text(
              '+ New Habit',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 10,
                color: scheme.onPrimary.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
      endDrawer: _buildEndDrawer(),
      body: _loading
          ? const HomeSkeleton()
          : CustomScrollView(
              slivers: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeService.instance.mode,
                  builder: (context, mode, _) {
                    final isDark = mode == ThemeMode.dark;
                    return HomeAppBar(
                      userName: _profileName.isEmpty ? 'Friend' : _profileName,
                      isDark: isDark,
                      reminderEnabled: _reminderEnabled,
                      refreshing: _refreshing,
                      onContact: _openInstagramContact,
                      onToggleTheme: () => ThemeService.instance.toggle(),
                      onToggleReminder: _toggleReminder,
                      onSendTestNotification: _sendTestNotification,
                      onRefresh: _refreshing ? null : _refreshTasks,
                      onOpenPerks: _openPerksSheet,
                      onOpenMenu: _openMenu,
                    );
                  },
                ),
                HomeHeaderSliver(
                  progress: headerProgress,
                  doneCount: headerDoneCount,
                  totalCount: headerTotalCount,
                  todayCompleted: headerTodayCompleted,
                  streak: headerStreak,
                  focusLabel: headerFocusLabel,
                  dateLabel: dateLabel,
                  onShare: _openShareSheet,
                  onOpenStats: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  ),
                  adaptiveLabel: headerAdaptiveLabel,
                  weeklyDone: headerWeeklyDone,
                  weeklyTarget: headerWeeklyTarget,
                  onOpenWeeklyPlan: () => _openWeeklyPlanSheet(),
                ),
                if (_showDebugTools && kDebugMode)
                  HomeDebugTimerSliver(
                    onPressed: _sendTaskTimerTest,
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
                if (allDone) const HomeAllDoneSliver(),
                HomeTaskListSliver(
                  tasks: _today,
                  completed: _completed,
                  activeTimerTaskId: _activeTimerTask?.id,
                  activeTimerRemaining: _activeTimerTask != null
                      ? _activeTimerRemaining
                      : null,
                  activeTimerDone: _activeTimerFinished,
                  onCancelTimer: (task) => _cancelTaskTimer(task),
                  onCompleteTimer: _activeTimerFinished
                      ? (task) async {
                          if (_activeTimerTask == null ||
                              _activeTimerTask!.id != task.id) {
                            return;
                          }
                          await _cancelTaskTimer(task);
                          setState(() => _completed[task.id] = true);
                          await _repo.saveCompletedMap(_completed);
                          await _markTaskDone(task);
                          await _applyStreakIfAllDone();
                        }
                      : null,
                  canSkip: true,
                  onToggle: _toggle,
                  onSkip: (task) =>
                      _skipOneTask(bypassLimit: false, taskId: task.id),
                ),
              ],
            ),
    );
  }
}

enum _RefreshChoice { rewarded, premium, cancel }

enum _SkipChoice { rewarded, premium, cancel }
