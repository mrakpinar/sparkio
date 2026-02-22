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
    final profileName = await _repo.getProfileName();
    final earnedBadgesCount = (await _repo.getEarnedBadges()).length;
    final xpProgress = await _repo.getXpProgress();
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
      _earnedBadgesCount = earnedBadgesCount;
      _totalXp = xpProgress.totalXp;
      _level = xpProgress.level;
      _xpInLevel = xpProgress.xpInLevel;
      _xpToNextLevel = xpProgress.xpToNextLevel;
      _profileName = profileName ?? '';
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
      unawaited(() async {
        await _ensureProfileNamePrompt(forceIfMissing: true);
        await _maybePromptWeeklyPlan();
        await _maybePromptDailyMood();
      }());
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
      final selected = await _showDailyMoodSheet();

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
      final selected = await _showDailyMoodSheet();

      if (!mounted || selected == null) return;
      final dateKey = _todayKey();
      await _repo.setDailyMood(dateKey: dateKey, mood: selected);
      _track('daily_mood_selected_debug', {'mood': selected});
      await _applyMoodToTodayTasks(selected);
    } finally {
      if (mounted) {
        _updateState(() => _dailyMoodPrompting = false);
      } else {
        _dailyMoodPrompting = false;
      }
    }
  }

  Future<String?> _showDailyMoodSheet() {
    return showGeneralDialog<String>(
      context: context,
      barrierLabel: 'Daily mood prompt',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 430),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: DailyMoodSheet(
              onSelect: (mood) => Navigator.of(dialogContext).pop(mood),
              onSkip: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final t = Curves.easeOutQuart.transform(animation.value);
        final blurSigma = 14 * t;
        final overlayOpacity = 0.16 + (0.4 * t);
        final riseOffset = 34 * (1 - t);
        final sheetScale = 0.985 + (0.015 * t);
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              IgnorePointer(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(overlayOpacity),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, riseOffset),
                child: Transform.scale(scale: sheetScale, child: child),
              ),
            ],
          ),
        );
      },
    );
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

  Future<void> _syncPremiumTopics([bool? premiumActive]) async {
    try {
      await _controller.syncNotificationTopics(
        premiumActive: premiumActive ?? _premiumActive,
      );
    } catch (_) {
      // Best-effort: ignore topic sync errors.
    }
  }

  int _taskXpReward(Task task) {
    final base = switch (task.difficulty) {
      'hard' => 8,
      'medium' => 6,
      _ => 5,
    };
    return task.isSpecial ? base + 2 : base;
  }

  String _remainingSparkCopy(int remaining) {
    if (remaining <= 0) return 'You can pause here. See you tomorrow.';
    if (remaining == 1) return 'One more if you feel like it.';
    if (remaining == 2) return 'Two more if you feel like it.';
    return '$remaining more if you feel like it.';
  }

  Future<void> _showTaskCompletionMomentum({
    required Task task,
    required int completedToday,
    required String completionChainId,
    required int remainingActionCount,
  }) async {
    if (!mounted) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    const dailyGoal = 3;
    final done = completedToday.clamp(0, dailyGoal);
    final remaining = (dailyGoal - done).clamp(0, dailyGoal);
    final xp = _taskXpReward(task);
    _track('completion_reinforcement_shown', {
      'chain_id': completionChainId,
      'task_id': task.id,
      'completed_today': done,
      'remaining_actions': remainingActionCount,
    });

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1320),
    );

    late OverlayEntry entry;
    var dismissed = false;
    final closeCompleter = Completer<void>();

    Future<void> dismissOverlay({bool animateToEnd = true}) async {
      if (dismissed) return;
      dismissed = true;
      if (animateToEnd) {
        try {
          if (controller.status != AnimationStatus.completed) {
            await controller.animateTo(
              1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeInOut,
            );
          }
        } catch (_) {}
      }
      if (entry.mounted) {
        entry.remove();
      }
      controller.dispose();
      if (!closeCompleter.isCompleted) {
        closeCompleter.complete();
      }
    }

    entry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final t = controller.value;
            final intro = Curves.easeOutCubic.transform(
              (t / 0.36).clamp(0.0, 1.0),
            );
            final outroT = ((t - 0.84) / 0.16).clamp(0.0, 1.0);
            final fadeOut = t < 0.86
                ? 1.0
                : 1 -
                      Curves.easeIn.transform(
                        ((t - 0.86) / 0.14).clamp(0.0, 1.0),
                      );
            final burst = Curves.easeOut.transform((t / 0.28).clamp(0.0, 1.0));
            final xpFloat = Curves.easeOut.transform(
              ((t - 0.24) / 0.28).clamp(0.0, 1.0),
            );
            final ringProgress = ui.lerpDouble(
              ((done - 1).clamp(0, dailyGoal) / dailyGoal),
              done / dailyGoal,
              Curves.easeOutCubic.transform((t / 0.54).clamp(0.0, 1.0)),
            )!;
            final breathePhase = (t / 0.78).clamp(0.0, 1.0);
            final glowBreath = sin(breathePhase * pi * 2).abs();
            final backdropGlow =
                (0.05 + (glowBreath * 0.08)) * (1 - (outroT * 0.7));
            final cardScale = ui.lerpDouble(
              ui.lerpDouble(0.92, 1.0, intro)!,
              0.965,
              Curves.easeIn.transform(outroT),
            )!;
            final ctaOpacity = Curves.easeOut.transform(
              ((t - 0.28) / 0.2).clamp(0.0, 1.0),
            );

            return Opacity(
              opacity: fadeOut,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.25),
                          radius: 1.08,
                          colors: [
                            scheme.primary.withOpacity(backdropGlow),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, ui.lerpDouble(24, 0, intro)!),
                      child: Transform.scale(
                        scale: cardScale,
                        child: Container(
                          width: min(
                            MediaQuery.of(context).size.width - 28,
                            382,
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.alphaBlend(
                                  scheme.primary.withOpacity(0.18),
                                  scheme.surface,
                                ),
                                Color.alphaBlend(
                                  scheme.secondary.withOpacity(0.1),
                                  scheme.surface,
                                ),
                              ],
                            ),
                            border: Border.all(
                              color: scheme.outline.withOpacity(0.24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withOpacity(0.2),
                                blurRadius: 22,
                                spreadRadius: -4,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CustomPaint(
                                        size: const Size(72, 72),
                                        painter: _SoftBurstPainter(
                                          progress: burst,
                                          color: scheme.primary,
                                        ),
                                      ),
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              scheme.primary.withOpacity(0.28),
                                              scheme.secondary.withOpacity(
                                                0.22,
                                              ),
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: _DrawnCheckIcon(
                                            progress: burst,
                                            color: scheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            height: 1.24,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Progress, not pressure.',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tiny actions compound.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant.withOpacity(
                                    0.9,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Row(
                                    children: [
                                      _MomentumRing(
                                        progress: ringProgress,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$done / $dailyGoal sparks today',
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _remainingSparkCopy(remaining),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: scheme
                                                        .onSurfaceVariant
                                                        .withOpacity(0.88),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    left: 26,
                                    top: -2 - (xpFloat * 18),
                                    child: Opacity(
                                      opacity: 1 - xpFloat,
                                      child: Text(
                                        '+$xp XP',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: scheme.primary.withOpacity(
                                                0.95,
                                              ),
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Opacity(
                                opacity: ctaOpacity,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: () {
                                          _track(
                                            'completion_reinforcement_cta',
                                            {
                                              'chain_id': completionChainId,
                                              'action': 'continue',
                                              'remaining_actions':
                                                  remainingActionCount,
                                            },
                                          );
                                          unawaited(dismissOverlay());
                                        },
                                        child: const Text('Continue'),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    TextButton(
                                      onPressed: () {
                                        _track('completion_reinforcement_cta', {
                                          'chain_id': completionChainId,
                                          'action': 'done_for_now',
                                          'remaining_actions':
                                              remainingActionCount,
                                        });
                                        unawaited(dismissOverlay());
                                      },
                                      child: const Text("I'm done for now"),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    unawaited(HapticFeedback.selectionClick());
    overlay.insert(entry);
    unawaited(() async {
      try {
        await controller.animateTo(
          0.82,
          duration: const Duration(milliseconds: 920),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {}
    }());
    await closeCompleter.future;
  }

  void _openMenu() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Widget _buildEndDrawer() {
    Theme.of(context);
    final isDark = ThemeService.instance.mode.value == ThemeMode.dark;

    return ModernDrawer(
      isDark: isDark,
      showDebugTools: _showDebugTools,
      profileName: _profileName,
      currentStreak: _streak,
      currentLevel: _level,
      totalXp: _totalXp,
      xpInLevel: _xpInLevel,
      xpToNextLevel: _xpToNextLevel,
      earnedBadgeCount: _earnedBadgesCount,
      badgeGoalCount: _HomeScreenState._badgeGoalCount,
      weeklyDoneCount: _weeklyDoneTotal(),
      weeklyGoalCount: _weeklyTargetTotal(),
      onToggleTheme: _toggleTheme,
      onOpenAddSpark: _openAddTaskSheet,
      onEditProfile: _openProfileEditor,
      onOpenProfile: _openProfileScreen,
      onOpenBadges: _openBadges,
      onOpenWeeklyPlan: () => _openWeeklyPlanSheet(),
      onOpenContact: _openContact,
      onSendTestNotification: _sendTestNotification,
      onOpenDailyMoodSheet: _openDailyMoodSheetDebug,
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

  void _openProfileScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          profileName: _profileName,
          currentStreak: _streak,
          currentLevel: _level,
          totalXp: _totalXp,
          xpInLevel: _xpInLevel,
          xpToNextLevel: _xpToNextLevel,
        ),
      ),
    ).then((_) async {
      final latest = await _repo.getProfileName();
      if (!mounted) return;
      _updateState(() => _profileName = latest ?? '');
    });
  }

  void _openContact() {
    _openInstagramContact();
  }

  Future<void> _openRateApp({String source = 'manual'}) async {
    final scheme = Theme.of(context).colorScheme;
    try {
      final available = await _inAppReview.isAvailable();
      if (available) {
        await _inAppReview.requestReview();
      } else {
        await _inAppReview.openStoreListing();
      }
      _track('rate_app_tapped', {'source': source});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to open rating right now.'),
          backgroundColor: scheme.error,
        ),
      );
    }
  }

  Future<void> _maybePromptForRating({required String trigger}) async {
    if (!mounted || _ratePromptOpen) return;
    if (await _repo.hasShownRatePromptFor(trigger)) return;

    _updateState(() => _ratePromptOpen = true);
    final action = await showDialog<_RatePromptAction>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enjoying Sparkio?'),
          content: const Text(
            'Your progress is great. Would you like to rate the app?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_RatePromptAction.later),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_RatePromptAction.rateNow),
              child: const Text('Rate now'),
            ),
          ],
        );
      },
    );

    await _repo.markRatePromptShownFor(trigger);
    if (!mounted) return;
    _updateState(() => _ratePromptOpen = false);

    if (action == _RatePromptAction.rateNow) {
      _track('rate_prompt_accepted', {'trigger': trigger});
      await _openRateApp(source: trigger);
      return;
    }

    _track('rate_prompt_dismissed', {'trigger': trigger});
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
    final primaryHsl = HSLColor.fromColor(scheme.primary);
    final shareButtonAccent = primaryHsl
        .withSaturation((primaryHsl.saturation * 0.9).clamp(0.0, 1.0))
        .toColor();
    final shareButtonBackground = Color.alphaBlend(
      shareButtonAccent.withOpacity(0.48),
      scheme.surface,
    );

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
                    icon: const Icon(Icons.ios_share_rounded, size: 20),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shareButtonBackground,
                      foregroundColor: scheme.onSurface.withOpacity(0.92),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      side: BorderSide(color: scheme.outline.withOpacity(0.26)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _resolveAddTaskCtaVariant() async {
    final existing = await _repo.getAddTaskCtaVariant();
    if (existing != null) return existing;

    const variants = ['a', 'b', 'c'];
    final picked = variants[Random().nextInt(variants.length)];
    await _repo.setAddTaskCtaVariant(picked);
    _track('add_task_cta_variant_assigned', {'variant': picked});
    return picked;
  }

  Map<String, String> _addTaskCtaCopy(String variant) {
    switch (variant) {
      case 'a':
        return {
          'label': '\uD83D\uDD25 Start My Streak',
          'subtitle': 'Takes less than 5 seconds',
        };
      case 'b':
        return {
          'label': '\u26A1 Create My Spark',
          'subtitle': 'Takes less than 5 seconds',
        };
      case 'c':
        return {
          'label': '\u2728 Begin Today',
          'subtitle': 'Takes less than 5 seconds',
        };
      default:
        return {
          'label': '\u26A1 Create My Spark',
          'subtitle': 'Takes less than 5 seconds',
        };
    }
  }

  Future<void> _openAddTaskSheet() async {
    final ctaVariant = await _resolveAddTaskCtaVariant();
    final ctaCopy = _addTaskCtaCopy(ctaVariant);
    unawaited(
      AnalyticsService.instance.setUserProperty(
        name: 'add_task_cta_variant',
        value: ctaVariant,
      ),
    );
    final freeSparkLeft = (1 - _dailyAddCount).clamp(0, 1);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.2),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, _, _) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: ColoredBox(color: Colors.black.withOpacity(0.12)),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: TaskAddSheet(
                  canAddTask: _premiumActive || _dailyAddCount < 1,
                  addLimitLabel: _premiumActive
                      ? 'Premium: Unlimited Sparks'
                      : freeSparkLeft > 0
                      ? 'Free Plan: $freeSparkLeft spark left'
                      : 'Go Unlimited',
                  initialCategory: _customCategory,
                  initialDifficulty: _customDifficulty,
                  initialDurationMinutes: _customDuration,
                  premiumActive: _premiumActive,
                  onAdd: _addCustomTask,
                  onGenerateAi: _generateAiTask,
                  onOpenPremium: _openSubscribeSheet,
                  ctaVariant: ctaVariant,
                  ctaLabel: ctaCopy['label']!,
                  ctaSubtitle: ctaCopy['subtitle']!,
                  onCtaEvent: (event, variant) {
                    _track('add_task_cta_$event', {'variant': variant});
                  },
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
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
    if (_completed[t.id] == true) {
      return;
    }
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
    final previousStreak = _streak;
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
      _updateState(() => _earnedBadgesCount += streakBadges.length);
      _showBadgeUnlocked(streakBadges.first);
      unawaited(_maybePromptForRating(trigger: 'badge_unlock'));
    }

    if (!mounted) return;
    _updateState(() => _streak = newStreak);
    if (newStreak >= 7 && previousStreak < 7) {
      unawaited(_maybePromptForRating(trigger: 'streak_7'));
    }
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

  String _levelTitleForUi(int level) {
    if (level >= 20) return 'Flow Master';
    if (level >= 14) return 'Momentum Maker';
    if (level >= 9) return 'Consistency Builder';
    if (level >= 5) return 'Habit Starter';
    return 'First Spark';
  }

  Future<void> _showLevelUpOverlay({
    required int previousLevel,
    required XpProgress progress,
  }) async {
    if (!mounted) return;
    final newLevel = progress.level;
    final levelTitle = _levelTitleForUi(newLevel);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Level up',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, _, _) {
        return Center(
          child: _LevelUpOverlayCard(
            previousLevel: previousLevel,
            newLevel: newLevel,
            levelTitle: levelTitle,
            totalXp: progress.totalXp,
            xpInLevel: progress.xpInLevel,
            xpToNextLevel: progress.xpToNextLevel,
            onClose: () => Navigator.of(dialogContext).maybePop(),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
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
    if (_awaitingSecondAction &&
        _pendingCompletionTaskId != null &&
        _pendingCompletionTaskId != task.id) {
      final elapsedSec = _pendingCompletionAt == null
          ? null
          : DateTime.now().difference(_pendingCompletionAt!).inSeconds;
      _track('completion_second_action_started', {
        'chain_id': _pendingCompletionChainId,
        'completed_today_at_entry': _pendingCompletionDoneCount,
        if (elapsedSec != null) 'elapsed_sec': elapsedSec,
        'task_id': task.id,
      });
      _updateState(() {
        _awaitingSecondAction = false;
        _pendingCompletionChainId = null;
        _pendingCompletionTaskId = null;
        _pendingCompletionAt = null;
        _pendingCompletionDoneCount = 0;
      });
    }
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
    final xpReward = _taskXpReward(task);
    final previousLevel = _level;
    await HapticFeedback.lightImpact();
    if (_activeTimerTask?.id == task.id) {
      await _cancelTaskTimer(task);
    }
    await _repo.incrementCompleted(task.category);
    final xpProgress = await _repo.addXp(xpReward);
    final newDaily = await _repo.incrementDailyCompleted(_todayKey());
    final remainingActionCount = _today
        .where((item) => _completed[item.id] != true)
        .length;
    final completionChainId =
        '${DateTime.now().millisecondsSinceEpoch}_${task.id}';
    if (mounted) {
      _updateState(() {
        _todayCompleted = newDaily;
        _totalXp = xpProgress.totalXp;
        _level = xpProgress.level;
        _xpInLevel = xpProgress.xpInLevel;
        _xpToNextLevel = xpProgress.xpToNextLevel;
        _awaitingSecondAction = remainingActionCount > 0;
        _pendingCompletionChainId = completionChainId;
        _pendingCompletionTaskId = task.id;
        _pendingCompletionAt = DateTime.now();
        _pendingCompletionDoneCount = newDaily;
      });
    }
    await _showTaskCompletionMomentum(
      task: task,
      completedToday: newDaily,
      completionChainId: completionChainId,
      remainingActionCount: remainingActionCount,
    );
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
      'xp_earned': xpReward,
      'xp_total': xpProgress.totalXp,
      'level': xpProgress.level,
    });
    if (xpProgress.level > previousLevel) {
      _track('level_up', {
        'previous_level': previousLevel,
        'new_level': xpProgress.level,
        'total_xp': xpProgress.totalXp,
      });
      if (mounted) {
        await _showLevelUpOverlay(
          previousLevel: previousLevel,
          progress: xpProgress,
        );
      }
    }
    if (mounted && newBadges.isNotEmpty) {
      _updateState(() => _earnedBadgesCount += newBadges.length);
      _showBadgeUnlocked(newBadges.first);
      unawaited(_maybePromptForRating(trigger: 'badge_unlock'));
    }
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
      barrierColor: Colors.black.withOpacity(0.56),
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.alphaBlend(
                              scheme.primary.withOpacity(0.055),
                              scheme.surface,
                            ),
                            Color.alphaBlend(
                              scheme.secondary.withOpacity(0.028),
                              scheme.surface,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -46,
                    right: -46,
                    top: -84,
                    height: 210,
                    child: IgnorePointer(
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 14,
                          sigmaY: 14,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -1.0),
                              radius: 1.24,
                              colors: [
                                scheme.primary.withOpacity(0.13),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _DialogParticlePainter(opacity: 0.02),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _DialogSparkIcon(
                              primary: scheme.primary,
                              secondary: scheme.primaryContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Start a new set',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.22,
                                  color: scheme.onSurface.withOpacity(0.94),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(
                                context,
                              ).pop(_RefreshChoice.cancel),
                              icon: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: scheme.onSurfaceVariant.withOpacity(
                                  0.54,
                                ),
                              ),
                              splashRadius: 16,
                              style: IconButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(34, 34),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Take a fresh moment.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant.withOpacity(0.9),
                            height: 1.36,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: scheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Includes a bonus task with Premium.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant.withOpacity(
                                    0.76,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  height: 1.42,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: _RefreshChoiceButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(_RefreshChoice.premium),
                            icon: Icons.workspace_premium_rounded,
                            label: 'Continue with Premium',
                            emphasized: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _RefreshChoiceButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(_RefreshChoice.rewarded),
                            icon: Icons.play_circle_outline_rounded,
                            label: 'Watch a short ad',
                            emphasized: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          builder: (context, t, child) {
            final sigma = 10 + (t * 0.5);
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 12),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                    child: child,
                  ),
                ),
              ),
            );
          },
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
                ? "Daily reminder enabled (12:00)."
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

  Future<void> _debugAddThreeTasks() async {
    final scheme = Theme.of(context).colorScheme;
    try {
      final pool = await _loadEffectivePool();
      final lastSeenDate = await _repo.getLastSeenDate();
      final lastSeenIds = await _repo.getLastSeenTaskIds();
      final avoidIds = lastSeenDate == _todayKey()
          ? lastSeenIds.toSet()
          : <String>{};
      final currentIds = _today.map((t) => t.id).toSet();
      final picked = _controller.pickTasksNoRepeat(
        pool: pool,
        count: 3,
        seedKey: 'debug_add_${DateTime.now().millisecondsSinceEpoch}',
        avoidIds: currentIds.union(avoidIds),
      );

      if (picked.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No extra tasks available.')),
          );
        }
        return;
      }

      final updated = [..._today, ...picked];
      await _repo.saveSelectedTasks(updated);
      await _controller.updateLastSeen(dateKey: _todayKey(), tasks: picked);

      if (!mounted) return;
      _updateState(() {
        _today = updated;
        for (final task in picked) {
          _completed[task.id] = false;
        }
      });
      unawaited(_syncHomeWidgetSnapshot());
      _track('debug_add_tasks', {'count': picked.length});
      final noun = picked.length == 1 ? 'task' : 'tasks';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${picked.length} debug $noun added.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to add debug tasks.'),
            backgroundColor: scheme.error,
          ),
        );
      }
    }
  }

  Future<void> _ensureProfileNamePrompt({bool forceIfMissing = false}) async {
    if (!mounted) return;
    final existing = await _repo.getProfileName();
    if (!forceIfMissing && existing != null) return;
    if ((existing ?? '').isNotEmpty) {
      if (_profileName != existing) {
        _updateState(() => _profileName = existing!);
      }
      return;
    }
    await _openProfileEditor(forceRequired: true);
  }

  Future<void> _openProfileEditor({bool forceRequired = false}) async {
    if (!mounted) return;
    var draftName = _profileName;
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<String>(
      context: context,
      barrierDismissible: !forceRequired,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;
        var fieldFocused = false;
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            final baseFieldColor = Color.alphaBlend(
              scheme.primary.withOpacity(
                theme.brightness == Brightness.dark ? 0.06 : 0.03,
              ),
              scheme.surfaceContainerHighest.withOpacity(
                theme.brightness == Brightness.dark ? 0.72 : 0.9,
              ),
            );
            final grainOpacity = theme.brightness == Brightness.dark
                ? 0.03
                : 0.022;
            final barrierBlur = fieldFocused ? 11.2 : 9.6;
            final keyboardVisible =
                MediaQuery.of(dialogContext).viewInsets.bottom > 0;
            return Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(
                          sigmaX: barrierBlur,
                          sigmaY: barrierBlur,
                        ),
                        child: ColoredBox(
                          color: Colors.black.withOpacity(
                            theme.brightness == Brightness.dark ? 0.16 : 0.08,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, openT, child) {
                        return AnimatedPadding(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.only(
                            bottom: keyboardVisible ? 20 : 0,
                          ),
                          child: Transform.scale(
                            scale: 0.97 + (0.03 * openT),
                            child: Opacity(opacity: openT, child: child),
                          ),
                        );
                      },
                      child: Dialog(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 420),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    scheme.surface.withOpacity(0.96),
                                    scheme.surfaceContainerHigh.withOpacity(
                                      theme.brightness == Brightness.dark
                                          ? 0.9
                                          : 0.94,
                                    ),
                                  ],
                                ),
                                border: Border.all(
                                  color: scheme.outline.withOpacity(
                                    theme.brightness == Brightness.dark
                                        ? 0.2
                                        : 0.14,
                                  ),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      theme.brightness == Brightness.dark
                                          ? 0.34
                                          : 0.1,
                                    ),
                                    blurRadius: 28,
                                    spreadRadius: -12,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                            center: const Alignment(0, -1.12),
                                            radius: 1.3,
                                            colors: [
                                              scheme.primary.withOpacity(0.04),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter: _SurfaceGrainPainter(
                                          opacity: grainOpacity,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      16,
                                      20,
                                      16,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            _DialogSparkIcon(
                                              primary: scheme.primary,
                                              secondary:
                                                  scheme.primaryContainer,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'What should we call you?',
                                                    style: theme
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'We use this name across your Sparkio experience.',
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: scheme
                                                              .onSurfaceVariant
                                                              .withOpacity(
                                                                0.82,
                                                              ),
                                                          height: 1.3,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Form(
                                          key: formKey,
                                          child: TweenAnimationBuilder<double>(
                                            duration: const Duration(
                                              milliseconds: 260,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            tween: Tween<double>(
                                              begin: 0,
                                              end: 1,
                                            ),
                                            builder: (context, glowT, child) {
                                              final idleGlow = 0.042 * glowT;
                                              final focusGlow = fieldFocused
                                                  ? (0.175 * glowT)
                                                  : 0.0;
                                              return AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 180,
                                                ),
                                                curve: Curves.easeOutCubic,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                    ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.white.withOpacity(
                                                        theme.brightness ==
                                                                Brightness.dark
                                                            ? 0.045
                                                            : 0.07,
                                                      ),
                                                      baseFieldColor,
                                                    ],
                                                  ),
                                                  border: Border.all(
                                                    color: fieldFocused
                                                        ? scheme.primary
                                                              .withOpacity(0.42)
                                                        : scheme.outline
                                                              .withOpacity(0.2),
                                                    width: 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: scheme.primary
                                                          .withOpacity(
                                                            idleGlow,
                                                          ),
                                                      blurRadius: 15,
                                                      spreadRadius: -7,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                    if (fieldFocused)
                                                      BoxShadow(
                                                        color: scheme.primary
                                                            .withOpacity(
                                                              focusGlow,
                                                            ),
                                                        blurRadius: 20,
                                                        spreadRadius: -5,
                                                        offset: const Offset(
                                                          0,
                                                          6,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                child: child,
                                              );
                                            },
                                            child: Focus(
                                              onFocusChange: (value) {
                                                if (value == fieldFocused) {
                                                  return;
                                                }
                                                setModalState(
                                                  () => fieldFocused = value,
                                                );
                                              },
                                              child: TextFormField(
                                                initialValue: draftName,
                                                autofocus: true,
                                                enableInteractiveSelection:
                                                    false,
                                                textCapitalization:
                                                    TextCapitalization.words,
                                                maxLength: 24,
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                cursorColor: Color.alphaBlend(
                                                  scheme.primary.withOpacity(
                                                    0.62,
                                                  ),
                                                  scheme.onSurfaceVariant
                                                      .withOpacity(0.42),
                                                ),
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Enter your first name',
                                                  counterText: '',
                                                  hintStyle: theme
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                        fontSize: 16,
                                                        color: scheme
                                                            .onSurfaceVariant
                                                            .withOpacity(0.62),
                                                      ),
                                                  border: InputBorder.none,
                                                  enabledBorder:
                                                      InputBorder.none,
                                                  focusedBorder:
                                                      InputBorder.none,
                                                  errorBorder: InputBorder.none,
                                                  focusedErrorBorder:
                                                      InputBorder.none,
                                                  contentPadding:
                                                      const EdgeInsets.fromLTRB(
                                                        2,
                                                        14,
                                                        2,
                                                        14,
                                                      ),
                                                ),
                                                validator: (value) {
                                                  final text =
                                                      value?.trim() ?? '';
                                                  if (text.isEmpty) {
                                                    return 'Please enter your name';
                                                  }
                                                  if (text.length < 2) {
                                                    return 'Name is too short';
                                                  }
                                                  return null;
                                                },
                                                onChanged: (value) =>
                                                    draftName = value,
                                                onFieldSubmitted: (_) {
                                                  if (formKey.currentState
                                                          ?.validate() ??
                                                      false) {
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop(draftName.trim());
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        if (!forceRequired)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: scheme
                                                    .onSurfaceVariant
                                                    .withOpacity(0.66),
                                              ),
                                              onPressed: () => Navigator.of(
                                                dialogContext,
                                              ).maybePop(),
                                              child: const Text('Cancel'),
                                            ),
                                          ),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: scheme.primary,
                                              foregroundColor: scheme.onPrimary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            onPressed: () {
                                              if (!(formKey.currentState
                                                      ?.validate() ??
                                                  false)) {
                                                return;
                                              }
                                              Navigator.of(
                                                dialogContext,
                                              ).pop(draftName.trim());
                                            },
                                            child: const Text('Done'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved == null || saved.trim().isEmpty) return;
    final normalized = TaskRepository.sanitizeProfileName(saved);
    if (normalized.isEmpty) return;
    await _repo.setProfileName(normalized);
    if (!mounted) return;
    _updateState(() => _profileName = normalized);
  }
}

enum _RatePromptAction { later, rateNow }

class _DialogSparkIcon extends StatefulWidget {
  const _DialogSparkIcon({required this.primary, required this.secondary});

  final Color primary;
  final Color secondary;

  @override
  State<_DialogSparkIcon> createState() => _DialogSparkIconState();
}

class _DialogSparkIconState extends State<_DialogSparkIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = Curves.easeOutCubic.transform(_controller.value);
        final pulse = sin(progress * pi).clamp(0.0, 1.0).toDouble();
        final glow = 0.16 + (pulse * 0.24);
        final scale = 1.0 + (pulse * 0.018);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.primary,
                  Color.alphaBlend(
                    widget.secondary.withOpacity(0.45),
                    widget.primary,
                  ),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.primary.withOpacity(glow),
                  blurRadius: 16 + (pulse * 7),
                  spreadRadius: -6 + (pulse * 1.4),
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RefreshChoiceButton extends StatefulWidget {
  const _RefreshChoiceButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.emphasized,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  State<_RefreshChoiceButton> createState() => _RefreshChoiceButtonState();
}

class _RefreshChoiceButtonState extends State<_RefreshChoiceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = widget.emphasized ? scheme.primary : scheme.secondary;
    final base = widget.emphasized ? scheme.primaryContainer : scheme.surface;
    final fg = widget.emphasized
        ? scheme.onPrimaryContainer
        : scheme.onSurface.withOpacity(0.88);
    final borderOpacity = widget.emphasized ? 0.18 : 0.06;
    final grainOpacity = widget.emphasized ? 0.02 : 0.016;
    final glowOpacity = widget.emphasized
        ? (_pressed ? 0.24 : 0.18)
        : (_pressed ? 0.13 : 0.07);
    final topTintOpacity = widget.emphasized ? 0.15 : 0.04;
    final bottomTintOpacity = widget.emphasized ? 0.07 : 0.025;

    return AnimatedScale(
      scale: _pressed ? 1.01 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (value) {
            if (_pressed == value) return;
            setState(() => _pressed = value);
          },
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: tint.withOpacity(borderOpacity),
                width: 0.9,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(tint.withOpacity(topTintOpacity), base),
                  Color.alphaBlend(tint.withOpacity(bottomTintOpacity), base),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: tint.withOpacity(glowOpacity),
                  blurRadius: 16 + (_pressed ? 4 : 0),
                  spreadRadius: -9 + (_pressed ? 1.2 : 0),
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -1.12),
                            radius: 1.3,
                            colors: [
                              Colors.white.withOpacity(
                                widget.emphasized ? 0.13 : 0.06,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 1,
                        color: Colors.white.withOpacity(
                          widget.emphasized ? 0.07 : 0.05,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.04),
                              Colors.transparent,
                              Colors.black.withOpacity(0.045),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SurfaceGrainPainter(opacity: grainOpacity),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.icon, size: 18, color: fg),
                        const SizedBox(width: 8),
                        Text(
                          widget.label,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SurfaceGrainPainter extends CustomPainter {
  const _SurfaceGrainPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final random = Random(19);
    final count = (size.width * size.height / 320).round().clamp(26, 80);
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 0.35 + random.nextDouble() * 0.75;
      final alpha = opacity * (0.4 + random.nextDouble() * 0.6);
      paint.color = (i % 2 == 0)
          ? Colors.white.withOpacity(alpha)
          : Colors.black.withOpacity(alpha * 0.86);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SurfaceGrainPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}

class _DialogParticlePainter extends CustomPainter {
  const _DialogParticlePainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final random = Random(27);
    final count = (size.width * size.height / 420).round().clamp(30, 95);
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 0.35 + (random.nextDouble() * 0.75);
      final alpha = opacity * (0.35 + (random.nextDouble() * 0.65));
      paint.color = i.isEven
          ? Colors.white.withOpacity(alpha * 0.95)
          : Colors.black.withOpacity(alpha * 0.72);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DialogParticlePainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}

class _DrawnCheckIcon extends StatelessWidget {
  const _DrawnCheckIcon({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    return SizedBox(
      width: 26,
      height: 26,
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: t,
        child: Icon(Icons.check_rounded, size: 24, color: color),
      ),
    );
  }
}

class _SoftBurstPainter extends CustomPainter {
  const _SoftBurstPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    if (t <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    const count = 9;
    for (var i = 0; i < count; i++) {
      final angle = (pi * 2 / count) * i;
      final distance = ui.lerpDouble(8, 26, t)!;
      final dot = Offset(
        center.dx + cos(angle) * distance,
        center.dy + sin(angle) * distance,
      );
      final dotSize = ui.lerpDouble(3.4, 1.2, t)!;
      paint.color = color.withOpacity((1 - t) * 0.22);
      canvas.drawCircle(dot, dotSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoftBurstPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _MomentumRing extends StatelessWidget {
  const _MomentumRing({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              value: p,
              strokeWidth: 4.5,
              backgroundColor: color.withOpacity(0.16),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Icon(
            Icons.bolt_rounded,
            size: 18,
            color: Color.alphaBlend(color.withOpacity(0.2), scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _LevelUpOverlayCard extends StatelessWidget {
  const _LevelUpOverlayCard({
    required this.previousLevel,
    required this.newLevel,
    required this.levelTitle,
    required this.totalXp,
    required this.xpInLevel,
    required this.xpToNextLevel,
    required this.onClose,
  });

  final int previousLevel;
  final int newLevel;
  final String levelTitle;
  final int totalXp;
  final int xpInLevel;
  final int xpToNextLevel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final safeXpToNext = xpToNextLevel <= 0 ? 1 : xpToNextLevel;
    final clampedInLevel = xpInLevel.clamp(0, safeXpToNext);
    final levelProgress = (clampedInLevel / safeXpToNext).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: min(MediaQuery.of(context).size.width - 32, 360),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withOpacity(0.22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: scheme.primary.withOpacity(0.14),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: scheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Level up',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Lv $previousLevel → $newLevel',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(0.62),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You reached level $newLevel · $levelTitle',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withOpacity(0.88),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total XP: $totalXp',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: levelProgress,
                minHeight: 3,
                backgroundColor: scheme.onSurface.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  scheme.primary.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$clampedInLevel/$safeXpToNext XP to next level',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.58),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onClose,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
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
  late final AnimationController _sparkleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();
  late final AnimationController _settleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
  )..forward();
  late final Animation<double> _cardScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0.965,
        end: 1.01,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 58,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.02,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 42,
    ),
  ]).animate(_settleController);

  @override
  void dispose() {
    _settleController.dispose();
    _sparkleController.dispose();
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
                animation: _sparkleController,
                builder: (_, _) {
                  final t = _sparkleController.value;
                  final fadeIn = Curves.easeOut.transform(
                    (t / 0.55).clamp(0.0, 1.0),
                  );
                  final fadeOut = t <= 0.55
                      ? 1.0
                      : 1 -
                            Curves.easeIn.transform(
                              ((t - 0.55) / 0.45).clamp(0.0, 1.0),
                            );
                  final opacity = (fadeIn * fadeOut * 0.08).clamp(0.0, 1.0);
                  if (opacity <= 0.001) return const SizedBox.shrink();
                  return Opacity(
                    opacity: opacity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.18),
                          radius: 1.08,
                          colors: [
                            scheme.primary.withOpacity(0.15),
                            scheme.secondary.withOpacity(0.04),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          ScaleTransition(
            scale: _cardScale,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.alphaBlend(
                      scheme.primary.withOpacity(0.1),
                      scheme.surface,
                    ),
                    Color.alphaBlend(
                      scheme.primary.withOpacity(0.05),
                      scheme.surface,
                    ),
                    scheme.surface.withOpacity(0.98),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: scheme.outline.withOpacity(0.24)),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.24),
                    blurRadius: 26,
                    spreadRadius: -2,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _settleController,
                    builder: (context, child) {
                      final pulse = sin(
                        _settleController.value * pi,
                      ).clamp(0.0, 1.0);
                      final glowOpacity = 0.14 + (pulse * 0.1);
                      final iconScale = 1.0 + (pulse * 0.018);
                      return Transform.scale(
                        scale: iconScale,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                scheme.primary.withOpacity(0.74),
                                Color.alphaBlend(
                                  scheme.secondary.withOpacity(0.24),
                                  scheme.primary,
                                ),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withOpacity(glowOpacity),
                                blurRadius: 22 + (pulse * 10),
                                spreadRadius: -4 + (pulse * 2),
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
                              Icons.task_alt_rounded,
                              size: 54,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "You're set for today",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Streak +1. See you tomorrow.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          'Close',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
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
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: widget.onViewStats,
                        icon: const Icon(Icons.insights_rounded, size: 17),
                        label: const Text('View progress'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.onSurface.withOpacity(0.88),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          side: BorderSide(
                            color: scheme.outline.withOpacity(0.28),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
