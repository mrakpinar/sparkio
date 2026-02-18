import 'dart:math';

import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/task.dart';
import '../services/ad_service.dart';
import '../services/notification_service.dart';
import '../services/premium_service.dart';
import '../services/task_engine.dart';
import '../services/task_repository.dart';

class HomeBootstrapResult {
  const HomeBootstrapResult({
    required this.streak,
    required this.reminderEnabled,
    required this.today,
    required this.completed,
    required this.todayCompleted,
    required this.premiumActive,
    required this.premiumUntil,
    required this.noAdsUntil,
    required this.dailyAddCount,
    required this.skipCount,
    required this.poolError,
  });

  final int streak;
  final bool reminderEnabled;
  final List<Task> today;
  final Map<String, bool> completed;
  final int todayCompleted;
  final bool premiumActive;
  final DateTime? premiumUntil;
  final DateTime? noAdsUntil;
  final int dailyAddCount;
  final int skipCount;
  final String? poolError;
}

class HomeController {
  HomeController({
    required TaskRepository repo,
    required TaskEngine engine,
    required PremiumService premium,
    required AdService adService,
    required NotificationService notifications,
  }) : _repo = repo,
       _engine = engine,
       _premium = premium,
       _adService = adService,
       _notifications = notifications;

  final TaskRepository _repo;
  final TaskEngine _engine;
  final PremiumService _premium;
  final AdService _adService;
  final NotificationService _notifications;

  Future<void> syncNotificationTopics({required bool premiumActive}) async {
    final messaging = FirebaseMessaging.instance;
    if (premiumActive) {
      await messaging.subscribeToTopic('premium_users');
      await messaging.unsubscribeFromTopic('free_users');
    } else {
      await messaging.subscribeToTopic('free_users');
      await messaging.unsubscribeFromTopic('premium_users');
    }
  }

  Future<double> getRecentCompletionRate({int days = 7}) {
    return _repo.getRecentCompletionRate(days: days);
  }

  int adaptationDeltaFromCompletionRate(double rate) {
    if (rate >= 0.85) return 1;
    if (rate <= 0.45) return -1;
    return 0;
  }

  String todayKey([DateTime? date]) =>
      DateFormat('yyyy-MM-dd').format(date ?? DateTime.now());

