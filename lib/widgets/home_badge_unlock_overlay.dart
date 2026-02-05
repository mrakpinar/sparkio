import 'package:flutter/material.dart';

class BadgeInfo {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const BadgeInfo({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class HomeBadgeUnlockOverlay extends StatelessWidget {
  const HomeBadgeUnlockOverlay({super.key, required this.info});

  final BadgeInfo info;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [info.color.withOpacity(0.25), scheme.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: scheme.outline.withOpacity(0.7)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: info.color.withOpacity(0.18),
                ),
                child: Icon(info.icon, color: info.color, size: 34),
              ),
              const SizedBox(height: 12),
              Text(
                'Badge unlocked',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                info.label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: info.color,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                info.description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Nice!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
