import 'dart:math' as math;

import 'package:flutter/material.dart';

class WeeklyReviewShareCard extends StatelessWidget {
  const WeeklyReviewShareCard({
    super.key,
    required this.doneTotal,
    required this.topCategoryLabel,
    required this.suggestedTarget,
  });

  final int doneTotal;
  final String topCategoryLabel;
  final int suggestedTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = 'This week $doneTotal sparks';
    final categoryLine = 'Top category: $topCategoryLabel';
    final nextLine = 'Next week target: $suggestedTarget';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF152742), Color(0xFF191D37), Color(0xFF261A34)],
          stops: [0.0, 0.54, 1.0],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.2, -0.9),
                      radius: 1.1,
                      colors: [
                        const Color(0xFF7B8CFF).withOpacity(0.22),
                        const Color(0xFF6E74F1).withOpacity(0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.42, 1.0],
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
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.26),
                      ],
                      stops: const [0.0, 0.62, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _WeeklyReviewShareGrainPainter(opacity: 0.028),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPARKIO WEEKLY REVIEW',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withOpacity(0.62),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    summary,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white.withOpacity(0.94),
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white.withOpacity(0.16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryLine,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nextLine,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

class _WeeklyReviewShareGrainPainter extends CustomPainter {
  const _WeeklyReviewShareGrainPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 12.0;
    final lightPaint = Paint()..style = PaintingStyle.fill;
    final darkPaint = Paint()..style = PaintingStyle.fill;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final hash = math.sin(x * 12.971 + y * 77.239) * 43758.5444;
        final noise = hash - hash.floorToDouble();
        final dotOpacity = noise * opacity;
        if (dotOpacity < 0.01) continue;
        final paint = noise > 0.5 ? lightPaint : darkPaint;
        final channel = noise > 0.5 ? 255 : 0;
        paint.color = Color.fromRGBO(channel, channel, channel, dotOpacity);
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyReviewShareGrainPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}
