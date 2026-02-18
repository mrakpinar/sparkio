import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'home_header_card.dart';

class HomeHeaderSliver extends StatelessWidget {
  const HomeHeaderSliver({
    super.key,
    required this.userName,
    required this.progress,
    required this.doneCount,
    required this.totalCount,
    required this.todayCompleted,
    required this.streak,
    required this.focusLabel,
    required this.dateLabel,
    required this.onShare,
    required this.onOpenStats,
    required this.adaptiveLabel,
    required this.weeklyDone,
    required this.weeklyTarget,
    required this.onOpenWeeklyPlan,
  });

  final String userName;
  final double progress;
  final int doneCount;
  final int totalCount;
  final int todayCompleted;
  final int streak;
  final String focusLabel;
  final String dateLabel;
  final VoidCallback onShare;
  final VoidCallback onOpenStats;
  final String adaptiveLabel;
  final int weeklyDone;
  final int weeklyTarget;
  final VoidCallback onOpenWeeklyPlan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IgnorePointer(
            child: SizedBox(
              height: 12,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          scheme.background.withOpacity(0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          HomeHeaderCard(
            userName: userName,
            progress: progress,
            doneCount: doneCount,
            totalCount: totalCount,
            todayCompleted: todayCompleted,
            streak: streak,
            focusLabel: focusLabel,
            dateLabel: dateLabel,
            onShare: onShare,
            onOpenStats: onOpenStats,
            adaptiveLabel: adaptiveLabel,
            weeklyDone: weeklyDone,
            weeklyTarget: weeklyTarget,
            onOpenWeeklyPlan: onOpenWeeklyPlan,
          ),
        ],
      ),
    );
  }
}
