import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sparkio/app_strings.dart';
import 'package:sparkio/models/focus_session.dart';
import 'package:sparkio/models/task.dart';
import 'package:sparkio/services/notification_service.dart';
import 'package:sparkio/services/task_localizer.dart';
import 'package:sparkio/services/task_repository.dart';

class FocusScreen extends StatefulWidget {
  final Task task;

  const FocusScreen({
    super.key,
    required this.task,
    this.audioPlayer,
    this.notifications,
    this.now,
    this.sessionDateKey,
  });

  final AudioPlayer? audioPlayer;
  final NotificationService? notifications;
  final DateTime Function()? now;
  final String? sessionDateKey;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  late final NotificationService _notifications;
  final TaskRepository _repo = TaskRepository();
  late final String _sessionDateKey;
  bool _loading = true;
  bool _exitPromptOpen = false;
  bool _sessionCompleted = false;
  Future<void> _sessionWrite = Future<void>.value();
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isPlaying = true;
  String? _activeTrack;
  DateTime? _endAt;
  bool _exiting = false;
  int? _lastOngoingNotificationSecond;

  // Track configurations
  final Map<String, String> _tracks = {
    'Rain': 'assets/audio/rain.mp3',
    'Cafe': 'assets/audio/cafe.mp3',
    'Ocean': 'assets/audio/ocean.mp3',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = widget.audioPlayer ?? AudioPlayer();
    _notifications = widget.notifications ?? NotificationService.instance;
    _sessionDateKey = widget.sessionDateKey ?? FocusSession.dateKeyFor(_now());
    _totalSeconds = widget.task.totalDurationSeconds > 0
        ? widget.task.totalDurationSeconds
        : 5 * 60; // fallback to 5 minutes
    _remainingSeconds = _totalSeconds;

    unawaited(_restoreSession());
  }

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  Future<void> _restoreSession() async {
    final saved = await _repo.getFocusSession(
      taskId: widget.task.id,
      assignmentId: widget.task.assignmentId,
      dateKey: _sessionDateKey,
    );
    if (!mounted) return;
    if (saved != null) {
      _totalSeconds = saved.totalSeconds;
      _remainingSeconds = saved.remainingAt(_now());
      _isPlaying = !saved.isPaused && _remainingSeconds > 0;
      _activeTrack = _tracks.containsKey(saved.activeTrack)
          ? saved.activeTrack
          : null;
      if (_activeTrack != null) {
        try {
          await _audioPlayer.setAsset(_tracks[_activeTrack]!);
          await _audioPlayer.setLoopMode(LoopMode.one);
        } catch (_) {
          _activeTrack = null;
        }
        if (!mounted) return;
      }
    }
    if (_remainingSeconds == 0) _isPlaying = false;
    _endAt = _isPlaying
        ? saved?.endAt ?? _now().add(Duration(seconds: _remainingSeconds))
        : null;
    // Persist the deadline before starting either the UI or notification timer.
    // A process death must not leave a visible timer with no resumable session.
    final persisted = await _persistSessionSafely();
    if (!mounted) return;
    if (!persisted) {
      _isPlaying = false;
      _endAt = null;
    }
    if (_isPlaying) {
      _startTimer(refreshNotifications: true, endAt: _endAt);
      if (_activeTrack != null) unawaited(_audioPlayer.play());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _persistSession() {
    if (_sessionCompleted) return _sessionWrite;
    final session = FocusSession(
      taskId: widget.task.id,
      assignmentId: widget.task.assignmentId,
      dateKey: _sessionDateKey,
      totalSeconds: _totalSeconds,
      remainingSeconds: _remainingSeconds,
      isPaused: !_isPlaying,
      endAt: _isPlaying ? _endAt : null,
      activeTrack: _activeTrack,
    );
    final write = _sessionWrite.then((_) => _repo.saveFocusSession(session));
    _sessionWrite = write.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return write;
  }

  Future<bool> _persistSessionSafely() async {
    try {
      await _persistSession();
      return true;
    } catch (_) {
      debugPrint('Could not persist focus session.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.tr('Session could not be saved. Please try again.'),
            ),
          ),
        );
      }
      return false;
    }
  }

  String get _localizedTaskTitle {
    final localized = TaskLocalizer.localizeTitle(
      widget.task.title,
      localeCode: Localizations.localeOf(context).languageCode,
      category: widget.task.category,
      taskId: widget.task.id,
    ).trim();
    return localized.isEmpty ? widget.task.title : localized;
  }

  int get _notificationId {
    final hash = widget.task.id.hashCode & 0x7fffffff;
    return 300000 + (hash % 100000);
  }

  Duration get _remaining {
    final endAt = _endAt;
    if (_isPlaying && endAt != null) {
      final remaining = endAt.difference(_now());
      return remaining > Duration.zero ? remaining : Duration.zero;
    }
    return Duration(seconds: _remainingSeconds);
  }

  String get _finishNotificationBody => context.l10n.trf(
    'Timer finished for {task}. Complete the task to record it.',
    {'task': _localizedTaskTitle},
  );

  void _startTimer({required bool refreshNotifications, DateTime? endAt}) {
    if (_remainingSeconds <= 0) {
      unawaited(_handleTimerFinished());
      return;
    }
    _endAt = endAt ?? _now().add(Duration(seconds: _remainingSeconds));
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _syncRemainingFromClock(),
    );
    if (refreshNotifications) {
      unawaited(_refreshScheduledNotifications());
    }
    _syncRemainingFromClock(forceNotificationRefresh: refreshNotifications);
  }

  void _syncRemainingFromClock({bool forceNotificationRefresh = false}) {
    if (!_isPlaying) return;
    final endAt = _endAt;
    if (endAt == null) return;

    final millisLeft = endAt.difference(_now()).inMilliseconds;
    final nextSeconds = (millisLeft <= 0 ? 0 : ((millisLeft + 999) ~/ 1000))
        .clamp(0, _totalSeconds);
    final shouldUpdateState = nextSeconds != _remainingSeconds;
    if (shouldUpdateState && mounted) {
      setState(() {
        _remainingSeconds = nextSeconds;
      });
    } else {
      _remainingSeconds = nextSeconds;
    }

    if (_remainingSeconds <= 0) {
      if (!_exiting) unawaited(_handleTimerFinished());
      return;
    }

    if (_shouldRefreshOngoingNotification(force: forceNotificationRefresh)) {
      unawaited(_showOngoingNotification());
    }
  }

  bool _shouldRefreshOngoingNotification({bool force = false}) {
    if (!_isPlaying || _remainingSeconds <= 0) return false;
    if (force) return true;
    if (_lastOngoingNotificationSecond == _remainingSeconds) return false;
    if (_remainingSeconds <= 60) return true;
    return _remainingSeconds % 5 == 0;
  }

  Future<void> _refreshScheduledNotifications() async {
    if (!_isPlaying || _remainingSeconds <= 0) return;
    try {
      // ignore: avoid_print
      print(
        'NOTI: focus schedule task=${widget.task.id} durationSec=$_remainingSeconds notificationId=$_notificationId',
      );
      await _notifications.scheduleTaskTimer(
        notificationId: _notificationId,
        title: context.l10n.tr('Time is up!'),
        body: _finishNotificationBody,
        duration: _remaining,
      );
    } catch (e) {
      // ignore: avoid_print
      print('NOTI: focus schedule failed task=${widget.task.id} error=$e');
    }
  }

  Future<void> _showOngoingNotification() async {
    if (!_isPlaying || _remainingSeconds <= 0) return;
    try {
      // ignore: avoid_print
      print(
        'NOTI: focus ongoing task=${widget.task.id} remainingSec=$_remainingSeconds',
      );
      await _notifications.showTaskTimerOngoing(
        taskTitle: _localizedTaskTitle,
        remaining: _remaining,
        total: Duration(seconds: _totalSeconds),
      );
      _lastOngoingNotificationSecond = _remainingSeconds;
    } catch (e) {
      // ignore: avoid_print
      print('NOTI: focus ongoing failed task=${widget.task.id} error=$e');
    }
  }

  Future<void> _clearNotifications() async {
    await _notifications.cancelTaskTimer(_notificationId);
    await _notifications.cancelTaskTimerOngoing();
  }

  Future<void> _handleTimerFinished() async {
    _timer?.cancel();
    _endAt = null;
    if (mounted) {
      setState(() {
        _remainingSeconds = 0;
        _isPlaying = false;
      });
    } else {
      _remainingSeconds = 0;
      _isPlaying = false;
    }
    _lastOngoingNotificationSecond = null;
    await _persistSessionSafely();
    await _audioPlayer.stop();
    await _notifications.cancelTaskTimerOngoing();
  }

  Future<void> _requestExit() async {
    if (_loading || _exiting || _exitPromptOpen) return;
    _exitPromptOpen = true;
    final l10n = context.l10n;
    try {
      final leave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          title: Text(l10n.tr('Leave focus session?')),
          content: Text(
            l10n.tr(
              _sessionDateKey != FocusSession.dateKeyFor(_now())
                  ? 'This session belongs to an earlier day. Leaving will not complete the task or carry this session into today.'
                  : _remainingSeconds == 0
                  ? 'Leaving will save the finished timer, but will not complete the task.'
                  : 'Your timer will pause. You can resume this task today.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.tr('Return to session')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.tr('Leave session')),
            ),
          ],
        ),
      );
      if (leave == true && mounted) await _exitFocusSession(false);
    } finally {
      _exitPromptOpen = false;
    }
  }

  Future<void> _exitFocusSession(bool completed) async {
    if (_exiting) return;
    _exiting = true;
    // A previous-day completion cannot be recorded safely by the home screen.
    // Preserve that session just like a normal exit, and return its original day.
    _sessionCompleted =
        completed && _sessionDateKey == FocusSession.dateKeyFor(_now());
    _syncRemainingFromClock();
    _timer?.cancel();
    _isPlaying = false;
    _endAt = null;
    _lastOngoingNotificationSecond = null;
    try {
      if (_sessionCompleted) {
        await _sessionWrite;
        await _repo.clearFocusSession(
          taskId: widget.task.id,
          assignmentId: widget.task.assignmentId,
          dateKey: _sessionDateKey,
        );
      } else {
        await _persistSession();
      }
    } catch (_) {
      _exiting = false;
      _sessionCompleted = false;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.tr('Session could not be saved. Please try again.'),
            ),
          ),
        );
      }
      return;
    }
    await _audioPlayer.stop();
    await _clearNotifications();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(FocusSessionResult(
      dateKey: _sessionDateKey,
      assignmentId: widget.task.assignmentId,
      completed: completed,
    ));
  }

  Future<void> _toggleTimer() async {
    if (_exiting) return;
    if (_isPlaying) {
      _syncRemainingFromClock();
      _timer?.cancel();
      _endAt = null;
      _audioPlayer.pause();
      _isPlaying = false;
      await _persistSessionSafely();
      await _clearNotifications();
    } else {
      _isPlaying = true;
      _endAt = _now().add(Duration(seconds: _remainingSeconds));
      final persisted = await _persistSessionSafely();
      if (!mounted) return;
      if (persisted) {
        _startTimer(refreshNotifications: true, endAt: _endAt);
        if (_activeTrack != null) _audioPlayer.play();
      } else {
        _isPlaying = false;
        _endAt = null;
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _playTrack(String name, String url) async {
    if (_exiting) return;
    try {
      if (_activeTrack == name) {
        // Toggle off if same
        await _audioPlayer.stop();
        setState(() => _activeTrack = null);
        await _persistSessionSafely();
        return;
      }

      setState(() => _activeTrack = name);
      await _audioPlayer.setAsset(url);
      await _audioPlayer.setLoopMode(LoopMode.one); // Loop ambient endlessly
      await _persistSessionSafely();
      if (_isPlaying) {
        _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.tr(
                'Ambient sound could not be played. Please try again.',
              ),
            ),
          ),
        );
        setState(() => _activeTrack = null);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_loading || _exiting) return;
    if (state == AppLifecycleState.resumed) {
      _syncRemainingFromClock(forceNotificationRefresh: true);
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _syncRemainingFromClock();
      unawaited(_persistSessionSafely());
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isDone = _remainingSeconds == 0;
    final progress = 1 - (_remainingSeconds / _totalSeconds);

    return WillPopScope(
      onWillPop: () async {
        await _requestExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.alphaBlend(
                  scheme.primary.withOpacity(0.06),
                  scheme.surface,
                ),
                theme.scaffoldBackgroundColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 360
                    ? 16.0
                    : 24.0;
                final contentWidth =
                    (constraints.maxWidth - horizontalPadding * 2)
                        .clamp(0.0, 560.0)
                        .toDouble();
                final timerDiameter = (constraints.maxHeight * 0.32)
                    .clamp(112.0, 280.0)
                    .clamp(0.0, contentWidth)
                    .toDouble();
                final sectionSpacing = (constraints.maxHeight * 0.03)
                    .clamp(12.0, 24.0)
                    .toDouble();

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 560,
                        minHeight: (constraints.maxHeight - 32)
                            .clamp(0.0, double.infinity)
                            .toDouble(),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: sectionSpacing),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      constraints: const BoxConstraints(
                                        minWidth: 48,
                                        minHeight: 48,
                                      ),
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                      tooltip: l10n.tr('Leave session'),
                                      onPressed: () =>
                                          unawaited(_requestExit()),
                                    ),
                                    Expanded(
                                      child: Text(
                                        l10n.categoryBadgeLabel(
                                          widget.task.category,
                                        ),
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.6,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 48),
                                  ],
                                ),
                                SizedBox(height: sectionSpacing / 2),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    _localizedTaskTitle,
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: scheme.onSurface,
                                          fontWeight: FontWeight.w800,
                                          height: 1.25,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: sectionSpacing),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: SizedBox.square(
                                    dimension: timerDiameter,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned.fill(
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: CircularProgressIndicator(
                                              value: progress.clamp(0.0, 1.0),
                                              strokeWidth: 8,
                                              backgroundColor: scheme.outline
                                                  .withOpacity(0.35),
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    scheme.primary,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              _formatTime(_remainingSeconds),
                                              style: theme
                                                  .textTheme
                                                  .displayLarge
                                                  ?.copyWith(
                                                    color: scheme.onSurface,
                                                    fontSize: 64,
                                                    fontWeight: FontWeight.w300,
                                                    fontFeatures: const [
                                                      FontFeature.tabularFigures(),
                                                    ],
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: sectionSpacing),
                                Row(
                                  children: [
                                    if (!isDone) ...[
                                      FloatingActionButton(
                                        heroTag: 'focus_toggle',
                                        backgroundColor: scheme.onSurface,
                                        foregroundColor: scheme.surface,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        onPressed: () =>
                                            unawaited(_toggleTimer()),
                                        tooltip: l10n.tr(
                                          _isPlaying
                                              ? 'Pause timer'
                                              : 'Resume timer',
                                        ),
                                        child: Icon(
                                          _isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDone
                                              ? scheme.onSurface
                                              : scheme.surface,
                                          foregroundColor: isDone
                                              ? scheme.surface
                                              : scheme.onSurface,
                                          elevation: 0,
                                          minimumSize: const Size(48, 56),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          side: isDone
                                              ? BorderSide.none
                                              : BorderSide(
                                                  color: scheme.outline,
                                                ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        onPressed: () =>
                                            unawaited(_exitFocusSession(true)),
                                        child: Text(
                                          l10n.tr(
                                            isDone
                                                ? 'Complete task'
                                                : 'Finish early',
                                          ),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                l10n.tr('Ambient Sound'),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: sectionSpacing / 2),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: _tracks.entries.map((entry) {
                                  final isActive = _activeTrack == entry.key;
                                  return ActionChip(
                                    label: Text(l10n.tr(entry.key)),
                                    labelStyle: TextStyle(
                                      color: isActive
                                          ? scheme.onPrimaryContainer
                                          : scheme.onSurfaceVariant,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                    backgroundColor: isActive
                                        ? scheme.primaryContainer
                                        : scheme.surfaceVariant,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.padded,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: BorderSide(
                                      color: isActive
                                          ? scheme.primary
                                          : scheme.outline,
                                    ),
                                    onPressed: () =>
                                        _playTrack(entry.key, entry.value),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
