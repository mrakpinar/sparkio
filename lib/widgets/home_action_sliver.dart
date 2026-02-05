import 'package:flutter/material.dart';

import 'home_action_bar.dart';

class HomeActionSliver extends StatelessWidget {
  const HomeActionSliver({
    super.key,
    required this.onAddTask,
    required this.onUnlockPerks,
    required this.premiumActive,
    required this.premiumRemaining,
    required this.onStatusTap,
  });

  final VoidCallback onAddTask;
  final VoidCallback onUnlockPerks;
  final bool premiumActive;
  final String premiumRemaining;
  final VoidCallback? onStatusTap;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: HomeActionBar(
        onAddTask: onAddTask,
        onUnlockPerks: onUnlockPerks,
        premiumActive: premiumActive,
        premiumRemaining: premiumRemaining,
        onStatusTap: onStatusTap,
      ),
    );
  }
}
