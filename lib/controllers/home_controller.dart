import 'dart:math';

import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../app_strings.dart';
import '../models/task.dart';
import '../models/level_unlocks.dart';
import '../services/ad_service.dart';
import '../services/locale_service.dart';
import '../services/notification_service.dart';
import '../services/premium_service.dart';
import '../services/task_quality_engine.dart';
import '../services/task_engine.dart';
import '../services/task_repository.dart';
import '../services/task_localizer.dart';

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
    required this.adaptiveTaskCount,
    required this.adaptiveDifficultyDelta,
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
  final int adaptiveTaskCount;
  final int adaptiveDifficultyDelta;
  final String? poolError;
}

class AdaptiveDailyPlan {
  const AdaptiveDailyPlan({
    required this.taskCount,
    required this.difficultyDelta,
    required this.completionRate,
    required this.observedDays,
    required this.avgCompletedPerActiveDay,
  });

  final int taskCount;
  final int difficultyDelta;
  final double completionRate;
  final int observedDays;
  final double avgCompletedPerActiveDay;
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
  static const int _starterSparkSeconds = 60;
  static const String _starterSparkPrefix = 'starter_';

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

  Future<double> getRecentCompletionRate({
    int days = 7,
    int assumedTasksPerDay = 3,
  }) {
    return _repo.getRecentCompletionRate(
      days: days,
      assumedTasksPerDay: assumedTasksPerDay,
    );
  }

  int adaptationDeltaFromCompletionRate(double rate) {
    if (rate >= 0.85) return 1;
    if (rate <= 0.45) return -1;
    return 0;
  }

