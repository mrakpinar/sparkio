import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskRepository {
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
  static const _kTotalCompleted = 'total_completed_v1';
  static const _kBestStreak = 'best_streak_v1';
  static const _kCategoryCounts = 'category_counts_v1';

  Future<List<Task>> loadPool() async {
    final raw = await rootBundle.loadString('assets/tasks.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final base = list.map(Task.fromMap).toList();
    final custom = await getCustomTasks();
    return [...base, ...custom];
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
    return sp.getBool(_kReminderEnabled) ?? false;
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
}
