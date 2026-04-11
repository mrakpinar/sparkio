import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sparkio/models/task.dart';

class FocusScreen extends StatefulWidget {
  final Task task;

  const FocusScreen({super.key, required this.task});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isPlaying = true;
  String? _activeTrack;

  // Track configurations
  final Map<String, String> _tracks = {
    'Rain': 'assets/audio/rain.mp3',
    'Cafe': 'assets/audio/cafe.mp3',
    'Ocean': 'assets/audio/ocean.mp3',
  };

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _totalSeconds = widget.task.totalDurationSeconds > 0
        ? widget.task.totalDurationSeconds
        : 5 * 60; // fallback to 5 minutes
    _remainingSeconds = _totalSeconds;

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _audioPlayer.stop();
      }
    });
  }

  void _toggleTimer() {
    if (_isPlaying) {
      _timer?.cancel();
      _audioPlayer.pause();
    } else {
      _startTimer();
      if (_activeTrack != null) _audioPlayer.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
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
      debugPrint('Error playing audio: \$e');
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
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F141E), // Deep elegant dark
      body: Stack(
        children: [
          // Subtle gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF0F141E), const Color(0xFF1B2332)],
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
                        onPressed: () => Navigator.of(context).pop(false),
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
                          value: progress,
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
                        child: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: _toggleTimer,
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
                      onPressed: () {
                        // Mark successful and pop
                        Navigator.of(context).pop(true);
                      },
                      child: Text(
                        isDone ? "Done" : "Finish Early",
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
                        "Ambient Sound",
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
                                color: isActive ? Colors.black : Colors.white70,
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
    );
  }
}
