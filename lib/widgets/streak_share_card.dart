import 'package:flutter/material.dart';

class ShareBadgeChipData {
  const ShareBadgeChipData({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class StreakShareCard extends StatelessWidget {
  const StreakShareCard({
    super.key,
    required this.streak,
    required this.doneCount,
    required this.totalCount,
    required this.dateLabel,
    this.badges = const <ShareBadgeChipData>[],
  });

  final int streak;
  final int doneCount;
  final int totalCount;
  final String dateLabel;
  final List<ShareBadgeChipData> badges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = theme.textTheme.titleLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    );
    final sub = theme.textTheme.bodyMedium?.copyWith(color: Colors.white70);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1A34), Color(0xFF14305A), Color(0xFF1B88A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Main glow blob - slightly larger and more visible
          Positioned(
            right: -50,
            top: -40,
            child: _GlowBlob(size: 200, color: Colors.white.withOpacity(0.16)),
          ),
          // Bottom left glow - repositioned
          Positioned(
            left: -40,
            bottom: -60,
            child: _GlowBlob(size: 200, color: Colors.white.withOpacity(0.1)),
          ),
          // Accent dots - repositioned for better visibility
          Positioned(
            right: 32,
            top: 130,
            child: _TinyDot(color: Colors.white.withOpacity(0.7)),
          ),
          Positioned(
            right: 52,
            top: 155,
            child: _TinyDot(color: Colors.white.withOpacity(0.5), size: 4),
          ),
          Positioned(
            right: 68,
            top: 175,
            child: _TinyDot(color: Colors.white.withOpacity(0.35), size: 3),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and name
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/icon/sparkio_icon.png'),
                    ),
                    const SizedBox(width: 12),
                    Text('SPARKIO', style: headline),
                  ],
                ),
                const Spacer(),
                // Streak label
                Text(
                  'STREAK',
                  style: sub?.copyWith(
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                // Streak number and days
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$streak',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 80,
                        height: 0.95,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'days',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Task completion pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$doneCount / $totalCount tasks completed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Description
                Text(
                  'Daily micro-tasks to build focus and habits',
                  style: sub?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                // Date
                Text(
                  dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 13,
                  ),
                ),
                // Badges section
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Badges',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: badges
                        .take(4)
                        .map((badge) => _ShareBadgeChip(badge: badge))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareBadgeChip extends StatelessWidget {
  const _ShareBadgeChip({required this.badge});

  final ShareBadgeChipData badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.26), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              color: badge.color.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(badge.icon, size: 12, color: badge.color),
          ),
          const SizedBox(width: 7),
          Text(
            badge.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 0.8],
        ),
      ),
    );
  }
}

class _TinyDot extends StatelessWidget {
  const _TinyDot({required this.color, this.size = 6});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
