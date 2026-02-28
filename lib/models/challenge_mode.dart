import '../app_strings.dart';
import '../services/locale_service.dart';

String _challengeLanguageCode([String? languageCode]) {
  return (languageCode ?? LocaleService.instance.effectiveLanguageCode)
      .toLowerCase();
}

class ChallengeTemplate {
  const ChallengeTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    this.dailyGoal = 1,
    this.themeKey = 'general',
  });

  final String id;
  final String title;
  final String description;
  final int durationDays;
  final int dailyGoal;
  final String themeKey;

  String localizedTitle([String? languageCode]) {
    return AppLocalizations.lookup(
      _challengeLanguageCode(languageCode),
      title,
    );
  }

  String localizedDescription([String? languageCode]) {
    return AppLocalizations.lookup(
      _challengeLanguageCode(languageCode),
      description,
    );
  }
}

const List<ChallengeTemplate> kChallengeTemplates = <ChallengeTemplate>[
  ChallengeTemplate(
    id: 'challenge_focus_reset_7',
    title: 'Focus Reset',
    description: 'Run one distraction-free spark each day to regain focus.',
    durationDays: 7,
    dailyGoal: 1,
    themeKey: 'focus',
  ),
  ChallengeTemplate(
    id: 'challenge_sleep_week_7',
    title: 'Sleep Week',
    description: 'Close each day with one short sleep-friendly spark.',
    durationDays: 7,
    dailyGoal: 1,
    themeKey: 'sleep',
  ),
  ChallengeTemplate(
    id: 'challenge_stress_offload_7',
    title: 'Stress Offload',
    description: 'Use one daily spark to downshift stress and reset calmly.',
    durationDays: 7,
    dailyGoal: 1,
    themeKey: 'stress',
  ),
  ChallengeTemplate(
    id: 'challenge_reset_7',
    title: '7-Day Reset',
    description: 'Do at least one spark every day for 7 days.',
    durationDays: 7,
    dailyGoal: 1,
    themeKey: 'classic',
  ),
  ChallengeTemplate(
    id: 'challenge_momentum_14',
    title: '14-Day Momentum',
    description: 'Build consistency with one daily spark for 14 days.',
    durationDays: 14,
    dailyGoal: 1,
    themeKey: 'classic',
  ),
];

class ChallengeShortContent {
  const ChallengeShortContent({
    required this.id,
    required this.challengeTemplateId,
    required this.title,
    required this.hook,
    required this.shotList,
    required this.caption,
    required this.hashtags,
  });

  final String id;
  final String challengeTemplateId;
  final String title;
  final String hook;
  final List<String> shotList;
  final String caption;
  final List<String> hashtags;

  String localizedTitle([String? languageCode]) {
    return AppLocalizations.lookup(
      _challengeLanguageCode(languageCode),
      title,
    );
  }

  String localizedHook([String? languageCode]) {
    return AppLocalizations.lookup(
      _challengeLanguageCode(languageCode),
      hook,
    );
  }

  List<String> localizedShotList([String? languageCode]) {
    final code = _challengeLanguageCode(languageCode);
    return shotList
        .map((item) => AppLocalizations.lookup(code, item))
        .toList(growable: false);
  }

  String localizedCaption([String? languageCode]) {
    return AppLocalizations.lookup(
      _challengeLanguageCode(languageCode),
      caption,
    );
  }

  List<String> localizedHashtags([String? languageCode]) => hashtags;
}

