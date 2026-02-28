import '../services/task_quality_engine.dart';

class Task {
  final String id;
  final String title;
  final String category; // mind, body, growth, calm, health
  final bool isCustom;
  final String difficulty; // easy, medium, hard
  final int durationMinutes;
  final int? durationSeconds;
  final bool aiSuggested;
  final bool premiumOnly;
  final bool isSpecial;

  const Task({
    required this.id,
    required this.title,
    required this.category,
    this.isCustom = false,
    this.difficulty = 'easy',
    this.durationMinutes = 5,
    this.durationSeconds,
    this.aiSuggested = false,
    this.premiumOnly = false,
    this.isSpecial = false,
  });

  int get totalDurationSeconds {
    final raw = durationSeconds ?? (durationMinutes * 60);
    return raw.clamp(1, 360000);
  }

  factory Task.fromMap(Map<String, dynamic> m) {
    final difficulty = _normalizeDifficulty(m['difficulty'] as String?);
    final category = m['category'] as String? ?? 'mind';
    final normalizedSeconds = _normalizeDurationSeconds(
      (m['durationSeconds'] as num?)?.toInt(),
    );
    final normalizedMinutes = _normalizeDuration(
      difficulty,
      (m['durationMinutes'] as num?)?.toInt(),
      durationSeconds: normalizedSeconds,
    );
    final totalSeconds = normalizedSeconds ?? (normalizedMinutes * 60);
    final titleQuality = TaskQualityEngine.sanitize(
      rawTitle: (m['title'] as String?) ?? '',
      category: category,
      durationSeconds: totalSeconds,
    );
    return Task(
      id: m['id'] as String,
      title: titleQuality.title,
      category: category,
      isCustom: (m['isCustom'] as bool?) ?? false,
      difficulty: difficulty,
      durationMinutes: normalizedMinutes,
      durationSeconds: normalizedSeconds,
      aiSuggested: (m['aiSuggested'] as bool?) ?? false,
      premiumOnly: (m['premiumOnly'] as bool?) ?? false,
      isSpecial: (m['isSpecial'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'category': category,
    'isCustom': isCustom,
    'difficulty': difficulty,
    'durationMinutes': durationMinutes,
    'durationSeconds': durationSeconds,
    'aiSuggested': aiSuggested,
    'premiumOnly': premiumOnly,
    'isSpecial': isSpecial,
  };
}

/// Clamp remote task durations to sensible ranges so overly long tasks
/// from Firestore don't degrade UX.
String _normalizeDifficulty(String? raw) {
  final value = (raw ?? 'easy').toLowerCase();
  if (value == 'medium' || value == 'hard' || value == 'easy') return value;
  return 'easy';
}

int _normalizeDuration(String difficulty, int? raw, {int? durationSeconds}) {
  if (durationSeconds != null && durationSeconds > 0) {
    return (durationSeconds / 60).ceil().clamp(1, 120);
  }

  const defaults = {'easy': 5, 'medium': 8, 'hard': 12};
  const mins = {'easy': 3, 'medium': 5, 'hard': 8};
  const maxs = {'easy': 8, 'medium': 12, 'hard': 18};

  final base = defaults[difficulty] ?? 7;
  final value = (raw ?? base).clamp(-9999, 9999);
  final min = mins[difficulty] ?? 4;
  final max = maxs[difficulty] ?? 15;
  // If backend sent 0/negative or absurdly high numbers, fall back to default.
  if (value <= 0) return base;
  return value.clamp(min, max);
}

int? _normalizeDurationSeconds(int? raw) {
  if (raw == null) return null;
  if (raw <= 0) return null;
  return raw.clamp(1, 360000);
}
