class Task {
  final String id;
  final String title;
  final String category; // mind, body, growth, calm, health
  final bool isCustom;
  final String difficulty; // easy, medium, hard
  final int durationMinutes;
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
    this.aiSuggested = false,
    this.premiumOnly = false,
    this.isSpecial = false,
  });

  factory Task.fromMap(Map<String, dynamic> m) => Task(
    id: m['id'] as String,
    title: m['title'] as String,
    category: m['category'] as String,
    isCustom: (m['isCustom'] as bool?) ?? false,
    difficulty: _normalizeDifficulty(m['difficulty'] as String?),
    durationMinutes: _normalizeDuration(
      _normalizeDifficulty(m['difficulty'] as String?),
      (m['durationMinutes'] as num?)?.toInt(),
    ),
    aiSuggested: (m['aiSuggested'] as bool?) ?? false,
    premiumOnly: (m['premiumOnly'] as bool?) ?? false,
    isSpecial: (m['isSpecial'] as bool?) ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'category': category,
    'isCustom': isCustom,
    'difficulty': difficulty,
    'durationMinutes': durationMinutes,
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

int _normalizeDuration(String difficulty, int? raw) {
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