const List<ChallengeShortContent>
kChallengeShortContents = <ChallengeShortContent>[
  ChallengeShortContent(
    id: 'short_focus_reset_1',
    challengeTemplateId: 'challenge_focus_reset_7',
    title: 'Focus Reset: Start clean',
    hook: 'If your focus feels scattered, do this one reset spark.',
    shotList: <String>[
      'Show noisy/chaotic work setup for 1 second.',
      'Open Sparkio Focus Reset and start timer.',
      'Show done state and one clear next task.',
    ],
    caption: 'One focused spark > waiting for motivation.',
    hashtags: <String>['#sparkio', '#focusreset', '#deepwork', '#microhabits'],
  ),
  ChallengeShortContent(
    id: 'short_sleep_week_1',
    challengeTemplateId: 'challenge_sleep_week_7',
    title: 'Sleep Week: Wind-down',
    hook: 'Tonight plan: one tiny spark before sleep.',
    shotList: <String>[
      'Show evening screen time moment.',
      'Start a calm/sleep spark in app.',
      'Show done state with low-light vibe.',
    ],
    caption: 'Protect your nights with tiny routines.',
    hashtags: <String>['#sparkio', '#sleepweek', '#sleepbetter', '#nightreset'],
  ),
  ChallengeShortContent(
    id: 'short_stress_offload_1',
    challengeTemplateId: 'challenge_stress_offload_7',
    title: 'Stress Offload: 2-minute reset',
    hook: 'Overloaded? Try this 2-minute offload spark.',
    shotList: <String>[
      'Show stressed moment / busy desk.',
      'Start breathing or body reset spark.',
      'Show calmer post-task state.',
    ],
    caption: 'No guilt, no pressure. Reset and continue.',
    hashtags: <String>[
      '#sparkio',
      '#stressoffload',
      '#calmreset',
      '#mentalfitness',
    ],
  ),
  ChallengeShortContent(
    id: 'short_reset_hook_1',
    challengeTemplateId: 'challenge_reset_7',
    title: '7-Day Reset: Day 1',
    hook: 'If your routine is broken, start with 60 seconds.',
    shotList: <String>[
      'Show your task card and timer (0:00).',
      'Do one tiny spark (walking, breathing, water).',
      'Show completion screen: You showed up today.',
    ],
    caption: 'Day 1/7 complete. Tiny actions still count.',
    hashtags: <String>[
      '#sparkio',
      '#7dayreset',
      '#microhabits',
      '#consistency',
    ],
  ),
  ChallengeShortContent(
    id: 'short_reset_hook_2',
    challengeTemplateId: 'challenge_reset_7',
    title: 'No Motivation Needed',
    hook: 'You do not need motivation. You need one tiny action.',
    shotList: <String>[
      'Record before: low-energy moment.',
      'Start a 60s spark from Sparkio.',
      'Record after: done state + streak/progress.',
    ],
    caption: 'One spark is enough to restart momentum.',
    hashtags: <String>[
      '#sparkio',
      '#habitbuilding',
      '#mentalfitness',
      '#showup',
    ],
  ),
  ChallengeShortContent(
    id: 'short_momentum_hook_1',
    challengeTemplateId: 'challenge_momentum_14',
    title: '14-Day Momentum: Midweek',
    hook: 'Day 6 and still going. Keep it simple.',
    shotList: <String>[
      'Show weekly progress bar.',
      'Complete a 2-5 minute spark.',
      'Close with challenge day count update.',
    ],
    caption: 'Progress, not pressure. Day by day.',
    hashtags: <String>[
      '#sparkio',
      '#14daychallenge',
      '#selfimprovement',
      '#buildinpublic',
    ],
  ),
  ChallengeShortContent(
    id: 'short_momentum_hook_2',
    challengeTemplateId: 'challenge_momentum_14',
    title: 'Reset After Missed Day',
    hook: 'Missed yesterday? Here is your 2-minute comeback.',
    shotList: <String>[
      'Show the app and pick one easy spark.',
      'Run timer and finish task.',
      'Show updated weekly plan progress.',
    ],
    caption: 'No guilt loop. Just reset and continue.',
    hashtags: <String>['#sparkio', '#comeback', '#routine', '#recoverymindset'],
  ),
];

List<ChallengeShortContent> shortContentsForChallenge(
  String challengeTemplateId,
) {
  final filtered = kChallengeShortContents
      .where((item) => item.challengeTemplateId == challengeTemplateId)
      .toList(growable: false);
  if (filtered.isNotEmpty) return filtered;
  return kChallengeShortContents
      .where((item) => item.challengeTemplateId == kChallengeTemplates.first.id)
      .toList(growable: false);
}

ChallengeTemplate challengeTemplateById(String id) {
  return challengeTemplateByIdOrNull(id) ?? kChallengeTemplates.first;
}

ChallengeTemplate? challengeTemplateByIdOrNull(String id) {
  for (final template in kChallengeTemplates) {
    if (template.id == id) return template;
  }
  return null;
}

class ActiveChallenge {
  const ActiveChallenge({
    required this.templateId,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.dailyGoal,
    required this.startDateKey,
    required this.completedDateKeys,
    this.completionNotified = false,
  });

