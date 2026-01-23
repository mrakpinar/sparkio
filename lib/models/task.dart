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
    difficulty: (m['difficulty'] as String?) ?? 'easy',
    durationMinutes: (m['durationMinutes'] as num?)?.toInt() ?? 5,
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