  Future<AdaptiveDailyPlan> resolveAdaptiveDailyPlan({
    int days = 7,
    int baseTaskCount = 3,
  }) async {
    final safeDays = days.clamp(3, 30);
    final safeBaseTaskCount = baseTaskCount.clamp(2, 5);
    final history = await _repo.getDailyHistory(days: safeDays);
    if (history.isEmpty) {
      return const AdaptiveDailyPlan(
        taskCount: 3,
        difficultyDelta: 0,
        completionRate: 0.0,
        observedDays: 0,
        avgCompletedPerActiveDay: 0.0,
      );
    }

    final observedDays = history.length.clamp(0, safeDays);
    final totalCompleted = history.values.fold<int>(
      0,
      (acc, value) => acc + value,
    );
    final avgCompletedPerActiveDay = observedDays <= 0
        ? 0.0
        : totalCompleted / observedDays;
    final completionRate = await getRecentCompletionRate(
      days: safeDays,
      assumedTasksPerDay: safeBaseTaskCount,
    );

    // We smooth adaptation with active-day coverage to avoid overreacting
    // when the user only has 1-2 data points in the last week.
    final activeCoverage = (observedDays / safeDays).clamp(0.0, 1.0);
    final observedScore =
        (completionRate * 0.7) +
        ((avgCompletedPerActiveDay / safeBaseTaskCount).clamp(0.0, 1.0) * 0.3);
    const priorScore = 0.55;
    final confidence = activeCoverage.clamp(0.35, 1.0);
    final score =
        (observedScore * confidence) + (priorScore * (1 - confidence));

    int taskCount;
    int delta;
    if (score >= 0.82 && avgCompletedPerActiveDay >= 2.8) {
      taskCount = 5;
      delta = 1;
    } else if (score >= 0.65) {
      taskCount = 4;
      delta = 1;
    } else if (score >= 0.42) {
      taskCount = 3;
      delta = 0;
    } else {
      taskCount = 2;
      delta = -1;
    }

    return AdaptiveDailyPlan(
      taskCount: taskCount,
      difficultyDelta: delta,
      completionRate: completionRate,
      observedDays: observedDays,
      avgCompletedPerActiveDay: avgCompletedPerActiveDay,
    );
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

  bool _isStarterSpark(Task task) => task.id.startsWith(_starterSparkPrefix);

  bool _sameTaskOrder(List<Task> left, List<Task> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i].id != right[i].id) return false;
    }
    return true;
  }

  String _starterTitleForCategory(String category) {
    return TaskLocalizer.localizeTitle(
      'Notice your breath for 60 seconds',
      category: category,
      taskId: 'starter_preview',
    );
  }

  Task _starterSparkTask({required String dateKey, required String category}) {
    return Task(
      id: '$_starterSparkPrefix$dateKey',
      title: _starterTitleForCategory(category),
      category: category,
      isCustom: true,
      difficulty: 'easy',
      durationMinutes: 1,
      durationSeconds: _starterSparkSeconds,
      isSpecial: true,
    );
  }

  List<Task> ensureStarterSpark({
    required List<Task> tasks,
    required String dateKey,
  }) {
    if (tasks.isEmpty) return tasks;

    final starterIndex = tasks.indexWhere(_isStarterSpark);
    if (starterIndex == 0 &&
        tasks.first.totalDurationSeconds == _starterSparkSeconds) {
      return tasks;
    }

    final category = starterIndex >= 0
        ? tasks[starterIndex].category
        : tasks.first.category;
    final withoutStarter = tasks
        .where((task) => !_isStarterSpark(task))
        .toList(growable: false);
    final withStarter = <Task>[
      _starterSparkTask(dateKey: dateKey, category: category),
      ...withoutStarter,
    ];
    final limit = tasks.length.clamp(1, 99);
    return withStarter.take(limit).toList(growable: false);
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
    final adaptivePlan = await resolveAdaptiveDailyPlan(days: 7);
    final adaptiveDelta = adaptivePlan.difficultyDelta;
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
        adaptiveTaskCount: adaptivePlan.taskCount,
        adaptiveDifficultyDelta: adaptiveDelta,
        poolError: poolError,
      );
    }

    List<Task> today;

    if (savedDate != dateKey) {
      final picked = pickTasksNoRepeat(
        pool: effectivePool,
        count: adaptivePlan.taskCount,
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
          count: adaptivePlan.taskCount,
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

    final starterAdjusted = ensureStarterSpark(tasks: today, dateKey: dateKey);
    if (!_sameTaskOrder(today, starterAdjusted)) {
      today = starterAdjusted;
      await _repo.saveSelectedTasks(today);
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
      adaptiveTaskCount: adaptivePlan.taskCount,
      adaptiveDifficultyDelta: adaptiveDelta,
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
      final durationDelta = delta;
      final nextDuration = (task.durationMinutes + durationDelta).clamp(2, 20);
      return Task(
        id: task.id,
        title: task.title,
        category: task.category,
        isCustom: task.isCustom,
        difficulty: nextDifficulty,
        durationMinutes: nextDuration,
        durationSeconds: task.durationSeconds,
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
    final freeSparkSlotLimit = await _repo.getFreeSparkSlotLimit(
      premiumActive: false,
    );
    if (!premiumActive && dailyAddCount >= freeSparkSlotLimit) {
      final sparkWord = freeSparkSlotLimit == 1 ? 'spark' : 'sparks';
      return AddTaskResponse.failure(
        AddTaskFailure.limitReached,
        message: 'Daily free limit reached ($freeSparkSlotLimit $sparkWord).',
      );
    }

    final quality = TaskQualityEngine.sanitize(
      rawTitle: title,
      category: category,
      durationSeconds: durationMinutes.clamp(1, 120) * 60,
      strictUserInput: true,
    );
    if (!quality.isValidForCustomInput) {
      return AddTaskResponse.failure(
        AddTaskFailure.lowQualityTitle,
        message: quality.feedback,
      );
    }

    final task = Task(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: quality.title,
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
    final title = TaskLocalizer.localizeTitle(list[rng.nextInt(list.length)]);
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
        title: TaskLocalizer.localizeTitle(item['title'] as String),
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

  Future<TaskPackResponse> applyTaskPack({
    required String packId,
    required List<Task> current,
    required int dailyAddCount,
  }) async {
    final templates = _taskPackTemplates[packId];
    return _applyTemplatePack(
      packId: packId,
      templates: templates,
      current: current,
      dailyAddCount: dailyAddCount,
      unknownPackMessage: 'Unknown task pack.',
    );
  }

  Future<List<CreatorPackCatalogItem>> getCreatorPackCatalog({
    CreatorPackCatalogSort sort = CreatorPackCatalogSort.popular,
    int currentLevel = 1,
  }) async {
    final categoryCounts = await _repo.getCategoryCounts();
    final items = _creatorTaskPacks
        .map(
          (pack) => CreatorPackCatalogItem(
            id: pack.id,
            title: pack.localizedTitle(),
            creatorName: pack.creatorName,
            description: pack.localizedDescription(),
            toneKey: pack.toneKey,
            installs: pack.installs,
            rating: pack.rating,
            ratingCount: pack.ratingCount,
            isNew: pack.isNew,
            releaseOrder: pack.releaseOrder,
            requiredLevel: pack.requiredLevel,
            isUnlocked: currentLevel >= pack.requiredLevel,
            forYouScore: _resolveCreatorPackForYouScore(
              pack: pack,
              categoryCounts: categoryCounts,
            ),
          ),
        )
        .toList(growable: false);
    items.sort(
      (a, b) => _compareCreatorPackCatalogItem(a: a, b: b, sort: sort),
    );
    return items;
  }

  int _compareCreatorPackCatalogItem({
    required CreatorPackCatalogItem a,
    required CreatorPackCatalogItem b,
    required CreatorPackCatalogSort sort,
  }) {
    switch (sort) {
      case CreatorPackCatalogSort.popular:
        final installsCompare = b.installs.compareTo(a.installs);
        if (installsCompare != 0) return installsCompare;
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        break;
      case CreatorPackCatalogSort.newest:
        final newCompare = (b.isNew ? 1 : 0).compareTo(a.isNew ? 1 : 0);
        if (newCompare != 0) return newCompare;
        final releaseCompare = b.releaseOrder.compareTo(a.releaseOrder);
        if (releaseCompare != 0) return releaseCompare;
        break;
      case CreatorPackCatalogSort.forYou:
        final scoreCompare = b.forYouScore.compareTo(a.forYouScore);
        if (scoreCompare != 0) return scoreCompare;
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        break;
    }
    return a.title.compareTo(b.title);
  }

  double _resolveCreatorPackForYouScore({
    required _CreatorTaskPackDefinition pack,
    required Map<String, int> categoryCounts,
  }) {
    final totalCompleted = categoryCounts.values.fold<int>(
      0,
      (acc, value) => acc + value,
    );
    final normalizedInstalls =
        (pack.installs.clamp(0, 5000).toDouble()) / 5000.0;
    final normalizedRating = (pack.rating / 5.0).clamp(0.0, 1.0);
    final freshnessBoost = pack.isNew ? 1.0 : 0.0;

    if (totalCompleted <= 0) {
      return (normalizedRating * 0.55) +
          (normalizedInstalls * 0.35) +
          (freshnessBoost * 0.1);
    }

    var affinity = 0.0;
    for (final category in pack.categories) {
      final count = categoryCounts[category] ?? 0;
      affinity += count / totalCompleted;
    }
    affinity = pack.categories.isEmpty ? 0 : affinity / pack.categories.length;

    return (affinity.clamp(0.0, 1.0) * 0.62) +
        (normalizedInstalls * 0.2) +
        (normalizedRating * 0.13) +
        (freshnessBoost * 0.05);
  }

  Future<TaskPackResponse> applyCreatorPack({
    required String creatorPackId,
    required List<Task> current,
    required int dailyAddCount,
    required int currentLevel,
  }) async {
    _CreatorTaskPackDefinition? pack;
    for (final item in _creatorTaskPacks) {
      if (item.id == creatorPackId) {
        pack = item;
        break;
      }
    }
    if (pack != null && currentLevel < pack.requiredLevel) {
      return TaskPackResponse.failure(
        TaskPackFailure.levelLocked,
        message: LevelUnlocks.unlockedAtLabel(
          level: pack.requiredLevel,
          featureName: pack.localizedTitle(),
        ),
      );
    }
    return _applyTemplatePack(
      packId: creatorPackId,
      templates: pack?.tasks,
      current: current,
      dailyAddCount: dailyAddCount,
      unknownPackMessage: 'Unknown creator pack.',
    );
  }

  Future<TaskPackResponse> _applyTemplatePack({
    required String packId,
    required List<_TaskPackTemplate>? templates,
    required List<Task> current,
    required int dailyAddCount,
    required String unknownPackMessage,
  }) async {
    if (templates == null || templates.isEmpty) {
      return TaskPackResponse.failure(
        TaskPackFailure.unknownPack,
        message: unknownPackMessage,
      );
    }

    final premiumActive = await _premium.isPremiumActive();
    final freeSparkSlotLimit = await _repo.getFreeSparkSlotLimit(
      premiumActive: false,
    );
    var remainingFreeSlots = premiumActive
        ? 999
        : (freeSparkSlotLimit - dailyAddCount).clamp(0, 999);
    if (!premiumActive && remainingFreeSlots <= 0) {
      final sparkWord = freeSparkSlotLimit == 1 ? 'spark' : 'sparks';
      return TaskPackResponse.failure(
        TaskPackFailure.limitReached,
        message: 'Daily free limit reached ($freeSparkSlotLimit $sparkWord).',
      );
    }

    var updated = current;
    var newCount = dailyAddCount;
    final added = <Task>[];
    for (var i = 0; i < templates.length; i++) {
      if (!premiumActive && remainingFreeSlots <= 0) break;

      final item = templates[i];
      final localizedTitle = item.localizedTitle();
      final duplicate = updated.any(
        (task) =>
            task.category == item.category &&
            task.title.toLowerCase().trim() ==
                localizedTitle.toLowerCase().trim(),
      );
      if (duplicate) continue;

      final task = Task(
        id: 'pack_${packId}_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: localizedTitle,
        category: item.category,
        isCustom: true,
        difficulty: item.difficulty,
        durationMinutes: item.durationMinutes,
        durationSeconds: item.durationSeconds,
      );
      final append = await _appendTask(task: task, current: updated);
      updated = append.updated;
      newCount = append.newCount;
      added.add(task);
      if (!premiumActive) {
        remainingFreeSlots -= 1;
      }
    }

    if (added.isEmpty) {
      return TaskPackResponse.failure(
        TaskPackFailure.noUniqueTask,
        message: 'These pack tasks are already in your list.',
      );
    }

    return TaskPackResponse.success(
      updated: updated,
      newCount: newCount,
      added: added,
      premiumActive: premiumActive,
      packId: packId,
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

  Future<bool> showInterstitialAfterTaskCompletion({
    required String dateKey,
    required int completedToday,
  }) async {
    return _adService.showInterstitialAfterTaskCompletion(
      dateKey: dateKey,
      completedToday: completedToday,
    );
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

class _TaskPackTemplate {
  const _TaskPackTemplate({
    required this.title,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    this.durationSeconds,
  });

  final String title;
  final String category;
  final String difficulty;
  final int durationMinutes;
  final int? durationSeconds;

  String localizedTitle([String? languageCode]) {
    return AppLocalizations.lookup(
      (languageCode ?? LocaleService.instance.effectiveLanguageCode)
          .toLowerCase(),
      title,
    );
  }
}

const Map<String, List<_TaskPackTemplate>> _taskPackTemplates = {
  'focus': [
    _TaskPackTemplate(
      title: 'Clear distractions for 2 minutes',
      category: 'mind',
      difficulty: 'easy',
      durationMinutes: 2,
    ),
    _TaskPackTemplate(
      title: 'Write your top focus target',
      category: 'growth',
      difficulty: 'easy',
      durationMinutes: 3,
    ),
    _TaskPackTemplate(
      title: 'Run a 5-minute deep focus sprint',
      category: 'mind',
      difficulty: 'medium',
      durationMinutes: 5,
    ),
  ],
  'sleep': [
    _TaskPackTemplate(
      title: 'No screens for the next 10 minutes',
      category: 'health',
      difficulty: 'easy',
      durationMinutes: 10,
    ),
    _TaskPackTemplate(
      title: 'Do 4-7-8 breathing for 3 minutes',
      category: 'calm',
      difficulty: 'easy',
      durationMinutes: 3,
    ),
    _TaskPackTemplate(
      title: 'Prepare tomorrow with 2 bullet points',
      category: 'mind',
      difficulty: 'easy',
      durationMinutes: 4,
    ),
  ],
  'stress': [
    _TaskPackTemplate(
      title: 'Box breathe for 2 minutes',
      category: 'calm',
      difficulty: 'easy',
      durationMinutes: 2,
    ),
    _TaskPackTemplate(
      title: 'Release shoulder tension for 90 seconds',
      category: 'body',
      difficulty: 'easy',
      durationMinutes: 2,
      durationSeconds: 90,
    ),
    _TaskPackTemplate(
      title: 'Write one thing you can control',
      category: 'mind',
      difficulty: 'easy',
      durationMinutes: 3,
    ),
  ],
};

class CreatorPackCatalogItem {
  const CreatorPackCatalogItem({
    required this.id,
    required this.title,
    required this.creatorName,
    required this.description,
    required this.toneKey,
    required this.installs,
    required this.rating,
    required this.ratingCount,
    required this.isNew,
    required this.releaseOrder,
    required this.requiredLevel,
    required this.isUnlocked,
    required this.forYouScore,
  });

  final String id;
  final String title;
  final String creatorName;
  final String description;
  final String toneKey;
  final int installs;
  final double rating;
  final int ratingCount;
  final bool isNew;
  final int releaseOrder;
  final int requiredLevel;
  final bool isUnlocked;
  final double forYouScore;
}

class _CreatorTaskPackDefinition {
  const _CreatorTaskPackDefinition({
    required this.id,
    required this.title,
    required this.creatorName,
    required this.description,
    required this.toneKey,
    required this.installs,
    required this.rating,
    required this.ratingCount,
    required this.isNew,
    required this.releaseOrder,
    required this.requiredLevel,
    required this.categories,
    required this.tasks,
  });

  final String id;
  final String title;
  final String creatorName;
  final String description;
  final String toneKey;
  final int installs;
  final double rating;
  final int ratingCount;
  final bool isNew;
  final int releaseOrder;
  final int requiredLevel;
  final List<String> categories;
  final List<_TaskPackTemplate> tasks;

  String localizedTitle([String? languageCode]) {
    return AppLocalizations.lookup(
      (languageCode ?? LocaleService.instance.effectiveLanguageCode)
          .toLowerCase(),
      title,
    );
  }

  String localizedDescription([String? languageCode]) {
    return AppLocalizations.lookup(
      (languageCode ?? LocaleService.instance.effectiveLanguageCode)
          .toLowerCase(),
      description,
    );
  }
}

enum CreatorPackCatalogSort { popular, newest, forYou }

const List<_CreatorTaskPackDefinition> _creatorTaskPacks = [
  _CreatorTaskPackDefinition(
    id: 'creator_ayla_focus_flow',
    title: 'Focus Flow',
    creatorName: 'Ayla',
    description: 'Creator-curated pack for deep work blocks.',
    toneKey: 'focus_pack',
    installs: 1820,
    rating: 4.8,
    ratingCount: 362,
    isNew: false,
    releaseOrder: 2,
    requiredLevel: 2,
    categories: ['mind', 'growth'],
    tasks: [
      _TaskPackTemplate(
        title: 'Set one clear focus outcome',
        category: 'mind',
        difficulty: 'easy',
        durationMinutes: 3,
      ),
      _TaskPackTemplate(
        title: 'Do a 12-minute deep work sprint',
        category: 'growth',
        difficulty: 'medium',
        durationMinutes: 12,
      ),
      _TaskPackTemplate(
        title: 'Write one distraction to avoid',
        category: 'mind',
        difficulty: 'easy',
        durationMinutes: 2,
      ),
    ],
  ),
  _CreatorTaskPackDefinition(
    id: 'creator_emir_sleep_reset',
    title: 'Sleep Reset',
    creatorName: 'Emir',
    description: 'Simple evening wind-down steps from a creator routine.',
    toneKey: 'sleep_pack',
    installs: 1435,
    rating: 4.7,
    ratingCount: 281,
    isNew: false,
    releaseOrder: 1,
    requiredLevel: 2,
    categories: ['calm', 'health', 'mind'],
    tasks: [
      _TaskPackTemplate(
        title: 'Dim lights and reduce noise for 5 minutes',
        category: 'calm',
        difficulty: 'easy',
        durationMinutes: 5,
      ),
      _TaskPackTemplate(
        title: 'Write tomorrow first task',
        category: 'mind',
        difficulty: 'easy',
        durationMinutes: 3,
      ),
      _TaskPackTemplate(
        title: 'No phone and breathe for 4 minutes',
        category: 'health',
        difficulty: 'easy',
        durationMinutes: 4,
      ),
    ],
  ),
  _CreatorTaskPackDefinition(
    id: 'creator_lina_stress_offload',
    title: 'Stress Offload',
    creatorName: 'Lina',
    description: 'Quick body + breath routine to downshift stress.',
    toneKey: 'stress_pack',
    installs: 1210,
    rating: 4.6,
    ratingCount: 214,
    isNew: true,
    releaseOrder: 5,
    requiredLevel: 3,
    categories: ['calm', 'body', 'mind'],
    tasks: [
      _TaskPackTemplate(
        title: 'Slow exhale breathing for 2 minutes',
        category: 'calm',
        difficulty: 'easy',
        durationMinutes: 2,
      ),
      _TaskPackTemplate(
        title: 'Neck and shoulder release for 3 minutes',
        category: 'body',
        difficulty: 'easy',
        durationMinutes: 3,
      ),
      _TaskPackTemplate(
        title: 'Note one pressure you can postpone',
        category: 'mind',
        difficulty: 'easy',
        durationMinutes: 3,
      ),
    ],
  ),
  _CreatorTaskPackDefinition(
    id: 'creator_nora_morning_reset',
    title: 'Morning Reset',
    creatorName: 'Nora',
    description: 'A low-friction start to regain momentum in under 10 minutes.',
    toneKey: 'focus_pack',
    installs: 980,
    rating: 4.7,
    ratingCount: 168,
    isNew: true,
    releaseOrder: 6,
    requiredLevel: 4,
    categories: ['mind', 'body'],
    tasks: [
      _TaskPackTemplate(
        title: 'Open curtains and take 5 deep breaths',
        category: 'body',
        difficulty: 'easy',
        durationMinutes: 2,
      ),
      _TaskPackTemplate(
        title: 'Write one tiny win target for today',
        category: 'mind',
        difficulty: 'easy',
        durationMinutes: 3,
      ),
      _TaskPackTemplate(
        title: 'Do a 4-minute start sprint on your top task',
        category: 'growth',
        difficulty: 'easy',
        durationMinutes: 4,
      ),
    ],
  ),
  _CreatorTaskPackDefinition(
    id: 'creator_kaan_walk_boost',
    title: 'Walk Boost',
    creatorName: 'Kaan',
    description: 'Body-first micro routine to break mental fog quickly.',
    toneKey: 'stress_pack',
    installs: 865,
    rating: 4.5,
    ratingCount: 119,
    isNew: false,
    releaseOrder: 3,
    requiredLevel: 3,
    categories: ['body', 'health', 'calm'],
    tasks: [
      _TaskPackTemplate(
        title: 'Walk for 4 minutes without your phone',
        category: 'body',
        difficulty: 'easy',
        durationMinutes: 4,
      ),
      _TaskPackTemplate(
        title: 'Drink water and relax jaw tension',
        category: 'health',
        difficulty: 'easy',
        durationMinutes: 2,
      ),
      _TaskPackTemplate(
        title: 'Take 90-second long exhales',
        category: 'calm',
        difficulty: 'easy',
        durationMinutes: 2,
        durationSeconds: 90,
      ),
    ],
  ),
  _CreatorTaskPackDefinition(
    id: 'creator_mina_evening_shutdown',
    title: 'Evening Shutdown',
    creatorName: 'Mina',
    description: 'Close the day with light planning and calm transition.',
    toneKey: 'sleep_pack',
    installs: 740,
    rating: 4.6,
    ratingCount: 108,
    isNew: true,
    releaseOrder: 7,
    requiredLevel: 4,
    categories: ['mind', 'calm', 'health'],
    tasks: [
      _TaskPackTemplate(
        title: 'Write tomorrow top priority in one line',
        category: 'mind',
        difficulty: 'easy',
        durationMinutes: 2,
      ),
      _TaskPackTemplate(
        title: 'Do gentle neck release for 2 minutes',
        category: 'body',
        difficulty: 'easy',
        durationMinutes: 2,
      ),
      _TaskPackTemplate(
        title: 'Sit quietly with slow breathing for 3 minutes',
        category: 'calm',
        difficulty: 'easy',
        durationMinutes: 3,
      ),
    ],
  ),
];

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

enum AddTaskFailure { limitReached, lowQualityTitle }

class AddTaskResponse {
  const AddTaskResponse._(this.data, this.failure, this.message);

  final AddTaskResult? data;
  final AddTaskFailure? failure;
  final String? message;

  bool get success => data != null;

  factory AddTaskResponse.success(AddTaskResult data) =>
      AddTaskResponse._(data, null, null);

  factory AddTaskResponse.failure(AddTaskFailure failure, {String? message}) =>
      AddTaskResponse._(null, failure, message);
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

enum TaskPackFailure { unknownPack, limitReached, noUniqueTask, levelLocked }

class TaskPackResponse {
  const TaskPackResponse._(
    this.updated,
    this.newCount,
    this.added,
    this.premiumActive,
    this.packId,
    this.failure,
    this.message,
  );

  final List<Task>? updated;
  final int? newCount;
  final List<Task>? added;
  final bool? premiumActive;
  final String? packId;
  final TaskPackFailure? failure;
  final String? message;

  bool get success => updated != null && newCount != null && added != null;

  factory TaskPackResponse.success({
    required List<Task> updated,
    required int newCount,
    required List<Task> added,
    required bool premiumActive,
    required String packId,
  }) => TaskPackResponse._(
    updated,
    newCount,
    added,
    premiumActive,
    packId,
    null,
    null,
  );

  factory TaskPackResponse.failure(
    TaskPackFailure failure, {
    String? message,
  }) => TaskPackResponse._(null, null, null, null, null, failure, message);
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
