import 'dart:math' as math;

import 'package:flutter/material.dart';

class StreakShareCard extends StatelessWidget {
  const StreakShareCard({
    super.key,
    required this.streak,
    required this.doneCount,
    required this.totalCount,
  });

  final int streak;
  final int doneCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = streak > 0 ? streak : 1;
    final dayLabel = 'DAY $day';
    final proofLabel = '$doneCount of $totalCount sparks completed';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF132743), Color(0xFF161F36), Color(0xFF241932)],
          stops: [0.0, 0.58, 1.0],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.08, -0.82),
                      radius: 1.14,
                      colors: [
                        const Color(0xFF7B9FFF).withOpacity(0.18),
                        const Color(0xFF7D71F6).withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.38, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -86,
              top: -114,
              child: IgnorePointer(
                child: SizedBox(
                  width: 332,
                  height: 332,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF8EA6FF).withOpacity(0.13),
                          const Color(0xFF7B6FF6).withOpacity(0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.46, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -92,
              top: 214,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -0.24,
                  child: Container(
                    width: 244,
                    height: 132,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8CA8FF).withOpacity(0.055),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF84A1FF).withOpacity(0.045),
                          blurRadius: 56,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -84,
              bottom: 146,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: 0.18,
                  child: Container(
                    width: 208,
                    height: 114,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7B6FF6).withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7D70F6).withOpacity(0.04),
                          blurRadius: 52,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.02),
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.2),
                      ],
                      stops: const [0.0, 0.34, 0.72, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _StoryGrainPainter(opacity: 0.035)),
              ),
            ),
            Positioned(
              right: 14,
              top: 12,
              child: Text(
                'Sparkio',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withOpacity(0.52),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 6),
                  Text(
                    dayLabel,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: const Color(0xFFF2F4FF).withOpacity(0.9),
                      fontSize: 62,
                      height: 0.94,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Showing up.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.84),
                      fontSize: 22,
                      height: 1.1,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(flex: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withOpacity(0.07),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                    ),
                    child: Text(
                      proofLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.84),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryGrainPainter extends CustomPainter {
  const _StoryGrainPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 11.0;
    final lightPaint = Paint()..style = PaintingStyle.fill;
    final darkPaint = Paint()..style = PaintingStyle.fill;

    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final hash = math.sin(x * 12.9898 + y * 78.233) * 43758.5453;
        final noise = hash - hash.floorToDouble();
        final dotOpacity = noise * opacity;
        if (dotOpacity < 0.01) continue;
        final paint = noise > 0.5 ? lightPaint : darkPaint;
        final channel = noise > 0.5 ? 255 : 0;
        paint.color = Color.fromRGBO(channel, channel, channel, dotOpacity);
        final offsetX = x + (noise - 0.5) * 2.0;
        final offsetY = y + (0.5 - noise) * 2.0;
        canvas.drawRect(Rect.fromLTWH(offsetX, offsetY, 1, 1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StoryGrainPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}
