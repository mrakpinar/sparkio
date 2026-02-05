import 'package:flutter/material.dart';

class StreakShareCard extends StatelessWidget {
  const StreakShareCard({
    super.key,
    required this.streak,
    required this.doneCount,
    required this.totalCount,
    required this.dateLabel,
  });

  final int streak;
  final int doneCount;
  final int totalCount;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = theme.textTheme.titleLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
    );
    final sub = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white70,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF081534),
            Color(0xFF123064),
            Color(0xFF1792AD),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -30,
            child: _GlowBlob(
              size: 160,
              color: Colors.white.withOpacity(0.14),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -50,
            child: _GlowBlob(
              size: 180,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            right: 28,
            top: 120,
            child: _TinyDot(color: Colors.white.withOpacity(0.6)),
          ),
          Positioned(
            right: 46,
            top: 150,
            child: _TinyDot(color: Colors.white.withOpacity(0.45), size: 4),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Image.asset('assets/icon/sparkio_icon.png'),
                    ),
                    const SizedBox(width: 12),
                    Text('SPARKIO', style: headline),
                  ],
                ),
                const Spacer(),
                Text('STREAK', style: sub?.copyWith(letterSpacing: 1.6)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$streak',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 0.9,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'days',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.28)),
                  ),
                  child: Text(
                    '$doneCount / $totalCount tasks completed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Daily micro-tasks to build focus and habits',
                  style: sub,
                ),
                const SizedBox(height: 6),
                Text(
                  dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
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
        color: color,
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
