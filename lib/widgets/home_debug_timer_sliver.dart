import 'package:flutter/material.dart';

class HomeDebugTimerSliver extends StatelessWidget {
  const HomeDebugTimerSliver({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.timer_rounded),
          label: const Text('Test task timer (30s)'),
        ),
      ),
    );
  }
}
