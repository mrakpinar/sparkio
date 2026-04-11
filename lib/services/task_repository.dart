import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/challenge_mode.dart';
import '../models/weekly_plan.dart';
import 'task_localizer.dart';

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
  static const _kTotalXp = 'total_xp_v1';
  static const _kXpBackfillDone = 'xp_backfill_done_v1';
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
  static const _kQueuedWeeklyPlan = 'queued_weekly_plan_v1';
  static const _kProfileName = 'profile_name_v1';
  static const _kProfileAvatar = 'profile_avatar_v1';
  static const _kAddTaskCtaVariant = 'add_task_cta_variant_v1';
  static const _kRatePromptShownTriggers = 'rate_prompt_shown_triggers_v1';
  static const _kStatsScreenshotPresetApplied =
      'stats_screenshot_preset_applied_v1';
  static const _kInstallAtMs = 'install_at_ms_v1';
  static const _kRetentionDay1Logged = 'retention_day1_logged_v1';
  static const _kRetentionDay7Logged = 'retention_day7_logged_v1';
  static const _kStreakRescueShownDate = 'streak_rescue_shown_date_v1';
  static const _kWeeklyReviewShownWeek = 'weekly_review_shown_week_v1';
  static const _kNudgesDismissedDate = 'nudges_dismissed_date_v1';
  static const _kNudgesDismissedIds = 'nudges_dismissed_ids_v1';
  static const _kCoachMorningIntentionDate = 'coach_morning_intention_date_v1';
  static const _kCoachMorningIntentionValue =
      'coach_morning_intention_value_v1';
  static const _kCoachEveningReviewDate = 'coach_evening_review_date_v1';
  static const _kCoachEveningReviewDone = 'coach_evening_review_done_v1';
  static const _kInstallId = 'install_id_v1';
  static const _kReferralExtraSparkSlots = 'referral_extra_spark_slots_v1';
  static const _kActiveChallenge = 'active_challenge_v1';
  static const _kCompletionHourCounts = 'completion_hour_counts_v1';
  static const _kTaskInsightCounts = 'task_insight_counts_v1';
  static const _kSavedCreatorPackIds = 'saved_creator_pack_ids_v1';
  static const _kCreatorPackRatings = 'creator_pack_ratings_v1';
  static const _kCategoryStreakPrefix = 'cat_streak_v1_';
  static const _kCategoryLastDatePrefix = 'cat_last_date_v1_';
  static const _kDailyMoodHistory_v2 = 'daily_mood_history_v2';
  static const _kSurvivalModeActiveDate = 'survival_mode_active_date_v1';
  static const _kSurvivalModeDeclinedDate = 'survival_mode_declined_date_v1';

  String? _lastPoolError;
  String? get lastPoolError => _lastPoolError;

  static String sanitizeProfileName(String raw) {
    var value = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    value = value.replaceAll(RegExp(r'^[\u26A1\u2728]+'), '').trimLeft();
    value = value.replaceAll(RegExp(r'[\u26A1\u2728]+$'), '').trimRight();
    value = value.replaceAll(RegExp(r'(?:âš¡)+$'), '').trimRight();
    value = value.replaceAll(RegExp(r'[�]+$'), '').trimRight();
    if (value.endsWith('?') && value.length > 1) {
      value = value.substring(0, value.length - 1).trimRight();
    }
    return value.trim();
  }

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

  static const List<Task> _localCatalog = [
    Task(
      id: 'local_mind_1',
      title: 'Take 3 slow breaths',
      category: 'mind',
      difficulty: 'easy',
      durationMinutes: 3,
    ),
    Task(
      id: 'local_mind_2',
      title: 'Write one clear priority for today',
      category: 'mind',
      difficulty: 'easy',
      durationMinutes: 4,
    ),
    Task(
      id: 'local_mind_3',
      title: 'Clear one distraction from your desk',
      category: 'mind',
      difficulty: 'easy',
      durationMinutes: 4,
    ),
    Task(
      id: 'local_mind_4',
      title: 'Close extra tabs and focus for 3 minutes',
      category: 'mind',
      difficulty: 'medium',
      durationMinutes: 3,
    ),
    Task(
      id: 'local_mind_5',
      title: 'Name one thing you can control today',
      category: 'mind',
      difficulty: 'easy',
      durationMinutes: 3,
    ),
    Task(
      id: 'local_mind_6',
      title: 'Write one win from your day',
      category: 'mind',
      difficulty: 'easy',
      durationMinutes: 4,
    ),
    Task(
      id: 'local_body_1',
      title: 'Stand up and stretch your neck and shoulders',
      category: 'body',
      difficulty: 'easy',
      durationMinutes: 4,
    ),
    Task(
      id: 'local_body_2',
      title: 'Do 10 squats at your own pace',
      category: 'body',
      difficulty: 'medium',
      durationMinutes: 4,
    ),
    Task(
      id: 'local_body_3',
      title: 'Walk for 4 minutes',
      category: 'body',
      difficulty: 'easy',
      durationMinutes: 4,
    ),
    Task(
      id: 'local_body_4',
      title: 'Roll your shoulders for 60 seconds',
      category: 'body',
      difficulty: 'easy',
      durationMinutes: 1,
      durationSeconds: 60,
    ),
    Task(
      id: 'local_body_5',
      title: 'Do 8 wall push-ups',
      category: 'body',
      difficulty: 'medium',
      durationMinutes: 3,
    ),
    Task(
      id: 'local_body_6',
      title: 'Stretch your calves for 2 minutes',
      category: 'body',
      difficulty: 'easy',
      durationMinutes: 2,
    ),
    Task(
      id: 'local_growth_1',
      title: 'Read one page of something useful',
      category: 'growth',
      difficulty: 'easy',
      durationMinutes: 5,
    ),
    Task(
      id: 'local_growth_2',
      title: 'Learn one new word and use it in a sentence',
      category: 'growth',
      difficulty: 'medium',
      durationMinutes: 5,
    ),
    Task(
      id: 'local_growth_3',
      title: 'Plan tomorrow in three bullet points',
      category: 'growth',
      difficulty: 'easy',
      durationMinutes: 5,
    ),
    Task(
      id: 'local_growth_4',
      title: 'Organize one small area around you',
      category: 'growth',
      difficulty: 'easy',
      durationMinutes: 5,
    ),
    Task(
      id: 'local_growth_5',
      title: 'Write one idea to improve your routine',
      category: 'growth',
      difficulty: 'medium',
      durationMinutes: 4,
    ),
    Task(
      id: 'local_growth_6',
      title: 'Start a task you avoid for just 2 minutes',
      category: 'growth',
      difficulty: 'easy',
      durationMinutes: 2,
    ),
    Task(
      id: 'local_calm_1',
      title: 'Breathe in for 4 and out for 6 for 2 minutes',
      category: 'calm',
      difficulty: 'easy',
      durationMinutes: 2,
    ),
    Task(
      id: 'local_calm_2',
      title: 'Sit quietly and notice sounds for 2 minutes',
      category: 'calm',
      difficulty: 'easy',
      durationMinutes: 2,
    ),
    Task(
      id: 'local_calm_3',
      title: 'Relax your jaw and shoulders',
      category: 'calm',
      difficulty: 'easy',
      durationMinutes: 3,
    ),
    Task(
      id: 'local_calm_4',
      title: 'Do a short body scan for 3 minutes',
      category: 'calm',
      difficulty: 'medium',
      durationMinutes: 3,
    ),
    Task(
      id: 'local_calm_5',
      title: 'Step away from your screen for 2 minutes',
      category: 'calm',
      difficulty: 'easy',
      durationMinutes: 2,
    ),
    Task(
      id: 'local_calm_6',
      title: 'Put your phone down and breathe for 60 seconds',
      category: 'calm',
      difficulty: 'easy',
      durationMinutes: 1,
      durationSeconds: 60,
    ),
    Task(
      id: 'local_health_1',
      title: 'Drink one full glass of water',
      category: 'health',
      difficulty: 'easy',
      durationMinutes: 3,
    ),
    Task(
      id: 'local_health_2',
      title: 'Refill your water bottle now',
      category: 'health',
      difficulty: 'easy',
      durationMinutes: 2,
    ),
    Task(
      id: 'local_health_3',
      title: 'Eat one healthy snack',
      category: 'health',
      difficulty: 'easy',
      durationMinutes: 4,
    ),
    Task(
      id: 'local_health_4',
      title: 'Step outside for fresh air for 3 minutes',
      category: 'health',
      difficulty: 'easy',
      durationMinutes: 3,
    ),
    Task(
      id: 'local_health_5',
      title: 'Reset your posture for 2 minutes',
      category: 'health',
      difficulty: 'easy',
      durationMinutes: 2,
    ),
    Task(
      id: 'local_health_6',
      title: 'Do a 20-20-20 eye break',
      category: 'health',
      difficulty: 'easy',
      durationMinutes: 3,
    ),
  ];

  List<Task> _dedupeTasks(List<Task> tasks) {
    final seenIds = <String>{};
    final seenTitleKeys = <String>{};
    final result = <Task>[];
    for (final task in tasks) {
      if (seenIds.contains(task.id)) continue;
      final titleKey = '${task.category}|${task.title.toLowerCase().trim()}';
      if (seenTitleKeys.contains(titleKey)) continue;
      seenIds.add(task.id);
      seenTitleKeys.add(titleKey);
      result.add(task);
    }
    return result;
  }

  Future<List<Task>> loadPool() async {
    _lastPoolError = null;
    final remote = await _loadRemoteTasks();
    if (remote.isEmpty) {
      _lastPoolError ??=
          'No tasks available right now. Please try again later.';
    }
    final custom = await getCustomTasks();
    return _dedupeTasks(
      [
        ...TaskLocalizer.localizeTasks(remote),
        ...TaskLocalizer.localizeTasks(_localCatalog),
        ...custom,
      ],
    );
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
    return TaskLocalizer.localizeTasks(decoded.map(Task.fromMap).toList());
  }

  Future<void> saveSelectedTasks(List<Task> tasks) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _kSelectedTasks,
      jsonEncode(tasks.map((t) => t.toMap()).toList()),
    );
  }

  List<Task> localizeTasksForCurrentLocale(List<Task> tasks) {
    return TaskLocalizer.localizeTasks(tasks);
  }

  String localizeTaskTitleForCurrentLocale(
    String title, {
    String? category,
    String? taskId,
  }) {
    return TaskLocalizer.localizeTitle(
      title,
      category: category,
      taskId: taskId,
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

  Future<int> getCategoryStreak(String category) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt('$_kCategoryStreakPrefix$category') ?? 0;
  }

  Future<void> setCategoryStreak(String category, int value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('$_kCategoryStreakPrefix$category', value);
  }

  Future<String?> getCategoryLastCompletedDate(String category) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('$_kCategoryLastDatePrefix$category');
  }

  Future<void> setCategoryLastCompletedDate(String category, String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('$_kCategoryLastDatePrefix$category', dateKey);
  }

  Future<Map<String, int>> getMoodHistory() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kDailyMoodHistory_v2);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDailyMood(String dateKey, int moodValue) async {
    final sp = await SharedPreferences.getInstance();
    final hist = await getMoodHistory();
    hist[dateKey] = moodValue.clamp(1, 5);
    await sp.setString(_kDailyMoodHistory_v2, jsonEncode(hist));
  }

  Future<String?> getSurvivalModeActiveDate() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kSurvivalModeActiveDate);
  }

  Future<void> setSurvivalModeActiveDate(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kSurvivalModeActiveDate, dateKey);
  }

  Future<String?> getSurvivalModeDeclinedDate() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kSurvivalModeDeclinedDate);
  }

  Future<void> setSurvivalModeDeclinedDate(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kSurvivalModeDeclinedDate, dateKey);
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

  Future<String?> getStreakRescueShownDate() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kStreakRescueShownDate);
  }

  Future<void> setStreakRescueShownDate(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kStreakRescueShownDate, dateKey);
  }

  Future<String?> getWeeklyReviewShownWeek() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kWeeklyReviewShownWeek);
  }

  Future<void> setWeeklyReviewShownWeek(String weekKey) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kWeeklyReviewShownWeek, weekKey);
  }

  Future<Set<String>> getDismissedInAppNudges(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    final savedDate = sp.getString(_kNudgesDismissedDate);
    if (savedDate != dateKey) return <String>{};
    final raw = sp.getString(_kNudgesDismissedIds);
    if (raw == null || raw.trim().isEmpty) return <String>{};
    try {
      final decoded = (jsonDecode(raw) as List).cast<String>();
      return decoded
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> dismissInAppNudge({
    required String dateKey,
    required String nudgeId,
  }) async {
    final trimmed = nudgeId.trim();
    if (trimmed.isEmpty) return;
    final sp = await SharedPreferences.getInstance();
    final current = await getDismissedInAppNudges(dateKey);
    current.add(trimmed);
    await sp.setString(_kNudgesDismissedDate, dateKey);
    await sp.setString(_kNudgesDismissedIds, jsonEncode(current.toList()));
  }

  Future<String?> getCoachMorningIntention(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    final savedDate = sp.getString(_kCoachMorningIntentionDate);
    if (savedDate != dateKey) return null;
    final value = sp.getString(_kCoachMorningIntentionValue)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> setCoachMorningIntention({
    required String dateKey,
    required String intention,
  }) async {
    final trimmed = intention.trim();
    if (trimmed.isEmpty) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kCoachMorningIntentionDate, dateKey);
    await sp.setString(_kCoachMorningIntentionValue, trimmed);
  }

  Future<bool> getCoachEveningReviewDone(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    final savedDate = sp.getString(_kCoachEveningReviewDate);
    if (savedDate != dateKey) return false;
    return sp.getBool(_kCoachEveningReviewDone) ?? false;
  }

  Future<void> setCoachEveningReviewDone({
    required String dateKey,
    required bool done,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kCoachEveningReviewDate, dateKey);
    await sp.setBool(_kCoachEveningReviewDone, done);
  }

  Future<FunnelOpenState> registerOpenForFunnel() async {
    final sp = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var installAtMs = sp.getInt(_kInstallAtMs);
    var isFirstOpen = false;
    if (installAtMs == null) {
      installAtMs = now.millisecondsSinceEpoch;
      isFirstOpen = true;
      await sp.setInt(_kInstallAtMs, installAtMs);
    }

    final installDate = DateTime.fromMillisecondsSinceEpoch(installAtMs);
    final installDay = DateTime(
      installDate.year,
      installDate.month,
      installDate.day,
    );
    final daysSinceInstall = today.difference(installDay).inDays;

    final d1Logged = sp.getBool(_kRetentionDay1Logged) ?? false;
    final d7Logged = sp.getBool(_kRetentionDay7Logged) ?? false;

    final day1Retained = !d1Logged && daysSinceInstall == 1;
    final day7Retained = !d7Logged && daysSinceInstall == 7;

    if (day1Retained) {
      await sp.setBool(_kRetentionDay1Logged, true);
    }
    if (day7Retained) {
      await sp.setBool(_kRetentionDay7Logged, true);
    }

    return FunnelOpenState(
      isFirstOpen: isFirstOpen,
      day1Retained: day1Retained,
      day7Retained: day7Retained,
      daysSinceInstall: daysSinceInstall,
    );
  }

  Future<String> getOrCreateInstallId() async {
    final sp = await SharedPreferences.getInstance();
    final existing = sp.getString(_kInstallId)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = const Uuid().v4();
    await sp.setString(_kInstallId, generated);
    return generated;
  }

  Future<int> getReferralExtraSparkSlots() async {
    final sp = await SharedPreferences.getInstance();
    final stored = sp.getInt(_kReferralExtraSparkSlots) ?? 0;
    return stored < 0 ? 0 : stored;
  }

  Future<int> addReferralExtraSparkSlots(int delta) async {
    if (delta <= 0) return getReferralExtraSparkSlots();
    final sp = await SharedPreferences.getInstance();
    final current = await getReferralExtraSparkSlots();
    final next = (current + delta).clamp(0, 99);
    await sp.setInt(_kReferralExtraSparkSlots, next);
    return next;
  }

  Future<int> getFreeSparkSlotLimit({required bool premiumActive}) async {
    if (premiumActive) return 999;
    final extra = await getReferralExtraSparkSlots();
    return (1 + extra).clamp(1, 999);
  }

  Future<Set<String>> getSavedCreatorPackIds() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kSavedCreatorPackIds);
    if (raw == null || raw.trim().isEmpty) return <String>{};
    try {
      final decoded = (jsonDecode(raw) as List).cast<String>();
      return decoded
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> setCreatorPackSaved({
    required String packId,
    required bool saved,
  }) async {
    final trimmed = packId.trim();
    if (trimmed.isEmpty) return;
    final sp = await SharedPreferences.getInstance();
    final current = await getSavedCreatorPackIds();
    if (saved) {
      current.add(trimmed);
    } else {
      current.remove(trimmed);
    }
    await sp.setString(_kSavedCreatorPackIds, jsonEncode(current.toList()));
  }

  Future<Map<String, int>> getCreatorPackRatings() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kCreatorPackRatings);
    if (raw == null || raw.trim().isEmpty) return <String, int>{};
    try {
      final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final ratings = <String, int>{};
      for (final entry in decoded.entries) {
        final id = entry.key.trim();
        final value = (entry.value as num?)?.toInt() ?? 0;
        if (id.isEmpty || value < 1 || value > 5) continue;
        ratings[id] = value;
      }
      return ratings;
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> setCreatorPackRating({
    required String packId,
    required int rating,
  }) async {
    final trimmed = packId.trim();
    if (trimmed.isEmpty) return;
    final safeRating = rating.clamp(1, 5).toInt();
    final sp = await SharedPreferences.getInstance();
    final ratings = await getCreatorPackRatings();
    ratings[trimmed] = safeRating;
    await sp.setString(_kCreatorPackRatings, jsonEncode(ratings));
  }

  Future<ActiveChallenge?> getActiveChallenge() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kActiveChallenge);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final challenge = ActiveChallenge.fromMap(map);
      if (challenge.templateId.isEmpty ||
          challenge.startDateKey.isEmpty ||
          challenge.durationDays <= 0) {
        await sp.remove(_kActiveChallenge);
        return null;
      }
      return challenge;
    } catch (_) {
      await sp.remove(_kActiveChallenge);
      return null;
    }
  }

  Future<void> saveActiveChallenge(ActiveChallenge challenge) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kActiveChallenge, jsonEncode(challenge.toMap()));
  }

  Future<void> clearActiveChallenge() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kActiveChallenge);
  }

  Future<ChallengeProgressUpdate?> markActiveChallengeProgress({
    required String dateKey,
    required int completedToday,
  }) async {
    final active = await getActiveChallenge();
    if (active == null) return null;
    if (completedToday < active.dailyGoal) {
      return ChallengeProgressUpdate(
        challenge: active,
        dayLogged: false,
        completedNow: false,
      );
    }
    if (!active.includesDate(dateKey) || active.hasLoggedDate(dateKey)) {
      return ChallengeProgressUpdate(
        challenge: active,
        dayLogged: false,
        completedNow: false,
      );
    }

    final nextCompleted = {...active.completedDateKeys, dateKey}.toList()
      ..sort();
    var updated = active.copyWith(completedDateKeys: nextCompleted);
    var completedNow = false;
    if (updated.isCompleted && !updated.completionNotified) {
      completedNow = true;
      updated = updated.copyWith(completionNotified: true);
    }
    await saveActiveChallenge(updated);
    return ChallengeProgressUpdate(
      challenge: updated,
      dayLogged: true,
      completedNow: completedNow,
    );
  }

  Future<String?> getProfileName() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kProfileName);
    if (raw == null) return null;
    final value = sanitizeProfileName(raw);
    if (value.isEmpty) {
      await sp.remove(_kProfileName);
      return null;
    }
    if (value != raw.trim()) {
      await sp.setString(_kProfileName, value);
    }
    return value;
  }

  Future<void> setProfileName(String name) async {
    final sp = await SharedPreferences.getInstance();
    final value = sanitizeProfileName(name);
    if (value.isEmpty) {
      await sp.remove(_kProfileName);
      return;
    }
    await sp.setString(_kProfileName, value);
  }

  Future<String?> getProfileAvatar() async {
    final sp = await SharedPreferences.getInstance();
    final value = sp.getString(_kProfileAvatar)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> setProfileAvatar(String? avatar) async {
    final sp = await SharedPreferences.getInstance();
    final value = avatar?.trim();
    if (value == null || value.isEmpty) {
      await sp.remove(_kProfileAvatar);
      return;
    }
    await sp.setString(_kProfileAvatar, value);
  }

  Future<String?> getAddTaskCtaVariant() async {
    final sp = await SharedPreferences.getInstance();
    final value = sp.getString(_kAddTaskCtaVariant)?.trim().toLowerCase();
    if (value == null || value.isEmpty) return null;
    if (value != 'a' && value != 'b' && value != 'c') return null;
    return value;
  }

  Future<void> setAddTaskCtaVariant(String variant) async {
    final sp = await SharedPreferences.getInstance();
    final value = variant.trim().toLowerCase();
    if (value != 'a' && value != 'b' && value != 'c') return;
    await sp.setString(_kAddTaskCtaVariant, value);
  }

  Future<Set<String>> getRatePromptShownTriggers() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kRatePromptShownTriggers);
    if (raw == null) return <String>{};
    final decoded = (jsonDecode(raw) as List).cast<String>();
    return decoded.toSet();
  }

  Future<bool> hasShownRatePromptFor(String trigger) async {
    final shown = await getRatePromptShownTriggers();
    return shown.contains(trigger);
  }

  Future<void> markRatePromptShownFor(String trigger) async {
    final sp = await SharedPreferences.getInstance();
    final shown = await getRatePromptShownTriggers();
    shown.add(trigger);
    await sp.setString(_kRatePromptShownTriggers, jsonEncode(shown.toList()));
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

  Future<void> incrementCompleted(
    String category, {
    Task? task,
    DateTime? completedAt,
  }) async {
    final sp = await SharedPreferences.getInstance();
    final total = (sp.getInt(_kTotalCompleted) ?? 0) + 1;
    await sp.setInt(_kTotalCompleted, total);

    final counts = await getCategoryCounts();
    counts[category] = (counts[category] ?? 0) + 1;
    await sp.setString(_kCategoryCounts, jsonEncode(counts));

    if (task != null) {
      final timestamp = completedAt ?? DateTime.now();
      await _incrementHourInsight(sp, timestamp.hour);
      await _incrementTaskInsight(sp, task: task, completedAt: timestamp);
    }
  }

  Future<void> _incrementHourInsight(SharedPreferences sp, int hour) async {
    final safeHour = hour.clamp(0, 23);
    final current = await getCompletionHourCounts();
    current[safeHour] = (current[safeHour] ?? 0) + 1;
    final rawMap = <String, int>{
      for (final entry in current.entries)
        if (entry.key >= 0 && entry.key <= 23)
          entry.key.toString(): entry.value,
    };
    await sp.setString(_kCompletionHourCounts, jsonEncode(rawMap));
  }

  Future<void> _incrementTaskInsight(
    SharedPreferences sp, {
    required Task task,
    required DateTime completedAt,
  }) async {
    final raw = sp.getString(_kTaskInsightCounts);
    final decoded = raw == null
        ? <String, dynamic>{}
        : (jsonDecode(raw) as Map<String, dynamic>);
    final key = _taskInsightKey(task);
    final existing = decoded[key] is Map
        ? (decoded[key] as Map).cast<String, dynamic>()
        : {};
    final nextCount = ((existing['count'] as num?)?.toInt() ?? 0) + 1;
    decoded[key] = <String, dynamic>{
      'title': task.title.trim(),
      'category': task.category,
      'count': nextCount,
      'lastCompletedAt': completedAt.millisecondsSinceEpoch,
    };

    if (decoded.length > 80) {
      final entries = decoded.entries.toList()
        ..sort((a, b) {
          final aCount = (((a.value as Map?)?['count'] as num?)?.toInt() ?? 0);
          final bCount = (((b.value as Map?)?['count'] as num?)?.toInt() ?? 0);
          return bCount.compareTo(aCount);
        });
      final keep = entries.take(60);
      final pruned = <String, dynamic>{
        for (final entry in keep) entry.key: entry.value,
      };
      await sp.setString(_kTaskInsightCounts, jsonEncode(pruned));
      return;
    }

    await sp.setString(_kTaskInsightCounts, jsonEncode(decoded));
  }

  String _taskInsightKey(Task task) {
    final normalizedTitle = task.title
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '${task.category}|$normalizedTitle';
  }

  Future<Map<int, int>> getCompletionHourCounts() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kCompletionHourCounts);
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final result = <int, int>{};
      for (final entry in decoded.entries) {
        final hour = int.tryParse(entry.key);
        if (hour == null || hour < 0 || hour > 23) continue;
        final value = (entry.value as num?)?.toInt() ?? 0;
        if (value <= 0) continue;
        result[hour] = value;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<List<TaskCompletionInsight>> getTopTaskCompletionInsights({
    int limit = 5,
  }) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kTaskInsightCounts);
    if (raw == null || raw.trim().isEmpty) {
      return const <TaskCompletionInsight>[];
    }
    try {
      final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final list = <TaskCompletionInsight>[];
      for (final entry in decoded.entries) {
        if (entry.value is! Map) continue;
        final map = (entry.value as Map).cast<String, dynamic>();
        final title = (map['title'] as String?)?.trim() ?? '';
        final category = (map['category'] as String?)?.trim() ?? 'mind';
        final count = (map['count'] as num?)?.toInt() ?? 0;
        if (title.isEmpty || count <= 0) continue;
        list.add(
          TaskCompletionInsight(
            key: entry.key,
            title: title,
            category: category,
            count: count,
          ),
        );
      }
      list.sort((a, b) => b.count.compareTo(a.count));
      return list.take(limit.clamp(1, 20)).toList(growable: false);
    } catch (_) {
      return const <TaskCompletionInsight>[];
    }
  }

  int xpForNextLevel(int level) {
    final safeLevel = level < 1 ? 1 : level;
    // Increasing XP requirement per level: 40, 60, 80, 100...
    return 40 + ((safeLevel - 1) * 20);
  }

  int xpNeededForLevel(int level) {
    if (level <= 1) return 0;
    var total = 0;
    for (var l = 1; l < level; l++) {
      total += xpForNextLevel(l);
    }
    return total;
  }

  XpProgress computeXpProgress(int totalXp) {
    var level = 1;
    var remaining = totalXp < 0 ? 0 : totalXp;
    while (remaining >= xpForNextLevel(level)) {
      remaining -= xpForNextLevel(level);
      level += 1;
    }
    final xpToNextLevel = xpForNextLevel(level);
    return XpProgress(
      totalXp: totalXp < 0 ? 0 : totalXp,
      level: level,
      xpInLevel: remaining,
      xpToNextLevel: xpToNextLevel,
    );
  }

  Future<int> getTotalXp() async {
    final sp = await SharedPreferences.getInstance();
    final stored = sp.getInt(_kTotalXp);
    if (stored != null) return stored;

    // One-time backfill so existing users don't lose progress after XP launch.
    final alreadyBackfilled = sp.getBool(_kXpBackfillDone) ?? false;
    if (alreadyBackfilled) return 0;
    final historicalCompleted = sp.getInt(_kTotalCompleted) ?? 0;
    final seeded = historicalCompleted * 5;
    await sp.setInt(_kTotalXp, seeded);
    await sp.setBool(_kXpBackfillDone, true);
    return seeded;
  }

  Future<void> setTotalXp(int value) async {
    final sp = await SharedPreferences.getInstance();
    final safeValue = value < 0 ? 0 : value;
    await sp.setInt(_kTotalXp, safeValue);
    await sp.setBool(_kXpBackfillDone, true);
  }

  Future<XpProgress> getXpProgress() async {
    final totalXp = await getTotalXp();
    return computeXpProgress(totalXp);
  }

  Future<XpProgress> addXp(int delta) async {
    final sp = await SharedPreferences.getInstance();
    final current = await getTotalXp();
    final next = (current + delta).clamp(0, 1 << 31).toInt();
    await sp.setInt(_kTotalXp, next);
    await sp.setBool(_kXpBackfillDone, true);
    return computeXpProgress(next);
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

  Future<void> queueWeeklyPlan(WeeklyPlan plan) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kQueuedWeeklyPlan, jsonEncode(plan.toMap()));
  }

  Future<WeeklyPlan?> getQueuedWeeklyPlan() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kQueuedWeeklyPlan);
    if (raw == null) return null;
    final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
    final queued = WeeklyPlan.fromMap(decoded);
    if (queued.weekKey.isEmpty || !queued.hasTargets) return null;
    return queued;
  }

  Future<void> clearQueuedWeeklyPlan() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kQueuedWeeklyPlan);
  }

  Future<bool> applyQueuedWeeklyPlanIfReady({String? weekKey}) async {
    final queued = await getQueuedWeeklyPlan();
    if (queued == null) return false;
    final expectedWeek = weekKey ?? currentWeekKey();
    if (queued.weekKey != expectedWeek) return false;
    await saveWeeklyPlan(queued);
    await clearQueuedWeeklyPlan();
    return true;
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

  Future<void> applyStatsScreenshotPreset({bool force = false}) async {
    final sp = await SharedPreferences.getInstance();
    final alreadyApplied = sp.getBool(_kStatsScreenshotPresetApplied) ?? false;
    if (alreadyApplied && !force) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _formatDateKey(today);
    final weekKey = currentWeekKey(today);

    final dailyHistory = <String, int>{};
    const completions = [1, 2, 1, 3, 2, 4, 3];
    for (var i = 0; i < completions.length; i++) {
      final day = today.subtract(Duration(days: completions.length - 1 - i));
      dailyHistory[_formatDateKey(day)] = completions[i];
    }

    const categoryCounts = <String, int>{
      'growth': 34,
      'mind': 27,
      'body': 18,
      'calm': 11,
      'health': 9,
    };
    const completionHourCounts = <String, int>{
      '6': 3,
      '8': 7,
      '12': 4,
      '18': 6,
      '21': 5,
    };
    const taskInsightCounts = <String, Map<String, dynamic>>{
      'growth|evening focus sprint': {
        'title': 'Evening focus sprint',
        'category': 'growth',
        'count': 8,
        'lastCompletedAt': 0,
      },
      'mind|write one clear priority for today': {
        'title': 'Write one clear priority for today',
        'category': 'mind',
        'count': 6,
        'lastCompletedAt': 0,
      },
      'calm|breathe in for 4 and out for 6 for 2 minutes': {
        'title': 'Breathe in for 4 and out for 6 for 2 minutes',
        'category': 'calm',
        'count': 5,
        'lastCompletedAt': 0,
      },
    };
    const totalCompleted = 99;
    const weeklyTargets = <String, int>{
      'growth': 2,
      'mind': 1,
      'body': 1,
      'calm': 1,
    };
    const weeklyDone = <String, int>{
      'growth': 1,
      'mind': 1,
      'body': 1,
      'calm': 0,
    };

    await sp.setInt(_kTotalCompleted, totalCompleted);
    await sp.setInt(_kBestStreak, 14);
    await sp.setInt(_kStreakCount, 6);
    await sp.setString(_kCategoryCounts, jsonEncode(categoryCounts));
    await sp.setString(
      _kCompletionHourCounts,
      jsonEncode(completionHourCounts),
    );
    await sp.setString(_kTaskInsightCounts, jsonEncode(taskInsightCounts));
    await sp.setString(_kDailyHistory, jsonEncode(dailyHistory));
    await sp.setString(_kDailyCompletedDate, todayKey);
    await sp.setInt(_kDailyCompletedCount, 3);
    await sp.setString(_kLastCompletedDate, todayKey);
    await sp.setString(_kLastCompletedTitle, 'Evening focus sprint');
    await sp.setString(_kLastCompletedCategory, 'growth');
    await sp.setString(_kLastCompletedAt, todayKey);
    await sp.setString(
      _kWeeklyPlan,
      jsonEncode(WeeklyPlan(weekKey: weekKey, targets: weeklyTargets).toMap()),
    );
    await sp.setString(
      _kWeeklyProgress,
      jsonEncode(WeeklyProgress(weekKey: weekKey, done: weeklyDone).toMap()),
    );
    await sp.setBool(_kStatsScreenshotPresetApplied, true);
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

class FunnelOpenState {
  const FunnelOpenState({
    required this.isFirstOpen,
    required this.day1Retained,
    required this.day7Retained,
    required this.daysSinceInstall,
  });

  final bool isFirstOpen;
  final bool day1Retained;
  final bool day7Retained;
  final int daysSinceInstall;
}

class TaskCompletionInsight {
  const TaskCompletionInsight({
    required this.key,
    required this.title,
    required this.category,
    required this.count,
  });

  final String key;
  final String title;
  final String category;
  final int count;
}

class XpProgress {
  const XpProgress({
    required this.totalXp,
    required this.level,
    required this.xpInLevel,
    required this.xpToNextLevel,
  });

  final int totalXp;
  final int level;
  final int xpInLevel;
  final int xpToNextLevel;

  double get levelProgress =>
      xpToNextLevel <= 0 ? 1 : (xpInLevel / xpToNextLevel).clamp(0.0, 1.0);
}
