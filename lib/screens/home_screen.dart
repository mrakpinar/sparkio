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
import 'package:sparkio/widgets/modern_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/task.dart';
import '../services/task_engine.dart';
import '../services/task_repository.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';
import '../services/premium_service.dart';
import '../services/theme_service.dart';
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
import '../widgets/home_header_sliver.dart';
import '../widgets/home_action_sliver.dart';
import '../widgets/home_debug_timer_sliver.dart';
import '../widgets/home_pool_error_sliver.dart';
import '../widgets/home_active_timer_sliver.dart';
import '../widgets/home_all_done_sliver.dart';
part 'home_screen_methods.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static final Uri _instagramUri = Uri.parse(
    'https://www.instagram.com/sparkio.app/',
  );
  final _repo = TaskRepository();
  final _engine = TaskEngine();
  final _premium = PremiumService.instance;
  final _adService = AdService.instance;
  final _notifications = NotificationService.instance;
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
  static const int _maxRefreshPerDay = 2;
  static const int _maxSkipsPerDay = 2;
  bool _rewardBusy = false;
  bool _poolErrorShown = false;
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
  String _customCategory = 'mind';
  String _customDifficulty = 'easy';
  int _customDuration = 5;
  Task? _activeTimerTask;
  Duration _activeTimerRemaining = Duration.zero;
  bool _activeTimerFinished = false;
  Timer? _activeTimerTicker;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _activeTimerTicker?.cancel();
    super.dispose();
  }

  // Helper method to allow extensions to update state
  void _updateState(void Function() fn) {
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _today.where((t) => _completed[t.id] == true).length;
    final remainingCount = _today.where((t) => _completed[t.id] != true).length;
    final allDone = _today.isNotEmpty && remainingCount == 0;
    final dateLabel = DateFormat('EEE, MMM d').format(DateTime.now());
    final focus = _controller.focusHint(_today);

    final premiumActiveNow =
        _premiumUntil != null && _premiumUntil!.isAfter(DateTime.now());
    final premiumRemaining = premiumActiveNow
        ? 'Remaining: ${_formatRemaining(_premiumUntil)}'
        : 'Expired - tap to renew';

    return Scaffold(
      key: _scaffoldKey,
      bottomNavigationBar: BannerAdBar(),
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
                      dateLabel: dateLabel,
                      isDark: isDark,
                      reminderEnabled: _reminderEnabled,
                      refreshing: _refreshing,
                      onContact: _openInstagramContact,
                      onToggleTheme: () => ThemeService.instance.toggle(),
                      onToggleReminder: _toggleReminder,
                      onSendTestNotification: _sendTestNotification,
                      onRefresh: _refreshing ? null : _refreshTasks,
                      onOpenMenu: _openMenu,
                    );
                  },
                ),
                HomeHeaderSliver(
                  progress: _progress,
                  doneCount: doneCount,
                  totalCount: _today.length,
                  todayCompleted: _todayCompleted,
                  streak: _streak,
                  focusLabel: focus,
                  dateLabel: dateLabel,
                  onShare: _openShareSheet,
                  onOpenStats: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  ),
                ),
                HomeActionSliver(
                  onAddTask: _openAddTaskSheet,
                  onUnlockPerks: _openPerksSheet,
                  premiumActive: premiumActiveNow,
                  premiumRemaining: premiumRemaining,
                  onStatusTap: premiumActiveNow ? null : _openPerksSheet,
                ),
                if (kDebugMode)
                  HomeDebugTimerSliver(onPressed: _sendTaskTimerTest),
                if (_poolError != null)
                  HomePoolErrorSliver(
                    message: 'Sunucuya baglanilamadi, tekrar dene.',
                    onRetry: _retryLoadPool,
                  ),
                if (_activeTimerTask != null)
                  HomeActiveTimerSliver(
                    task: _activeTimerTask!,
                    remaining: _activeTimerRemaining,
                    done: _activeTimerFinished,
                    onCancel: () => _cancelTaskTimer(_activeTimerTask!),
                    onComplete: _activeTimerFinished
                        ? () async {
                            final task = _activeTimerTask!;
                            await _cancelTaskTimer(task);
                            setState(() => _completed[task.id] = true);
                            await _repo.saveCompletedMap(_completed);
                            await _markTaskDone(task);
                          }
                        : null,
                  ),
                if (allDone) const HomeAllDoneSliver(),
                HomeTaskListSliver(
                  tasks: _today,
                  completed: _completed,
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
