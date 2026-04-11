import 'dart:math';
import 'package:flutter/material.dart';

class SparkParticlesBackground extends StatefulWidget {
  final int streak;
  const SparkParticlesBackground({super.key, required this.streak});

  @override
  State<SparkParticlesBackground> createState() => _SparkParticlesBackgroundState();
}

class _SparkParticlesBackgroundState extends State<SparkParticlesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();
  int _particleCount = 0;

  @override
  void initState() {
    super.initState();
    _recalculateCount();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..addListener(_updateParticles)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant SparkParticlesBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streak != widget.streak) {
      _recalculateCount();
    }
  }

  void _recalculateCount() {
    if (widget.streak < 5) {
      _particleCount = 0;
    } else {
      // Scale particles with streak playfully, cap at 40
      _particleCount = min(40, 10 + (widget.streak - 5) * 2);
    }
    _ensureParticles();
  }

  void _ensureParticles() {
    while (_particles.length < _particleCount) {
      _particles.add(_createParticle(spawnAnywhere: true));
    }
    while (_particles.length > _particleCount) {
      _particles.removeLast();
    }
  }

  _Particle _createParticle({bool spawnAnywhere = false}) {
    // Colors ranging from deep orange to light yellow
    final colors = [
      const Color(0xFFF59E0B),
      const Color(0xFFF97316),
      const Color(0xFFFCD34D),
      const Color(0xFFEF4444).withOpacity(0.8),
    ];
    return _Particle(
      x: _rnd.nextDouble(),
      y: spawnAnywhere ? _rnd.nextDouble() : 1.1, // Start slightly below screen
      size: _rnd.nextDouble() * 3 + 1.5,
      speed: _rnd.nextDouble() * 0.2 + 0.1,
      horizontalWander: (_rnd.nextDouble() - 0.5) * 0.1,
      color: colors[_rnd.nextInt(colors.length)],
      opacity: _rnd.nextDouble() * 0.5 + 0.3,
    );
  }

  void _updateParticles() {
    if (!mounted) return;
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.y -= p.speed * 0.016; // Approx 60fps delta
      p.x += p.horizontalWander * 0.016;
      p.opacity -= 0.001; // Fade out slowly
      
      if (p.y < -0.1 || p.opacity <= 0 || p.x < -0.1 || p.x > 1.1) {
        _particles[i] = _createParticle(spawnAnywhere: false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particleCount == 0) return const SizedBox.shrink();
    
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _SparkPainter(_particles),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double horizontalWander;
  Color color;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.horizontalWander,
    required this.color,
    required this.opacity,
  });
}

class _SparkPainter extends CustomPainter {
  final List<_Particle> particles;
  _SparkPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.opacity <= 0) continue;
      
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => true;
}
