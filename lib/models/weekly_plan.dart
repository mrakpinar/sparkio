class WeeklyPlan {
  const WeeklyPlan({required this.weekKey, required this.targets});

  final String weekKey; // yyyy-MM-dd of week start (Monday)
  final Map<String, int> targets;

  int get totalTarget =>
      targets.values.fold<int>(0, (sum, value) => sum + value);

  bool get hasTargets => totalTarget > 0;

  Map<String, dynamic> toMap() => {'weekKey': weekKey, 'targets': targets};

  factory WeeklyPlan.fromMap(Map<String, dynamic> map) {
    final rawTargets = (map['targets'] as Map?) ?? const <String, dynamic>{};
    final targets = <String, int>{};
    for (final entry in rawTargets.entries) {
      final value = entry.value;
      final parsed = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
      if (parsed > 0) {
        targets['${entry.key}'] = parsed;
      }
    }
    return WeeklyPlan(weekKey: '${map['weekKey'] ?? ''}', targets: targets);
  }
}

class WeeklyProgress {
  const WeeklyProgress({required this.weekKey, required this.done});

  final String weekKey; // yyyy-MM-dd of week start (Monday)
  final Map<String, int> done;

  int get totalDone => done.values.fold<int>(0, (sum, value) => sum + value);

  Map<String, dynamic> toMap() => {'weekKey': weekKey, 'done': done};

  factory WeeklyProgress.fromMap(Map<String, dynamic> map) {
    final rawDone = (map['done'] as Map?) ?? const <String, dynamic>{};
    final done = <String, int>{};
    for (final entry in rawDone.entries) {
      final value = entry.value;
      final parsed = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
      if (parsed > 0) {
        done['${entry.key}'] = parsed;
      }
    }
    return WeeklyProgress(weekKey: '${map['weekKey'] ?? ''}', done: done);
  }
}
