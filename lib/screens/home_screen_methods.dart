part of 'home_screen.dart';

extension _HomeScreenStateMethods on _HomeScreenState {
  String _todayKey() => _controller.todayKey();

  Future<
    ({
      bool isFirstOpen,
      bool day1Retained,
      bool day7Retained,
      int daysSinceInstall,
    })
  >
  _registerOpenForFunnelCompat() async {
    try {
      final dynamic repo = _repo;
      final dynamic state = await repo.registerOpenForFunnel();
      return (
        isFirstOpen: state.isFirstOpen == true,
        day1Retained: state.day1Retained == true,
        day7Retained: state.day7Retained == true,
        daysSinceInstall: (state.daysSinceInstall is int)
            ? state.daysSinceInstall as int
            : 0,
      );
    } catch (_) {
      return (
        isFirstOpen: false,
        day1Retained: false,
        day7Retained: false,
        daysSinceInstall: 0,
      );
    }
  }

  Widget _buildInAppNudgesSliver() {
    final nudges = _resolveInAppNudges();
    if (nudges.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(
          children: [
            for (final nudge in nudges) ...[
              _InAppNudgeCard(
                nudge: nudge,
                onAction: () => _onInAppNudgeAction(nudge),
                onDismiss: () => _dismissInAppNudge(nudge.id),
              ),
              if (nudge != nudges.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEndOfDayReviewSliver() {
    final nudge = _resolveEndOfDayReviewNudge();
    if (nudge == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: _InAppNudgeCard(
          nudge: nudge,
          onAction: () => _onInAppNudgeAction(nudge),
          onDismiss: () => _dismissInAppNudge(nudge.id),
        ),
      ),
    );
  }

  String _coachWeeklyTopCategoryLabel() {
    if (_weeklyDone.isEmpty) return _controller.categoryLabel('mind');
    final ranked = _weeklyDone.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (ranked.isEmpty) return _controller.categoryLabel('mind');
    return _controller.categoryLabel(ranked.first.key);
  }

  List<_InAppNudge> _resolveInAppNudges() {
    final l10n = context.l10n;
    final result = <_InAppNudge>[];
    final now = DateTime.now();
    final todayKey = _todayKey();
    final pendingTasks = _today
        .where((task) => _completed[task.id] != true)
        .toList();
    final hasPending = pendingTasks.isNotEmpty;
    final weeklyTarget = _weeklyTargetTotal();
    final weeklyDone = _weeklyDoneTotal();
    final weeklyRemaining = max(weeklyTarget - weeklyDone, 0);
    final currentWeekKey = _repo.currentWeekKey(now);

    bool dismissed(String id) => _dismissedNudgesToday.contains(id);

    if (hasPending &&
        _todayCompleted <= 0 &&
        now.hour >= 5 &&
        now.hour < 15 &&
        (_coachMorningIntentionToday == null ||
            _coachMorningIntentionToday!.trim().isEmpty) &&
        !dismissed('coach_morning_intention')) {
      result.add(
        _InAppNudge(
          id: 'coach_morning_intention',
          icon: Icons.wb_sunny_rounded,
          title: l10n.tr('Morning intention'),
          subtitle: l10n.tr(
            'Set one tiny intention for today before your first spark.',
          ),
          ctaLabel: l10n.tr('Set intention'),
          action: _InAppNudgeAction.openMorningIntention,
        ),
      );
    }

    if (now.weekday == DateTime.sunday &&
        now.hour >= 16 &&
        _weeklyReviewShownWeek != currentWeekKey &&
        !dismissed('coach_weekly_closing')) {
      final topCategory = _coachWeeklyTopCategoryLabel();
      result.add(
        _InAppNudge(
          id: 'coach_weekly_closing',
          icon: Icons.event_available_rounded,
          title: 'Weekly closing',
          subtitle: '$weeklyDone sparks • Top category $topCategory',
          ctaLabel: 'Close week',
          action: _InAppNudgeAction.openWeeklyClosing,
        ),
      );
    }

    if (_activeTimerTask != null &&
        _activeTimerFinished &&
        _completed[_activeTimerTask!.id] != true &&
        !dismissed('nudge_timer_done')) {
      result.add(
        _InAppNudge(
          id: 'nudge_timer_done',
          icon: Icons.check_circle_outline_rounded,
          title: 'Timer finished',
          subtitle: 'Mark "${_activeTimerTask!.title}" as done.',
          ctaLabel: 'Mark done',
          action: _InAppNudgeAction.completeFinishedTimer,
        ),
      );
    }

    if (_activeChallenge != null &&
        !_activeChallenge!.isCompleted &&
        _activeChallenge!.includesDate(todayKey) &&
        !_activeChallenge!.hasLoggedDate(todayKey) &&
        _todayCompleted < _activeChallenge!.dailyGoal &&
        hasPending &&
        !dismissed('nudge_challenge_day')) {
      result.add(
        _InAppNudge(
          id: 'nudge_challenge_day',
          icon: Icons.emoji_events_rounded,
          title: l10n.tr('Challenge day is open'),
          subtitle: l10n.trf(
            '{title}: one spark logs today automatically.',
            <String, Object>{'title': _activeChallenge!.localizedTitle()},
          ),
          ctaLabel: l10n.tr('Start spark'),
          action: _InAppNudgeAction.startQuickTask,
        ),
      );
    }

    if (hasPending &&
        _todayCompleted <= 0 &&
        _streak > 0 &&
        !dismissed('nudge_streak_guard')) {
      result.add(
        const _InAppNudge(
          id: 'nudge_streak_guard',
          icon: Icons.local_fire_department_rounded,
          title: 'Protect your streak',
          subtitle: 'One quick spark keeps your rhythm alive today.',
          ctaLabel: 'Keep streak',
          action: _InAppNudgeAction.startQuickTask,
        ),
      );
    } else if (hasPending &&
        _todayCompleted <= 0 &&
        now.hour >= 11 &&
        !dismissed('nudge_start_today')) {
      result.add(
        const _InAppNudge(
          id: 'nudge_start_today',
          icon: Icons.bolt_rounded,
          title: 'Start with one tiny spark',
          subtitle: '60 seconds is enough to build momentum.',
          ctaLabel: 'Start now',
          action: _InAppNudgeAction.startQuickTask,
        ),
      );
    }

    if (weeklyTarget > 0 &&
        weeklyRemaining > 0 &&
        now.weekday >= DateTime.thursday &&
        !dismissed('nudge_weekly_catchup')) {
      final dayLabel = now.weekday == DateTime.sunday ? 'Today' : 'This week';
      result.add(
        _InAppNudge(
          id: 'nudge_weekly_catchup',
          icon: Icons.calendar_view_week_rounded,
          title: 'Weekly plan needs $weeklyRemaining more',
          subtitle: '$dayLabel is a good time to catch up.',
          ctaLabel: 'Open plan',
          action: _InAppNudgeAction.openWeeklyPlan,
        ),
      );
    }

    if (_awaitingSecondAction &&
        _todayCompleted > 0 &&
        hasPending &&
        !dismissed('nudge_second_step')) {
      result.add(
        const _InAppNudge(
          id: 'nudge_second_step',
          icon: Icons.trending_up_rounded,
          title: 'Momentum is active',
          subtitle: 'One more micro spark makes today stick.',
          ctaLabel: 'Do one more',
          action: _InAppNudgeAction.startQuickTask,
        ),
      );
    }

    return result.take(2).toList(growable: false);
  }

  _InAppNudge? _resolveEndOfDayReviewNudge() {
    final now = DateTime.now();
    if (now.hour < 18) return null;
    if (_coachEveningReviewDoneToday) return null;
    if (_dismissedNudgesToday.contains('coach_evening_review')) return null;
    if (_today.isEmpty) return null;
    final hasPending = _today.any((task) => _completed[task.id] != true);
    if (hasPending) return null;
    return _InAppNudge(
      id: 'coach_evening_review',
      icon: Icons.nights_stay_rounded,
      title: 'End of day',
      subtitle: 'You completed $_todayCompleted sparks today. Close the day.',
      ctaLabel: 'Mini review',
      action: _InAppNudgeAction.openEveningReview,
    );
  }

  Future<void> _dismissInAppNudge(String id) async {
    if (_dismissedNudgesToday.contains(id)) return;
    final todayKey = _todayKey();
    await _repo.dismissInAppNudge(dateKey: todayKey, nudgeId: id);
    if (!mounted) return;
    _updateState(() {
      _dismissedNudgesToday = {..._dismissedNudgesToday, id};
    });
    _track('in_app_nudge_dismissed', {'nudge_id': id});
  }

  Future<void> _onInAppNudgeAction(_InAppNudge nudge) async {
    _track('in_app_nudge_tapped', {
      'nudge_id': nudge.id,
      'action': nudge.action.name,
    });
    bool handled = false;
    switch (nudge.action) {
      case _InAppNudgeAction.startQuickTask:
        handled = await _startQuickTaskFromNudge();
        break;
      case _InAppNudgeAction.completeFinishedTimer:
        handled = await _completeFinishedTimerFromNudge();
        break;
      case _InAppNudgeAction.openWeeklyPlan:
        await _openWeeklyPlanSheet();
        handled = true;
        break;
      case _InAppNudgeAction.openMorningIntention:
        handled = await _openMorningIntentionCoach();
        break;
      case _InAppNudgeAction.openEveningReview:
        handled = await _openEveningMiniReviewCoach();
        break;
      case _InAppNudgeAction.openWeeklyClosing:
        handled = await _openWeeklyClosingCoach();
        break;
    }
    if (handled) {
      await _dismissInAppNudge(nudge.id);
    }
  }

  Future<bool> _startQuickTaskFromNudge() async {
    if (_activeTimerTask != null) return false;
    final pending = _today
        .where((task) => _completed[task.id] != true)
        .toList();
    if (pending.isEmpty) return false;
    pending.sort((a, b) {
      final durationCompare = a.totalDurationSeconds.compareTo(
        b.totalDurationSeconds,
      );
      if (durationCompare != 0) return durationCompare;
      return a.title.compareTo(b.title);
    });
    await _startTaskTimer(pending.first);
    return true;
  }

  Future<bool> _completeFinishedTimerFromNudge() async {
    final task = _activeTimerTask;
    if (task == null || !_activeTimerFinished) return false;
    if (_completed[task.id] == true) return false;
    await _cancelTaskTimer(task);
    if (!mounted) return false;
    _updateState(() => _completed[task.id] = true);
    await _repo.saveCompletedMap(_completed);
    await _markTaskDone(task);
    await _applyStreakIfAllDone();
    return true;
  }

  Future<bool> _openMorningIntentionCoach() async {
    if (!mounted) return false;
    final controller = TextEditingController(
      text: _coachMorningIntentionToday ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;
        return AlertDialog(
          title: Text(l10n.tr('Morning intention')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tr('What is one tiny intention for today?'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 64,
                decoration: InputDecoration(
                  hintText: l10n.tr('e.g. Show up for one 2-min spark'),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.tr('Cancel')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.tr('Save')),
            ),
          ],
        );
      },
    );
    final intention = result?.trim();
    if (intention == null || intention.isEmpty) return false;
    final todayKey = _todayKey();
    await _repo.setCoachMorningIntention(
      dateKey: todayKey,
      intention: intention,
    );
    if (!mounted) return false;
    _updateState(() => _coachMorningIntentionToday = intention);
    _track('coach_morning_intention_saved', {
      'length': intention.length,
      'has_pending': _today.any((task) => _completed[task.id] != true),
    });
    _showSnack(context.l10n.tr('Intention saved for today.'));
    return true;
  }

  Future<bool> _openEveningMiniReviewCoach() async {
    if (!mounted) return false;
    final topCategory =
        _today
            .where((task) => _completed[task.id] == true)
            .fold<Map<String, int>>(<String, int>{}, (acc, task) {
              acc[task.category] = (acc[task.category] ?? 0) + 1;
              return acc;
            })
          ..removeWhere((_, value) => value <= 0);
    String categoryLabel = _controller.categoryLabel('mind');
    if (topCategory.isNotEmpty) {
      final ranked = topCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      categoryLabel = _controller.categoryLabel(ranked.first.key);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;
        return AlertDialog(
          title: Text(l10n.tr('Evening mini review')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.trf('You showed up with {count} sparks today.', {
                  'count': _todayCompleted,
                }),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.trf('Top focus today: {category}', {
                  'category': categoryLabel,
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.trf('Weekly progress: {done}/{total}', {
                  'done': _weeklyDoneTotal(),
                  'total': _weeklyTargetTotal(),
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.tr('Later')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.tr('Done button')),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return false;
    final todayKey = _todayKey();
    await _repo.setCoachEveningReviewDone(dateKey: todayKey, done: true);
    if (!mounted) return false;
    _updateState(() => _coachEveningReviewDoneToday = true);
    _track('coach_evening_review_done', {
      'completed_today': _todayCompleted,
      'weekly_done': _weeklyDoneTotal(),
      'weekly_target': _weeklyTargetTotal(),
    });
    _showSnack('Mini review completed.');
    return true;
  }

  Future<bool> _openWeeklyClosingCoach() async {
    if (!mounted) return false;
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return false;
    await _maybeShowWeeklyReviewAndAutoPlan();
    return true;
  }

  Future<void> _bootstrap() async {
    _updateState(() => _loading = true);
    await _controller.preloadAds();
    final queuedApplied = await _repo.applyQueuedWeeklyPlanIfReady(
      weekKey: _repo.currentWeekKey(),
    );
    final result = await _controller.bootstrap();
    final funnelOpen = await _registerOpenForFunnelCompat();
    final profileName = await _repo.getProfileName();
    final profileAvatar = await _repo.getProfileAvatar();
    final activeChallenge = await _repo.getActiveChallenge();
    final dismissedNudges = await _repo.getDismissedInAppNudges(_todayKey());
    final coachMorningIntention = await _repo.getCoachMorningIntention(
      _todayKey(),
    );
    final coachEveningReviewDone = await _repo.getCoachEveningReviewDone(
      _todayKey(),
    );
    final weeklyReviewShownWeek = await _repo.getWeeklyReviewShownWeek() ?? '';
    final lastCompletedTask = await _repo.getLastCompletedTask();
    final earnedBadgesCount = (await _repo.getEarnedBadges()).length;
    final totalSparksLit = await _repo.getTotalCompleted();
    final xpProgress = await _repo.getXpProgress();
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
      _totalSparksLit = totalSparksLit;
      _reminderEnabled = result.reminderEnabled;
      _today = result.today;
      _completed = normalizedCompleted;
      _premiumActive = result.premiumActive;
      _premiumUntil = result.premiumUntil;
      _noAdsUntil = result.noAdsUntil;
      _dailyAddCount = result.dailyAddCount;
      _adaptiveDifficultyDelta = result.adaptiveDifficultyDelta;
      _earnedBadgesCount = earnedBadgesCount;
      _totalXp = xpProgress.totalXp;
      _level = xpProgress.level;
      _xpInLevel = xpProgress.xpInLevel;
      _xpToNextLevel = xpProgress.xpToNextLevel;
      _profileName = profileName ?? '';
      _profileAvatar = profileAvatar;
      _poolError = result.poolError;
      _weeklyWeekKey = weekKey;
      _weeklyTargets = weeklyTargets;
      _weeklyDone = weeklyDone;
      _activeChallenge = activeChallenge;
      _dismissedNudgesToday = dismissedNudges;
      _coachMorningIntentionToday = coachMorningIntention;
      _coachEveningReviewDoneToday = coachEveningReviewDone;
      _weeklyReviewShownWeek = weeklyReviewShownWeek;
      _lastCompletedTaskTitle =
          (lastCompletedTask != null &&
              lastCompletedTask.dateKey == _todayKey())
          ? _repo.localizeTaskTitleForCurrentLocale(lastCompletedTask.title)
          : null;
      _loading = false;
    });
    await _restoreActiveTimerIfNeeded();
    unawaited(_syncHomeWidgetSnapshot());
    _track('home_bootstrap_done', {
      'today_task_count': _today.length,
      'pool_error': result.poolError != null,
      'premium_active': _premiumActive,
      'adaptive_delta': _adaptiveDifficultyDelta,
      'adaptive_task_count': result.adaptiveTaskCount,
      'queued_weekly_plan_applied': queuedApplied,
    });
    if (funnelOpen.isFirstOpen) {
      _track('funnel_install_open', {
        'days_since_install': funnelOpen.daysSinceInstall,
      });
    }
    if (funnelOpen.day1Retained) {
      _track('funnel_day1_retained', {
        'days_since_install': funnelOpen.daysSinceInstall,
      });
    }
    if (funnelOpen.day7Retained) {
      _track('funnel_day7_retained', {
        'days_since_install': funnelOpen.daysSinceInstall,
      });
    }
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
    unawaited(_syncReferralRewardsSilently());

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
        await _prepareStreakRescuePlan();
        await _maybePromptWeeklyPlan();
        await _maybePromptDailyMood();
      }());
    });
  }

  Future<void> _syncReferralRewardsSilently() async {
    final result = await _referral.syncAndApplyRewards();
    if (!mounted || result.claimedCredits <= 0) return;

    final premiumStatus = await _controller.loadPremiumStatus();
    if (!mounted) return;

    _updateState(() {
      _premiumActive = premiumStatus.premiumActive;
      _premiumUntil = premiumStatus.premiumUntil;
      _noAdsUntil = premiumStatus.noAdsUntil;
    });
    await _syncPremiumTopics(_premiumActive);

    final sparkWord = result.claimedCredits == 1 ? 'slot' : 'slots';
    final dayWord = result.claimedCredits == 1 ? 'day' : 'days';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Referral reward applied: +${result.claimedCredits} spark $sparkWord and ${result.claimedCredits} $dayWord premium.',
        ),
      ),
    );
  }

  Future<void> _syncChallengeProgressForToday({
    required int completedToday,
    bool fromTaskCompletion = false,
  }) async {
    final update = await _repo.markActiveChallengeProgress(
      dateKey: _todayKey(),
      completedToday: completedToday,
    );
    if (update == null) return;
    if (mounted) {
      _updateState(() => _activeChallenge = update.challenge);
    } else {
      _activeChallenge = update.challenge;
    }
    if (!mounted) return;
    if (!update.dayLogged) return;

    final challenge = update.challenge;
    final l10n = context.l10n;
    _track('challenge_day_logged', {
      'challenge_id': challenge.templateId,
      'done_days': challenge.completedDaysCount,
      'duration_days': challenge.durationDays,
      'from_task_completion': fromTaskCompletion,
    });

    if (update.completedNow) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          final scheme = theme.colorScheme;
          return AlertDialog(
            title: Text(
              l10n.trf('{title} completed', <String, Object>{
                'title': challenge.localizedTitle(),
              }),
            ),
            content: Text(
              l10n.trf(
                'Great consistency. You completed {done}/{total} days.',
                <String, Object>{
                  'done': challenge.durationDays,
                  'total': challenge.durationDays,
                },
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.tr('Nice')),
              ),
            ],
          );
        },
      );
      _track('challenge_completed', {
        'challenge_id': challenge.templateId,
        'duration_days': challenge.durationDays,
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.trf('{title}: {done}/{total} days logged.', <String, Object>{
            'title': challenge.localizedTitle(),
            'done': challenge.completedDaysCount,
            'total': challenge.durationDays,
          }),
        ),
      ),
    );
  }

  DateTime? _parseDateKeyOrNull(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  int _dateDiffDays(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  Task _buildStreakRescueTask() {
    return Task(
      id: 'rescue_${_todayKey()}',
      title: '2-minute reset: breathe slowly and relax your shoulders',
      category: 'calm',
      isCustom: true,
      difficulty: 'easy',
      durationMinutes: 2,
      isSpecial: true,
    );
  }

  Future<Task> _ensureStreakRescueTask() async {
    final targetId = 'rescue_${_todayKey()}';
    for (final task in _today) {
      if (task.id == targetId) return task;
    }

    final rescueTask = _buildStreakRescueTask();
    final withoutOtherRescues = _today
        .where((task) => !task.id.startsWith('rescue_'))
        .toList();

    final baseLength = withoutOtherRescues.isEmpty
        ? 1
        : withoutOtherRescues.length;
    final updated = <Task>[];
    if (withoutOtherRescues.isEmpty) {
      updated.add(rescueTask);
    } else {
      updated.add(withoutOtherRescues.first);
      updated.add(rescueTask);
      updated.addAll(withoutOtherRescues.skip(1));
    }
    while (updated.length > baseLength) {
      updated.removeLast();
    }

    if (mounted) {
      _updateState(() {
        _today = updated;
        _syncCompletedMap();
      });
    } else {
      _today = updated;
      _syncCompletedMap();
    }
    await _repo.saveSelectedTasks(updated);
    await _repo.saveCompletedMap(_completed);
    return rescueTask;
  }

  Future<void> _prepareStreakRescuePlan() async {
    if (!mounted || _loading || _today.isEmpty) return;
    if (_todayCompleted > 0) {
      _updateState(() {
        _streakRescueTask = null;
        _streakRescueMissedDays = 0;
      });
      return;
    }

    final lastCompletedKey = await _repo.getLastCompletedDate();
    final lastCompleted = _parseDateKeyOrNull(lastCompletedKey);
    if (lastCompleted == null) {
      _updateState(() {
        _streakRescueTask = null;
        _streakRescueMissedDays = 0;
      });
      return;
    }

    final missedDays = _dateDiffDays(lastCompleted, DateTime.now()) - 1;
    if (missedDays < 1) {
      _updateState(() {
        _streakRescueTask = null;
        _streakRescueMissedDays = 0;
      });
      return;
    }

    final rescueTask = await _ensureStreakRescueTask();
    if (!mounted) return;

    final shownDate = await _repo.getStreakRescueShownDate();
    if (shownDate != _todayKey()) {
      _track('streak_rescue_shown', {
        'missed_days': missedDays,
        'task_id': rescueTask.id,
        'duration_sec': rescueTask.totalDurationSeconds,
      });
      await _repo.setStreakRescueShownDate(_todayKey());
    }

    _updateState(() {
      _streakRescueTask = rescueTask;
      _streakRescueMissedDays = missedDays;
    });
  }

  Future<void> _startStreakRescuePlan(Task rescueTask) async {
    if (_activeTimerTask != null && _activeTimerTask!.id != rescueTask.id) {
      return;
    }
    _track('streak_rescue_started', {
      'task_id': rescueTask.id,
      'missed_days': _streakRescueMissedDays,
      'duration_sec': rescueTask.totalDurationSeconds,
    });
    _updateState(() => _streakRescueTask = null);
    await _startTaskTimer(rescueTask);
  }

  void _dismissStreakRescuePlanCard() {
    final rescueTask = _streakRescueTask;
    _updateState(() => _streakRescueTask = null);
    if (rescueTask == null) return;
    _track('streak_rescue_dismissed', {
      'task_id': rescueTask.id,
      'missed_days': _streakRescueMissedDays,
    });
  }

  Widget _buildStreakRescuePlanSliver() {
    final rescueTask = _streakRescueTask;
    if (rescueTask == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    if (_todayCompleted > 0 ||
        _completed[rescueTask.id] == true ||
        _activeTimerTask != null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final titleLead = _streakRescueMissedDays <= 1
        ? 'Yesterday slipped. No pressure.'
        : 'You took a short break. No pressure.';
    final titleTail = 'Start this 2-minute comeback and continue gently.';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;
            return Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: scheme.surface.withOpacity(0.82),
                border: Border.all(color: scheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          color: scheme.primary.withOpacity(0.14),
                        ),
                        child: Icon(
                          Icons.replay_rounded,
                          color: scheme.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '2-minute comeback plan',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _dismissStreakRescuePlanCard,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Hide',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    titleLead,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    titleTail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: scheme.surface.withOpacity(0.34),
                      border: Border.all(
                        color: scheme.outline.withOpacity(0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rescueTask.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '2 min',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _startStreakRescuePlan(rescueTask),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Start 2-minute reset'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _nextWeekKeyFrom(String weekKey) {
    final base = _parseDateKeyOrNull(weekKey);
    if (base == null) {
      return _repo.currentWeekKey(DateTime.now().add(const Duration(days: 7)));
    }
    final nextMonday = base.add(const Duration(days: 7));
    return _repo.currentWeekKey(nextMonday);
  }

  int _suggestedNextWeekTarget(int doneTotal) {
    if (doneTotal <= 0) return 7;
    if (doneTotal <= 20) return (doneTotal + 2).clamp(5, 25);
    return (doneTotal + 3).clamp(8, 25);
  }

  Map<String, int> _buildSuggestedNextWeekTargets({
    required Map<String, int> doneByCategory,
    required int targetTotal,
  }) {
    if (targetTotal <= 0) return const <String, int>{};
    const categories = ['mind', 'body', 'growth', 'calm', 'health'];
    final ranked =
        categories.map((c) => MapEntry(c, doneByCategory[c] ?? 0)).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    var active = ranked
        .where((entry) => entry.value > 0)
        .take(3)
        .map((e) => e.key)
        .toList();
    if (active.isEmpty) {
      active = const ['mind', 'body', 'calm'];
    }
    if (targetTotal < active.length) {
      active = active.take(targetTotal).toList();
    }

    final result = <String, int>{for (final c in active) c: 1};
    var remaining = targetTotal - active.length;
    if (remaining <= 0) return result;

    final weights = <String, int>{
      for (final c in active) c: max(doneByCategory[c] ?? 0, 1),
    };
    final weightSum = weights.values.fold<int>(0, (s, v) => s + v);
    final remainders = <String, double>{};

    for (final c in active) {
      final exact = (remaining * weights[c]!) / weightSum;
      final extra = exact.floor();
      result[c] = (result[c] ?? 0) + extra;
      remainders[c] = exact - extra;
    }

    final used = result.values.fold<int>(0, (s, v) => s + v);
    var left = targetTotal - used;
    while (left > 0) {
      active.sort((a, b) => (remainders[b] ?? 0).compareTo(remainders[a] ?? 0));
      final pick = active.first;
      result[pick] = (result[pick] ?? 0) + 1;
      remainders[pick] = 0;
      left--;
    }

    return result;
  }

  String _suggestedTargetSummaryLine(Map<String, int> targets) {
    final entries = targets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topThree = entries.take(3);
    return topThree
        .map(
          (entry) => '${_controller.categoryLabel(entry.key)} ${entry.value}',
        )
        .join('  •  ');
  }

  Future<_WeeklyReviewChoice?> _showWeeklyReviewDialog({
    required int doneTotal,
    required String topCategory,
    required int suggestedTarget,
    required Map<String, int> suggestedTargets,
  }) {
    final sharePreviewKey = GlobalKey();
    var shareBusy = false;
    return showDialog<_WeeklyReviewChoice>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            Future<void> shareWeeklyReviewCard() async {
              if (shareBusy) return;
              setModalState(() => shareBusy = true);
              final topCategoryLabel = _controller.categoryLabel(topCategory);
              final shared = await _shareImage(
                previewKey: sharePreviewKey,
                filePrefix: 'sparkio_weekly_review',
                shareText:
                    'This week: $doneTotal sparks. Top category: $topCategoryLabel.',
              );
              if (shared) {
                _track('weekly_review_shared', {
                  'done_total': doneTotal,
                  'top_category': topCategory,
                  'suggested_target': suggestedTarget,
                });
              }
              if (!dialogContext.mounted) return;
              setModalState(() => shareBusy = false);
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.88,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '20-second weekly review',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'This week: $doneTotal sparks',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Top category: ${_controller.categoryLabel(topCategory)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Suggested target for next week: $suggestedTarget',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: scheme.surfaceContainerHighest.withOpacity(
                            0.28,
                          ),
                        ),
                        child: Text(
                          _suggestedTargetSummaryLine(suggestedTargets),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 148,
                            child: AspectRatio(
                              aspectRatio: 9 / 16,
                              child: RepaintBoundary(
                                key: sharePreviewKey,
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: 360,
                                    height: 640,
                                    child: WeeklyReviewShareCard(
                                      doneTotal: doneTotal,
                                      topCategoryLabel: _controller
                                          .categoryLabel(topCategory),
                                      suggestedTarget: suggestedTarget,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: shareBusy ? null : shareWeeklyReviewCard,
                          icon: shareBusy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.ios_share_rounded, size: 18),
                          label: Text(
                            shareBusy ? 'Preparing...' : 'Share weekly card',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(
                                dialogContext,
                              ).pop(_WeeklyReviewChoice.later),
                              child: const Text('Later'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(
                                dialogContext,
                              ).pop(_WeeklyReviewChoice.applySuggestion),
                              child: const Text('Apply suggestion'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _maybeShowWeeklyReviewAndAutoPlan() async {
    if (!mounted || _loading) return;
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return;

    final currentWeekKey = _repo.currentWeekKey(now);
    final alreadyShown = await _repo.getWeeklyReviewShownWeek();
    if (alreadyShown == currentWeekKey) return;

    final progress = await _repo.getWeeklyProgress(weekKey: currentWeekKey);
    final doneByCategory = progress.done;
    final doneTotal = progress.totalDone;
    final ranked = doneByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategory = ranked.isEmpty ? 'mind' : ranked.first.key;

    final suggestedTarget = _suggestedNextWeekTarget(doneTotal);
    final suggestedTargets = _buildSuggestedNextWeekTargets(
      doneByCategory: doneByCategory,
      targetTotal: suggestedTarget,
    );
    final nextWeekKey = _nextWeekKeyFrom(currentWeekKey);

    _track('weekly_review_shown', {
      'week_key': currentWeekKey,
      'done_total': doneTotal,
      'top_category': topCategory,
      'suggested_target': suggestedTarget,
    });

    final choice = await _showWeeklyReviewDialog(
      doneTotal: doneTotal,
      topCategory: topCategory,
      suggestedTarget: suggestedTarget,
      suggestedTargets: suggestedTargets,
    );
    await _repo.setWeeklyReviewShownWeek(currentWeekKey);
    if (mounted) {
      _updateState(() => _weeklyReviewShownWeek = currentWeekKey);
    }

    if (!mounted || choice == null || choice == _WeeklyReviewChoice.later) {
      _track('weekly_review_later', {'week_key': currentWeekKey});
      return;
    }

    if (choice == _WeeklyReviewChoice.applySuggestion) {
      await _repo.queueWeeklyPlan(
        WeeklyPlan(weekKey: nextWeekKey, targets: suggestedTargets),
      );
      if (!mounted) return;
      _track('weekly_review_applied', {
        'current_week_key': currentWeekKey,
        'next_week_key': nextWeekKey,
        'target_total': suggestedTarget,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Next week plan queued: $suggestedTarget sparks'),
        ),
      );
    }
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DailyMoodSheet(
                onSelect: (mood) => Navigator.of(dialogContext).pop(mood),
                onSkip: () => Navigator.of(dialogContext).pop(),
              ),
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
    if (DateTime.now().weekday == DateTime.sunday) return;
    if (_weeklyTargets.isNotEmpty) return;
    await _openWeeklyPlanSheet(
      autoPrompt: true,
      forceForWeek: _weeklyWeekKey.isEmpty
          ? _repo.currentWeekKey()
          : _weeklyWeekKey,
    );
  }

  Future<void> _openChallengeModeSheet() async {
    if (!mounted) return;
    final current = _activeChallenge;
    final hasOngoingChallenge = current != null && !current.isCompleted;
    final selected = await showModalBottomSheet<ChallengeTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final scheme = theme.colorScheme;
        final l10n = sheetContext.l10n;
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.8;
        final active = _activeChallenge;
        final starterTemplate = kChallengeTemplates.firstWhere(
          (item) => item.durationDays <= 7,
          orElse: () => kChallengeTemplates.first,
        );

        Color accentFor(ChallengeTemplate template) {
          switch (template.themeKey) {
            case 'focus':
              return const Color(0xFF60A5FA);
            case 'sleep':
              return const Color(0xFF34D399);
            case 'stress':
              return const Color(0xFFF59E0B);
            case 'classic':
              return template.durationDays >= 14
                  ? const Color(0xFFA78BFA)
                  : const Color(0xFF22D3EE);
            default:
              return scheme.primary;
          }
        }

        Widget badge({
          required String label,
          required Color color,
          required Color textColor,
        }) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: color,
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          );
        }

        return SafeArea(
          child: Container(
            height: maxHeight,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('Challenges'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  active == null
                      ? l10n.tr('Pick one and start today.')
                      : l10n.trf(
                          '{title} - {done}/{total} days',
                          <String, Object>{
                            'title': active.localizedTitle(),
                            'done': active.completedDaysCount,
                            'total': active.durationDays,
                          },
                        ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: kChallengeTemplates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final template = kChallengeTemplates[index];
                      final accent = accentFor(template);
                      final isActive =
                          active != null &&
                          !active.isCompleted &&
                          active.templateId == template.id;
                      final isCompleted =
                          active != null &&
                          active.isCompleted &&
                          active.templateId == template.id;
                      final isLocked =
                          hasOngoingChallenge &&
                          active != null &&
                          active.templateId != template.id;
                      final isAdvanced = template.durationDays >= 14;
                      final tierLabel = isAdvanced
                          ? l10n.tr('Advanced')
                          : l10n.tr('Starter');
                      final stateIcon = isLocked
                          ? Icons.lock_rounded
                          : isCompleted
                          ? Icons.check_circle_rounded
                          : isActive
                          ? Icons.bolt_rounded
                          : Icons.flag_rounded;
                      final stateColor = isLocked
                          ? scheme.onSurfaceVariant.withOpacity(0.58)
                          : isCompleted
                          ? const Color(0xFF34D399)
                          : isActive
                          ? accent
                          : scheme.onSurfaceVariant.withOpacity(0.9);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: isLocked
                              ? null
                              : () => Navigator.of(sheetContext).pop(template),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.alphaBlend(
                                    accent.withOpacity(isActive ? 0.28 : 0.16),
                                    scheme.surfaceContainerHighest.withOpacity(
                                      isLocked ? 0.22 : 0.36,
                                    ),
                                  ),
                                  Color.alphaBlend(
                                    accent.withOpacity(isActive ? 0.2 : 0.1),
                                    scheme.surfaceContainerHighest.withOpacity(
                                      isLocked ? 0.18 : 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              border: Border.all(
                                color: isActive
                                    ? accent.withOpacity(0.42)
                                    : Colors.white.withOpacity(
                                        isLocked ? 0.05 : 0.09,
                                      ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: stateColor.withOpacity(0.18),
                                  ),
                                  child: Icon(
                                    stateIcon,
                                    size: 16,
                                    color: stateColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        template.localizedTitle(),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: isLocked
                                                  ? scheme.onSurfaceVariant
                                                        .withOpacity(0.7)
                                                  : scheme.onSurface
                                                        .withOpacity(0.96),
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        template.localizedDescription(),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: isLocked
                                                  ? scheme.onSurfaceVariant
                                                        .withOpacity(0.68)
                                                  : scheme.onSurfaceVariant
                                                        .withOpacity(0.92),
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          badge(
                                            label: l10n.trf(
                                              '{count} days',
                                              <String, Object>{
                                                'count': template.durationDays,
                                              },
                                            ),
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            textColor: scheme.onSurface
                                                .withOpacity(0.9),
                                          ),
                                          badge(
                                            label: l10n.trf(
                                              'Goal {count}/day',
                                              <String, Object>{
                                                'count': template.dailyGoal,
                                              },
                                            ),
                                            color: accent.withOpacity(0.18),
                                            textColor: accent,
                                          ),
                                          badge(
                                            label: tierLabel,
                                            color: isAdvanced
                                                ? const Color(
                                                    0xFFA78BFA,
                                                  ).withOpacity(0.2)
                                                : const Color(
                                                    0xFF22D3EE,
                                                  ).withOpacity(0.2),
                                            textColor: isAdvanced
                                                ? const Color(0xFFD8B4FE)
                                                : const Color(0xFF67E8F9),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: accent.withOpacity(0.2),
                                    ),
                                    child: Text(
                                      l10n.tr('Active'),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: accent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  )
                                else if (isCompleted)
                                  Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: const Color(0xFF34D399),
                                  )
                                else if (isLocked)
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 18,
                                    color: scheme.onSurfaceVariant.withOpacity(
                                      0.6,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: scheme.onSurfaceVariant.withOpacity(
                                      0.86,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: scheme.surfaceContainerHighest.withOpacity(0.28),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: active == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.tr('No active challenge'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.tr(
                                'Start one today and keep your streak moving.',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant.withOpacity(
                                  0.88,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => Navigator.of(
                                  sheetContext,
                                ).pop(starterTemplate),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(l10n.tr('Start one today')),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              active.localizedTitle(),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.trf(
                                '{done}/{total} days completed',
                                <String, Object>{
                                  'done': active.completedDaysCount,
                                  'total': active.durationDays,
                                },
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: active.progress.clamp(0.0, 1.0),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (!active.isCompleted &&
                                    !active.hasLoggedDate(_todayKey()))
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () async {
                                        Navigator.of(sheetContext).pop();
                                        await _startQuickTaskFromNudge();
                                      },
                                      icon: const Icon(Icons.bolt_rounded),
                                      label: Text(l10n.tr('Start today spark')),
                                    ),
                                  ),
                                if (!active.isCompleted &&
                                    !active.hasLoggedDate(_todayKey()))
                                  const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () async {
                                    await _repo.clearActiveChallenge();
                                    if (!mounted) return;
                                    _updateState(() => _activeChallenge = null);
                                    Navigator.of(sheetContext).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.tr('Active challenge removed.'),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(l10n.tr('Remove')),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    if (current != null &&
        !current.isCompleted &&
        current.templateId == selected.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.trf('{title} is already active.', <String, Object>{
              'title': selected.localizedTitle(),
            }),
          ),
        ),
      );
      return;
    }
    final started = ActiveChallenge.fromTemplate(
      template: selected,
      startDateKey: _todayKey(),
    );
    await _repo.saveActiveChallenge(started);
    if (!mounted) return;
    _updateState(() => _activeChallenge = started);
    _track('challenge_started', {
      'challenge_id': started.templateId,
      'duration_days': started.durationDays,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.trf('{title} challenge started.', <String, Object>{
            'title': selected.localizedTitle(),
          }),
        ),
      ),
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

  void _showWeeklyPlanInAppNotice({
    required int doneTotal,
    required int targetTotal,
    required bool completed,
  }) {
    // Weekly progress is now shown as a persistent mini bar on Home.
    if (!mounted || targetTotal <= 0) return;
  }

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

  String _shortDurationLabel(Task task) {
    final seconds = task.totalDurationSeconds;
    if (seconds < 60) return '$seconds sec';
    if (seconds % 60 == 0) {
      final mins = seconds ~/ 60;
      return '$mins min';
    }
    final mins = seconds ~/ 60;
    final sec = seconds % 60;
    return '${mins}m ${sec}s';
  }

  Task? _nextMicroStepSuggestion({required String completedTaskId}) {
    final candidates = _today
        .where(
          (task) => task.id != completedTaskId && _completed[task.id] != true,
        )
        .toList();
    if (candidates.isEmpty) return null;
    int difficultyRank(String value) {
      switch (value) {
        case 'easy':
          return 0;
        case 'medium':
          return 1;
        case 'hard':
          return 2;
        default:
          return 1;
      }
    }

    candidates.sort((a, b) {
      final durationCompare = a.totalDurationSeconds.compareTo(
        b.totalDurationSeconds,
      );
      if (durationCompare != 0) return durationCompare;
      return difficultyRank(
        a.difficulty,
      ).compareTo(difficultyRank(b.difficulty));
    });
    return candidates.first;
  }

  Map<String, int> _weeklyRemainingByCategory() {
    if (_weeklyTargets.isEmpty) return const <String, int>{};
    final remaining = <String, int>{};
    for (final entry in _weeklyTargets.entries) {
      final target = entry.value;
      if (target <= 0) continue;
      final done = _weeklyDone[entry.key] ?? 0;
      final left = max(target - done, 0);
      if (left > 0) {
        remaining[entry.key] = left;
      }
    }
    return remaining;
  }

  Future<_NextBestSparkSuggestion?> _resolveNextBestSparkSuggestion() async {
    final pool = await _loadEffectivePool();
    if (pool.isEmpty) return null;

    final todayKey = _todayKey();
    final lastSeenDate = await _repo.getLastSeenDate();
    final lastSeenIds = await _repo.getLastSeenTaskIds();
    final avoidFromLastSeen = lastSeenDate == todayKey
        ? lastSeenIds.toSet()
        : <String>{};
    final currentIds = _today.map((task) => task.id).toSet();
    final avoidIds = currentIds.union(avoidFromLastSeen);

    var candidates = pool
        .where((task) => !avoidIds.contains(task.id))
        .toList(growable: false);
    if (candidates.isEmpty) {
      candidates = pool
          .where((task) => !currentIds.contains(task.id))
          .toList(growable: false);
    }
    if (candidates.isEmpty) return null;

    final remainingByCategory = _weeklyRemainingByCategory();
    final categoryCounts = await _repo.getCategoryCounts();

    int difficultyWeight(String difficulty) {
      switch (difficulty) {
        case 'easy':
          return 26;
        case 'medium':
          return 12;
        case 'hard':
          return 0;
        default:
          return 8;
      }
    }

    double score(Task task) {
      final weeklyBoost = (remainingByCategory[task.category] ?? 0) * 160.0;
      final affinity = min(categoryCounts[task.category] ?? 0, 40) * 2.2;
      final quickWin = max(0.0, (220 - task.totalDurationSeconds) / 6);
      final difficulty = difficultyWeight(task.difficulty).toDouble();
      final specialBoost = task.isSpecial ? 7.0 : 0.0;
      return weeklyBoost + affinity + quickWin + difficulty + specialBoost;
    }

    final ranked = [...candidates]
      ..sort((a, b) {
        final scoreCompare = score(b).compareTo(score(a));
        if (scoreCompare != 0) return scoreCompare;
        final durationCompare = a.totalDurationSeconds.compareTo(
          b.totalDurationSeconds,
        );
        if (durationCompare != 0) return durationCompare;
        return a.title.compareTo(b.title);
      });

    final best = ranked.first;
    final weeklyLeftForCategory = remainingByCategory[best.category] ?? 0;
    final reason = weeklyLeftForCategory > 0
        ? 'Boosts your weekly ${_controller.categoryLabel(best.category)} goal.'
        : 'Quick ${_shortDurationLabel(best)} spark based on your rhythm.';
    return _NextBestSparkSuggestion(task: best, reason: reason);
  }

  Future<bool> _addAndStartNextBestSpark({
    _NextBestSparkSuggestion? suggestion,
  }) async {
    final resolved = suggestion ?? await _resolveNextBestSparkSuggestion();
    final task = resolved?.task;
    if (task == null) {
      if (mounted) _showSnack('No next spark suggestion right now.');
      return false;
    }
    if (_today.any((item) => item.id == task.id)) {
      if (mounted) _showSnack('That spark is already in your list.');
      return false;
    }

    final updated = [..._today, task];
    await _repo.saveSelectedTasks(updated);
    await _controller.updateLastSeen(dateKey: _todayKey(), tasks: [task]);

    if (!mounted) return false;
    _updateState(() {
      _today = updated;
      _completed[task.id] = false;
      _syncCompletedMap();
    });
    await _repo.saveCompletedMap(_completed);
    unawaited(_syncHomeWidgetSnapshot());
    _track('next_best_spark_added', {
      'task_id': task.id,
      'category': task.category,
      'duration_sec': task.totalDurationSeconds,
      'difficulty': task.difficulty,
    });
    await _startTaskTimer(task);
    if (!mounted) return false;
    _showSnack('Next best spark started.');
    return true;
  }

  Future<void> _showTaskCompletionMomentum({
    required Task task,
    required int completedToday,
    required String completionChainId,
    required int remainingActionCount,
    Task? secondStepSuggestion,
    int? weeklyDoneTotal,
    int? weeklyTargetTotal,
  }) async {
    if (!mounted) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final dailyGoal = max(max(_today.length, completedToday), 1);
    final done = completedToday.clamp(0, dailyGoal);
    final activationMoment = done == 1;
    final hasSecondStepSuggestion =
        activationMoment && secondStepSuggestion != null;
    _track('completion_reinforcement_shown', {
      'chain_id': completionChainId,
      'task_id': task.id,
      'completed_today': done,
      'remaining_actions': remainingActionCount,
      'activation_moment': activationMoment,
      'has_second_step': hasSecondStepSuggestion,
    });
    if (hasSecondStepSuggestion) {
      _track('activation_second_step_suggested', {
        'chain_id': completionChainId,
        'suggested_task_id': secondStepSuggestion.id,
        'suggested_duration_sec': secondStepSuggestion.totalDurationSeconds,
      });
    }

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
        const accent = Color(0xFF8776FF);
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
                            accent.withOpacity(backdropGlow),
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
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF201D3D), Color(0xFF121D33)],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.2),
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
                                          color: accent,
                                        ),
                                      ),
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              accent.withOpacity(0.42),
                                              accent.withOpacity(0.22),
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: _DrawnCheckIcon(
                                            progress: burst,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Nice. You showed up.',
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
                              Row(
                                children: [
                                  _MomentumRing(
                                    progress: ringProgress,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '$done/$dailyGoal sparks today',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white.withOpacity(
                                              0.94,
                                            ),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              if (hasSecondStepSuggestion) ...[
                                const SizedBox(height: 10),
                                Material(
                                  color: Colors.transparent,
                                  child: Ink(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white.withOpacity(0.06),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.12),
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        _track(
                                          'completion_reinforcement_next_card',
                                          {
                                            'chain_id': completionChainId,
                                            'suggested_task_id':
                                                secondStepSuggestion.id,
                                          },
                                        );
                                        unawaited(() async {
                                          await dismissOverlay();
                                          await _startTaskTimer(
                                            secondStepSuggestion,
                                          );
                                        }());
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          10,
                                          9,
                                          10,
                                          9,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.auto_awesome_rounded,
                                              size: 17,
                                              color: accent,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                secondStepSuggestion.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: Colors.white
                                                          .withOpacity(0.88),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _shortDurationLabel(
                                                secondStepSuggestion,
                                              ),
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    color: accent,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Opacity(
                                opacity: ctaOpacity,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: accent,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(46),
                                    ),
                                    onPressed: () {
                                      final action = hasSecondStepSuggestion
                                          ? 'start_second_step'
                                          : 'continue';
                                      _track('completion_reinforcement_cta', {
                                        'chain_id': completionChainId,
                                        'action': action,
                                        'remaining_actions':
                                            remainingActionCount,
                                        if (hasSecondStepSuggestion)
                                          'suggested_task_id':
                                              secondStepSuggestion.id,
                                      });
                                      if (hasSecondStepSuggestion) {
                                        unawaited(() async {
                                          await dismissOverlay();
                                          await _startTaskTimer(
                                            secondStepSuggestion,
                                          );
                                        }());
                                      } else {
                                        unawaited(dismissOverlay());
                                      }
                                    },
                                    child: Text(
                                      hasSecondStepSuggestion
                                          ? 'Start second spark'
                                          : 'Continue',
                                    ),
                                  ),
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

  Widget _buildEndDrawer() {
    Theme.of(context);
    final isDark = ThemeService.instance.mode.value == ThemeMode.dark;
    final themeUnlocked = LevelUnlocks.canUseThemeSwitcher(_level);
    final selectedLocale = LocaleService.instance.locale.value;

    return ModernDrawer(
      isDark: isDark,
      showDebugTools: _showDebugTools,
      profileName: _profileName,
      profileAvatar: _profileAvatar,
      currentStreak: _streak,
      totalSparksLit: _totalSparksLit,
      currentLevel: _level,
      totalXp: _totalXp,
      xpInLevel: _xpInLevel,
      xpToNextLevel: _xpToNextLevel,
      earnedBadgeCount: _earnedBadgesCount,
      badgeGoalCount: _HomeScreenState._badgeGoalCount,
      weeklyDoneCount: _weeklyDoneTotal(),
      weeklyGoalCount: _weeklyTargetTotal(),
      themeUnlocked: themeUnlocked,
      themeUnlockLevel: LevelUnlocks.themeSwitcherLevel,
      onToggleTheme: _toggleTheme,
      onOpenAddSpark: _openAddTaskSheet,
      onRefreshTasks: _refreshTasks,
      onEditProfile: _openProfileEditor,
      onOpenProfile: _openProfileScreen,
      onOpenReferral: _openReferralFromDrawer,
      onOpenBadges: _openBadges,
      onOpenWeeklyPlan: () => _openWeeklyPlanSheet(),
      onOpenContact: _openContact,
      onOpenRateUs: () => _openRateApp(source: 'drawer'),
      onSendTestNotification: _sendTestNotification,
      onOpenDailyMoodSheet: _openDailyMoodSheetDebug,
      onOpenChallenges: _openChallengeModeSheet,
      onOpenPremium: _openPremiumPerksSheet,
      selectedLocale: selectedLocale,
      onOpenLanguagePicker: _openLanguagePicker,
    );
  }

  void _toggleTheme() {
    if (!LevelUnlocks.canUseThemeSwitcher(_level)) {
      final message = LevelUnlocks.unlockedAtLabel(
        level: LevelUnlocks.themeSwitcherLevel,
        featureName: 'Theme switcher',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
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

  void _openReferralFromDrawer() {
    _openProfileScreen(openReferralOnLoad: true);
  }

  void _openProfileScreen({bool openReferralOnLoad = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          profileName: _profileName,
          profileAvatar: _profileAvatar,
          currentStreak: _streak,
          currentLevel: _level,
          totalXp: _totalXp,
          xpInLevel: _xpInLevel,
          xpToNextLevel: _xpToNextLevel,
          openReferralOnLoad: openReferralOnLoad,
        ),
      ),
    ).then((_) async {
      final latest = await _repo.getProfileName();
      final latestAvatar = await _repo.getProfileAvatar();
      final premiumStatus = await _controller.loadPremiumStatus();
      if (!mounted) return;
      _updateState(() {
        _profileName = latest ?? '';
        _profileAvatar = latestAvatar;
        _premiumActive = premiumStatus.premiumActive;
        _premiumUntil = premiumStatus.premiumUntil;
        _noAdsUntil = premiumStatus.noAdsUntil;
      });
      await _syncPremiumTopics(_premiumActive);
    });
  }

  void _openContact() {
    _openInstagramContact();
  }

  Future<void> _openRateApp({String source = 'manual'}) async {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
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
          content: Text(l10n.tr('Unable to open rating right now.')),
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

  // ignore: unused_element
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

  // ignore: unused_element
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
      final message = switch (result.failure) {
        AddTaskFailure.limitReached => result.message ?? 'Daily limit reached.',
        AddTaskFailure.lowQualityTitle =>
          result.message ??
              'Task is too vague. Try action + outcome (e.g. Drink one glass of water).',
        null => 'Could not add task.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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

  Future<bool> _applyTaskPack(String packId) async {
    final response = await _controller.applyTaskPack(
      packId: packId,
      current: _today,
      dailyAddCount: _dailyAddCount,
    );

    if (!response.success) {
      final message = response.message ?? 'Could not apply task pack.';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      _track('task_pack_apply_failed', {
        'pack_id': packId,
        'reason': response.failure?.name ?? 'unknown',
      });
      return false;
    }

    final added = response.added!;
    _updateState(() {
      _today = response.updated!;
      for (final task in added) {
        _completed[task.id] = false;
      }
      _syncCompletedMap();
      _dailyAddCount = response.newCount!;
      _premiumActive = response.premiumActive ?? _premiumActive;
      if (added.isNotEmpty) {
        final last = added.last;
        _customCategory = last.category;
        _customDifficulty = last.difficulty;
        _customDuration = last.durationMinutes;
      }
    });
    await _repo.saveCompletedMap(_completed);
    unawaited(_syncHomeWidgetSnapshot());

    final noun = added.length == 1 ? 'task' : 'tasks';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${added.length} $noun added from pack.')),
      );
    }
    _track('task_pack_applied', {
      'pack_id': response.packId ?? packId,
      'added_count': added.length,
      'premium_active': _premiumActive,
    });
    return true;
  }

  Future<bool> _applyCreatorPack(String creatorPackId) async {
    final response = await _controller.applyCreatorPack(
      creatorPackId: creatorPackId,
      current: _today,
      dailyAddCount: _dailyAddCount,
      currentLevel: _level,
    );

    if (!response.success) {
      final message = response.message ?? 'Could not apply creator pack.';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      _track('creator_pack_apply_failed', {
        'creator_pack_id': creatorPackId,
        'reason': response.failure?.name ?? 'unknown',
      });
      return false;
    }

    final added = response.added!;
    _updateState(() {
      _today = response.updated!;
      for (final task in added) {
        _completed[task.id] = false;
      }
      _syncCompletedMap();
      _dailyAddCount = response.newCount!;
      _premiumActive = response.premiumActive ?? _premiumActive;
      if (added.isNotEmpty) {
        final last = added.last;
        _customCategory = last.category;
        _customDifficulty = last.difficulty;
        _customDuration = last.durationMinutes;
      }
    });
    await _repo.saveCompletedMap(_completed);
    unawaited(_syncHomeWidgetSnapshot());

    final noun = added.length == 1 ? 'task' : 'tasks';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${added.length} $noun added from creator pack.'),
        ),
      );
    }
    _track('creator_pack_applied', {
      'creator_pack_id': response.packId ?? creatorPackId,
      'added_count': added.length,
      'premium_active': _premiumActive,
    });
    return true;
  }

  Future<void> _setCreatorPackSaved(String creatorPackId, bool saved) async {
    await _repo.setCreatorPackSaved(packId: creatorPackId, saved: saved);
    _track('creator_pack_saved_toggled', {
      'creator_pack_id': creatorPackId,
      'saved': saved,
    });
  }

  Future<void> _setCreatorPackRating(String creatorPackId, int rating) async {
    await _repo.setCreatorPackRating(packId: creatorPackId, rating: rating);
    _track('creator_pack_rated', {
      'creator_pack_id': creatorPackId,
      'rating': rating,
    });
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

  // ignore: unused_element
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

  // ignore: unused_element
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

  Future<Uint8List> _captureShareBytes({GlobalKey? previewKey}) async {
    await WidgetsBinding.instance.endOfFrame;
    final key = previewKey ?? _sharePreviewKey;
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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

  Future<File> _writeShareImage({
    GlobalKey? previewKey,
    String filePrefix = 'sparkio_share',
  }) async {
    final bytes = await _captureShareBytes(previewKey: previewKey);
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _shareImage({
    String? hint,
    GlobalKey? previewKey,
    String filePrefix = 'sparkio_streak',
    String? shareText,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 20));
      final file = await _writeShareImage(
        previewKey: previewKey,
        filePrefix: filePrefix,
      );
      final baseText = 'My Sparkio streak: $_streak days.';
      final text = shareText ?? (hint == null ? baseText : '$baseText ($hint)');
      await Share.shareXFiles([XFile(file.path)], text: text);
      return true;
    } catch (_) {
      if (mounted) _showSnack('Unable to share right now.');
      return false;
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
    final creatorCatalog = await _controller.getCreatorPackCatalog(
      sort: CreatorPackCatalogSort.popular,
      currentLevel: _level,
    );
    final savedCreatorPackIds = await _repo.getSavedCreatorPackIds();
    final creatorPackRatings = await _repo.getCreatorPackRatings();
    final creatorPacks = creatorCatalog
        .map(
          (pack) => TaskAddSheetCreatorPack(
            id: pack.id,
            title: pack.title,
            creatorName: pack.creatorName,
            description: pack.description,
            toneKey: pack.toneKey,
            installs: pack.installs,
            rating: pack.rating,
            ratingCount: pack.ratingCount,
            isNew: pack.isNew,
            forYouScore: pack.forYouScore,
            releaseOrder: pack.releaseOrder,
            requiredLevel: pack.requiredLevel,
            isUnlocked: pack.isUnlocked,
            isSaved: savedCreatorPackIds.contains(pack.id),
            userRating: creatorPackRatings[pack.id],
          ),
        )
        .toList(growable: false);
    final freeSparkSlotLimit = await _repo.getFreeSparkSlotLimit(
      premiumActive: false,
    );
    unawaited(
      AnalyticsService.instance.setUserProperty(
        name: 'add_task_cta_variant',
        value: ctaVariant,
      ),
    );
    final freeSparkLeft = (freeSparkSlotLimit - _dailyAddCount).clamp(
      0,
      freeSparkSlotLimit,
    );
    final sparkWord = freeSparkLeft == 1 ? 'spark' : 'sparks';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (dialogContext) {
        return TaskAddSheet(
          canAddTask: _premiumActive || _dailyAddCount < freeSparkSlotLimit,
          addLimitLabel: _premiumActive
              ? 'Premium: Unlimited Sparks'
              : freeSparkLeft > 0
              ? 'Free Plan: $freeSparkLeft $sparkWord left'
              : 'Go Unlimited',
          initialCategory: _customCategory,
          initialDifficulty: _customDifficulty,
          initialDurationMinutes: _customDuration,
          premiumActive: _premiumActive,
          onAdd: _addCustomTask,
          onGenerateAi: _generateAiTask,
          onApplyPack: _applyTaskPack,
          onApplyCreatorPack: _applyCreatorPack,
          onSetCreatorPackSaved: _setCreatorPackSaved,
          onSetCreatorPackRating: _setCreatorPackRating,
          creatorPacks: creatorPacks,
          onOpenPremium: _openSubscribeSheet,
          ctaVariant: ctaVariant,
          ctaLabel: ctaCopy['label']!,
          ctaSubtitle: ctaCopy['subtitle']!,
          onCtaEvent: (event, variant) {
            _track('add_task_cta_$event', {'variant': variant});
          },
        );
      },
    );
  }

  Future<void> _openLanguagePicker() async {
    final l10n = context.l10n;
    final currentSelection = LocaleService.instance.locale.value;
    final effectiveLocale = Localizations.localeOf(context);
    final systemLabel =
        '${l10n.followSystem} · ${l10n.languageDisplayName(effectiveLocale.languageCode)}';

    Future<void> selectLocale(Locale? locale) async {
      await LocaleService.instance.setLocale(locale);
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final scheme = theme.colorScheme;

        Widget optionTile({
          required String title,
          required String subtitle,
          required bool selected,
          required VoidCallback onTap,
        }) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Color.alphaBlend(
                      (selected ? const Color(0xFF8B7CFF) : Colors.white)
                          .withOpacity(selected ? 0.10 : 0.04),
                      const Color(0xFF111827),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(selected ? 0.10 : 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white.withOpacity(
                                  selected ? 0.96 : 0.88,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected
                            ? const Color(0xFF8B7CFF)
                            : Colors.white.withOpacity(0.42),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color.fromRGBO(11, 15, 26, 0.94),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.28),
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white.withOpacity(0.16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.chooseLanguage,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.94),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.chooseLanguageSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant.withOpacity(0.84),
                        ),
                      ),
                      const SizedBox(height: 18),
                      optionTile(
                        title: l10n.followSystem,
                        subtitle: systemLabel,
                        selected: currentSelection == null,
                        onTap: () => selectLocale(null),
                      ),
                      optionTile(
                        title: l10n.languageDisplayName('en'),
                        subtitle: 'English',
                        selected: currentSelection?.languageCode == 'en',
                        onTap: () => selectLocale(const Locale('en')),
                      ),
                      optionTile(
                        title: l10n.languageDisplayName('tr'),
                        subtitle: 'Turkce',
                        selected: currentSelection?.languageCode == 'tr',
                        onTap: () => selectLocale(const Locale('tr')),
                      ),
                      optionTile(
                        title: l10n.languageDisplayName('es'),
                        subtitle: 'Espanol',
                        selected: currentSelection?.languageCode == 'es',
                        onTap: () => selectLocale(const Locale('es')),
                      ),
                      optionTile(
                        title: l10n.languageDisplayName('de'),
                        subtitle: 'Deutsch',
                        selected: currentSelection?.languageCode == 'de',
                        onTap: () => selectLocale(const Locale('de')),
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
  }

  Future<void> _openTodayPlanSheet({
    required List<Task> doneTasks,
    required Task? nextTask,
    required List<Task> laterTasks,
  }) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    var laterExpanded = false;

    String durationLabel(Task task) {
      final totalSeconds = task.totalDurationSeconds.clamp(1, 360000);
      if (totalSeconds < 60) return '~ $totalSeconds ${l10n.tr('seconds')}';
      if (totalSeconds % 60 == 0) {
        final mins = totalSeconds ~/ 60;
        return mins == 1 ? '1 ${l10n.tr('min')}' : '$mins ${l10n.tr('min')}';
      }
      final mins = totalSeconds ~/ 60;
      final secs = totalSeconds % 60;
      return '~ $mins ${l10n.tr('min')} $secs ${l10n.tr('seconds')}';
    }

    Widget divider() {
      return Container(
        height: 1,
        margin: const EdgeInsets.only(left: 26),
        color: Colors.white.withOpacity(0.06),
      );
    }

    Widget flatRow(
      Task task, {
      required String section,
      required IconData icon,
      required Color iconColor,
      required double iconOpacity,
      required double textOpacity,
      required FontWeight textWeight,
      bool showAccent = false,
      String? helper,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 16,
              child: showAccent
                  ? Container(
                      width: 2,
                      height: helper == null ? 20 : 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF8B7CFF).withOpacity(0.9),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      size: 14,
                      color: iconColor.withOpacity(iconOpacity),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withOpacity(textOpacity),
                              fontWeight: textWeight,
                              height: 1.2,
                            ),
                            children: [
                              TextSpan(
                                text: '$section\n',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurface.withOpacity(
                                    showAccent ? 0.68 : textOpacity,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: _repo.localizeTaskTitleForCurrentLocale(
                                  task.title,
                                  category: task.category,
                                  taskId: task.id,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        durationLabel(task),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant.withOpacity(
                            showAccent ? 0.82 : textOpacity,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (helper != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      helper,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withOpacity(0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      const Color.fromRGBO(14, 18, 32, 0.92),
                      scheme.surface,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Text(
                        l10n.tr("Today's rhythm"),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface.withOpacity(0.92),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (nextTask != null) ...[
                                flatRow(
                                  nextTask,
                                  section: l10n.tr('Now'),
                                  icon: Icons.play_arrow_rounded,
                                  iconColor: const Color(0xFF8B7CFF),
                                  iconOpacity: 1,
                                  textOpacity: 1,
                                  textWeight: FontWeight.w600,
                                  showAccent: true,
                                  helper: l10n.tr('Start small.'),
                                ),
                                divider(),
                                const SizedBox(height: 24),
                              ],
                              if (doneTasks.isNotEmpty) ...[
                                ...doneTasks.asMap().entries.map((entry) {
                                  final row = flatRow(
                                    entry.value,
                                    section: l10n.tr('Done'),
                                    icon: Icons.check_rounded,
                                    iconColor: const Color(0xFFA7D4C8),
                                    iconOpacity: 0.6,
                                    textOpacity: 0.62,
                                    textWeight: FontWeight.w500,
                                  );
                                  if (entry.key == doneTasks.length - 1) {
                                    return row;
                                  }
                                  return Column(
                                    children: [
                                      row,
                                      divider(),
                                      const SizedBox(height: 14),
                                    ],
                                  );
                                }),
                                const SizedBox(height: 24),
                              ],
                              if (laterTasks.isNotEmpty) ...[
                                InkWell(
                                  onTap: () => setModalState(
                                    () => laterExpanded = !laterExpanded,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          l10n.tr('Later'),
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color: scheme.onSurface
                                                    .withOpacity(0.46),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          laterExpanded
                                              ? l10n.tr(
                                                  'Optional - no pressure.',
                                                )
                                              : l10n.trf('{count} optional', {
                                                  'count': laterTasks.length,
                                                }),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant
                                                    .withOpacity(0.42),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          laterExpanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons
                                                    .keyboard_arrow_down_rounded,
                                          size: 18,
                                          color: scheme.onSurfaceVariant
                                              .withOpacity(0.38),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (laterExpanded) ...[
                                  const SizedBox(height: 14),
                                  ...laterTasks.asMap().entries.map((entry) {
                                    final row = flatRow(
                                      entry.value,
                                      section: l10n.tr('Later'),
                                      icon: Icons.circle_outlined,
                                      iconColor: scheme.onSurfaceVariant,
                                      iconOpacity: 0.35,
                                      textOpacity: 0.35,
                                      textWeight: FontWeight.w500,
                                    );
                                    if (entry.key == laterTasks.length - 1) {
                                      return row;
                                    }
                                    return Column(
                                      children: [
                                        row,
                                        divider(),
                                        const SizedBox(height: 14),
                                      ],
                                    );
                                  }),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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

  Future<void> _openPremiumPerksSheet() async {
    final noAdsActive = _noAdsUntil?.isAfter(DateTime.now()) ?? false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: PremiumPerksSheet(
            rewardBusy: _rewardBusy,
            premiumActive: _premiumActive,
            noAdsActive: noAdsActive,
            premiumStatus: _formatRemaining(_premiumUntil),
            noAdsStatus: _formatRemaining(_noAdsUntil),
            onWatchPremium: () {
              unawaited(
                _watchAdForReward(
                  duration: const Duration(minutes: 30),
                  noAds: false,
                ),
              );
            },
            onWatchNoAds: () {
              unawaited(
                _watchAdForReward(
                  duration: const Duration(days: 1),
                  noAds: true,
                ),
              );
            },
            onOpenSubscribe: () {
              Navigator.of(sheetContext).pop();
              unawaited(
                Future<void>.delayed(
                  const Duration(milliseconds: 180),
                  _openSubscribeSheet,
                ),
              );
            },
            onExtraTask: () {
              unawaited(
                _runRewardedAction(
                  action: _addExtraTask,
                  successMessage: 'Extra task added.',
                ),
              );
            },
            onRecoverStreak: () {
              unawaited(
                _runRewardedAction(
                  action: _recoverStreak,
                  successMessage: 'Streak recovered.',
                ),
              );
            },
          ),
        );
      },
    );
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

    final nextBestSuggestion = await _resolveNextBestSparkSuggestion();
    unawaited(_showAllDoneCelebration(nextBestSuggestion: nextBestSuggestion));

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
    if (mounted) {
      _updateState(() => _totalSparksLit = totalCompleted);
    }
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

  Future<void> _showAllDoneCelebration({
    _NextBestSparkSuggestion? nextBestSuggestion,
  }) async {
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
              nextBestSuggestion: nextBestSuggestion,
              onStartNextBestSpark: () async {
                final started = await _addAndStartNextBestSpark(
                  suggestion: nextBestSuggestion,
                );
                if (!started || !mounted) return;
                Navigator.of(ctx).maybePop();
              },
              onViewStats: () {
                Navigator.of(ctx).maybePop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StatsScreen(currentLevel: _level),
                  ),
                );
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
    final unlockedFeature = LevelUnlocks.unlockForLevel(newLevel);
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
            unlockedFeature: unlockedFeature,
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
    final duration = Duration(seconds: task.totalDurationSeconds);
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
      _activeTimerPaused = false;
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
      'duration_sec': task.totalDurationSeconds,
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
      _activeTimerPaused = false;
    });
    unawaited(_syncHomeWidgetSnapshot());
  }

  Future<void> _pauseTaskTimer(Task task) async {
    if (_activeTimerTask?.id != task.id) return;
    if (_activeTimerFinished || _activeTimerPaused) return;
    final notificationId = _taskTimerNotificationId(task.id);
    _activeTimerTicker?.cancel();
    await NotificationService.instance.cancelTaskTimer(notificationId);
    await NotificationService.instance.cancelTaskTimerOngoing();
    await _repo.clearActiveTaskTimer();
    if (!mounted) return;
    _updateState(() => _activeTimerPaused = true);
    _track('task_timer_paused', {'task_id': task.id});
    unawaited(_syncHomeWidgetSnapshot());
  }

  Future<void> _resumeTaskTimer(Task task) async {
    if (_activeTimerTask?.id != task.id) return;
    if (_activeTimerFinished || !_activeTimerPaused) return;
    final remaining = _activeTimerRemaining;
    if (remaining <= Duration.zero) return;
    final notificationId = _taskTimerNotificationId(task.id);
    final endAt = DateTime.now().add(remaining);
    if (mounted) {
      _updateState(() => _activeTimerPaused = false);
    } else {
      _activeTimerPaused = false;
    }
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
    unawaited(() async {
      try {
        await NotificationService.instance.cancelTaskTimer(notificationId);
        await NotificationService.instance.scheduleTaskTimer(
          notificationId: notificationId,
          title: 'Task timer finished',
          body: '${task.title} is ready to mark done.',
          duration: remaining,
        );
      } catch (e) {
        _log('NOTI: scheduleTaskTimer (resume) failed: $e');
      }
    }());
    _showTaskTimerOngoingBestEffort(task: task, remaining: remaining);
    _track('task_timer_resumed', {'task_id': task.id});
    unawaited(_syncHomeWidgetSnapshot());
  }

  Future<void> _markTaskDone(Task task) async {
    final completedFromTimer = _activeTimerTask?.id == task.id;
    final weekKey = _repo.currentWeekKey();
    final beforeWeekDone = _weeklyDoneTotal();
    final weekTarget = _weeklyTargetTotal();
    final categoryTarget = _weeklyTargets[task.category] ?? 0;
    final weeklyDoneForOverlay = (weekTarget > 0 && categoryTarget > 0)
        ? beforeWeekDone + 1
        : null;
    final xpReward = _taskXpReward(task);
    final previousLevel = _level;
    await HapticFeedback.lightImpact();
    if (_activeTimerTask?.id == task.id) {
      await _cancelTaskTimer(task);
    }
    await _repo.incrementCompleted(
      task.category,
      task: task,
      completedAt: DateTime.now(),
    );
    final xpProgress = await _repo.addXp(xpReward);
    final newDaily = await _repo.incrementDailyCompleted(_todayKey());
    final remainingActionCount = _today
        .where((item) => _completed[item.id] != true)
        .length;
    final secondStepSuggestion = _nextMicroStepSuggestion(
      completedTaskId: task.id,
    );
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
      secondStepSuggestion: secondStepSuggestion,
      weeklyDoneTotal: weeklyDoneForOverlay,
      weeklyTargetTotal: weekTarget > 0 ? weekTarget : null,
    );
    await _syncChallengeProgressForToday(
      completedToday: newDaily,
      fromTaskCompletion: true,
    );
    await _repo.setLastCompletedTask(
      title: task.title,
      category: task.category,
      dateKey: _todayKey(),
    );
    if (mounted) {
      _updateState(() => _lastCompletedTaskTitle = task.title);
    } else {
      _lastCompletedTaskTitle = task.title;
    }
    final total = await _repo.getTotalCompleted();
    if (mounted) {
      _updateState(() => _totalSparksLit = total);
    }
    if (total == 1) {
      _track('funnel_first_spark', {
        'task_id': task.id,
        'category': task.category,
        'duration_sec': task.totalDurationSeconds,
      });
    }
    final best = await _repo.getBestStreak();
    final counts = await _repo.getCategoryCounts();
    final newBadges = await _repo.awardBadges(
      totalCompleted: total,
      bestStreak: best,
      categoryCounts: counts,
    );
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
        _showWeeklyPlanInAppNotice(
          doneTotal: afterWeekDone,
          targetTotal: weekTarget,
          completed: true,
        );
      } else if (weekTarget > 0 &&
          beforeWeekDone < weekTarget &&
          afterWeekDone < weekTarget) {
        _showWeeklyPlanInAppNotice(
          doneTotal: afterWeekDone,
          targetTotal: weekTarget,
          completed: false,
        );
      }
    }
    _track('task_completed', {
      'task_id': task.id,
      'category': task.category,
      'duration_min': task.durationMinutes,
      'duration_sec': task.totalDurationSeconds,
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
          _activeTimerPaused = false;
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
        _activeTimerPaused = false;
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
          _activeTimerPaused = false;
        });
        unawaited(NotificationService.instance.cancelTaskTimerOngoing());
        unawaited(NotificationService.instance.cancelTaskTimer(notificationId));
        if (_flowModeEnabled) {
          _activeTimerTicker?.cancel();
          unawaited(_completeFlowTaskAfterTimer(task));
          return;
        }
        unawaited(
          NotificationService.instance.showTaskTimerNotification(
            title: 'Task timer finished',
            body: '${task.title} is ready to mark done.',
          ),
        );
        _track('task_timer_finished', {
          'task_id': task.id,
          'duration_min': task.durationMinutes,
          'duration_sec': task.totalDurationSeconds,
        });
        _track('timer_finished', {
          'task_id': task.id,
          'duration_min': task.durationMinutes,
          'duration_sec': task.totalDurationSeconds,
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
    final total = Duration(seconds: task.totalDurationSeconds);
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
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
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
                              const Color(0xFF8B7CFF).withOpacity(0.07),
                              const Color(0xFF101726),
                            ),
                            Color.alphaBlend(
                              const Color(0xFF5DE1FF).withOpacity(0.035),
                              const Color(0xFF0E1523),
                            ),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.26),
                            blurRadius: 24,
                            spreadRadius: -8,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -40,
                    top: -52,
                    width: 200,
                    height: 200,
                    child: IgnorePointer(
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 18,
                          sigmaY: 18,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0.7, -0.7),
                              radius: 1.0,
                              colors: [
                                const Color(0xFF8B7CFF).withOpacity(0.09),
                                const Color(0xFF5DE1FF).withOpacity(0.03),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.42, 1.0],
                            ),
                          ),
                        ),
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
                                  color: Colors.white.withOpacity(0.95),
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
                            color: scheme.onSurfaceVariant.withOpacity(0.76),
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
                                    0.66,
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
    final adaptivePlan = await _controller.resolveAdaptiveDailyPlan(days: 7);
    final adaptiveCount = adaptivePlan.taskCount.clamp(2, 5);
    // Avoid repeating tasks from earlier refreshes for the first 2 refreshes.
    final avoidIds = (lastSeenDate == dateKey && refreshCount < 2)
        ? lastSeenIds.toSet()
        : <String>{};
    _log(" REFRESH: Current task IDs = $currentIds");

    List<Task> availablePool = effectivePool
        .where((t) => !currentIds.contains(t.id))
        .where((t) => !avoidIds.contains(t.id))
        .toList();
    if (availablePool.length < adaptiveCount) {
      // Relax filters to avoid empty refresh.
      availablePool = effectivePool
          .where((t) => !avoidIds.contains(t.id))
          .toList();
    }
    if (availablePool.length < adaptiveCount) {
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
      count: min(adaptiveCount, availablePool.length),
      seedKey: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
      weeklyTargets: _weeklyTargets.isEmpty ? null : _weeklyTargets,
      weeklyDone: _weeklyDone.isEmpty ? null : _weeklyDone,
    );
    final adaptiveDelta = adaptivePlan.difficultyDelta;
    final adapted = _controller.applyDifficultyDelta(
      tasks: picked,
      delta: adaptiveDelta,
    );
    if (adaptiveDelta != 0) {
      _track('difficulty_adapted', {
        'source': 'refresh',
        'completion_rate': double.parse(
          adaptivePlan.completionRate.toStringAsFixed(3),
        ),
        'delta': adaptiveDelta,
        'target_task_count': adaptiveCount,
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
    await _prepareStreakRescuePlan();
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
                                                  hintText: context.l10n.tr(
                                                    'Enter your first name',
                                                  ),
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
                                                    return context.l10n.tr(
                                                      'Please enter your name',
                                                    );
                                                  }
                                                  if (text.length < 2) {
                                                    return context.l10n.tr(
                                                      'Name is too short',
                                                    );
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
                                              child: Text(
                                                context.l10n.tr('Cancel'),
                                              ),
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
                                            child: Text(
                                              context.l10n.tr('Done button'),
                                            ),
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
    final tint = widget.emphasized
        ? const Color(0xFF8B7CFF)
        : const Color(0xFF5DE1FF);
    final fg = widget.emphasized
        ? Colors.white.withOpacity(0.96)
        : scheme.onSurface.withOpacity(0.86);
    final borderOpacity = widget.emphasized ? 0.0 : 0.06;
    final grainOpacity = widget.emphasized ? 0.0 : 0.012;
    final glowOpacity = widget.emphasized
        ? (_pressed ? 0.34 : 0.26)
        : (_pressed ? 0.06 : 0.02);

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
              border: borderOpacity > 0
                  ? Border.all(
                      color: tint.withOpacity(borderOpacity),
                      width: 0.9,
                    )
                  : null,
              gradient: widget.emphasized
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF8B7CFF), Color(0xFF5DE1FF)],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [Color(0xFF101726), Color(0xFF101726)],
                    ),
              boxShadow: [
                BoxShadow(
                  color: tint.withOpacity(glowOpacity),
                  blurRadius: widget.emphasized ? 18 + (_pressed ? 4 : 0) : 8,
                  spreadRadius: widget.emphasized
                      ? -7 + (_pressed ? 1 : 0)
                      : -9,
                  offset: const Offset(0, 7),
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
                                widget.emphasized ? 0.08 : 0.02,
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
                          widget.emphasized ? 0.04 : 0.03,
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
                              Colors.white.withOpacity(
                                widget.emphasized ? 0.02 : 0.03,
                              ),
                              Colors.transparent,
                              Colors.black.withOpacity(
                                widget.emphasized ? 0.02 : 0.03,
                              ),
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
    required this.unlockedFeature,
    required this.onClose,
  });

  final int previousLevel;
  final int newLevel;
  final String levelTitle;
  final int totalXp;
  final int xpInLevel;
  final int xpToNextLevel;
  final String? unlockedFeature;
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
            if (unlockedFeature != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: scheme.primary.withOpacity(0.1),
                  border: Border.all(color: scheme.primary.withOpacity(0.28)),
                ),
                child: Text(
                  'Unlocked: $unlockedFeature',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
  const _AllDoneOverlay({
    required this.scheme,
    required this.onViewStats,
    this.nextBestSuggestion,
    this.onStartNextBestSpark,
  });

  final ColorScheme scheme;
  final VoidCallback onViewStats;
  final _NextBestSparkSuggestion? nextBestSuggestion;
  final Future<void> Function()? onStartNextBestSpark;

  @override
  Widget build(BuildContext context) {
    return _AllDoneOverlayBody(
      scheme: scheme,
      onViewStats: onViewStats,
      nextBestSuggestion: nextBestSuggestion,
      onStartNextBestSpark: onStartNextBestSpark,
    );
  }
}

class _AllDoneOverlayBody extends StatefulWidget {
  const _AllDoneOverlayBody({
    required this.scheme,
    required this.onViewStats,
    this.nextBestSuggestion,
    this.onStartNextBestSpark,
  });

  final ColorScheme scheme;
  final VoidCallback onViewStats;
  final _NextBestSparkSuggestion? nextBestSuggestion;
  final Future<void> Function()? onStartNextBestSpark;

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
  bool _startingNextBest = false;

  Future<void> _handleStartNextBestSpark() async {
    final action = widget.onStartNextBestSpark;
    if (action == null || _startingNextBest) return;
    setState(() => _startingNextBest = true);
    await action();
    if (!mounted) return;
    setState(() => _startingNextBest = false);
  }

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
                  if (widget.nextBestSuggestion != null) ...[
                    const SizedBox(height: 12),
                    _NextBestSparkCard(
                      suggestion: widget.nextBestSuggestion!,
                      onStart: _handleStartNextBestSpark,
                      busy: _startingNextBest,
                    ),
                  ],
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

class _NextBestSparkSuggestion {
  const _NextBestSparkSuggestion({required this.task, required this.reason});

  final Task task;
  final String reason;
}

class _NextBestSparkCard extends StatelessWidget {
  const _NextBestSparkCard({
    required this.suggestion,
    required this.onStart,
    required this.busy,
  });

  final _NextBestSparkSuggestion suggestion;
  final VoidCallback onStart;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final durationSec = suggestion.task.totalDurationSeconds;
    final durationLabel = durationSec >= 60
        ? '${(durationSec / 60).ceil()} min'
        : '$durationSec sec';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surface.withOpacity(0.88),
        border: Border.all(color: scheme.outline.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withOpacity(0.14),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Next best spark',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                durationLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            suggestion.task.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            suggestion.reason,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onStart,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(busy ? 'Starting...' : 'Add & Start'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _InAppNudgeAction {
  startQuickTask,
  completeFinishedTimer,
  openWeeklyPlan,
  openMorningIntention,
  openEveningReview,
  openWeeklyClosing,
}

class _InAppNudge {
  const _InAppNudge({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.action,
  });

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final _InAppNudgeAction action;
}

class _InAppNudgeCard extends StatelessWidget {
  const _InAppNudgeCard({
    required this.nudge,
    required this.onAction,
    required this.onDismiss,
  });

  final _InAppNudge nudge;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surface.withOpacity(0.82),
        border: Border.all(color: scheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: scheme.primary.withOpacity(0.14),
            ),
            child: Icon(nudge.icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nudge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nudge.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(nudge.ctaLabel),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant.withOpacity(0.82),
            ),
          ),
        ],
      ),
    );
  }
}
