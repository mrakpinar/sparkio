class FocusSessionResult {
  const FocusSessionResult({
    required this.dateKey,
    required this.completed,
    this.assignmentId,
  });

  final String dateKey;
  final String? assignmentId;

  /// Reports the explicit action. The caller must validate [dateKey] before
  /// granting progress; an earlier-day session cannot be credited today.
  final bool completed;
}

class FocusSession {
  const FocusSession({
    required this.taskId,
    this.assignmentId,
    required this.dateKey,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.isPaused,
    this.endAt,
    this.activeTrack,
  });

  final String taskId;
  final String? assignmentId;
  final String dateKey;
  final int totalSeconds;
  final int remainingSeconds;
  final bool isPaused;
  final DateTime? endAt;
  final String? activeTrack;

  static String dateKeyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  int remainingAt(DateTime now) {
    if (isPaused || endAt == null) return remainingSeconds;
    final millis = endAt!.difference(now).inMilliseconds;
    return (millis <= 0 ? 0 : (millis + 999) ~/ 1000).clamp(0, totalSeconds);
  }

  Map<String, dynamic> toMap() => {
    'taskId': taskId,
    if (assignmentId != null) 'assignmentId': assignmentId,
    'dateKey': dateKey,
    'totalSeconds': totalSeconds,
    'remainingSeconds': remainingSeconds,
    'isPaused': isPaused,
    'endAtMs': endAt?.millisecondsSinceEpoch,
    'activeTrack': activeTrack,
  };

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    final taskId = map['taskId'] as String;
    final dateKey = map['dateKey'] as String;
    final total = map['totalSeconds'] as int;
    final remaining = map['remainingSeconds'] as int;
    final paused = map['isPaused'] as bool;
    final endAtMs = map['endAtMs'] as int?;
    if (taskId.isEmpty ||
        dateKey.isEmpty ||
        total <= 0 ||
        remaining < 0 ||
        remaining > total ||
        (!paused && endAtMs == null)) {
      throw const FormatException('Invalid focus session');
    }
    return FocusSession(
      taskId: taskId,
      assignmentId: (map['assignmentId'] as String?)?.isNotEmpty == true
          ? map['assignmentId'] as String
          : null,
      dateKey: dateKey,
      totalSeconds: total,
      remainingSeconds: remaining,
      isPaused: paused,
      endAt: endAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(endAtMs),
      activeTrack: map['activeTrack'] as String?,
    );
  }

  FocusSession withAssignmentId(String value) => FocusSession(
    taskId: taskId,
    assignmentId: value,
    dateKey: dateKey,
    totalSeconds: totalSeconds,
    remainingSeconds: remainingSeconds,
    isPaused: isPaused,
    endAt: endAt,
    activeTrack: activeTrack,
  );
}
