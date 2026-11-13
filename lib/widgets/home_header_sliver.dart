import 'package:flutter/material.dart';

import 'home_header_card.dart';
import 'home_card_entrance.dart';

class HomeHeaderSliver extends StatelessWidget {
  const HomeHeaderSliver({
    super.key,
    required this.doneCount,
    required this.totalCount,
    required this.streakCount,
    required this.weeklyDoneCount,
    required this.weeklyTotalCount,
    this.dayKey = '',
    this.dailyCompletions = const {},
    this.celebration = 0,
    this.level = 1,
    this.xpInLevel = 0,
    this.xpToNextLevel = 0,
    this.syncedProgress,
    required this.onShare,
    required this.onOpenWeekly,
    required this.onStartFirstSpark,
    required this.hasPendingSpark,
    required this.showAction,
  });

  final int doneCount;
  final int totalCount;
  final int streakCount;
  final int weeklyDoneCount;
  final int weeklyTotalCount;
  final String dayKey;
  final Map<String, int> dailyCompletions;
  final int celebration;
  final int level;
  final int xpInLevel;
  final int xpToNextLevel;
  final double? syncedProgress;
  final VoidCallback onShare;
  final VoidCallback onOpenWeekly;
  final VoidCallback? onStartFirstSpark;
  final bool hasPendingSpark;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: HomeCardEntrance(
        child: HomeHeaderCard(
          doneCount: doneCount,
          totalCount: totalCount,
          streakCount: streakCount,
          weeklyDoneCount: weeklyDoneCount,
          weeklyTotalCount: weeklyTotalCount,
          dayKey: dayKey,
          dailyCompletions: dailyCompletions,
          celebration: celebration,
          level: level,
          xpInLevel: xpInLevel,
          xpToNextLevel: xpToNextLevel,
          syncedProgress: syncedProgress,
          onShare: onShare,
          onOpenWeekly: onOpenWeekly,
          onStartFirstSpark: onStartFirstSpark,
          hasPendingSpark: hasPendingSpark,
          showAction: showAction,
        ),
      ),
    );
  }
}
