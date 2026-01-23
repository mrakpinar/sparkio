import 'package:flutter/material.dart';

class HomeActionBar extends StatelessWidget {
  const HomeActionBar({
    super.key,
    required this.onAddTask,
    required this.onUnlockPerks,
  });

  final VoidCallback onAddTask;
  final VoidCallback onUnlockPerks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAddTask,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add task'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onUnlockPerks,
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Unlock perks'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
