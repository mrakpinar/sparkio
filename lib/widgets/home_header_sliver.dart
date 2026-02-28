import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'home_header_card.dart';

class HomeHeaderSliver extends StatelessWidget {
  const HomeHeaderSliver({
    super.key,
    required this.doneCount,
    required this.totalCount,
    required this.streakCount,
    required this.weeklyDoneCount,
    required this.weeklyTotalCount,
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
  final double? syncedProgress;
  final VoidCallback onShare;
  final VoidCallback onOpenWeekly;
  final VoidCallback? onStartFirstSpark;
  final bool hasPendingSpark;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IgnorePointer(
            child: SizedBox(
              height: 4,
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
            doneCount: doneCount,
            totalCount: totalCount,
            streakCount: streakCount,
            weeklyDoneCount: weeklyDoneCount,
            weeklyTotalCount: weeklyTotalCount,
            syncedProgress: syncedProgress,
            onShare: onShare,
            onOpenWeekly: onOpenWeekly,
            onStartFirstSpark: onStartFirstSpark,
            hasPendingSpark: hasPendingSpark,
            showAction: showAction,
          ),
        ],
      ),
    );
  }
}
