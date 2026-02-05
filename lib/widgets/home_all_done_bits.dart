import 'package:flutter/material.dart';

class FinishChip extends StatelessWidget {
  const FinishChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline.withOpacity(0.8)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class MiniConfetti extends StatefulWidget {
  const MiniConfetti({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;

  @override
  State<MiniConfetti> createState() => _MiniConfettiState();
}

class _MiniConfettiState extends State<MiniConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  final List<_ConfettiParticle> _particles = const [
    _ConfettiParticle(dx: 6, dy: 6, size: 4, drift: 6),
    _ConfettiParticle(dx: 20, dy: 2, size: 3, drift: 8),
    _ConfettiParticle(dx: 34, dy: 8, size: 5, drift: 7),
    _ConfettiParticle(dx: 12, dy: 18, size: 3, drift: 5),
    _ConfettiParticle(dx: 28, dy: 20, size: 4, drift: 6),
    _ConfettiParticle(dx: 44, dy: 14, size: 3, drift: 7),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 56,
        height: 40,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ConfettiPainter(
                t: _controller.value,
                primary: widget.primary,
                secondary: widget.secondary,
                particles: _particles,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.dx,
    required this.dy,
    required this.size,
    required this.drift,
  });

  final double dx;
  final double dy;
  final double size;
  final double drift;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.t,
    required this.primary,
    required this.secondary,
    required this.particles,
  });

  final double t;
  final Color primary;
  final Color secondary;
  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      final phase = (t + (i * 0.13)) % 1.0;
      final x = p.dx + (p.drift * (0.5 - phase));
      final y = p.dy + (phase * 10);
      final alpha = (1.0 - (phase * 0.9)).clamp(0.1, 1.0);
      paint.color = (i.isEven ? primary : secondary).withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary;
  }
}
