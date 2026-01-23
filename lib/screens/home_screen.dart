import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../services/task_engine.dart';
import '../services/task_repository.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';
import '../services/premium_service.dart';
import '../services/theme_service.dart';
import 'task_add_sheet.dart';
import 'premium_perks_sheet.dart';
import 'stats_screen.dart';
import '../widgets/banner_ad_bar.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_header_card.dart';
import '../widgets/home_action_bar.dart';
import '../widgets/home_task_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _repo = TaskRepository();
  final _engine = TaskEngine();
  final _premium = PremiumService.instance;

  bool _loading = true;
  bool _refreshing = false;
  static const int _maxRefreshPerDay = 2;
  static const int _maxSkipsPerDay = 2;
  bool _rewardBusy = false;

  List<Task> _today = [];
  Map<String, bool> _completed = {};

  int _streak = 0;
  bool _reminderEnabled = false;
  bool _premiumActive = false;
  DateTime? _premiumUntil;
  DateTime? _noAdsUntil;
  int _dailyAddCount = 0;
  int _skipCount = 0;
  String _customCategory = 'mind';
  String _customDifficulty = 'easy';
  int _customDuration = 5;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _bootstrap() async {
    setState(() => _loading = true);

    await AdService.instance.preloadAll();

    final streak = await _repo.getStreakCount();
    final reminderEnabled = await _repo.getReminderEnabled();

    final pool = await _repo.loadPool();
    final completed = await _repo.getCompletedMap();

    final dateKey = _todayKey();
    final savedDate = await _repo.getSelectedDate();
    final lastSeenDate = await _repo.getLastSeenDate();
    final lastSeenIds = await _repo.getLastSeenTaskIds();

    final premiumUntilEpoch = await _premium.getPremiumUntilEpoch();
    final noAdsUntilEpoch = await _premium.getNoAdsUntilEpoch();
    final premiumActive = await _premium.isPremiumActive();
    await _premium.isNoAdsActive();
    final dailyAddCount = await _repo.getDailyCustomAddCount(dateKey);
    final skipCount = await _repo.getSkipCount(dateKey);

    // ✅ Premium durumuna göre pool filtreleme
    final effectivePool = premiumActive
        ? pool
        : pool.where((t) => !t.premiumOnly).toList();

    final avoidIds = lastSeenDate == dateKey ? <String>{} : lastSeenIds.toSet();

    final premiumUntil = premiumUntilEpoch == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(premiumUntilEpoch);
    final noAdsUntil = noAdsUntilEpoch == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(noAdsUntilEpoch);

    if (effectivePool.isEmpty) {
      if (!mounted) return;
      setState(() {
        _streak = streak;
        _reminderEnabled = reminderEnabled;
        _today = [];
        _completed = {};
        _premiumActive = premiumActive;
        _premiumUntil = premiumUntil;
        _noAdsUntil = noAdsUntil;
        _dailyAddCount = dailyAddCount;
        _skipCount = skipCount;
        _loading = false;
      });
      return;
    }

    List<Task> today;

    if (savedDate != dateKey) {
      final picked = _pickTasksNoRepeat(
        pool: effectivePool,
        count: 3,
        seedKey: dateKey,
        avoidIds: avoidIds,
      );
      await _repo.saveSelectedTasks(picked);
      await _repo.setSelectedDate(dateKey);
      await _repo.clearCompleted();
      await _updateLastSeen(dateKey: dateKey, tasks: picked);
      today = picked;
    } else {
      today = await _repo.getSelectedTasks(pool);
      if (!premiumActive) {
        today = today.where((t) => !t.premiumOnly).toList();
      }
      if (today.isEmpty) {
        final picked = _pickTasksNoRepeat(
          pool: effectivePool,
          count: 3,
          seedKey: dateKey,
          avoidIds: avoidIds,
        );
        await _repo.saveSelectedTasks(picked);
        await _updateLastSeen(dateKey: dateKey, tasks: picked);
        today = picked;
      }
    }

    if (!mounted) return;

    setState(() {
      _streak = streak;
      _reminderEnabled = reminderEnabled;
      _today = today;
      _completed = (savedDate != dateKey)
          ? {}
          : (completed.cast<String, bool>());
      _premiumActive = premiumActive;
      _premiumUntil = premiumUntil;
      _noAdsUntil = noAdsUntil;
      _dailyAddCount = dailyAddCount;
      _skipCount = skipCount;
      _loading = false;
    });
  }

  double get _progress {
    if (_today.isEmpty) return 0;
    final done = _today.where((t) => _completed[t.id] == true).length;
    return done / _today.length;
  }

  List<Task> _pickTasksNoRepeat({
    required List<Task> pool,
    required int count,
    required String seedKey,
    required Set<String> avoidIds,
  }) {
    final rng = Random(seedKey.hashCode);
    final filtered = pool.where((t) => !avoidIds.contains(t.id)).toList();
    final source = filtered.length >= count ? filtered : pool;
    source.shuffle(rng);
    return source.take(count).toList();
  }

  Future<void> _updateLastSeen({
    required String dateKey,
    required List<Task> tasks,
  }) async {
    final lastSeenDate = await _repo.getLastSeenDate();
    final existing = lastSeenDate == dateKey
        ? await _repo.getLastSeenTaskIds()
        : <String>[];
    final merged = {...existing, ...tasks.map((t) => t.id)}.toList();
    await _repo.saveLastSeenTaskIds(dateKey: dateKey, taskIds: merged);
  }

  String _categoryLabel(String c) {
    switch (c) {
      case 'body':
        return 'Body';
      case 'mind':
        return 'Mind';
      case 'growth':
        return 'Growth';
      case 'calm':
        return 'Calm';
      case 'health':
        return 'Health';
      default:
        return 'Focus';
    }
  }

  String _focusHint() {
    if (_today.isEmpty) return '';
    final counts = <String, int>{};
    for (final t in _today) {
      counts[t.category] = (counts[t.category] ?? 0) + 1;
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _categoryLabel(top.first.key);
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  final List<String> _successMessages = const [
    'Well done 💪',
    'Small step, big win.',
    'Keep going 🚀',
  ];

  String _pickSuccessMessage() {
    final rng = Random();
    return _successMessages[rng.nextInt(_successMessages.length)];
  }

  Future<void> _showSuccessPulse(String message) async {
    if (!mounted) return;

    final overlay = Overlay.of(context);

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          child: Center(
            child: FadeTransition(
              opacity: controller,
              child: ScaleTransition(
                scale: curved,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withOpacity(0.2),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded),
                      const SizedBox(width: 10),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
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

    overlay.insert(entry);
    await controller.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    await controller.reverse();
    entry.remove();
    controller.dispose();
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Contact us'),
          content: const SelectableText('mrahmiakpinar@gmial.com'),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                  const ClipboardData(text: 'mrahmiakpinar@gmial.com'),
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Email copied.')));
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatRemaining(DateTime? until) {
    if (until == null) return 'Inactive';
    final now = DateTime.now();
    if (!until.isAfter(now)) return 'Expired';
    final diff = until.difference(now);
    if (diff.inDays >= 1) {
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      return '${days}d ${hours}h';
    }
    if (diff.inHours >= 1) {
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      return '${hours}h ${mins}m';
    }
    return '${diff.inMinutes}m';
  }

  Future<void> _grantSpecialTask() async {
    if (_today.any((t) => t.isSpecial)) return;

    final special = Task(
      id: 'special_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Special Spark: try something new today',
      category: 'growth',
      isSpecial: true,
      aiSuggested: true,
      difficulty: 'medium',
      durationMinutes: 7,
    );

    final updated = [..._today, special];
    await _repo.saveSelectedTasks(updated);
    if (!mounted) return;
    setState(() {
      _today = updated;
      _completed[special.id] = false;
    });
  }

  Future<void> _refreshPremiumState() async {
    final premiumUntilEpoch = await _premium.getPremiumUntilEpoch();
    final noAdsUntilEpoch = await _premium.getNoAdsUntilEpoch();
    final premiumActive = await _premium.isPremiumActive();
    await _premium.isNoAdsActive();
    final premiumUntil = premiumUntilEpoch == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(premiumUntilEpoch);
    final noAdsUntil = noAdsUntilEpoch == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(noAdsUntilEpoch);

    if (!mounted) return;
    setState(() {
      _premiumActive = premiumActive;
      _premiumUntil = premiumUntil;
      _noAdsUntil = noAdsUntil;
    });
  }

  Future<bool> _ensureRewardedReady() async {
    if (AdService.instance.rewardedReady) return true;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading ad, please wait...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    int attempts = 0;
    while (!AdService.instance.rewardedReady && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }

    return AdService.instance.rewardedReady;
  }

  Future<void> _watchAdForReward({
    required Duration duration,
    required bool noAds,
  }) async {
    if (_rewardBusy) return;
    setState(() => _rewardBusy = true);
    final scheme = Theme.of(context).colorScheme;

    final ready = await _ensureRewardedReady();
    if (!ready) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not load ad. Try again later.'),
            backgroundColor: scheme.error,
          ),
        );
      }
      if (mounted) setState(() => _rewardBusy = false);
      return;
    }

    final unlocked = await AdService.instance.showRewardedToUnlock();
    if (!unlocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Watch the full ad to unlock.')),
        );
      }
      if (mounted) setState(() => _rewardBusy = false);
      return;
    }

    if (noAds) {
      await _premium.grantNoAds(duration);
    } else {
      await _premium.grantPremium(duration);
    }

    await _refreshPremiumState();
    await _grantSpecialTask();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(noAds ? 'No ads unlocked.' : 'Premium unlocked.'),
          backgroundColor: scheme.primary,
        ),
      );
      setState(() => _rewardBusy = false);
    }
  }

  Future<void> _saveAddedTask(Task task) async {
    final dateKey = _todayKey();
    final newCount = await _repo.addCustomTask(task, dateKey);
    final updated = [..._today, task];
    await _repo.saveSelectedTasks(updated);

    if (!mounted) return;
    setState(() {
      _today = updated;
      _completed[task.id] = false;
      _dailyAddCount = newCount;
      _customCategory = task.category;
      _customDifficulty = task.difficulty;
      _customDuration = task.durationMinutes;
    });
  }

  Future<bool> _addCustomTask(
    String title,
    String category,
    String difficulty,
    int durationMinutes,
  ) async {
    final premiumActive = await _premium.isPremiumActive();
    if (premiumActive != _premiumActive && mounted) {
      setState(() => _premiumActive = premiumActive);
    }

    final canAdd = premiumActive || _dailyAddCount < 1;
    if (!canAdd) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Daily limit reached.')));
      return false;
    }

    final task = Task(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      isCustom: true,
      difficulty: difficulty,
      durationMinutes: durationMinutes,
    );

    await _saveAddedTask(task);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task added.')));
    return true;
  }

  Future<void> _generateAiTask() async {
    final premiumActive = await _premium.isPremiumActive();
    if (!premiumActive) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI tasks are Premium only.')),
      );
      return;
    }

    const templates = {
      'mind': [
        'AI pick: write one clear priority',
        'AI pick: tidy one tiny space',
        'AI pick: send a kind message',
      ],
      'body': [
        'AI pick: 12 squats + stretch',
        'AI pick: 2 minutes of mobility',
        'AI pick: 15 wall push-ups',
      ],
      'growth': [
        'AI pick: learn one quick fact',
        'AI pick: 10-minute focused read',
        'AI pick: note one improvement idea',
      ],
      'calm': [
        'AI pick: 2-minute breath reset',
        'AI pick: 60 seconds of stillness',
        'AI pick: soften shoulders and jaw',
      ],
      'health': [
        'AI pick: drink water mindfully',
        'AI pick: stand and breathe deeply',
        'AI pick: short screen break',
      ],
    };

    final list = templates[_customCategory] ?? templates['mind']!;
    final rng = Random();
    final title = list[rng.nextInt(list.length)];
    final duration = 5 + rng.nextInt(8);

    final task = Task(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: _customCategory,
      isCustom: true,
      aiSuggested: true,
      difficulty: 'medium',
      durationMinutes: duration,
    );

    await _saveAddedTask(task);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI task added.')));
    }
  }

  Future<void> _generateAiMoodTasks(String mood) async {
    final premiumActive = await _premium.isPremiumActive();
    if (!premiumActive) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI tasks are Premium only.')),
      );
      return;
    }

    final templates = <String, List<Map<String, dynamic>>>{
      'stressed': [
        {
          'title': 'AI pick: 2-minute breath reset',
          'category': 'calm',
          'duration': 2,
          'difficulty': 'easy',
        },
        {
          'title': 'AI pick: relax jaw and shoulders',
          'category': 'calm',
          'duration': 3,
          'difficulty': 'easy',
        },
        {
          'title': 'AI pick: short gratitude note',
          'category': 'mind',
          'duration': 4,
          'difficulty': 'easy',
        },
      ],
      'low_energy': [
        {
          'title': 'AI pick: quick posture reset',
          'category': 'health',
          'duration': 4,
          'difficulty': 'easy',
        },
        {
          'title': 'AI pick: 12 squats + stretch',
          'category': 'body',
          'duration': 6,
          'difficulty': 'medium',
        },
        {
          'title': 'AI pick: drink water mindfully',
          'category': 'health',
          'duration': 2,
          'difficulty': 'easy',
        },
      ],
      'focus': [
        {
          'title': 'AI pick: 10-minute focus sprint',
          'category': 'growth',
          'duration': 10,
          'difficulty': 'medium',
        },
        {
          'title': 'AI pick: write one clear priority',
          'category': 'mind',
          'duration': 5,
          'difficulty': 'easy',
        },
        {
          'title': 'AI pick: tidy one tiny space',
          'category': 'mind',
          'duration': 6,
          'difficulty': 'easy',
        },
      ],
    };

    final list = templates[mood] ?? templates['focus']!;
    for (final item in list) {
      final task = Task(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}_${item['title']}',
        title: item['title'] as String,
        category: item['category'] as String,
        isCustom: true,
        aiSuggested: true,
        difficulty: item['difficulty'] as String,
        durationMinutes: item['duration'] as int,
      );
      await _saveAddedTask(task);
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI tasks added.')));
    }
  }

  Future<List<Task>> _loadEffectivePool() async {
    final pool = await _repo.loadPool();
    final premiumActive = await _premium.isPremiumActive();
    if (premiumActive != _premiumActive && mounted) {
      setState(() => _premiumActive = premiumActive);
    }
    return premiumActive ? pool : pool.where((t) => !t.premiumOnly).toList();
  }

  Future<void> _runRewardedAction({
    required Future<bool> Function() action,
    required String successMessage,
  }) async {
    if (_rewardBusy) return;
    setState(() => _rewardBusy = true);

    final ready = await _ensureRewardedReady();
    if (!ready) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load ad. Try again later.')),
        );
      }
      if (mounted) setState(() => _rewardBusy = false);
      return;
    }

    final unlocked = await AdService.instance.showRewardedToUnlock();
    if (!unlocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Watch the full ad to unlock.')),
        );
      }
      if (mounted) setState(() => _rewardBusy = false);
      return;
    }

    final ok = await action();
    if (!ok) {
      if (mounted) setState(() => _rewardBusy = false);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      setState(() => _rewardBusy = false);
    }
  }

  Future<bool> _skipOneTask({bool bypassLimit = true, String? taskId}) async {
    final dateKey = _todayKey();
    final skipCount = await _repo.getSkipCount(dateKey);
    if (!bypassLimit && skipCount >= _maxSkipsPerDay) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily skip limit reached.')),
        );
      }
      return false;
    }

    if (_today.isEmpty) return false;

    int idx;
    if (taskId != null) {
      idx = _today.indexWhere((t) => t.id == taskId);
      if (idx == -1) return false;
    } else {
      final targetIndex = _today.indexWhere((t) => _completed[t.id] != true);
      idx = targetIndex == -1 ? 0 : targetIndex;
    }
    final removed = _today[idx];

    final pool = await _loadEffectivePool();
    final lastSeenDate = await _repo.getLastSeenDate();
    final lastSeenIds = await _repo.getLastSeenTaskIds();
    final avoidIds = lastSeenDate == _todayKey()
        ? lastSeenIds.toSet()
        : <String>{};
    final currentIds = _today.map((t) => t.id).toSet();

    final picked = _pickTasksNoRepeat(
      pool: pool,
      count: 1,
      seedKey: 'skip_${DateTime.now().millisecondsSinceEpoch}',
      avoidIds: currentIds.union(avoidIds),
    );

    if (picked.isEmpty) return false;

    final updated = [..._today]..removeAt(idx);
    updated.insert(idx, picked.first);
    await _repo.saveSelectedTasks(updated);
    await _updateLastSeen(dateKey: _todayKey(), tasks: [picked.first]);
    final newSkipCount = await _repo.incrementSkipCount(dateKey);

    if (!mounted) return false;
    setState(() {
      _today = updated;
      _completed.remove(removed.id);
      _skipCount = newSkipCount;
    });
    return true;
  }

  Future<bool> _addExtraTask() async {
    final pool = await _loadEffectivePool();
    final lastSeenDate = await _repo.getLastSeenDate();
    final lastSeenIds = await _repo.getLastSeenTaskIds();
    final avoidIds = lastSeenDate == _todayKey()
        ? lastSeenIds.toSet()
        : <String>{};
    final currentIds = _today.map((t) => t.id).toSet();

    final picked = _pickTasksNoRepeat(
      pool: pool,
      count: 1,
      seedKey: 'extra_${DateTime.now().millisecondsSinceEpoch}',
      avoidIds: currentIds.union(avoidIds),
    );

    if (picked.isEmpty) return false;

    final updated = [..._today, picked.first];
    await _repo.saveSelectedTasks(updated);
    await _updateLastSeen(dateKey: _todayKey(), tasks: [picked.first]);

    if (!mounted) return false;
    setState(() {
      _today = updated;
      _completed[picked.first.id] = false;
    });
    return true;
  }

  Future<bool> _recoverStreak() async {
    final lastDone = await _repo.getLastCompletedDate();
    if (lastDone == null) return false;

    final todayKey = _todayKey();
    if (lastDone == todayKey) return false;

    final yesterdayKey = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));

    if (lastDone == yesterdayKey) return false;
    if (_streak <= 0) return false;

    await _repo.setLastCompletedDate(yesterdayKey);
    return true;
  }

  Future<void> _openAddTaskSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TaskAddSheet(
          canAddTask: _premiumActive || _dailyAddCount < 1,
          addLimitLabel: _premiumActive
              ? 'Premium: unlimited tasks'
              : 'Free: 1 task/day ($_dailyAddCount/1)',
          initialCategory: _customCategory,
          initialDifficulty: _customDifficulty,
          initialDurationMinutes: _customDuration,
          premiumActive: _premiumActive,
          onAdd: _addCustomTask,
          onGenerateAi: _generateAiTask,
          onGenerateAiMood: _generateAiMoodTasks,
        );
      },
    );
  }

  Future<void> _openPerksSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PremiumPerksSheet(
          rewardBusy: _rewardBusy,
          premiumStatus: _formatRemaining(_premiumUntil),
          noAdsStatus: _formatRemaining(_noAdsUntil),
          onWatchPremium: () => _watchAdForReward(
            duration: const Duration(minutes: 30),
            noAds: false,
          ),
          onWatchNoAds: () =>
              _watchAdForReward(duration: const Duration(days: 1), noAds: true),
          onSkipTask: () => _runRewardedAction(
            action: () => _skipOneTask(bypassLimit: false),
            successMessage: 'Task skipped.',
          ),
          onExtraTask: () => _runRewardedAction(
            action: _addExtraTask,
            successMessage: 'Extra task added.',
          ),
          onRecoverStreak: () => _runRewardedAction(
            action: _recoverStreak,
            successMessage: 'Streak recovered.',
          ),
        );
      },
    );
  }

  Future<void> _toggle(Task t) async {
    final newVal = !(_completed[t.id] ?? false);
    setState(() => _completed[t.id] = newVal);
    await _repo.saveCompletedMap(_completed);

    if (newVal) {
      await HapticFeedback.lightImpact();
      await _showSuccessPulse(_pickSuccessMessage());
      await _repo.incrementCompleted(t.category);
    }

    final done = _today.where((x) => _completed[x.id] == true).length;
    final allDone = _today.isNotEmpty && done == _today.length;
    if (!allDone) return;

    final todayKey = _todayKey();
    final lastDone = await _repo.getLastCompletedDate();

    if (lastDone == todayKey) {
      if (mounted) _showCompletedSheet();
      return;
    }

    final yesterdayKey = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));

    final newStreak = (lastDone == yesterdayKey) ? (_streak + 1) : 1;

    await _repo.setStreakCount(newStreak);
    await _repo.setLastCompletedDate(todayKey);
    await _repo.setBestStreakIfHigher(newStreak);

    if (!mounted) return;

    setState(() => _streak = newStreak);

    if (AdService.instance.interstitialReady) {
      await AdService.instance.showInterstitialIfAllowed(dateKey: todayKey);
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (mounted) _showCompletedSheet();
  }

  Future<void> _refreshTasks() async {
    final scheme = Theme.of(context).colorScheme;
    final dateKey = _todayKey();
    final refreshCount = await _repo.getRefreshCount(dateKey);
    if (refreshCount >= _maxRefreshPerDay) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily refresh limit reached.')),
        );
      }
      return;
    }

    _log("🔄 REFRESH: Starting...");

    if (_refreshing) {
      _log("⏳ REFRESH: Already refreshing...");
      return;
    }

    setState(() => _refreshing = true);

    if (!AdService.instance.rewardedReady) {
      _log("⏳ REFRESH: Waiting for ad to load...");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Loading ad, please wait..."),
            duration: Duration(seconds: 2),
          ),
        );
      }

      int attempts = 0;
      while (!AdService.instance.rewardedReady && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
        _log("⏳ REFRESH: Waiting... attempt $attempts/10");
      }

      if (!AdService.instance.rewardedReady) {
        _log("❌ REFRESH: Ad failed to load after waiting");
        setState(() => _refreshing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Couldn't load ad. Please try again."),
              backgroundColor: scheme.error,
            ),
          );
        }
        return;
      }
    }

    _log("✅ REFRESH: Showing rewarded ad...");
    final unlocked = await AdService.instance.showRewardedToUnlock();
    _log("🎬 REFRESH: Ad result = $unlocked");

    if (!unlocked) {
      _log("❌ REFRESH: User didn't complete ad");
      setState(() => _refreshing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Watch the complete ad to unlock new tasks."),
          ),
        );
      }
      return;
    }

    _log("🎯 REFRESH: Loading new tasks...");
    final pool = await _repo.loadPool();
    final lastSeenDate = await _repo.getLastSeenDate();
    final lastSeenIds = await _repo.getLastSeenTaskIds();
    _log("📦 REFRESH: Pool size = ${pool.length}");

    // ✅ Premium durumuna göre pool'u filtrele
    final premiumActive = await _premium.isPremiumActive();
    final effectivePool = premiumActive
        ? pool
        : pool.where((t) => !t.premiumOnly).toList();
    if (effectivePool.isEmpty) {
      setState(() => _refreshing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No tasks available.')));
      }
      return;
    }

    final currentIds = _today.map((t) => t.id).toSet();
    final avoidIds = lastSeenDate == dateKey ? lastSeenIds.toSet() : <String>{};
    _log("🔒 REFRESH: Current task IDs = $currentIds");

    final availablePool = effectivePool
        .where((t) => !currentIds.contains(t.id))
        .where((t) => !avoidIds.contains(t.id))
        .toList();
    _log("📋 REFRESH: Available pool size = ${availablePool.length}");

    if (availablePool.length < 3) {
      _log("⚠️ REFRESH: Not enough tasks in pool");
      setState(() => _refreshing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Not enough different tasks available!"),
            backgroundColor: scheme.secondary,
          ),
        );
      }
      return;
    }

    final picked = _engine.pickDailyTasks(
      pool: availablePool,
      count: 3,
      seedKey: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
    );

    final special = Task(
      id: 'special_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Special Spark: try something new today',
      category: 'growth',
      isSpecial: true,
      aiSuggested: true,
      difficulty: 'medium',
      durationMinutes: 7,
    );

    final pickedWithSpecial = [...picked, special];

    _log("🎲 REFRESH: Picked task IDs = ${picked.map((t) => t.id).toList()}");

    await _repo.saveSelectedTasks(pickedWithSpecial);
    await _repo.clearCompleted();
    await _updateLastSeen(dateKey: dateKey, tasks: pickedWithSpecial);
    await _repo.incrementRefreshCount(dateKey);
    _log("💾 REFRESH: Saved to repository");

    if (!mounted) {
      _log("❌ REFRESH: Widget not mounted");
      return;
    }

    setState(() {
      _today = pickedWithSpecial;
      _completed = {};
      _refreshing = false;
    });

    _log("✨ REFRESH: UI updated with new tasks");
    _log(
      "📝 REFRESH: New tasks = ${pickedWithSpecial.map((t) => t.title).toList()}",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✨ New tasks loaded! (${pickedWithSpecial.length})"),
        duration: const Duration(seconds: 2),
        backgroundColor: scheme.primary,
      ),
    );
  }

  Future<void> _toggleReminder() async {
    final newVal = !_reminderEnabled;
    final scheme = Theme.of(context).colorScheme;
    setState(() => _reminderEnabled = newVal);
    await _repo.setReminderEnabled(newVal);

    try {
      if (newVal) {
        await NotificationService.instance.scheduleDailyReminder(
          hour: 9,
          minute: 0,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Daily reminder enabled (09:00).")),
          );
        }
      } else {
        await NotificationService.instance.cancelDailyReminder();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Daily reminder disabled.")),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _reminderEnabled = !newVal);
      await _repo.setReminderEnabled(!newVal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Notification permission not available."),
          backgroundColor: scheme.error,
        ),
      );
    }
  }

  void _showCompletedSheet() {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              const Icon(Icons.auto_awesome_rounded, size: 42),
              const SizedBox(height: 10),
              const Text(
                "All done for today!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                "Streak: $_streak day${_streak == 1 ? '' : 's'}",
                style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Nice!"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _today.where((t) => _completed[t.id] == true).length;
    final dateLabel = DateFormat('EEE, MMM d').format(DateTime.now());
    final focus = _focusHint();

    return Scaffold(
      bottomNavigationBar: BannerAdBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
                      onOpenStats: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StatsScreen()),
                      ),
                      onContact: _showContactDialog,
                      onToggleTheme: () => ThemeService.instance.toggle(),
                      onToggleReminder: _toggleReminder,
                      onRefresh: _refreshing ? null : _refreshTasks,
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: HomeHeaderCard(
                    progress: _progress,
                    doneCount: doneCount,
                    totalCount: _today.length,
                    streak: _streak,
                    focusLabel: focus,
                    dateLabel: dateLabel,
                  ),
                ),
                SliverToBoxAdapter(
                  child: HomeActionBar(
                    onAddTask: _openAddTaskSheet,
                    onUnlockPerks: _openPerksSheet,
                  ),
                ),
                HomeTaskListSliver(
                  tasks: _today,
                  completed: _completed,
                  canSkip: _skipCount < _maxSkipsPerDay,
                  onToggle: _toggle,
                  onSkip: (task) =>
                      _skipOneTask(bypassLimit: false, taskId: task.id),
                ),
              ],
            ),
    );
  }
}
