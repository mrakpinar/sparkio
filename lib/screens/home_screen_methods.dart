part of 'home_screen.dart';

extension _HomeScreenStateMethods on _HomeScreenState {
  String _todayKey() => _controller.todayKey();

  String _adaptiveDifficultyLabel() {
    if (_adaptiveDifficultyDelta > 0) return 'Adaptive mode: harder';
    if (_adaptiveDifficultyDelta < 0) return 'Adaptive mode: easier';
    return '';
  }

  Future<void> _bootstrap() async {
    _updateState(() => _loading = true);
    await _controller.preloadAds();
    final result = await _controller.bootstrap();
    final completionRate = await _controller.getRecentCompletionRate(days: 7);
    final adaptiveDelta = _controller.adaptationDeltaFromCompletionRate(
      completionRate,
    );
    final weekKey = _repo.currentWeekKey();
    final weeklyPlan = await _repo.getWeeklyPlan(weekKey: weekKey);
    final weeklyProgress = await _repo.getWeeklyProgress(weekKey: weekKey);
    final weeklyTargets = weeklyPlan?.targets ?? const <String, int>{};
    final weeklyDone = _filterWeeklyDoneByTargets(
      done: weeklyProgress.done,
      targets: weeklyTargets,
    );
    if (weeklyTargets.isNotEmpty &&
        !_intMapEquals(weeklyDone, weeklyProgress.done)) {
      await _repo.saveWeeklyProgress(
        WeeklyProgress(weekKey: weekKey, done: weeklyDone),
      );
    }
    if (!mounted) return;
    final todayIds = result.today.map((t) => t.id).toSet();
    final normalizedCompleted = <String, bool>{
      for (final id in todayIds) id: result.completed[id] ?? false,
    };
    _updateState(() {
      _streak = result.streak;
      _todayCompleted = result.todayCompleted;
      _reminderEnabled = result.reminderEnabled;
      _today = result.today;
      _completed = normalizedCompleted;
      _premiumActive = result.premiumActive;
      _premiumUntil = result.premiumUntil;
      _noAdsUntil = result.noAdsUntil;
      _dailyAddCount = result.dailyAddCount;
      _adaptiveDifficultyDelta = adaptiveDelta;
      _poolError = result.poolError;
      _weeklyWeekKey = weekKey;
      _weeklyTargets = weeklyTargets;
      _weeklyDone = weeklyDone;
      _loading = false;
    });
    await _restoreActiveTimerIfNeeded();
    unawaited(_syncHomeWidgetSnapshot());
    _track('home_bootstrap_done', {
      'today_task_count': _today.length,
      'pool_error': result.poolError != null,
      'premium_active': _premiumActive,
      'adaptive_delta': _adaptiveDifficultyDelta,
    });
    unawaited(
      AnalyticsService.instance.setUserProperty(
        name: 'premium_active',
        value: _premiumActive ? 'true' : 'false',
      ),
    );
    unawaited(
      AnalyticsService.instance.setUserProperty(
        name: 'theme_mode',
        value: ThemeService.instance.mode.value == ThemeMode.dark
            ? 'dark'
            : 'light',
      ),
    );
    await _syncPremiumTopics(_premiumActive);

    if (result.poolError != null && !_poolErrorShown && mounted) {
      _poolErrorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.poolError!)));
    }

    if (_reminderEnabled) {
      await _controller.applyReminderEnabled(true);
    }

    // Show one interstitial per cold start (after initial load).
    unawaited(() async {
      await Future.delayed(const Duration(milliseconds: 800));
      await _controller.showInterstitialOnLaunch();
    }());

    // Ask once per day, on the first open, to tailor a task to the user's mood.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybePromptWeeklyPlan());
      unawaited(_maybePromptDailyMood());
    });
  }

  List<String> _moodTargetCategories(String mood) {
    switch (mood) {
      case 'stressed':
        return const ['calm', 'mind'];
      case 'low_energy':
        return const ['health', 'body'];
      case 'focus':
        return const ['mind', 'growth'];
      default:
        return const [];
    }
  }

  Future<void> _maybePromptDailyMood() async {
    if (!mounted || _loading || _dailyMoodPrompting) return;
    if (_today.isEmpty) return;

    final dateKey = _todayKey();
    final existing = await _repo.getDailyMood(dateKey);
    if (existing != null) return;

    _updateState(() => _dailyMoodPrompting = true);
    try {
      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return DailyMoodSheet(
            onSelect: (mood) => Navigator.of(sheetContext).pop(mood),
            onSkip: () => Navigator.of(sheetContext).pop(),
          );
        },
      );

      if (!mounted) return;

      // Don't keep re-prompting the user on the same day if they dismiss it.
      if (selected == null) {
        await _repo.setDailyMood(dateKey: dateKey, mood: 'skipped');
        _track('daily_mood_selected', {'mood': 'skipped'});
        return;
      }

      await _repo.setDailyMood(dateKey: dateKey, mood: selected);
      _track('daily_mood_selected', {'mood': selected});
      await _applyMoodToTodayTasks(selected);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Got it — tailored one task for you.')),
      );
    } finally {
      if (mounted) {
        _updateState(() => _dailyMoodPrompting = false);
      } else {
        _dailyMoodPrompting = false;
      }
    }
  }

  Future<void> _openDailyMoodSheetDebug() async {
    if (!mounted || _loading || _dailyMoodPrompting) return;
    if (_today.isEmpty) return;

    _updateState(() => _dailyMoodPrompting = true);
    try {
      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return DailyMoodSheet(
            onSelect: (mood) => Navigator.of(sheetContext).pop(mood),
            onSkip: () => Navigator.of(sheetContext).pop(),
          );
        },
      );

      if (!mounted || selected == null) return;
      final dateKey = _todayKey();
      await _repo.setDailyMood(dateKey: dateKey, mood: selected);
      _track('daily_mood_selected_debug', {'mood': selected});
      await _applyMoodToTodayTasks(selected);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debug mood selection applied.')),
      );
    } finally {
      if (mounted) {
        _updateState(() => _dailyMoodPrompting = false);
      } else {
        _dailyMoodPrompting = false;
      }
    }
  }

  Future<void> _applyMoodToTodayTasks(String mood) async {
    final targets = _moodTargetCategories(mood);
    if (targets.isEmpty || _today.isEmpty) return;
    final dateKey = _todayKey();

    // If today already contains a matching category, keep the list stable.
    if (_today.any((t) => targets.contains(t.category))) return;

    final pool = await _repo.loadPool();
    if (pool.isEmpty) return;

    final todayIds = _today.map((t) => t.id).toSet();
    final candidates = pool
        .where(
          (t) =>
              targets.contains(t.category) &&
              !todayIds.contains(t.id) &&
              (_premiumActive || !t.premiumOnly),
        )
        .toList();
    if (candidates.isEmpty) return;

    final replaceIndex = _today.indexWhere(
      (t) => _completed[t.id] != true && !t.isCustom,
    );
    final idx = replaceIndex >= 0
        ? replaceIndex
        : _today.indexWhere((t) => _completed[t.id] != true);
    if (idx < 0) return;

    candidates.shuffle(Random('$dateKey-$mood'.hashCode));
    final chosen = candidates.first;

    final updated = [..._today];
    updated[idx] = chosen;

    _updateState(() {
      _today = updated;
      _syncCompletedMap();
    });

    await _repo.saveSelectedTasks(updated);
    await _repo.saveCompletedMap(_completed);
    await _controller.updateLastSeen(dateKey: _todayKey(), tasks: [chosen]);
  }

  Future<void> _maybePromptWeeklyPlan() async {
    if (!mounted || _loading) return;
    if (_weeklyTargets.isNotEmpty) return;
    await _openWeeklyPlanSheet(
      autoPrompt: true,
      forceForWeek: _weeklyWeekKey.isEmpty
          ? _repo.currentWeekKey()
          : _weeklyWeekKey,
    );
  }

  Future<void> _openWeeklyPlanSheet({
    bool autoPrompt = false,
    String? forceForWeek,
  }) async {
    final weekKey = forceForWeek ?? _repo.currentWeekKey();
    final plan = await _repo.getWeeklyPlan(weekKey: weekKey);
    final initialTargets = {
      'mind': plan?.targets['mind'] ?? 0,
      'body': plan?.targets['body'] ?? 0,
      'growth': plan?.targets['growth'] ?? 0,
      'calm': plan?.targets['calm'] ?? 0,
      'health': plan?.targets['health'] ?? 0,
    };

    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return WeeklyPlanSheet(
          initialTargets: initialTargets,
          onSave: (targets) => Navigator.of(sheetContext).pop(targets),
          onSkip: () => Navigator.of(sheetContext).pop(),
          showSkip: autoPrompt,
        );
      },
    );

    if (result == null) return;

    final cleaned = <String, int>{};
    for (final entry in result.entries) {
      if (entry.value > 0) {
        cleaned[entry.key] = entry.value;
      }
    }

    if (cleaned.isEmpty) {
      await _repo.clearWeeklyPlan();
      if (!mounted) return;
      _updateState(() {
        _weeklyWeekKey = weekKey;
        _weeklyTargets = {};
        _weeklyDone = {};
      });
      _track('weekly_plan_updated', {'has_targets': false, 'target_total': 0});
      return;
    }

    final hadPlan = plan != null && plan.targets.isNotEmpty;
    final weeklyPlan = WeeklyPlan(weekKey: weekKey, targets: cleaned);
    await _repo.saveWeeklyPlan(weeklyPlan);
    final progress = await _repo.getWeeklyProgress(weekKey: weekKey);
    final filteredDone = _filterWeeklyDoneByTargets(
      done: progress.done,
      targets: cleaned,
    );
    if (!_intMapEquals(filteredDone, progress.done)) {
      await _repo.saveWeeklyProgress(
        WeeklyProgress(weekKey: weekKey, done: filteredDone),
      );
    }
    if (!mounted) return;
    _updateState(() {
      _weeklyWeekKey = weekKey;
      _weeklyTargets = cleaned;
      _weeklyDone = filteredDone;
    });

    final total = cleaned.values.fold<int>(0, (sum, value) => sum + value);
    _track(hadPlan ? 'weekly_plan_updated' : 'weekly_plan_created', {
      'target_total': total,
      'categories': cleaned.length,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Weekly plan saved: ${_weeklyDoneTotal()}/$total'),
      ),
    );
  }

  int _weeklyDoneTotal() => _weeklyDone.values.fold<int>(0, (s, v) => s + v);

  int _weeklyTargetTotal() =>
      _weeklyTargets.values.fold<int>(0, (s, v) => s + v);

  Map<String, int> _filterWeeklyDoneByTargets({
    required Map<String, int> done,
    required Map<String, int> targets,
  }) {
    if (done.isEmpty || targets.isEmpty) return const <String, int>{};
    final filtered = <String, int>{};
    for (final entry in done.entries) {
      final target = targets[entry.key] ?? 0;
      if (target <= 0) continue;
      final value = entry.value;
      if (value <= 0) continue;
      filtered[entry.key] = value;
    }
    return filtered;
  }

  bool _intMapEquals(Map<String, int> a, Map<String, int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  double get _progress {
    if (_today.isEmpty) return 0;
    final done = _today.where((t) => _completed[t.id] == true).length;
    return done / _today.length;
  }

  void _applyAddTaskResult(AddTaskResult result) {
    _updateState(() {
      _today = result.updated;
      _completed[result.task.id] = false;
      _syncCompletedMap();
      _dailyAddCount = result.newCount;
      _premiumActive = result.premiumActive;
      _customCategory = result.task.category;
      _customDifficulty = result.task.difficulty;
      _customDuration = result.task.durationMinutes;
    });
    _repo.saveCompletedMap(_completed);
    unawaited(_syncHomeWidgetSnapshot());
  }

  void _applyAiResponse(AiTaskResponse response) {
    if (!response.success) return;
    final updated = response.updated!;
    final added = response.added ?? const <Task>[];
    _updateState(() {
      _today = updated;
      for (final task in added) {
        _completed[task.id] = false;
      }
      _syncCompletedMap();
      _dailyAddCount = response.newCount ?? _dailyAddCount;
      if (added.isNotEmpty) {
        final last = added.last;
        _customCategory = last.category;
        _customDifficulty = last.difficulty;
        _customDuration = last.durationMinutes;
      }
    });
    _repo.saveCompletedMap(_completed);
    unawaited(_syncHomeWidgetSnapshot());
  }

  void _syncCompletedMap() {
    final ids = _today.map((t) => t.id).toSet();
    _completed = {for (final id in ids) id: _completed[id] ?? false};
  }

  Future<void> _syncHomeWidgetSnapshot() async {
    final remainingTasks = _today.where((t) => _completed[t.id] != true).length;
    final timerActive = _activeTimerTask != null;
    final timerRemaining = _activeTimerFinished
        ? 0
        : _activeTimerRemaining.inSeconds;
    await HomeWidgetService.instance.updateSnapshot(
      remainingTasks: remainingTasks,
      timerActive: timerActive,
      timerFinished: timerActive && _activeTimerFinished,
      timerTaskTitle: _activeTimerTask?.title,
      timerRemainingSec: timerRemaining,
    );
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  void _track(String event, [Map<String, Object?> params = const {}]) {
    unawaited(AnalyticsService.instance.logEvent(event, params: params));
  }

  List<String> get _successMessages => const [
    'Well done ',
    'Small step, big win.',
    'Keep going ',
  ];

  Future<void> _syncPremiumTopics([bool? premiumActive]) async {
    try {
      await _controller.syncNotificationTopics(
        premiumActive: premiumActive ?? _premiumActive,
      );
    } catch (_) {
      // Best-effort: ignore topic sync errors.
    }
  }

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

  void _openMenu() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Widget _buildEndDrawer() {
    Theme.of(context);
    final isDark = ThemeService.instance.mode.value == ThemeMode.dark;

    return ModernDrawer(
      isDark: isDark,
      onToggleTheme: _toggleTheme,
      onOpenBadges: _openBadges,
      onOpenWeeklyPlan: () => _openWeeklyPlanSheet(),
      onOpenContact: _openContact,
      onSendTestNotification: _sendTestNotification,
    );
  }

  void _toggleTheme() {
    ThemeService.instance.toggle();
    if (mounted) {
      _updateState(() {});
    }
  }

  void _openBadges() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BadgesScreen()),
    );
  }

  void _openContact() {
    _openInstagramContact();
  }

  Future<void> _openInstagramContact() async {
    final scheme = Theme.of(context).colorScheme;
    try {
      final opened = await launchUrl(
        _HomeScreenState._instagramUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open Instagram right now.'),
            backgroundColor: scheme.error,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to open Instagram right now.'),
          backgroundColor: scheme.error,
        ),
      );
    }
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
    _updateState(() {
      _today = updated;
      _completed[special.id] = false;
    });
  }

  Future<void> _watchAdForReward({
    required Duration duration,
    required bool noAds,
  }) async {
    if (_rewardBusy) return;
    _track('rewarded_watch_started', {
      'reward_type': noAds ? 'no_ads' : 'premium',
    });
    _updateState(() => _rewardBusy = true);
    final scheme = Theme.of(context).colorScheme;

    try {
      final result = await _controller.watchAdForReward(
        duration: duration,
        noAds: noAds,
      );

      if (!result.success) {
        _track('rewarded_watch_failed', {
          'reward_type': noAds ? 'no_ads' : 'premium',
          'reason': result.failure?.name ?? 'unknown',
        });
        if (mounted) {
          final message = result.failure == RewardFailure.notReady
              ? 'Could not load ad. Try again later.'
              : 'Watch the full ad to unlock.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: result.failure == RewardFailure.notReady
                  ? scheme.error
                  : null,
            ),
          );
        }
        return;
      }

      final status = result.status!;
      _track('rewarded_watch_completed', {
        'reward_type': noAds ? 'no_ads' : 'premium',
        'premium_active': status.premiumActive,
      });
      _track('rewarded_watched', {'reward_type': noAds ? 'no_ads' : 'premium'});
      if (!noAds && !_premiumActive && status.premiumActive) {
        _track('premium_started', {'source': 'rewarded'});
      }
      if (!mounted) return;
      _updateState(() {
        _premiumActive = status.premiumActive;
        _premiumUntil = status.premiumUntil;
        _noAdsUntil = status.noAdsUntil;
      });
      await _syncPremiumTopics(_premiumActive);

      await _grantSpecialTask();

      if (mounted) {
        // Close the perks sheet so the user sees updated status on reopen.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(noAds ? 'No ads unlocked.' : 'Premium unlocked.'),
            backgroundColor: scheme.primary,
          ),
        );
      }
    } finally {
      if (mounted) _updateState(() => _rewardBusy = false);
    }
  }

  Future<bool> _addCustomTask(
    String title,
    String category,
    String difficulty,
    int durationMinutes,
  ) async {
    final result = await _controller.addCustomTaskWithLimit(
      title: title,
      category: category,
      difficulty: difficulty,
      durationMinutes: durationMinutes,
      current: _today,
      dailyAddCount: _dailyAddCount,
    );

    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Daily limit reached.')));
      return false;
    }

    _applyAddTaskResult(result.data!);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task added.')));
    return true;
  }

  Future<void> _generateAiTask() async {
    final result = await _controller.generateAiTask(
      category: _customCategory,
      current: _today,
    );

    if (!result.success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI tasks are Premium only.')),
      );
      return;
    }

    _applyAiResponse(result);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI task added.')));
    }
  }

  Future<List<Task>> _loadEffectivePool() async {
    final result = await _controller.loadEffectivePool(
      currentPremiumActive: _premiumActive,
    );
    if (result.premiumChanged && mounted) {
      _updateState(() => _premiumActive = result.premiumActive);
      await _syncPremiumTopics(_premiumActive);
    }
    if (mounted) {
      _updateState(() => _poolError = result.poolError);
    }
    if (result.poolError != null && !_poolErrorShown && mounted) {
      _poolErrorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.poolError!)));
    }
    return result.pool;
  }

  Future<void> _retryLoadPool() async {
    _updateState(() {
      _poolErrorShown = false;
      _poolError = null;
    });
    await _bootstrap();
  }

  Future<void> _runRewardedAction({
    required Future<bool> Function() action,
    required String successMessage,
  }) async {
    if (_rewardBusy) return;
    _updateState(() => _rewardBusy = true);

    final ready = await _controller.ensureRewardedReady();
    if (!ready) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load ad. Try again later.')),
        );
      }
      if (mounted) _updateState(() => _rewardBusy = false);
      return;
    }

    final unlocked = await _controller.showRewardedToUnlock();
    if (!unlocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Watch the full ad to unlock.')),
        );
      }
      if (mounted) _updateState(() => _rewardBusy = false);
      return;
    }

    final ok = await action();
    if (!ok) {
      if (mounted) _updateState(() => _rewardBusy = false);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      _updateState(() => _rewardBusy = false);
    }
  }

  Future<void> _showSkipGate({String? taskId}) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final choice = await showDialog<_SkipChoice>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.primaryContainer],
                        ),
                      ),
                      child: const Icon(
                        Icons.fast_forward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Skip limit reached',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_SkipChoice.cancel),
                      icon: const Icon(Icons.close_rounded),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'You can skip 1 task per day on the free plan. Unlock more skips or go Premium.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(_SkipChoice.premium),
                    icon: const Icon(Icons.star_rounded),
                    label: const Text('Go Premium'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(_SkipChoice.rewarded),
                    icon: const Icon(Icons.play_circle_fill_rounded),
                    label: const Text('Watch ad for skip'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null || choice == _SkipChoice.cancel) return;
    if (choice == _SkipChoice.premium) {
      await _openSubscribeSheet();
      return;
    }

    await _runRewardedAction(
      action: () => _skipOneTask(bypassLimit: true, taskId: taskId),
      successMessage: 'Task skipped.',
    );
  }

  Future<bool> _skipOneTask({bool bypassLimit = true, String? taskId}) async {
    final dateKey = _todayKey();
    final skipCount = await _repo.getSkipCount(dateKey);
    final maxSkips = _premiumActive ? _HomeScreenState._maxSkipsPerDay : 1;
    if (!bypassLimit && skipCount >= maxSkips) {
      if (!_premiumActive) {
        await _showSkipGate(taskId: taskId);
      } else if (mounted) {
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

    final picked = _controller.pickTasksNoRepeat(
      pool: pool,
      count: 1,
      seedKey: 'skip_${DateTime.now().millisecondsSinceEpoch}',
      avoidIds: currentIds.union(avoidIds),
    );

    if (picked.isEmpty) return false;

    final updated = [..._today]..removeAt(idx);
    updated.insert(idx, picked.first);
    await _repo.saveSelectedTasks(updated);
    await _controller.updateLastSeen(
      dateKey: _todayKey(),
      tasks: [picked.first],
    );
    await _repo.incrementSkipCount(dateKey);

    if (!mounted) return false;
    _updateState(() {
      _today = updated;
      _completed.remove(removed.id);
    });
    _track('task_skipped', {
      'task_id': removed.id,
      'bypass_limit': bypassLimit,
      'premium_active': _premiumActive,
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

    final picked = _controller.pickTasksNoRepeat(
      pool: pool,
      count: 1,
      seedKey: 'extra_${DateTime.now().millisecondsSinceEpoch}',
      avoidIds: currentIds.union(avoidIds),
    );

    if (picked.isEmpty) return false;

    final updated = [..._today, picked.first];
    await _repo.saveSelectedTasks(updated);
    await _controller.updateLastSeen(
      dateKey: _todayKey(),
      tasks: [picked.first],
    );

    if (!mounted) return false;
    _updateState(() {
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

  Future<Uint8List> _captureShareBytes() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _sharePreviewKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Share card is not ready yet.');
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Unable to capture share image.');
    }
    return byteData.buffer.asUint8List();
  }

  Future<File> _writeShareImage() async {
    final bytes = await _captureShareBytes();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/sparkio_streak_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _shareImage({String? hint}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 20));
      final file = await _writeShareImage();
      final baseText = 'My Sparkio streak: $_streak days.';
      final text = hint == null ? baseText : '$baseText ($hint)';
      await Share.shareXFiles([XFile(file.path)], text: text);
    } catch (_) {
      if (mounted) _showSnack('Unable to share right now.');
    }
  }

  Future<void> _openShareSheet() async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final earnedBadgeIds = await _repo.getEarnedBadges();
    final orderedBadgeIds = _shareBadgeOrder
        .where(earnedBadgeIds.contains)
        .toList();
    for (final id in earnedBadgeIds) {
      if (!orderedBadgeIds.contains(id)) {
        orderedBadgeIds.add(id);
      }
    }
    final shareBadges = orderedBadgeIds
        .take(4)
        .map(_badgeInfo)
        .map(
          (info) => ShareBadgeChipData(
            label: info.label,
            icon: info.icon,
            color: info.color,
          ),
        )
        .toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: scheme.outline),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: scheme.outline,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Share your streak',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      splashRadius: 18,
                    ),
                  ],
                ),
                Text(
                  'Your progress, ready for stories.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: RepaintBoundary(
                      key: _sharePreviewKey,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: 360,
                          height: 640,
                          child: StreakShareCard(
                            streak: _streak,
                            doneCount: _today
                                .where((t) => _completed[t.id] == true)
                                .length,
                            totalCount: _today.length,
                            dateLabel: DateFormat(
                              'EEE, MMM d',
                            ).format(DateTime.now()),
                            badges: shareBadges,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _shareImage,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const List<String> _shareBadgeOrder = [
    'total_100',
    'total_50',
    'total_10',
    'streak_7',
    'streak_3',
    'cat_mind_10',
    'cat_body_10',
    'cat_growth_10',
    'cat_calm_10',
    'cat_health_10',
  ];

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
          premiumActive:
              _premiumUntil != null && _premiumUntil!.isAfter(DateTime.now()),
          noAdsActive:
              _noAdsUntil != null && _noAdsUntil!.isAfter(DateTime.now()),
          premiumStatus: _formatRemaining(_premiumUntil),
          noAdsStatus: _formatRemaining(_noAdsUntil),
          onWatchPremium: () => _watchAdForReward(
            duration: const Duration(minutes: 30),
            noAds: false,
          ),
          onWatchNoAds: () =>
              _watchAdForReward(duration: const Duration(days: 1), noAds: true),
          onOpenSubscribe: _openSubscribeSheet,
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

  Future<void> _openSubscribeSheet() async {
    final wasPremium = _premiumActive;
    _track('premium_purchase_opened');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const PremiumPurchaseSheet();
      },
    );
    final status = await _controller.loadPremiumStatus();
    if (!mounted) return;
    _updateState(() {
      _premiumActive = status.premiumActive;
      _premiumUntil = status.premiumUntil;
      _noAdsUntil = status.noAdsUntil;
    });
    if (!wasPremium && _premiumActive) {
      _track('premium_purchase_success');
      _track('premium_started', {'source': 'iap'});
    }
    await _syncPremiumTopics(_premiumActive);
  }

  Future<void> _toggle(Task t) async {
    final newVal = !(_completed[t.id] ?? false);
    if (newVal) {
      if (kDebugMode && _debugInstantComplete) {
        await _completeTaskImmediately(t);
      } else {
        await _startTaskTimer(t);
        return;
      }
    }
    _updateState(() => _completed[t.id] = newVal);
    await _repo.saveCompletedMap(_completed);

    if (newVal) {
      await _markTaskDone(t);
    } else {
      final newDaily = await _repo.incrementDailyCompleted(
        _todayKey(),
        delta: -1,
      );
      if (mounted) _updateState(() => _todayCompleted = newDaily);
    }

    await _applyStreakIfAllDone();
    unawaited(_syncHomeWidgetSnapshot());
  }

  Future<void> _applyStreakIfAllDone() async {
    final done = _today.where((x) => _completed[x.id] == true).length;
    final allDone = _today.isNotEmpty && done == _today.length;
    if (!allDone) return;

    final todayKey = _todayKey();
    if (_allDoneShownKey == todayKey) return;
    _allDoneShownKey = todayKey;

    final lastDone = await _repo.getLastCompletedDate();
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    DateTime? lastDoneDate;
    if (lastDone != null && lastDone.isNotEmpty) {
      try {
        lastDoneDate = DateFormat('yyyy-MM-dd').parse(lastDone);
      } catch (_) {
        lastDoneDate = null;
      }
    }

    final resolution = StreakService.resolveNextStreak(
      currentStreak: _streak,
      today: todayDate,
      lastCompletedDate: lastDoneDate,
    );
    final diffDays = lastDoneDate == null
        ? null
        : todayDate.difference(lastDoneDate).inDays;
    _log(
      "STREAK: lastDone=$lastDone today=$todayKey diffDays=$diffDays current=$_streak next=${resolution.nextStreak} update=${resolution.shouldUpdate}",
    );

    unawaited(_showAllDoneCelebration());

    if (!resolution.shouldUpdate) return;
    final newStreak = resolution.nextStreak;

    await _repo.setStreakCount(newStreak);
    await _repo.setLastCompletedDate(todayKey);
    await _repo.setBestStreakIfHigher(newStreak);
    _track('streak_updated', {'new_streak': newStreak, 'was_all_done': true});
    if (newStreak > _streak) {
      _track('streak_incremented', {'new_streak': newStreak});
    }

    final totalCompleted = await _repo.getTotalCompleted();
    final categoryCounts = await _repo.getCategoryCounts();
    final streakBadges = await _repo.awardBadges(
      totalCompleted: totalCompleted,
      bestStreak: newStreak,
      categoryCounts: categoryCounts,
    );
    if (mounted && streakBadges.isNotEmpty) {
      _showBadgeUnlocked(streakBadges.first);
    }

    if (!mounted) return;
    _updateState(() => _streak = newStreak);
  }

  Future<void> _completeTaskImmediately(Task t) async {
    _updateState(() => _completed[t.id] = true);
    await _repo.saveCompletedMap(_completed);
  }

  Future<void> _showAllDoneCelebration() async {
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'All done',
      barrierColor: Colors.black.withOpacity(0.75),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, _, _) {
        final scale = Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: scale,
            child: _AllDoneOverlay(
              scheme: scheme,
              onViewStats: () {
                Navigator.of(ctx).maybePop();
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const StatsScreen()));
              },
            ),
          ),
        );
      },
    );
  }

  void _showBadgeUnlocked(String badgeId) {
    final info = _badgeInfo(badgeId);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Badge unlocked',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, _, _) {
        return Center(child: HomeBadgeUnlockOverlay(info: info));
      },
      transitionBuilder: (context, animation, _, child) {
        final scale = Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  BadgeInfo _badgeInfo(String id) {
    switch (id) {
      case 'total_10':
        return const BadgeInfo(
          id: 'total_10',
          label: '10 tasks',
          description: 'Complete 10 total tasks.',
          icon: Icons.bolt_rounded,
          color: Color(0xFF60A5FA),
        );
      case 'total_50':
        return const BadgeInfo(
          id: 'total_50',
          label: '50 tasks',
          description: 'Complete 50 total tasks.',
          icon: Icons.emoji_events_rounded,
          color: Color(0xFFFBBF24),
        );
      case 'total_100':
        return const BadgeInfo(
          id: 'total_100',
          label: '100 tasks',
          description: 'Complete 100 total tasks.',
          icon: Icons.workspace_premium_rounded,
          color: Color(0xFFFB7185),
        );
      case 'streak_3':
        return const BadgeInfo(
          id: 'streak_3',
          label: '3-day streak',
          description: 'Finish tasks 3 days in a row.',
          icon: Icons.local_fire_department_rounded,
          color: Color(0xFFF97316),
        );
      case 'streak_7':
        return const BadgeInfo(
          id: 'streak_7',
          label: '7-day streak',
          description: 'Keep a 7 day streak.',
          icon: Icons.whatshot_rounded,
          color: Color(0xFFEF4444),
        );
      case 'cat_mind_10':
        return const BadgeInfo(
          id: 'cat_mind_10',
          label: 'Mind x10',
          description: 'Complete 10 Mind tasks.',
          icon: Icons.psychology_rounded,
          color: Color(0xFF8B5CF6),
        );
      case 'cat_body_10':
        return const BadgeInfo(
          id: 'cat_body_10',
          label: 'Body x10',
          description: 'Complete 10 Body tasks.',
          icon: Icons.fitness_center_rounded,
          color: Color(0xFFF97316),
        );
      case 'cat_growth_10':
        return const BadgeInfo(
          id: 'cat_growth_10',
          label: 'Growth x10',
          description: 'Complete 10 Growth tasks.',
          icon: Icons.trending_up_rounded,
          color: Color(0xFF22C55E),
        );
      case 'cat_calm_10':
        return const BadgeInfo(
          id: 'cat_calm_10',
          label: 'Calm x10',
          description: 'Complete 10 Calm tasks.',
          icon: Icons.spa_rounded,
          color: Color(0xFF06B6D4),
        );
      case 'cat_health_10':
        return const BadgeInfo(
          id: 'cat_health_10',
          label: 'Health x10',
          description: 'Complete 10 Health tasks.',
          icon: Icons.favorite_rounded,
          color: Color(0xFF3B82F6),
        );
      default:
        return const BadgeInfo(
          id: 'unknown',
          label: 'New badge',
          description: 'You unlocked a new badge.',
          icon: Icons.emoji_events_rounded,
          color: Color(0xFF60A5FA),
        );
    }
  }

  Future<void> _startTaskTimer(Task task) async {
    final duration = Duration(minutes: task.durationMinutes);
    final notificationId = _taskTimerNotificationId(task.id);
    if (_activeTimerTask != null && _activeTimerTask!.id != task.id) {
      await _cancelTaskTimer(_activeTimerTask!);
    }
    _activeTimerTicker?.cancel();
    final endAt = DateTime.now().add(duration);
    _updateState(() {
      _activeTimerTask = task;
      _activeTimerRemaining = duration;
      _activeTimerFinished = false;
    });
    _track('task_started', {
      'task_id': task.id,
      'category': task.category,
      'duration_min': task.durationMinutes,
      'difficulty': task.difficulty,
    });
    await _repo.saveActiveTaskTimer(
      taskId: task.id,
      taskTitle: task.title,
      endAt: endAt,
    );

    _startActiveTimerTicker(
      task: task,
      endAt: endAt,
      notificationId: notificationId,
    );

    // Best-effort local scheduling for the "timer finished" notification (covers
    // background/idle). Do not block the UI timer if scheduling fails.
    unawaited(() async {
      try {
        await NotificationService.instance.cancelTaskTimer(notificationId);
        await NotificationService.instance.scheduleTaskTimer(
          notificationId: notificationId,
          title: 'Task timer finished',
          body: '${task.title} is ready to mark done.',
          duration: duration,
        );
      } catch (e) {
        _log('NOTI: scheduleTaskTimer failed: $e');
        if (mounted) {
          final scheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Timer notification failed: $e', maxLines: 3),
              backgroundColor: scheme.error,
            ),
          );
        }
      }
    }());

    _showTaskTimerOngoingBestEffort(task: task, remaining: duration);
    unawaited(_syncHomeWidgetSnapshot());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Go finish this task: ${task.title}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _cancelTaskTimer(Task task) async {
    final notificationId = _taskTimerNotificationId(task.id);
    await NotificationService.instance.cancelTaskTimer(notificationId);
    await NotificationService.instance.cancelTaskTimerOngoing();
    await _repo.clearActiveTaskTimer();
    _activeTimerTicker?.cancel();
    if (!mounted) return;
    _updateState(() {
      _activeTimerTask = null;
      _activeTimerRemaining = Duration.zero;
      _activeTimerFinished = false;
    });
    unawaited(_syncHomeWidgetSnapshot());
  }

  Future<void> _markTaskDone(Task task) async {
    final completedFromTimer = _activeTimerTask?.id == task.id;
    final weekKey = _repo.currentWeekKey();
    final beforeWeekDone = _weeklyDoneTotal();
    final weekTarget = _weeklyTargetTotal();
    await HapticFeedback.lightImpact();
    await _showSuccessPulse(_pickSuccessMessage());
    if (_activeTimerTask?.id == task.id) {
      await _cancelTaskTimer(task);
    }
    await _repo.incrementCompleted(task.category);
    final newDaily = await _repo.incrementDailyCompleted(_todayKey());
    await _repo.setLastCompletedTask(
      title: task.title,
      category: task.category,
      dateKey: _todayKey(),
    );
    final total = await _repo.getTotalCompleted();
    final best = await _repo.getBestStreak();
    final counts = await _repo.getCategoryCounts();
    final newBadges = await _repo.awardBadges(
      totalCompleted: total,
      bestStreak: best,
      categoryCounts: counts,
    );
    final categoryTarget = _weeklyTargets[task.category] ?? 0;
    if (categoryTarget > 0) {
      final progress = await _repo.incrementWeeklyProgress(
        weekKey: weekKey,
        category: task.category,
      );
      if (mounted) {
        _updateState(() {
          _weeklyWeekKey = weekKey;
          _weeklyDone = progress.done;
        });
      }
      final afterWeekDone = progress.totalDone;
      _track('weekly_progress_updated', {
        'week_key': weekKey,
        'category': task.category,
        'done_total': afterWeekDone,
        'target_total': weekTarget,
      });
      if (weekTarget > 0 &&
          beforeWeekDone < weekTarget &&
          afterWeekDone >= weekTarget) {
        _track('weekly_goal_hit', {
          'week_key': weekKey,
          'target_total': weekTarget,
          'done_total': afterWeekDone,
        });
      }
    }
    _track('task_completed', {
      'task_id': task.id,
      'category': task.category,
      'duration_min': task.durationMinutes,
      'from_timer': completedFromTimer,
    });
    if (mounted && newBadges.isNotEmpty) {
      _showBadgeUnlocked(newBadges.first);
    }
    if (mounted) _updateState(() => _todayCompleted = newDaily);
  }

  int _taskTimerNotificationId(String taskId) {
    // Avoid collisions with fixed notification IDs (e.g. daily reminder, ongoing timer).
    final h = taskId.hashCode & 0x7fffffff;
    return 300000 + (h % 100000);
  }

  Future<void> _restoreActiveTimerIfNeeded() async {
    try {
      final saved = await _repo.getActiveTaskTimer();
      if (saved == null) {
        await _syncHomeWidgetSnapshot();
        return;
      }

      Task? matchedTask;
      for (final task in _today) {
        if (task.id == saved.taskId) {
          matchedTask = task;
          break;
        }
      }

      if (matchedTask == null) {
        await _repo.clearActiveTaskTimer();
        await NotificationService.instance.cancelTaskTimerOngoing();
        await _syncHomeWidgetSnapshot();
        return;
      }

      final notificationId = _taskTimerNotificationId(matchedTask.id);
      final remaining = saved.endAt.difference(DateTime.now());
      _activeTimerTicker?.cancel();

      if (remaining <= Duration.zero) {
        _updateState(() {
          _activeTimerTask = matchedTask;
          _activeTimerRemaining = Duration.zero;
          _activeTimerFinished = true;
        });
        await NotificationService.instance.cancelTaskTimer(notificationId);
        await NotificationService.instance.cancelTaskTimerOngoing();
        await _syncHomeWidgetSnapshot();
        return;
      }

      _updateState(() {
        _activeTimerTask = matchedTask;
        _activeTimerRemaining = remaining;
        _activeTimerFinished = false;
      });
      _track('task_timer_restored', {
        'task_id': matchedTask.id,
        'remaining_sec': remaining.inSeconds,
      });

      _startActiveTimerTicker(
        task: matchedTask,
        endAt: saved.endAt,
        notificationId: notificationId,
      );
      _showTaskTimerOngoingBestEffort(task: matchedTask, remaining: remaining);
      await _syncHomeWidgetSnapshot();
    } catch (e) {
      _log('TIMER: restore failed: $e');
    }
  }

  void _startActiveTimerTicker({
    required Task task,
    required DateTime endAt,
    required int notificationId,
  }) {
    // Keep UI timer in sync and fire completion notification when app is active.
    _activeTimerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = endAt.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        _updateState(() {
          _activeTimerRemaining = Duration.zero;
          _activeTimerFinished = true;
        });
        unawaited(NotificationService.instance.cancelTaskTimerOngoing());
        unawaited(NotificationService.instance.cancelTaskTimer(notificationId));
        unawaited(
          NotificationService.instance.showTaskTimerNotification(
            title: 'Task timer finished',
            body: '${task.title} is ready to mark done.',
          ),
        );
        _track('task_timer_finished', {
          'task_id': task.id,
          'duration_min': task.durationMinutes,
        });
        _track('timer_finished', {
          'task_id': task.id,
          'duration_min': task.durationMinutes,
        });
        unawaited(_syncHomeWidgetSnapshot());
        _activeTimerTicker?.cancel();
        return;
      }
      _updateState(() => _activeTimerRemaining = remaining);
      if (remaining.inSeconds % 15 == 0) {
        _showTaskTimerOngoingBestEffort(task: task, remaining: remaining);
        unawaited(_syncHomeWidgetSnapshot());
      }
    });
  }

  void _showTaskTimerOngoingBestEffort({
    required Task task,
    required Duration remaining,
  }) {
    final total = Duration(minutes: task.durationMinutes);
    unawaited(() async {
      try {
        await NotificationService.instance.showTaskTimerOngoing(
          taskTitle: task.title,
          remaining: remaining,
          total: total,
        );
      } catch (e) {
        _log('NOTI: showTaskTimerOngoing failed: $e');
      }
    }());
  }

  Future<void> _refreshTasks() async {
    final scheme = Theme.of(context).colorScheme;
    final dateKey = _todayKey();
    final refreshCount = await _repo.getRefreshCount(dateKey);
    if (refreshCount >= _HomeScreenState._maxRefreshPerDay) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily refresh limit reached.')),
        );
      }
      return;
    }

    _log(" REFRESH: Starting...");

    if (_refreshing) {
      _log(" REFRESH: Already refreshing...");
      return;
    }

    final premiumNow = await _premium.isPremiumActive();
    if (mounted && premiumNow != _premiumActive) {
      _updateState(() => _premiumActive = premiumNow);
      await _syncPremiumTopics(_premiumActive);
    }

    if (premiumNow) {
      await _performRefresh(
        scheme: scheme,
        dateKey: dateKey,
        premiumActive: premiumNow,
        refreshCount: refreshCount,
      );
      return;
    }

    final choice = await showDialog<_RefreshChoice>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.primaryContainer],
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Fresh set, fresh momentum',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_RefreshChoice.cancel),
                      icon: const Icon(Icons.close_rounded),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Pick how you want to unlock a new set today.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withOpacity(0.18),
                        scheme.secondary.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign_rounded),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Limited offer: 30 min Premium + 1 bonus task',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(_RefreshChoice.premium),
                    icon: const Icon(Icons.star_rounded),
                    label: const Text('Go Premium'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(_RefreshChoice.rewarded),
                    icon: const Icon(Icons.play_circle_fill_rounded),
                    label: const Text('Unlock with ad'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null || choice == _RefreshChoice.cancel) {
      return;
    }

    if (choice == _RefreshChoice.premium) {
      await _openSubscribeSheet();
      return;
    }

    _updateState(() => _refreshing = true);

    if (!_adService.rewardedReady) {
      _log(" REFRESH: Waiting for ad to load...");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Loading ad, please wait..."),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    final ready = await _controller.ensureRewardedReady();
    if (!ready) {
      _log(" REFRESH: Ad failed to load after waiting");
      _updateState(() => _refreshing = false);
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

    _log(" REFRESH: Showing rewarded ad...");
    final unlocked = await _controller.showRewardedToUnlock();
    _log(" REFRESH: Ad result = $unlocked");

    if (!unlocked) {
      _log(" REFRESH: User didn't complete ad");
      _updateState(() => _refreshing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Watch the complete ad to unlock new tasks."),
          ),
        );
      }
      return;
    }

    await _performRefresh(
      scheme: scheme,
      dateKey: dateKey,
      premiumActive: false,
      refreshCount: refreshCount,
    );
  }

  Future<void> _performRefresh({
    required ColorScheme scheme,
    required String dateKey,
    required bool premiumActive,
    required int refreshCount,
  }) async {
    _log(" REFRESH: Loading new tasks...");
    final pool = await _repo.loadPool();
    final poolError = _repo.lastPoolError;
    if (poolError != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(poolError)));
    }
    final lastSeenDate = await _repo.getLastSeenDate();
    final lastSeenIds = await _repo.getLastSeenTaskIds();
    _log(" REFRESH: Pool size = ${pool.length}");

    final effectivePool = premiumActive
        ? pool
        : pool.where((t) => !t.premiumOnly).toList();
    if (effectivePool.isEmpty) {
      _updateState(() => _refreshing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tasks available right now.')),
        );
      }
      return;
    }

    final currentIds = _today.map((t) => t.id).toSet();
    // Avoid repeating tasks from earlier refreshes for the first 2 refreshes.
    final avoidIds = (lastSeenDate == dateKey && refreshCount < 2)
        ? lastSeenIds.toSet()
        : <String>{};
    _log(" REFRESH: Current task IDs = $currentIds");

    List<Task> availablePool = effectivePool
        .where((t) => !currentIds.contains(t.id))
        .where((t) => !avoidIds.contains(t.id))
        .toList();
    if (availablePool.length < 3) {
      // Relax filters to avoid empty refresh.
      availablePool = effectivePool
          .where((t) => !avoidIds.contains(t.id))
          .toList();
    }
    if (availablePool.length < 3) {
      availablePool = effectivePool.toList();
    }
    _log(" REFRESH: Available pool size = ${availablePool.length}");

    if (availablePool.isEmpty) {
      _updateState(() => _refreshing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Not enough tasks available right now."),
            backgroundColor: scheme.secondary,
          ),
        );
      }
      return;
    }

    final picked = _controller.pickDailyTasks(
      pool: availablePool,
      count: min(3, availablePool.length),
      seedKey: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
      weeklyTargets: _weeklyTargets.isEmpty ? null : _weeklyTargets,
      weeklyDone: _weeklyDone.isEmpty ? null : _weeklyDone,
    );
    final completionRate = await _controller.getRecentCompletionRate(days: 7);
    final adaptiveDelta = _controller.adaptationDeltaFromCompletionRate(
      completionRate,
    );
    final adapted = _controller.applyDifficultyDelta(
      tasks: picked,
      delta: adaptiveDelta,
    );
    if (adaptiveDelta != 0) {
      _track('difficulty_adapted', {
        'source': 'refresh',
        'completion_rate': double.parse(completionRate.toStringAsFixed(3)),
        'delta': adaptiveDelta,
      });
    }

    final special = Task(
      id: 'special_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Special Spark: try something new today',
      category: 'growth',
      isSpecial: true,
      aiSuggested: true,
      difficulty: 'medium',
      durationMinutes: 7,
    );

    final pickedWithSpecial = [...adapted, special];

    _log(
      " REFRESH: Picked task IDs = ${pickedWithSpecial.map((t) => t.id).toList()}",
    );

    await _repo.saveSelectedTasks(pickedWithSpecial);
    await _repo.clearCompleted();
    await _controller.updateLastSeen(
      dateKey: dateKey,
      tasks: pickedWithSpecial,
    );
    await _repo.incrementRefreshCount(dateKey);
    _log(" REFRESH: Saved to repository");

    if (!mounted) {
      _log(" REFRESH: Widget not mounted");
      return;
    }

    _updateState(() {
      _today = pickedWithSpecial;
      _completed = {};
      _syncCompletedMap();
      _adaptiveDifficultyDelta = adaptiveDelta;
      _refreshing = false;
    });
    unawaited(_syncHomeWidgetSnapshot());

    _log(" REFRESH: UI updated with new tasks");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(" New tasks loaded! (${pickedWithSpecial.length})"),
        duration: const Duration(seconds: 2),
        backgroundColor: scheme.primary,
      ),
    );
  }

  Future<void> _toggleReminder() async {
    final newVal = !_reminderEnabled;
    final scheme = Theme.of(context).colorScheme;
    _updateState(() => _reminderEnabled = newVal);
    await _repo.setReminderEnabled(newVal);

    final ok = await _controller.applyReminderEnabled(newVal);
    if (!ok) {
      if (!mounted) return;
      _updateState(() => _reminderEnabled = !newVal);
      await _repo.setReminderEnabled(!newVal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Notification permission not available."),
          backgroundColor: scheme.error,
        ),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newVal
                ? "Daily reminder enabled (09:00)."
                : "Daily reminder disabled.",
          ),
        ),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    final scheme = Theme.of(context).colorScheme;
    try {
      final error = await NotificationService.instance.showTestNotification();
      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test notification sent.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: scheme.error),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to send test notification.'),
            backgroundColor: scheme.error,
          ),
        );
      }
    }
  }

  Future<void> _sendTaskTimerTest() async {
    final scheme = Theme.of(context).colorScheme;
    try {
      await NotificationService.instance.scheduleTaskTimer(
        notificationId: 990001,
        title: 'SPARKIO',
        body: 'Task timer finished. Nice work!',
        duration: const Duration(seconds: 30),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task timer test scheduled (30s).')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to schedule task timer test.'),
            backgroundColor: scheme.error,
          ),
        );
      }
    }
  }
}

