import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sparkio/models/task.dart';
import 'package:sparkio/services/notification_service.dart';
import 'package:sparkio/services/task_localizer.dart';

class FocusScreen extends StatefulWidget {
  final Task task;

  const FocusScreen({super.key, required this.task});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  final NotificationService _notifications = NotificationService.instance;
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
    _audioPlayer = AudioPlayer();
    _totalSeconds = widget.task.totalDurationSeconds > 0
        ? widget.task.totalDurationSeconds
        : 5 * 60; // fallback to 5 minutes
    _remainingSeconds = _totalSeconds;

    _startTimer(refreshNotifications: true);
  }

  String get _localizedTaskTitle {
    final localized = TaskLocalizer.localizeTitle(
      widget.task.title,
      category: widget.task.category,
      taskId: widget.task.id,
    ).trim();
    return localized.isEmpty ? widget.task.title : localized;
  }

  int get _notificationId {
    final hash = widget.task.id.hashCode & 0x7fffffff;
    return 300000 + (hash % 100000);
  }

  Duration get _remaining => Duration(seconds: _remainingSeconds);

  String get _finishNotificationBody =>
      '$_localizedTaskTitle is complete. Mark it done.';

  void _startTimer({required bool refreshNotifications}) {
    if (_remainingSeconds <= 0) {
      unawaited(_handleTimerFinished());
      return;
    }
    _endAt = DateTime.now().add(Duration(seconds: _remainingSeconds));
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

    final millisLeft = endAt.difference(DateTime.now()).inMilliseconds;
    final nextSeconds = millisLeft <= 0 ? 0 : ((millisLeft + 999) ~/ 1000);
    final shouldUpdateState = nextSeconds != _remainingSeconds;
    if (shouldUpdateState && mounted) {
      setState(() {
        _remainingSeconds = nextSeconds;
      });
    } else {
      _remainingSeconds = nextSeconds;
    }

    if (_remainingSeconds <= 0) {
      unawaited(_handleTimerFinished());
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
        title: 'Time is up',
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
    await _audioPlayer.stop();
    await _notifications.cancelTaskTimerOngoing();
  }

  Future<void> _exitFocusSession(bool completed) async {
    if (_exiting) return;
    _exiting = true;
    _timer?.cancel();
    _endAt = null;
    _lastOngoingNotificationSecond = null;
    await _audioPlayer.stop();
    await _clearNotifications();
    if (!mounted) return;
    Navigator.of(context).pop(completed);
  }

  Future<void> _toggleTimer() async {
    if (_isPlaying) {
      _syncRemainingFromClock();
      _timer?.cancel();
      _endAt = null;
      _audioPlayer.pause();
      _isPlaying = false;
      await _clearNotifications();
    } else {
      _isPlaying = true;
      _startTimer(refreshNotifications: true);
      if (_activeTrack != null) _audioPlayer.play();
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _playTrack(String name, String url) async {
    try {
      if (_activeTrack == name) {
        // Toggle off if same
        await _audioPlayer.stop();
        setState(() => _activeTrack = null);
        return;
      }

      setState(() => _activeTrack = name);
      await _audioPlayer.setAsset(url);
      await _audioPlayer.setLoopMode(LoopMode.one); // Loop ambient endlessly
      if (_isPlaying) {
        _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't load stream. You may need to drop local MP3s!",
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
    if (state == AppLifecycleState.resumed) {
      _syncRemainingFromClock(forceNotificationRefresh: true);
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _remainingSeconds == 0;
    final progress = 1 - (_remainingSeconds / _totalSeconds);

    return WillPopScope(
      onWillPop: () async {
        await _exitFocusSession(false);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F141E), // Deep elegant dark
        body: Stack(
          children: [
            // Subtle gradient background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F141E), Color(0xFF1B2332)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Nav
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                          onPressed: () => unawaited(_exitFocusSession(false)),
                        ),
                        Expanded(
                          child: Text(
                            widget.task.category.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance icon
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Task Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      widget.task.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Giant Timer Layout
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress Ring
                        SizedBox(
                          width: 280,
                          height: 280,
                          child: CircularProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            strokeWidth: 8,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        // Time Text
                        Text(
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.w200,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Play/Pause & Finish Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isDone)
                        FloatingActionButton(
                          heroTag: 'focus_toggle',
                          backgroundColor: Colors.white10,
                          elevation: 0,
                          onPressed: () => unawaited(_toggleTimer()),
                          child: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      if (!isDone) const SizedBox(width: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        onPressed: () => unawaited(_exitFocusSession(true)),
                        child: Text(
                          isDone ? 'Done' : 'Finish Early',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Ambient Sounds
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      children: [
                        const Text(
                          'Ambient Sound',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _tracks.entries.map((entry) {
                            final isActive = _activeTrack == entry.key;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                              ),
                              child: ActionChip(
                                label: Text(entry.key),
                                labelStyle: TextStyle(
                                  color: isActive
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                backgroundColor: isActive
                                    ? Colors.white
                                    : Colors.white10,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                side: BorderSide.none,
                                onPressed: () =>
                                    _playTrack(entry.key, entry.value),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
