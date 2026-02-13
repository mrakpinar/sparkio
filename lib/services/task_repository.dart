import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/weekly_plan.dart';

class TaskRepository {
  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');
  static const _kSelectedTasks = 'selected_tasks_v1';
  static const _kSelectedDate = 'selected_date_v1';
  static const _kCompletedMap = 'completed_map_v1';
  static const _kStreakCount = 'streak_count_v1';
  static const _kLastCompletedDate = 'last_completed_date_v1';
  static const _kReminderEnabled = 'reminder_enabled_v1';
  static const _kCustomTasks = 'custom_tasks_v1';
  static const _kCustomAddDate = 'custom_add_date_v1';
  static const _kCustomAddCount = 'custom_add_count_v1';
  static const _kLastSeenDate = 'last_seen_date_v1';
  static const _kLastSeenIds = 'last_seen_ids_v1';
  static const _kRefreshCountDate = 'refresh_count_date_v1';
  static const _kRefreshCount = 'refresh_count_v1';
  static const _kSkipCountDate = 'skip_count_date_v1';
  static const _kSkipCount = 'skip_count_v1';
  static const _kDailyCompletedDate = 'daily_completed_date_v1';
  static const _kDailyCompletedCount = 'daily_completed_count_v1';
  static const _kDailyHistory = 'daily_completed_history_v1';
  static const _kTotalCompleted = 'total_completed_v1';
  static const _kBestStreak = 'best_streak_v1';
  static const _kCategoryCounts = 'category_counts_v1';
  static const _kRemoteCache = 'remote_task_cache_v1';
  static const _kLastCompletedTitle = 'last_completed_title_v1';
  static const _kLastCompletedCategory = 'last_completed_category_v1';
  static const _kLastCompletedAt = 'last_completed_at_v1';
  static const _kBadges = 'earned_badges_v1';
  static const _kDailyMoodDate = 'daily_mood_date_v1';
  static const _kDailyMoodValue = 'daily_mood_value_v1';
  static const _kActiveTimerTaskId = 'active_timer_task_id_v1';
  static const _kActiveTimerTaskTitle = 'active_timer_task_title_v1';
  static const _kActiveTimerEndAtMs = 'active_timer_end_at_ms_v1';
  static const _kWeeklyPlan = 'weekly_plan_v1';
  static const _kWeeklyProgress = 'weekly_progress_v1';

  String? _lastPoolError;
  String? get lastPoolError => _lastPoolError;

  static const List<Task> _offlineFallback = [
    Task(
      id: 'offline_1',
      title: 'Take 3 deep breaths',
      category: 'calm',
      difficulty: 'easy',
      durationMinutes: 2,
    ),
    Task(
      id: 'offline_2',
      title: 'Drink a glass of water',
      category: 'health',
      difficulty: 'easy',
      durationMinutes: 3,
    ),
    Task(
      id: 'offline_3',
      title: 'Stretch your shoulders',
      category: 'body',
      difficulty: 'easy',
      durationMinutes: 4,
    ),
    Task(
      id: 'offline_4',
      title: 'Write one priority for today',
      category: 'mind',
      difficulty: 'easy',
      durationMinutes: 5,
    ),
    Task(
      id: 'offline_5',
      title: 'Tidy a tiny space',
      category: 'growth',
      difficulty: 'easy',
      durationMinutes: 6,
    ),
  ];

  Future<List<Task>> loadPool() async {
    _lastPoolError = null;
    final remote = await _loadRemoteTasks();
    if (remote.isEmpty) {
      _lastPoolError ??=
          'No tasks available right now. Please try again later.';
    }
    final custom = await getCustomTasks();
    return [...remote, ...custom];
  }