  final String templateId;
  final String title;
  final String description;
  final int durationDays;
  final int dailyGoal;
  final String startDateKey;
  final List<String> completedDateKeys;
  final bool completionNotified;

  ChallengeTemplate? get template => challengeTemplateByIdOrNull(templateId);

  String localizedTitle([String? languageCode]) {
    final source = template?.title ?? title;
    return AppLocalizations.lookup(_challengeLanguageCode(languageCode), source);
  }

  String localizedDescription([String? languageCode]) {
    final source = template?.description ?? description;
    return AppLocalizations.lookup(_challengeLanguageCode(languageCode), source);
  }

  factory ActiveChallenge.fromTemplate({
    required ChallengeTemplate template,
    required String startDateKey,
    List<String> completedDateKeys = const <String>[],
  }) {
    return ActiveChallenge(
      templateId: template.id,
      title: template.title,
      description: template.description,
      durationDays: template.durationDays,
      dailyGoal: template.dailyGoal,
      startDateKey: startDateKey,
      completedDateKeys: completedDateKeys.toSet().toList()..sort(),
      completionNotified: false,
    );
  }

  factory ActiveChallenge.fromMap(Map<String, dynamic> map) {
    final rawCompleted = map['completedDateKeys'];
    final completed = rawCompleted is List
        ? (rawCompleted.map((value) => value.toString()).toSet().toList()
            ..sort())
        : <String>[];
    return ActiveChallenge(
      templateId: (map['templateId'] as String?)?.trim() ?? '',
      title: (map['title'] as String?)?.trim() ?? '',
      description: (map['description'] as String?)?.trim() ?? '',
      durationDays: _safeInt(map['durationDays'], fallback: 7),
      dailyGoal: _safeInt(map['dailyGoal'], fallback: 1),
      startDateKey: (map['startDateKey'] as String?)?.trim() ?? '',
      completedDateKeys: completed,
      completionNotified: map['completionNotified'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'templateId': templateId,
      'title': title,
      'description': description,
      'durationDays': durationDays,
      'dailyGoal': dailyGoal,
      'startDateKey': startDateKey,
      'completedDateKeys': completedDateKeys,
      'completionNotified': completionNotified,
    };
  }

  ActiveChallenge copyWith({
    String? templateId,
    String? title,
    String? description,
    int? durationDays,
    int? dailyGoal,
    String? startDateKey,
    List<String>? completedDateKeys,
    bool? completionNotified,
  }) {
    return ActiveChallenge(
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      description: description ?? this.description,
      durationDays: durationDays ?? this.durationDays,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      startDateKey: startDateKey ?? this.startDateKey,
      completedDateKeys: completedDateKeys ?? this.completedDateKeys,
      completionNotified: completionNotified ?? this.completionNotified,
    );
  }

  int get completedDaysCount => completedDateKeys.length;

  double get progress {
    if (durationDays <= 0) return 0.0;
    return (completedDaysCount / durationDays).clamp(0.0, 1.0);
  }

  bool get isCompleted => completedDaysCount >= durationDays;

  DateTime? get startDate => _parseDateKey(startDateKey);

  DateTime? get endDate {
    final start = startDate;
    if (start == null) return null;
    return start.add(Duration(days: durationDays - 1));
  }

  bool includesDate(String dateKey) {
    final target = _parseDateKey(dateKey);
    final start = startDate;
    final end = endDate;
    if (target == null || start == null || end == null) return false;
    return !target.isBefore(start) && !target.isAfter(end);
  }

  bool hasLoggedDate(String dateKey) => completedDateKeys.contains(dateKey);

  int dayIndexFor(String dateKey) {
    final target = _parseDateKey(dateKey);
    final start = startDate;
    if (target == null || start == null) return 0;
    return target.difference(start).inDays + 1;
  }
}

class ChallengeProgressUpdate {
  const ChallengeProgressUpdate({
    required this.challenge,
    required this.dayLogged,
    required this.completedNow,
  });

  final ActiveChallenge challenge;
  final bool dayLogged;
  final bool completedNow;
}

int _safeInt(dynamic raw, {required int fallback}) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return fallback;
}

DateTime? _parseDateKey(String raw) {
  if (raw.isEmpty) return null;
  final parts = raw.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}
