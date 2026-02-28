enum InsightUnlockModule { personalInsights }

class LevelUnlocks {
  LevelUnlocks._();

  static const int creatorPacksBaseLevel = 2;
  static const int themeSwitcherLevel = 3;
  static const int personalInsightsLevel = 4;

  static bool canUseCreatorPacks(int level) => level >= creatorPacksBaseLevel;

  static bool canUseThemeSwitcher(int level) => level >= themeSwitcherLevel;

  static bool canUseInsightModule({
    required int level,
    required InsightUnlockModule module,
  }) {
    switch (module) {
      case InsightUnlockModule.personalInsights:
        return level >= personalInsightsLevel;
    }
  }

  static String unlockedAtLabel({
    required int level,
    required String featureName,
  }) {
    return '$featureName unlocks at Level $level';
  }

  static String? unlockForLevel(int level) {
    switch (level) {
      case creatorPacksBaseLevel:
        return 'Creator Pack Marketplace';
      case themeSwitcherLevel:
        return 'Theme Switcher';
      case personalInsightsLevel:
        return 'Personal Insights';
      default:
        return null;
    }
  }

  static String nextUnlockLabel(int currentLevel) {
    final checks = <(int, String)>[
      (creatorPacksBaseLevel, 'Creator Pack Marketplace'),
      (themeSwitcherLevel, 'Theme Switcher'),
      (personalInsightsLevel, 'Personal Insights'),
    ];
    for (final item in checks) {
      if (currentLevel < item.$1) {
        return 'Level ${item.$1} unlocks ${item.$2}';
      }
    }
    return 'All core unlocks active';
  }
}