  Future<List<Task>> _loadRemoteTasks() async {
    try {
      final snap = await _queryRemoteTasks(
        () => _db
            .collection('tasks')
            .where('active', isEqualTo: true)
            .get(const GetOptions(source: Source.serverAndCache)),
      );
      if (snap.docs.isEmpty) {
        // Fallback: fetch without filter in case "active" is missing/typed differently.
        final allSnap = await _queryRemoteTasks(
          () => _db
              .collection('tasks')
              .limit(500)
              .get(const GetOptions(source: Source.serverAndCache)),
        );
        if (allSnap.docs.isNotEmpty) {
          final tasks = allSnap.docs
              .map((doc) {
                final data = doc.data();
                data['id'] ??= doc.id;
                final active = data['active'];
                final isActive =
                    active == null ||
                    active == true ||
                    (active is String && active.toLowerCase() == 'true');
                return isActive ? Task.fromMap(data) : null;
              })
              .whereType<Task>()
              .toList();
          if (tasks.isNotEmpty) {
            await _saveRemoteCache(tasks);
            return tasks;
          }
        }
        final cached = await _getRemoteCache();
        if (cached.isNotEmpty) {
          _lastPoolError = 'Could not refresh tasks. Showing last saved tasks.';
          return cached;
        }
        _lastPoolError = 'No active tasks found on the server.';
        return [];
      }
      final tasks = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] ??= doc.id;
        return Task.fromMap(data);
      }).toList();
      await _saveRemoteCache(tasks);
      return tasks;
    } catch (e) {
      final cached = await _getRemoteCache();
      if (cached.isNotEmpty) {
        _lastPoolError = 'Could not refresh tasks. Showing last saved tasks.';
        return cached;
      }
      _lastPoolError = _friendlyFirestoreError(e);
      if (e is FirebaseException && e.code == 'unavailable') {
        return _offlineFallback;
      }
      return [];
    }
  }

  // No explicit active field on Task; handled while mapping fallback docs.

  Future<QuerySnapshot<Map<String, dynamic>>> _queryRemoteTasks(
    Future<QuerySnapshot<Map<String, dynamic>>> Function() query,
  ) async {
    const delays = [200, 500, 1200];
    for (var attempt = 0; attempt < delays.length; attempt++) {
      try {
        return await query();
      } on FirebaseException catch (e) {
        if (e.code != 'unavailable') rethrow;
        await Future.delayed(Duration(milliseconds: delays[attempt]));
      }
    }
    return await query();
  }

  String _friendlyFirestoreError(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'unavailable') {
        return 'Service temporarily unavailable. Please try again.';
      }
      if (error.code == 'permission-denied') {
        return 'Task service permission denied.';
      }
    }
    return 'Could not load tasks. Check your internet connection and try again.';
  }

  Future<void> _saveRemoteCache(List<Task> tasks) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _kRemoteCache,
      jsonEncode(tasks.map((t) => t.toMap()).toList()),
    );
  }

  Future<List<Task>> _getRemoteCache() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kRemoteCache);
    if (raw == null) return [];
    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return decoded.map(Task.fromMap).toList();
  }

  Future<String?> getSelectedDate() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kSelectedDate);
  }

  Future<void> setSelectedDate(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kSelectedDate, dateKey);
  }

  Future<List<Task>> getSelectedTasks(List<Task> pool) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kSelectedTasks);
    if (raw == null) return [];
    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return decoded.map(Task.fromMap).toList();
  }

  Future<void> saveSelectedTasks(List<Task> tasks) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _kSelectedTasks,
      jsonEncode(tasks.map((t) => t.toMap()).toList()),
    );
  }

  Future<Map<dynamic, bool>> getCompletedMap() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kCompletedMap);
    if (raw == null) return {};
    final m = (jsonDecode(raw) as Map).map((k, v) => MapEntry(k, v as bool));
    return m;
  }

  Future<void> saveCompletedMap(Map<dynamic, bool> completed) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kCompletedMap, jsonEncode(completed));
  }

  Future<void> clearCompleted() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kCompletedMap);
  }

  Future<int> getStreakCount() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kStreakCount) ?? 0;
  }

  Future<String?> getLastCompletedDate() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kLastCompletedDate);
  }

  Future<void> setStreakCount(int value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kStreakCount, value);
  }

  Future<void> setLastCompletedDate(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLastCompletedDate, dateKey);
  }

  Future<bool> getReminderEnabled() async {
    final sp = await SharedPreferences.getInstance();
    final stored = sp.getBool(_kReminderEnabled);
    if (stored == null) {
      await sp.setBool(_kReminderEnabled, true);
      return true;
    }
    return stored;
  }

  Future<void> setReminderEnabled(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kReminderEnabled, value);
  }

  Future<String?> getLastSeenDate() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kLastSeenDate);
  }

  Future<List<String>> getLastSeenTaskIds() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kLastSeenIds);
    if (raw == null) return [];
    final decoded = (jsonDecode(raw) as List).cast<String>();
    return decoded;
  }

  Future<void> saveLastSeenTaskIds({
    required String dateKey,
    required List<String> taskIds,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLastSeenDate, dateKey);
    await sp.setString(_kLastSeenIds, jsonEncode(taskIds));
  }

  Future<int> getRefreshCount(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    final savedDate = sp.getString(_kRefreshCountDate);
    if (savedDate != dateKey) return 0;
    return sp.getInt(_kRefreshCount) ?? 0;
  }

  Future<int> incrementRefreshCount(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    final savedDate = sp.getString(_kRefreshCountDate);
    int nextCount;
    if (savedDate == dateKey) {
      nextCount = (sp.getInt(_kRefreshCount) ?? 0) + 1;
    } else {
      nextCount = 1;
      await sp.setString(_kRefreshCountDate, dateKey);
    }
    await sp.setInt(_kRefreshCount, nextCount);
    return nextCount;
  }

  Future<int> getSkipCount(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    final savedDate = sp.getString(_kSkipCountDate);
    if (savedDate != dateKey) return 0;
    return sp.getInt(_kSkipCount) ?? 0;
  }

  Future<int> incrementSkipCount(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    final savedDate = sp.getString(_kSkipCountDate);
    int nextCount;
    if (savedDate == dateKey) {
      nextCount = (sp.getInt(_kSkipCount) ?? 0) + 1;
    } else {
      nextCount = 1;
      await sp.setString(_kSkipCountDate, dateKey);
    }
    await sp.setInt(_kSkipCount, nextCount);
    return nextCount;
  }

  Future<int> getTotalCompleted() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kTotalCompleted) ?? 0;
  }

  Future<int> getDailyCompleted(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    final savedDate = sp.getString(_kDailyCompletedDate);
    if (savedDate != dateKey) return 0;
    return sp.getInt(_kDailyCompletedCount) ?? 0;
  }

  Future<int> incrementDailyCompleted(String dateKey, {int delta = 1}) async {
    final sp = await SharedPreferences.getInstance();
    final savedDate = sp.getString(_kDailyCompletedDate);
    int nextCount;
    if (savedDate == dateKey) {
      nextCount = (sp.getInt(_kDailyCompletedCount) ?? 0) + delta;
    } else {
      nextCount = delta;
      await sp.setString(_kDailyCompletedDate, dateKey);
    }
    if (nextCount < 0) nextCount = 0;
    await sp.setInt(_kDailyCompletedCount, nextCount);
    await _updateDailyHistory(sp, dateKey, nextCount);
    return nextCount;
  }

  Future<int> getBestStreak() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kBestStreak) ?? 0;
  }

  Future<Map<String, int>> getCategoryCounts() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kCategoryCounts);
    if (raw == null) return {};
    final decoded = (jsonDecode(raw) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );
    return decoded;
  }

  Future<void> incrementCompleted(String category) async {
    final sp = await SharedPreferences.getInstance();
    final total = (sp.getInt(_kTotalCompleted) ?? 0) + 1;
    await sp.setInt(_kTotalCompleted, total);

    final counts = await getCategoryCounts();
    counts[category] = (counts[category] ?? 0) + 1;
    await sp.setString(_kCategoryCounts, jsonEncode(counts));
  }

  Future<void> setBestStreakIfHigher(int value) async {
    final sp = await SharedPreferences.getInstance();
    final best = sp.getInt(_kBestStreak) ?? 0;
    if (value > best) {
      await sp.setInt(_kBestStreak, value);
    }
  }

  Future<List<Task>> getCustomTasks() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kCustomTasks);
    if (raw == null) return [];
    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return decoded.map(Task.fromMap).toList();
  }

  Future<void> saveCustomTasks(List<Task> tasks) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _kCustomTasks,
      jsonEncode(tasks.map((t) => t.toMap()).toList()),
    );
  }

  Future<int> getDailyCustomAddCount(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    final savedDate = sp.getString(_kCustomAddDate);
    if (savedDate != dateKey) return 0;
    return sp.getInt(_kCustomAddCount) ?? 0;
  }

  Future<int> addCustomTask(Task task, String dateKey) async {
    final tasks = await getCustomTasks();
    tasks.add(task);
    await saveCustomTasks(tasks);

    final sp = await SharedPreferences.getInstance();
    final savedDate = sp.getString(_kCustomAddDate);
    int nextCount;
    if (savedDate == dateKey) {
      nextCount = (sp.getInt(_kCustomAddCount) ?? 0) + 1;
    } else {
      nextCount = 1;
      await sp.setString(_kCustomAddDate, dateKey);
    }

    await sp.setInt(_kCustomAddCount, nextCount);
    return nextCount;
  }

  Future<void> _updateDailyHistory(
    SharedPreferences sp,
    String dateKey,
    int count,
  ) async {
    final raw = sp.getString(_kDailyHistory);
    final history = raw == null
        ? <String, dynamic>{}
        : (jsonDecode(raw) as Map<String, dynamic>);
    history[dateKey] = count;
    await sp.setString(_kDailyHistory, jsonEncode(history));
  }

  Future<Map<String, int>> getDailyHistory({int days = 14}) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kDailyHistory);
    if (raw == null) return {};
    final decoded = (jsonDecode(raw) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );
    if (days <= 0) return decoded;
    final cutoff = DateTime.now().subtract(Duration(days: days - 1));
    final filtered = <String, int>{};
    for (final entry in decoded.entries) {
      final parsed = DateTime.tryParse(entry.key);
      if (parsed == null) continue;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      if (day.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day))) {
        continue;
      }
      filtered[entry.key] = entry.value;
    }
    return filtered;
  }

  Future<double> getRecentCompletionRate({
    int days = 7,
    int assumedTasksPerDay = 3,
  }) async {
    final history = await getDailyHistory(days: days);
    if (history.isEmpty) return 0.0;
    final totalCompleted = history.values.fold<int>(
      0,
      (acc, value) => acc + value,
    );
    final observedDays = history.length;
    final denominator = observedDays * assumedTasksPerDay;
    if (denominator <= 0) return 0.0;
    final ratio = totalCompleted / denominator;
    if (ratio < 0) return 0.0;
    if (ratio > 1) return 1.0;
    return ratio;
  }

  Future<void> setLastCompletedTask({
    required String title,
    required String category,
    required String dateKey,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLastCompletedTitle, title);
    await sp.setString(_kLastCompletedCategory, category);
    await sp.setString(_kLastCompletedAt, dateKey);
  }

  Future<LastCompletedTask?> getLastCompletedTask() async {
    final sp = await SharedPreferences.getInstance();
    final title = sp.getString(_kLastCompletedTitle);
    final category = sp.getString(_kLastCompletedCategory);
    final dateKey = sp.getString(_kLastCompletedAt);
    if (title == null || category == null || dateKey == null) return null;
    final parsed = DateTime.tryParse(dateKey);
    return LastCompletedTask(
      title: title,
      category: category,
      completedAt: parsed ?? DateTime.now(),
      dateKey: dateKey,
    );
  }

  Future<Set<String>> getEarnedBadges() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kBadges);
    if (raw == null) return <String>{};
    final decoded = (jsonDecode(raw) as List).cast<String>();
    return decoded.toSet();
  }

  Future<List<String>> awardBadges({
    required int totalCompleted,
    required int bestStreak,
    required Map<String, int> categoryCounts,
  }) async {
    final eligible = <String>{
      if (totalCompleted >= 10) 'total_10',
      if (totalCompleted >= 50) 'total_50',
      if (totalCompleted >= 100) 'total_100',
      if (bestStreak >= 3) 'streak_3',
      if (bestStreak >= 7) 'streak_7',
      if ((categoryCounts['mind'] ?? 0) >= 10) 'cat_mind_10',
      if ((categoryCounts['body'] ?? 0) >= 10) 'cat_body_10',
      if ((categoryCounts['growth'] ?? 0) >= 10) 'cat_growth_10',
      if ((categoryCounts['calm'] ?? 0) >= 10) 'cat_calm_10',
      if ((categoryCounts['health'] ?? 0) >= 10) 'cat_health_10',
    };

    if (eligible.isEmpty) return [];
    final current = await getEarnedBadges();
    final newlyAdded = eligible.difference(current);
    if (newlyAdded.isEmpty) return [];

    final updated = {...current, ...newlyAdded};
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kBadges, jsonEncode(updated.toList()));
    return newlyAdded.toList();
  }

  Future<String?> getDailyMood(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    final savedDate = sp.getString(_kDailyMoodDate);
    if (savedDate != dateKey) return null;
    return sp.getString(_kDailyMoodValue);
  }

  Future<void> setDailyMood({
    required String dateKey,
    required String mood,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kDailyMoodDate, dateKey);
    await sp.setString(_kDailyMoodValue, mood);
  }

  String currentWeekKey([DateTime? now]) {
    final base = now ?? DateTime.now();
    final day = DateTime(base.year, base.month, base.day);
    final monday = day.subtract(Duration(days: day.weekday - DateTime.monday));
    return _formatDateKey(monday);
  }

  Future<WeeklyPlan?> getWeeklyPlan({String? weekKey}) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kWeeklyPlan);
    if (raw == null) return null;
    final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
    final plan = WeeklyPlan.fromMap(decoded);
    if (plan.weekKey.isEmpty || !plan.hasTargets) return null;
    final expectedWeek = weekKey ?? currentWeekKey();
    if (plan.weekKey != expectedWeek) return null;
    return plan;
  }

  Future<void> saveWeeklyPlan(WeeklyPlan plan) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kWeeklyPlan, jsonEncode(plan.toMap()));
    final progress = await getWeeklyProgress(weekKey: plan.weekKey);
    await saveWeeklyProgress(progress);
  }

  Future<void> clearWeeklyPlan() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kWeeklyPlan);
    await sp.remove(_kWeeklyProgress);
  }

  Future<WeeklyProgress> getWeeklyProgress({required String weekKey}) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kWeeklyProgress);
    if (raw == null) {
      return WeeklyProgress(weekKey: weekKey, done: const {});
    }
    final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
    final progress = WeeklyProgress.fromMap(decoded);
    if (progress.weekKey != weekKey) {
      return WeeklyProgress(weekKey: weekKey, done: const {});
    }
    return progress;
  }

  Future<void> saveWeeklyProgress(WeeklyProgress progress) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kWeeklyProgress, jsonEncode(progress.toMap()));
  }

  Future<WeeklyProgress> incrementWeeklyProgress({
    required String weekKey,
    required String category,
    int delta = 1,
  }) async {
    final current = await getWeeklyProgress(weekKey: weekKey);
    final next = <String, int>{...current.done};
    final value = (next[category] ?? 0) + delta;
    if (value <= 0) {
      next.remove(category);
    } else {
      next[category] = value;
    }
    final updated = WeeklyProgress(weekKey: weekKey, done: next);
    await saveWeeklyProgress(updated);
    return updated;
  }

  Future<void> saveActiveTaskTimer({
    required String taskId,
    required String taskTitle,
    required DateTime endAt,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kActiveTimerTaskId, taskId);
    await sp.setString(_kActiveTimerTaskTitle, taskTitle);
    await sp.setInt(_kActiveTimerEndAtMs, endAt.millisecondsSinceEpoch);
  }

  Future<ActiveTaskTimer?> getActiveTaskTimer() async {
    final sp = await SharedPreferences.getInstance();
    final taskId = sp.getString(_kActiveTimerTaskId);
    final taskTitle = sp.getString(_kActiveTimerTaskTitle);
    final endAtMs = sp.getInt(_kActiveTimerEndAtMs);
    if (taskId == null || taskTitle == null || endAtMs == null) return null;
    return ActiveTaskTimer(
      taskId: taskId,
      taskTitle: taskTitle,
      endAt: DateTime.fromMillisecondsSinceEpoch(endAtMs),
    );
  }

  Future<void> clearActiveTaskTimer() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kActiveTimerTaskId);
    await sp.remove(_kActiveTimerTaskTitle);
    await sp.remove(_kActiveTimerEndAtMs);
  }

  String _formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class LastCompletedTask {
  final String title;
  final String category;
  final DateTime completedAt;
  final String dateKey;

  const LastCompletedTask({
    required this.title,
    required this.category,
    required this.completedAt,
    required this.dateKey,
  });
}

class ActiveTaskTimer {
  final String taskId;
  final String taskTitle;
  final DateTime endAt;

  const ActiveTaskTimer({
    required this.taskId,
    required this.taskTitle,
    required this.endAt,
  });
}
