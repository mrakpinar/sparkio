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
    final scheme = Theme.of(context).colorScheme;
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
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: scheme.onSurface,
                side: BorderSide(color: scheme.outline.withOpacity(0.28)),
                backgroundColor: scheme.surface.withOpacity(0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onOpenDailyMood,
              icon: const Icon(Icons.psychology_rounded),
              label: const Text('Open daily mood sheet (debug)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: scheme.onSurface,
                side: BorderSide(color: scheme.outline.withOpacity(0.28)),
                backgroundColor: scheme.surface.withOpacity(0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: scheme.surface.withOpacity(0.55),
                border: Border.all(color: scheme.outline.withOpacity(0.24)),
              ),
              child: SwitchListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                value: instantEnabled,
                onChanged: onToggleInstant,
                title: const Text('Instant-complete tasks (debug only)'),
                subtitle: const Text('Skips timer when you tap a task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