  String categoryLabel(String category) {
    switch (category) {
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

  String focusHint(List<Task> today) {
    if (today.isEmpty) return '';
    final counts = <String, int>{};
    for (final task in today) {
      counts[task.category] = (counts[task.category] ?? 0) + 1;
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return categoryLabel(top.first.key);
  }

  List<Task> pickTasksNoRepeat({
    required List<Task> pool,
    required int count,
    required String seedKey,
    required Set<String> avoidIds,
    Map<String, int>? weeklyTargets,
    Map<String, int>? weeklyDone,
  }) {
    final filtered = pool.where((t) => !avoidIds.contains(t.id)).toList();
    final source = filtered.length >= count ? filtered : pool;
    return _engine.pickDailyTasks(
      pool: source,
      count: count,
      seedKey: seedKey,
      weeklyTargets: weeklyTargets,
      weeklyDone: weeklyDone,
    );
  }

  Future<void> updateLastSeen({
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

  Future<HomeBootstrapResult> bootstrap() async {
    final streak = await _repo.getStreakCount();
    final reminderEnabled = await _repo.getReminderEnabled();

    final pool = await _repo.loadPool();
    final poolError = _repo.lastPoolError;
    final completed = await _repo.getCompletedMap();

    final dateKey = todayKey();
    final savedDate = await _repo.getSelectedDate();
    final lastSeenDate = await _repo.getLastSeenDate();
    final lastSeenIds = await _repo.getLastSeenTaskIds();
    final todayCompleted = await _repo.getDailyCompleted(dateKey);
    final recentCompletionRate = await getRecentCompletionRate(days: 7);
    final adaptiveDelta = adaptationDeltaFromCompletionRate(
      recentCompletionRate,
    );
    final weekKey = _repo.currentWeekKey();
    final weeklyPlan = await _repo.getWeeklyPlan(weekKey: weekKey);
    final weeklyProgress = await _repo.getWeeklyProgress(weekKey: weekKey);

    final premiumUntilEpoch = await _premium.getPremiumUntilEpoch();
    final noAdsUntilEpoch = await _premium.getNoAdsUntilEpoch();
    final premiumActive = await _premium.isPremiumActive();
    await _premium.isNoAdsActive();
    final dailyAddCount = await _repo.getDailyCustomAddCount(dateKey);
    final skipCount = await _repo.getSkipCount(dateKey);

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
      return HomeBootstrapResult(
        streak: streak,
        reminderEnabled: reminderEnabled,
        today: const [],
        completed: const {},
        todayCompleted: todayCompleted,
        premiumActive: premiumActive,
        premiumUntil: premiumUntil,
        noAdsUntil: noAdsUntil,
        dailyAddCount: dailyAddCount,
        skipCount: skipCount,
        poolError: poolError,
      );
    }

    List<Task> today;

    if (savedDate != dateKey) {
      final picked = pickTasksNoRepeat(
        pool: effectivePool,
        count: 3,
        seedKey: dateKey,
        avoidIds: avoidIds,
        weeklyTargets: weeklyPlan?.targets,
        weeklyDone: weeklyProgress.done,
      );
      final adjusted = applyDifficultyDelta(
        tasks: picked,
        delta: adaptiveDelta,
      );
      await _repo.saveSelectedTasks(adjusted);
      await _repo.setSelectedDate(dateKey);
      await _repo.clearCompleted();
      await updateLastSeen(dateKey: dateKey, tasks: adjusted);
      today = adjusted;
    } else {
      today = await _repo.getSelectedTasks(pool);
      if (!premiumActive) {
        today = today.where((t) => !t.premiumOnly).toList();
      }
      if (today.isEmpty) {
        final picked = pickTasksNoRepeat(
          pool: effectivePool,
          count: 3,
          seedKey: dateKey,
          avoidIds: avoidIds,
          weeklyTargets: weeklyPlan?.targets,
          weeklyDone: weeklyProgress.done,
        );
        final adjusted = applyDifficultyDelta(
          tasks: picked,
          delta: adaptiveDelta,
        );
        await _repo.saveSelectedTasks(adjusted);
        await updateLastSeen(dateKey: dateKey, tasks: adjusted);
        today = adjusted;
      }
    }

    return HomeBootstrapResult(
      streak: streak,
      reminderEnabled: reminderEnabled,
      today: today,
      completed: (savedDate != dateKey) ? {} : completed.cast<String, bool>(),
      todayCompleted: todayCompleted,
      premiumActive: premiumActive,
      premiumUntil: premiumUntil,
      noAdsUntil: noAdsUntil,
      dailyAddCount: dailyAddCount,
      skipCount: skipCount,
      poolError: poolError,
    );
  }

  List<Task> pickDailyTasks({
    required List<Task> pool,
    required int count,
    required String seedKey,
    Map<String, int>? weeklyTargets,
    Map<String, int>? weeklyDone,
  }) {
    return _engine.pickDailyTasks(
      pool: pool,
      count: count,
      seedKey: seedKey,
      weeklyTargets: weeklyTargets,
      weeklyDone: weeklyDone,
    );
  }

  List<Task> applyDifficultyDelta({
    required List<Task> tasks,
    required int delta,
  }) {
    if (delta == 0) return tasks;
    return tasks.map((task) {
      if (task.isCustom || task.isSpecial) return task;
      final current = task.difficulty.toLowerCase();
      final nextDifficulty = _shiftDifficulty(current, delta);
      final durationDelta = delta > 0 ? 1 : -1;
      final nextDuration = (task.durationMinutes + durationDelta).clamp(2, 20);
      return Task(
        id: task.id,
        title: task.title,
        category: task.category,
        isCustom: task.isCustom,
        difficulty: nextDifficulty,
        durationMinutes: nextDuration,
        aiSuggested: task.aiSuggested,
        premiumOnly: task.premiumOnly,
        isSpecial: task.isSpecial,
      );
    }).toList();
  }

  String _shiftDifficulty(String difficulty, int delta) {
    const levels = ['easy', 'medium', 'hard'];
    final index = levels.indexOf(difficulty);
    final current = index < 0 ? 0 : index;
    final shifted = (current + delta).clamp(0, levels.length - 1);
    return levels[shifted];
  }

  Future<bool> isPremiumActive() async {
    return _premium.isPremiumActive();
  }

  Future<EffectivePoolResult> loadEffectivePool({
    required bool currentPremiumActive,
  }) async {
    final pool = await _repo.loadPool();
    final poolError = _repo.lastPoolError;
    final premiumActive = await _premium.isPremiumActive();
    final effective = premiumActive
        ? pool
        : pool.where((t) => !t.premiumOnly).toList();
    return EffectivePoolResult(
      pool: effective,
      premiumActive: premiumActive,
      premiumChanged: premiumActive != currentPremiumActive,
      poolError: poolError,
    );
  }

  Future<AddTaskResponse> addCustomTaskWithLimit({
    required String title,
    required String category,
    required String difficulty,
    required int durationMinutes,
    required List<Task> current,
    required int dailyAddCount,
  }) async {
    final premiumActive = await _premium.isPremiumActive();
    if (!premiumActive && dailyAddCount >= 1) {
      return AddTaskResponse.failure(AddTaskFailure.limitReached);
    }

    final task = Task(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      isCustom: true,
      difficulty: difficulty,
      durationMinutes: durationMinutes,
    );

    final result = await _appendTask(task: task, current: current);
    return AddTaskResponse.success(
      result.copyWith(premiumActive: premiumActive),
    );
  }

  Future<AiTaskResponse> generateAiTask({
    required String category,
    required List<Task> current,
  }) async {
    final premiumActive = await _premium.isPremiumActive();
    if (!premiumActive) {
      return AiTaskResponse.failure(AiTaskFailure.premiumRequired);
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

    final list = templates[category] ?? templates['mind']!;
    final rng = Random();
    final title = list[rng.nextInt(list.length)];
    final duration = 5 + rng.nextInt(8);

    final task = Task(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      isCustom: true,
      aiSuggested: true,
      difficulty: 'medium',
      durationMinutes: duration,
    );

    final result = await _appendTask(task: task, current: current);
    return AiTaskResponse.success(
      updated: result.updated,
      newCount: result.newCount,
      added: [task],
    );
  }

  Future<AiTaskResponse> generateAiMoodTasks({
    required String mood,
    required List<Task> current,
  }) async {
    final premiumActive = await _premium.isPremiumActive();
    if (!premiumActive) {
      return AiTaskResponse.failure(AiTaskFailure.premiumRequired);
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
    var updated = current;
    var newCount = 0;
    final added = <Task>[];

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
      final result = await _appendTask(task: task, current: updated);
      updated = result.updated;
      newCount = result.newCount;
      added.add(task);
    }

    return AiTaskResponse.success(
      updated: updated,
      newCount: newCount,
      added: added,
    );
  }

  Future<void> preloadAds() async {
    await _adService.preloadAll();
  }

  Future<bool> ensureRewardedReady({int maxAttempts = 10}) async {
    if (_adService.rewardedReady) return true;
    int attempts = 0;
    while (!_adService.rewardedReady && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }
    return _adService.rewardedReady;
  }

  Future<bool> showRewardedToUnlock() async {
    return _adService.showRewardedToUnlock();
  }

  bool get interstitialReady => _adService.interstitialReady;

  Future<void> showInterstitialIfAllowed({required String dateKey}) async {
    await _adService.showInterstitialIfAllowed(dateKey: dateKey);
  }

  Future<void> showInterstitialOnLaunch() async {
    await _adService.showInterstitialOnLaunch();
  }

  Future<bool> applyReminderEnabled(bool enabled) async {
    try {
      if (enabled) {
        final allowed = await _notifications.areNotificationsEnabled();
        if (!allowed) return false;
        final scheduled = await _notifications.scheduleDailyReminder(
          hour: 12,
          minute: 0,
        );
        return scheduled;
      } else {
        await _notifications.cancelDailyReminder();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<PremiumStatus> loadPremiumStatus() async {
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
    return PremiumStatus(
      premiumActive: premiumActive,
      premiumUntil: premiumUntil,
      noAdsUntil: noAdsUntil,
    );
  }

  Future<RewardResult> watchAdForReward({
    required Duration duration,
    required bool noAds,
  }) async {
    final ready = await ensureRewardedReady();
    if (!ready) return RewardResult.failure(RewardFailure.notReady);

    final unlocked = await showRewardedToUnlock();
    if (!unlocked) return RewardResult.failure(RewardFailure.notCompleted);

    if (noAds) {
      await _premium.grantNoAds(duration);
    } else {
      await _premium.grantPremium(duration);
    }

    final status = await loadPremiumStatus();
    return RewardResult.success(status);
  }

  Future<AddTaskResult> _appendTask({
    required Task task,
    required List<Task> current,
  }) async {
    final dateKey = todayKey();
    final newCount = await _repo.addCustomTask(task, dateKey);
    final updated = [...current, task];
    await _repo.saveSelectedTasks(updated);
    return AddTaskResult(
      task: task,
      updated: updated,
      newCount: newCount,
      premiumActive: await _premium.isPremiumActive(),
    );
  }
}

class PremiumStatus {
  const PremiumStatus({
    required this.premiumActive,
    required this.premiumUntil,
    required this.noAdsUntil,
  });

  final bool premiumActive;
  final DateTime? premiumUntil;
  final DateTime? noAdsUntil;
}

class EffectivePoolResult {
  const EffectivePoolResult({
    required this.pool,
    required this.premiumActive,
    required this.premiumChanged,
    required this.poolError,
  });

  final List<Task> pool;
  final bool premiumActive;
  final bool premiumChanged;
  final String? poolError;
}

enum AddTaskFailure { limitReached }

class AddTaskResponse {
  const AddTaskResponse._(this.data, this.failure);

  final AddTaskResult? data;
  final AddTaskFailure? failure;

  bool get success => data != null;

  factory AddTaskResponse.success(AddTaskResult data) =>
      AddTaskResponse._(data, null);

  factory AddTaskResponse.failure(AddTaskFailure failure) =>
      AddTaskResponse._(null, failure);
}

class AddTaskResult {
  const AddTaskResult({
    required this.task,
    required this.updated,
    required this.newCount,
    required this.premiumActive,
  });

  final Task task;
  final List<Task> updated;
  final int newCount;
  final bool premiumActive;

  AddTaskResult copyWith({bool? premiumActive}) {
    return AddTaskResult(
      task: task,
      updated: updated,
      newCount: newCount,
      premiumActive: premiumActive ?? this.premiumActive,
    );
  }
}

enum AiTaskFailure { premiumRequired }

class AiTaskResponse {
  const AiTaskResponse._(this.updated, this.newCount, this.added, this.failure);

  final List<Task>? updated;
  final int? newCount;
  final List<Task>? added;
  final AiTaskFailure? failure;

  bool get success => updated != null;

  factory AiTaskResponse.success({
    required List<Task> updated,
    required int newCount,
    required List<Task> added,
  }) => AiTaskResponse._(updated, newCount, added, null);

  factory AiTaskResponse.failure(AiTaskFailure failure) =>
      AiTaskResponse._(null, null, null, failure);
}

enum RewardFailure { notReady, notCompleted }

class RewardResult {
  const RewardResult._(this.status, this.failure);

  final PremiumStatus? status;
  final RewardFailure? failure;

  bool get success => status != null;

  factory RewardResult.success(PremiumStatus status) =>
      RewardResult._(status, null);

  factory RewardResult.failure(RewardFailure failure) =>
      RewardResult._(null, failure);
}
