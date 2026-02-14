import 'package:flutter/material.dart';

class HomeDebugTimerSliver extends StatelessWidget {
  const HomeDebugTimerSliver({
    super.key,
    required this.onPressed,
    required this.onOpenDailyMood,
    required this.instantEnabled,
    required this.onToggleInstant,
  });

  final VoidCallback onPressed;
  final VoidCallback onOpenDailyMood;
  final bool instantEnabled;
  final ValueChanged<bool> onToggleInstant;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.timer_rounded),
              label: const Text('Test task timer (30s)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onOpenDailyMood,
              icon: const Icon(Icons.psychology_rounded),
              label: const Text('Open daily mood sheet (debug)'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: instantEnabled,
              onChanged: onToggleInstant,
              title: const Text('Instant-complete tasks (debug only)'),
              subtitle: const Text('Skips timer when you tap a task'),
            ),
          ],
        ),
      ),
    );
  }
}
