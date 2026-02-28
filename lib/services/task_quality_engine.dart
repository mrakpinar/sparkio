class TaskTitleQuality {
  const TaskTitleQuality({
    required this.title,
    required this.score,
    required this.usedFallback,
    required this.isValidForCustomInput,
    this.feedback,
  });

  final String title;
  final int score;
  final bool usedFallback;
  final bool isValidForCustomInput;
  final String? feedback;
}

class TaskQualityEngine {
  static const int _minAcceptScore = 55;

  static const Set<String> _placeholderKeys = {
    'seed',
    'task',
    'spark',
    'newtask',
    'test',
    'todo',
    'deneme',
  };

  static const Map<String, String> _explicitMap = {
    'seed': 'Write one tiny intention for today',
    'reset': 'Take 5 slow breaths and reset',
    'focus': 'Write one priority and start for 2 minutes',
    'reflect': 'Write one line about your day',
    'hydrate': 'Drink one full glass of water',
    'pause': 'Pause for 1 minute and breathe',
    'move': 'Stand up and move for 2 minutes',
  };

  static const Set<String> _actionVerbs = {
    'take',
    'write',
    'drink',
    'walk',
    'stretch',
    'focus',
    'breathe',
    'do',
    'plan',
    'clear',
    'close',
    'read',
    'learn',
    'notice',
    'send',
    'tidy',
    'organize',
    'start',
    'name',
    'relax',
    'step',
    'refill',
    'eat',
    'move',
    'pause',
    'journal',
    'yaz',
    'ic',
    'yuru',
    'nefes',
    'esne',
  };

  static const Set<String> _concreteTokens = {
    'breath',
    'water',
    'priority',
    'walk',
    'stretch',
    'glass',
    'minute',
    'minutes',
    'seconds',
    'desk',
    'tabs',
    'message',
    'goal',
    'posture',
    'shoulders',
    'screen',
    'line',
    'idea',
    'intention',
    'focus',
    'bottle',
    'snack',
    'notebook',
  };

  static TaskTitleQuality sanitize({
    required String rawTitle,
    required String category,
    required int durationSeconds,
    bool strictUserInput = false,
  }) {
    final normalizedBase = _normalizeBase(rawTitle);
    final rawWords = normalizedBase
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final rawKey = normalizedBase.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );
    final rawLooksPlaceholder =
        normalizedBase.isEmpty ||
        _placeholderKeys.contains(rawKey) ||
        rawWords.length < 2;
    final categoryKey = _normalizeCategory(category);
    final mapped = _applyExplicitMap(normalizedBase, categoryKey);
    final score = _score(mapped);

    if (strictUserInput && rawLooksPlaceholder) {
      return const TaskTitleQuality(
        title: '',
        score: 0,
        usedFallback: false,
        isValidForCustomInput: false,
        feedback:
            'Task is too vague. Use action + outcome, e.g. "Drink one glass of water".',
      );
    }

    if (strictUserInput && score < _minAcceptScore) {
      return TaskTitleQuality(
        title: mapped,
        score: score,
        usedFallback: false,
        isValidForCustomInput: false,
        feedback:
            'Task is too vague. Use action + outcome, e.g. "Drink one glass of water".',
      );
    }

    if (score >= _minAcceptScore) {
      return TaskTitleQuality(
        title: mapped,
        score: score,
        usedFallback: false,
        isValidForCustomInput: true,
      );
    }

    final fallback = _fallbackTitle(
      category: categoryKey,
      durationSeconds: durationSeconds,
    );
    return TaskTitleQuality(
      title: fallback,
      score: _minAcceptScore,
      usedFallback: true,
      isValidForCustomInput: !strictUserInput,
      feedback: strictUserInput
          ? 'Task is too vague. Add a clear action and outcome.'
          : null,
    );
  }

  static String _normalizeCategory(String raw) {
    final value = raw.toLowerCase().trim();
    switch (value) {
      case 'body':
      case 'growth':
      case 'calm':
      case 'health':
      case 'mind':
        return value;
      default:
        return 'mind';
    }
  }

  static String _normalizeBase(String rawTitle) {
    var value = rawTitle.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (value.isEmpty) return value;
    value = value.replaceFirst(
      RegExp(r'^(ai\s*pick\s*:|task\s*:|spark\s*:)\s*', caseSensitive: false),
      '',
    );
    value = value.replaceAll(RegExp(r'^[\-\u2022>\s]+'), '').trim();
    value = value.replaceAll(RegExp(r'[.!]+$'), '').trim();
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  static String _applyExplicitMap(String title, String category) {
    if (title.isEmpty) {
      return _fallbackTitle(category: category, durationSeconds: 120);
    }
    final key = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    if (_explicitMap.containsKey(key)) return _explicitMap[key]!;
    if (_placeholderKeys.contains(key)) {
      return _fallbackTitle(category: category, durationSeconds: 120);
    }
    return title;
  }

  static int _score(String title) {
    var score = 100;
    final lower = title.toLowerCase().trim();
    final words = lower
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final key = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '');

    if (title.length < 10) score -= 25;
    if (title.length > 100) score -= 15;
    if (words.length < 3) score -= 35;
    if (words.length > 14) score -= 10;
    if (_placeholderKeys.contains(key)) score -= 70;
    if (!_startsWithActionVerb(words)) score -= 20;
    if (!_hasConcreteTarget(words)) score -= 15;

    if (score < 0) return 0;
    if (score > 100) return 100;
    return score;
  }

  static bool _startsWithActionVerb(List<String> words) {
    if (words.isEmpty) return false;
    final first = words.first.replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return _actionVerbs.contains(first);
  }

  static bool _hasConcreteTarget(List<String> words) {
    for (final word in words) {
      final cleaned = word.replaceAll(RegExp(r'[^a-z0-9]+'), '');
      if (_concreteTokens.contains(cleaned)) return true;
      if (RegExp(r'^\d+$').hasMatch(cleaned)) return true;
    }
    return false;
  }

  static String _fallbackTitle({
    required String category,
    required int durationSeconds,
  }) {
    final duration = _durationLabel(durationSeconds);
    switch (category) {
      case 'body':
        return 'Move your body for $duration';
      case 'growth':
        return 'Start one small improvement for $duration';
      case 'calm':
        return 'Breathe slowly for $duration and relax your shoulders';
      case 'health':
        return 'Drink water and reset posture for $duration';
      case 'mind':
      default:
        return 'Write one clear priority and focus for $duration';
    }
  }

  static String _durationLabel(int durationSeconds) {
    final safe = durationSeconds.clamp(1, 360000);
    if (safe < 60) return '$safe seconds';
    if (safe % 60 == 0) {
      final mins = safe ~/ 60;
      final unit = mins == 1 ? 'minute' : 'minutes';
      return '$mins $unit';
    }
    final mins = safe ~/ 60;
    final secs = safe % 60;
    return '$mins min $secs sec';
  }
}