class _AllDoneOverlay extends StatelessWidget {
  const _AllDoneOverlay({required this.scheme, required this.onViewStats});

  final ColorScheme scheme;
  final VoidCallback onViewStats;

  @override
  Widget build(BuildContext context) {
    return _AllDoneOverlayBody(scheme: scheme, onViewStats: onViewStats);
  }
}

class _AllDoneOverlayBody extends StatefulWidget {
  const _AllDoneOverlayBody({required this.scheme, required this.onViewStats});

  final ColorScheme scheme;
  final VoidCallback onViewStats;

  @override
  State<_AllDoneOverlayBody> createState() => _AllDoneOverlayBodyState();
}

class _AllDoneOverlayBodyState extends State<_AllDoneOverlayBody>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
    lowerBound: 0.94,
    upperBound: 1.06,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, _) => CustomPaint(
                  painter: _ConfettiFullPainter(
                    t: _controller.value,
                    primary: scheme.primary,
                    secondary: scheme.secondary,
                  ),
                ),
              ),
            ),
          ),
          ScaleTransition(
            scale: _pulseController,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withOpacity(0.22),
                    scheme.secondary.withOpacity(0.18),
                    scheme.surface.withOpacity(0.96),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: scheme.outline.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.35),
                    blurRadius: 32,
                    spreadRadius: 2,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          scheme.primary,
                          scheme.secondary,
                          scheme.primary,
                        ],
                        startAngle: 0,
                        endAngle: 6.28,
                        transform: GradientRotation(
                          _pulseController.value * 6.28,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withOpacity(0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.surface,
                      ),
                      child: Icon(
                        Icons.celebration_rounded,
                        size: 64,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'All done!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You finished every spark today.\nStreak +1, progress saved.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: scheme.onSurface,
                        ),
                        label: Text(
                          'Close',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          backgroundColor: scheme.surfaceVariant.withOpacity(
                            0.6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: widget.onViewStats,
                        icon: const Icon(Icons.bar_chart_rounded),
                        label: const Text('View stats'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiFullPainter extends CustomPainter {
  const _ConfettiFullPainter({
    required this.t,
    required this.primary,
    required this.secondary,
  });

  final double t;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final spots = [
      const Offset(0.1, 0.2),
      const Offset(0.8, 0.25),
      const Offset(0.3, 0.6),
      const Offset(0.6, 0.7),
      const Offset(0.2, 0.85),
      const Offset(0.9, 0.55),
    ];
    for (var i = 0; i < spots.length; i++) {
      final phase = (t + i * 0.17) % 1.0;
      final dx = spots[i].dx * size.width;
      final dy = (spots[i].dy * size.height) + (40 * phase);
      final alpha = (1 - phase).clamp(0.2, 1.0);
      paint.color = (i.isEven ? primary : secondary).withOpacity(alpha * 0.6);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(phase * 6.28);
      final w = 10 + 6 * (1 - phase);
      final h = 4 + 4 * (1 - phase);
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        const Radius.circular(2),
      );
      canvas.drawRRect(r, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiFullPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary;
  }
}
