import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

class DailyMoodSheet extends StatefulWidget {
  const DailyMoodSheet({
    super.key,
    required this.onSelect,
    required this.onSkip,
  });

  final ValueChanged<String> onSelect;
  final VoidCallback onSkip;

  @override
  State<DailyMoodSheet> createState() => _DailyMoodSheetState();
}

class _DailyMoodSheetState extends State<DailyMoodSheet>
    with SingleTickerProviderStateMixin {
  static String? _lastSuggestedMood;
  late final String _featuredMood = _pickFeaturedMood();
  late final AnimationController _atmosphereController;

  String _pickFeaturedMood() {
    const moods = ['stressed', 'low_energy', 'focus'];
    final random = Random();
    var mood = moods[random.nextInt(moods.length)];
    if (_lastSuggestedMood != null && mood == _lastSuggestedMood) {
      final alternatives = moods.where((m) => m != _lastSuggestedMood).toList();
      mood = alternatives[random.nextInt(alternatives.length)];
    }
    _lastSuggestedMood = mood;
    return mood;
  }

  @override
  void initState() {
    super.initState();
    _atmosphereController = AnimationController(
      duration: const Duration(milliseconds: 14000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _atmosphereController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF0B1324), Color(0xFF151E36)]
                        : [scheme.surface, scheme.surfaceContainerHighest],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -110,
              left: -70,
              child: IgnorePointer(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        scheme.primary.withOpacity(isDark ? 0.2 : 0.09),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 90,
              right: -85,
              child: IgnorePointer(
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        scheme.tertiary.withOpacity(isDark ? 0.14 : 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _MoodSheetNoisePainter(
                    isDark: isDark,
                    opacity: isDark ? 0.10 : 0.04,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _atmosphereController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _MoodAtmosphereDriftPainter(
                        isDark: isDark,
                        opacity: isDark ? 0.03 : 0.02,
                        phase: _atmosphereController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                scheme.primary,
                                scheme.primary.withOpacity(0.7),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.waving_hand_rounded,
                            color: scheme.onPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Let's reset your day.",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Pick what you need. We'll handle the rest.",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: widget.onSkip,
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Close',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    IgnorePointer(
                      child: Transform.translate(
                        offset: const Offset(0, 6),
                        child: Container(
                          width: double.infinity,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.85),
                              radius: 1.25,
                              colors: [
                                Color.lerp(
                                  scheme.primary,
                                  scheme.tertiary,
                                  0.35,
                                )!.withOpacity(isDark ? 0.2 : 0.09),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Mood options
                    _MoodOption(
                      value: 'stressed',
                      title: 'Feeling stressed',
                      subtitle: 'Slow down. 2 minutes is enough.',
                      outcome: '2-minute breathing reset',
                      icon: Icons.spa_rounded,
                      accent: const Color(0xFF38BDF8),
                      dnaTint: const Color(0xFFA78BFA),
                      glowProfile: _MoodGlowProfile.soft,
                      isFeatured: _featuredMood == 'stressed',
                      onTap: () => widget.onSelect('stressed'),
                    ),
                    const SizedBox(height: 12),
                    _MoodOption(
                      value: 'low_energy',
                      title: 'Low energy',
                      subtitle: "Let's wake your brain up.",
                      outcome: '2-minute energy reset',
                      icon: Icons.battery_2_bar_rounded,
                      accent: const Color(0xFF67E8F9),
                      dnaTint: const Color(0xFFFBBF24),
                      glowProfile: _MoodGlowProfile.warm,
                      isFeatured: _featuredMood == 'low_energy',
                      onTap: () => widget.onSelect('low_energy'),
                    ),
                    const SizedBox(height: 12),
                    _MoodOption(
                      value: 'focus',
                      title: 'Need focus',
                      subtitle: 'One small win. Ready?',
                      outcome: '2-minute focus reset',
                      icon: Icons.center_focus_strong_rounded,
                      accent: const Color(0xFF06B6D4),
                      dnaTint: const Color(0xFF2563EB),
                      glowProfile: _MoodGlowProfile.sharp,
                      isFeatured: _featuredMood == 'focus',
                      onTap: () => widget.onSelect('focus'),
                    ),
                    const SizedBox(height: 20),

                    // Skip button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: widget.onSkip,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: scheme.outline.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'Maybe later',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodSheetNoisePainter extends CustomPainter {
  const _MoodSheetNoisePainter({required this.isDark, required this.opacity});

  final bool isDark;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const step = 8;
    final baseColor = isDark ? Colors.white : Colors.black;
    for (int y = 0; y < size.height; y += step) {
      for (int x = 0; x < size.width; x += step) {
        final hash = _hash(x, y);
        if (hash % 10 != 0) continue;
        final alpha = opacity * (0.3 + ((hash % 100) / 1000));
        paint.color = baseColor.withOpacity(alpha);
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1.2, 1.2),
          paint,
        );
      }
    }
  }

  int _hash(int x, int y) {
    int n = x * 374761393 + y * 668265263;
    n = (n ^ (n >> 13)) * 1274126177;
    n ^= (n >> 16);
    return n & 0x7fffffff;
  }

  @override
  bool shouldRepaint(covariant _MoodSheetNoisePainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.opacity != opacity;
  }
}

class _MoodAtmosphereDriftPainter extends CustomPainter {
  const _MoodAtmosphereDriftPainter({
    required this.isDark,
    required this.opacity,
    required this.phase,
  });

  final bool isDark;
  final double opacity;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = isDark ? Colors.white : Colors.black;
    final noisePaint = Paint()..style = PaintingStyle.fill;
    final starPaint = Paint()..style = PaintingStyle.fill;
    const step = 20;
    final angle = phase * 2 * pi;

    for (int y = 0; y < size.height; y += step) {
      for (int x = 0; x < size.width; x += step) {
        final hash = _hash(x, y);
        if (hash % 9 != 0) continue;
        final twinkle = (sin(angle + (hash % 360) * 0.01745) + 1) * 0.5;
        final driftX = sin(angle + (hash * 0.013)) * 1.1;
        final driftY = cos((angle * 0.82) + (hash * 0.011)) * 1.2;
        noisePaint.color = baseColor.withOpacity(
          opacity * (0.22 + twinkle * 0.5),
        );
        canvas.drawRect(
          Rect.fromLTWH(x + driftX, y + driftY, 1.0, 1.0),
          noisePaint,
        );

        if (hash % 37 == 0) {
          starPaint.color = baseColor.withOpacity(
            opacity * (0.55 + twinkle * 0.75),
          );
          canvas.drawCircle(
            Offset(x + 0.5 + driftX * 0.7, y + 0.5 + driftY * 0.7),
            0.75,
            starPaint,
          );
        }
      }
    }
  }

  int _hash(int x, int y) {
    int n = x * 374761393 + y * 668265263;
    n = (n ^ (n >> 13)) * 1274126177;
    n ^= (n >> 16);
    return n & 0x7fffffff;
  }

  @override
  bool shouldRepaint(covariant _MoodAtmosphereDriftPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.opacity != opacity ||
        oldDelegate.phase != phase;
  }
}

class _MoodOption extends StatefulWidget {
  const _MoodOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.outcome,
    required this.icon,
    required this.accent,
    required this.dnaTint,
    required this.glowProfile,
    this.isFeatured = false,
    required this.onTap,
  });

  final String value;
  final String title;
  final String subtitle;
  final String outcome;
  final IconData icon;
  final Color accent;
  final Color dnaTint;
  final _MoodGlowProfile glowProfile;
  final bool isFeatured;
  final VoidCallback onTap;

  @override
  State<_MoodOption> createState() => _MoodOptionState();
}

class _MoodOptionState extends State<_MoodOption>
    with TickerProviderStateMixin {
  late final AnimationController _pressController;
  late final AnimationController _pulseController;
  late final AnimationController _driftController;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 3400),
      reverseDuration: const Duration(milliseconds: 3400),
      vsync: this,
    );
    _driftController = AnimationController(
      duration: const Duration(milliseconds: 5600),
      vsync: this,
    )..repeat();
    if (widget.isFeatured) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _MoodOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFeatured == oldWidget.isFeatured) return;
    if (widget.isFeatured) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  void _setHover(bool value) {
    if (_isHovering == value) return;
    setState(() => _isHovering = value);
  }

  void _onTapDown(TapDownDetails _) {
    _pressController.forward();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  Future<void> _handleTap() async {
    if (_pressController.value < 1) {
      await _pressController.forward();
    }
    if (!mounted) return;
    widget.onTap();
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        _pressController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pressController,
          _pulseController,
          _driftController,
        ]),
        builder: (context, _) {
          final isFeatured = widget.isFeatured;
          final profile = widget.glowProfile;
          final pressT = Curves.easeOutCubic.transform(_pressController.value);
          final pulseT = isFeatured
              ? Curves.easeInOutSine.transform(_pulseController.value)
              : 0.0;
          final driftPhase =
              ((widget.value.codeUnits.fold<int>(0, (a, b) => a + b) % 100) /
                  100.0) *
              2 *
              pi;
          final driftWave = sin((_driftController.value * 2 * pi) + driftPhase);
          final driftCross = cos(
            (_driftController.value * 2 * pi) + driftPhase,
          );
          final signatureGlowColor =
              Color.lerp(
                widget.accent,
                widget.dnaTint,
                isFeatured ? 0.48 : 0.34,
              ) ??
              widget.accent;
          final featuredScale = isFeatured ? 1.02 : 1.0;
          final pulseScale = isFeatured ? (0.995 + (0.005 * pulseT)) : 1.0;
          final tapScale = 1 - (0.056 * pressT);
          final effectiveScale = featuredScale * pulseScale * tapScale;
          final pressOffsetY = 1.8 * pressT;
          final hoverBoost = _isHovering ? 0.08 : 0.0;
          final featuredBorderBase = switch (profile) {
            _MoodGlowProfile.soft => 0.52,
            _MoodGlowProfile.warm => 0.5,
            _MoodGlowProfile.sharp => 0.31,
          };
          final featuredBorderHoverBoost = switch (profile) {
            _MoodGlowProfile.soft => 0.38,
            _MoodGlowProfile.warm => 0.34,
            _MoodGlowProfile.sharp => 0.22,
          };
          final borderWidth = (isFeatured && profile == _MoodGlowProfile.sharp)
              ? 1.2
              : 1.5;
          final borderColor = isFeatured
              ? widget.accent.withOpacity(
                  featuredBorderBase + (hoverBoost * featuredBorderHoverBoost),
                )
              : widget.accent.withOpacity(_isHovering ? 0.34 : 0.22);
          final gradientColors = isFeatured
              ? <Color>[
                  widget.accent.withOpacity(
                    0.26 + hoverBoost + (pulseT * 0.05),
                  ),
                  widget.dnaTint.withOpacity(0.11 + (hoverBoost * 0.22)),
                  scheme.surface,
                ]
              : <Color>[
                  widget.accent.withOpacity(0.08 + hoverBoost),
                  widget.dnaTint.withOpacity(0.045 + (hoverBoost * 0.12)),
                  scheme.surface,
                ];
          final baseShadows = <BoxShadow>[
            if (_isHovering)
              BoxShadow(
                color: signatureGlowColor.withOpacity(isFeatured ? 0.24 : 0.16),
                blurRadius: isFeatured
                    ? (profile == _MoodGlowProfile.sharp ? 32 : 26)
                    : 20,
                spreadRadius: -3,
                offset: const Offset(0, 8),
              ),
            if (isFeatured)
              BoxShadow(
                color: signatureGlowColor.withOpacity(
                  (profile == _MoodGlowProfile.sharp ? 0.16 : 0.2) +
                      (pulseT *
                          (profile == _MoodGlowProfile.sharp ? 0.06 : 0.08)),
                ),
                blurRadius:
                    (profile == _MoodGlowProfile.sharp ? 30 : 22) +
                    (pulseT * (profile == _MoodGlowProfile.sharp ? 7 : 5)),
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            BoxShadow(
              color: Colors.black.withOpacity(isFeatured ? 0.08 : 0.04),
              blurRadius: isFeatured ? 12 : 8,
              spreadRadius: isFeatured ? -4 : -2,
              offset: isFeatured ? const Offset(0, 4) : const Offset(0, 2),
            ),
          ];
          final pressShadowDamp = 1 - (0.38 * pressT);
          final cardShadows = baseShadows
              .map(
                (shadow) => shadow.copyWith(
                  color: shadow.color.withOpacity(
                    shadow.color.opacity * pressShadowDamp,
                  ),
                  blurRadius: shadow.blurRadius * pressShadowDamp,
                  offset: Offset(
                    shadow.offset.dx,
                    shadow.offset.dy * pressShadowDamp,
                  ),
                ),
              )
              .toList();
          final gradientBegin = Alignment(
            -1 + (0.15 * driftWave),
            -1 + (0.08 * driftCross),
          );
          final gradientEnd = Alignment(
            1 - (0.12 * driftWave),
            1 + (0.1 * driftCross),
          );
          final arrowColor = signatureGlowColor.withOpacity(
            isFeatured
                ? (_isHovering ? 0.9 : 0.62)
                : (_isHovering ? 0.82 : 0.5),
          );
          final arrowReveal =
              ((_isHovering ? 0.65 : 0.0) +
                      (isFeatured ? 0.08 : 0.0) +
                      (pressT * 0.7))
                  .clamp(0.0, 1.0)
                  .toDouble();
          final arrowOpacity = (0.04 + (arrowReveal * 0.84))
              .clamp(0.0, 1.0)
              .toDouble();
          final arrowIconScale = 0.96 + (arrowReveal * 0.1);
          final arrowShadowBlur = 4 + (arrowReveal * 10);
          final arrowShadowOpacity = 0.04 + (arrowReveal * 0.18);

          return Transform.translate(
            offset: Offset(0, pressOffsetY),
            child: Transform.scale(
              scale: effectiveScale,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleTap,
                  onTapDown: _onTapDown,
                  onTapCancel: _onTapCancel,
                  onHover: _setHover,
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: scheme.surface,
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                      boxShadow: cardShadows,
                      gradient: LinearGradient(
                        begin: gradientBegin,
                        end: gradientEnd,
                        colors: gradientColors,
                      ),
                    ),
                    child: Row(
                      children: [
                        _MoodGlowIcon(
                          icon: widget.icon,
                          accent: widget.accent,
                          glowTint: widget.dnaTint,
                          profile: widget.glowProfile,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isFeatured) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 5.2,
                                      sigmaY: 5.2,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        color: signatureGlowColor.withOpacity(
                                          0.16,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 12,
                                            color: signatureGlowColor
                                                .withOpacity(0.9),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Suggested for you',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: signatureGlowColor
                                                      .withOpacity(0.94),
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: 0.12,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                              Text(
                                widget.title,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.subtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _OutcomePill(
                                    icon: Icons.timelapse_rounded,
                                    text: widget.outcome,
                                    accent: widget.accent,
                                  ),
                                  const SizedBox(height: 6),
                                  Transform.translate(
                                    offset: const Offset(0, 2),
                                    child: Wrap(
                                      spacing: 7,
                                      children: [
                                        _OutcomePill(
                                          icon: Icons.flash_on_rounded,
                                          text: '1 quick action',
                                          accent: widget.accent,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 2,
                                          ),
                                          child: _OutcomePill(
                                            icon: Icons.tune_rounded,
                                            text: 'No setup needed',
                                            accent: widget.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Opacity(
                          opacity: arrowOpacity,
                          child: Transform.scale(
                            scale: arrowIconScale,
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: arrowColor,
                              size: 15,
                              shadows: [
                                Shadow(
                                  color: signatureGlowColor.withOpacity(
                                    arrowShadowOpacity,
                                  ),
                                  blurRadius: arrowShadowBlur,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OutcomePill extends StatelessWidget {
  const _OutcomePill({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseFill = accent.withOpacity(isDark ? 0.145 : 0.085);
    final borderColor = accent.withOpacity(isDark ? 0.26 : 0.18);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: baseFill,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: accent.withOpacity(0.83)),
              const SizedBox(width: 5),
              Text(
                text,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent.withOpacity(0.86),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MoodGlowProfile { soft, warm, sharp }

class _MoodGlowIcon extends StatefulWidget {
  const _MoodGlowIcon({
    required this.icon,
    required this.accent,
    required this.glowTint,
    required this.profile,
  });

  final IconData icon;
  final Color accent;
  final Color glowTint;
  final _MoodGlowProfile profile;

  @override
  State<_MoodGlowIcon> createState() => _MoodGlowIconState();
}

class _MoodGlowIconState extends State<_MoodGlowIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final phaseOffset = (widget.icon.codePoint % 100) / 100.0;
        final shimmerT = (_shimmerController.value + phaseOffset) % 1.0;
        final shimmerX = -34 + (shimmerT * 86);
        final profile = widget.profile;

        final warmBlend = const Color(0xFFF59E0B);
        final glowColor =
            Color.lerp(widget.accent, widget.glowTint, 0.5) ?? widget.accent;
        final profileGlowColor = switch (profile) {
          _MoodGlowProfile.soft => Color.lerp(glowColor, Colors.white, 0.08)!,
          _MoodGlowProfile.warm => Color.lerp(glowColor, warmBlend, 0.28)!,
          _MoodGlowProfile.sharp => Color.lerp(glowColor, widget.accent, 0.38)!,
        };
        final topColor = switch (profile) {
          _MoodGlowProfile.soft => Color.lerp(
            widget.glowTint,
            Colors.white,
            0.22,
          )!,
          _MoodGlowProfile.warm => Color.lerp(
            widget.glowTint,
            const Color(0xFFFFE7B8),
            0.36,
          )!,
          _MoodGlowProfile.sharp => Color.lerp(
            widget.glowTint,
            Colors.white,
            0.42,
          )!,
        };
        final bottomColor = switch (profile) {
          _MoodGlowProfile.soft => Color.lerp(
            widget.accent,
            const Color(0xFF0B1220),
            0.14,
          )!,
          _MoodGlowProfile.warm => Color.lerp(
            widget.accent,
            const Color(0xFF0B1220),
            0.2,
          )!,
          _MoodGlowProfile.sharp => Color.lerp(
            widget.accent,
            const Color(0xFF030712),
            0.3,
          )!,
        };
        final outerGlowOpacity = switch (profile) {
          _MoodGlowProfile.soft => 0.24,
          _MoodGlowProfile.warm => 0.34,
          _MoodGlowProfile.sharp => 0.42,
        };
        final outerGlowBlur = switch (profile) {
          _MoodGlowProfile.soft => 22.0,
          _MoodGlowProfile.warm => 18.0,
          _MoodGlowProfile.sharp => 14.0,
        };
        final innerGlowOpacity = switch (profile) {
          _MoodGlowProfile.soft => 0.11,
          _MoodGlowProfile.warm => 0.18,
          _MoodGlowProfile.sharp => 0.23,
        };
        final innerGlowBlur = switch (profile) {
          _MoodGlowProfile.soft => 10.0,
          _MoodGlowProfile.warm => 8.5,
          _MoodGlowProfile.sharp => 7.0,
        };
        final shimmerOpacity = switch (profile) {
          _MoodGlowProfile.soft => 0.2,
          _MoodGlowProfile.warm => 0.27,
          _MoodGlowProfile.sharp => 0.34,
        };
        final shimmerBandWidth = switch (profile) {
          _MoodGlowProfile.soft => 16.0,
          _MoodGlowProfile.warm => 18.0,
          _MoodGlowProfile.sharp => 13.0,
        };
        final borderOpacity = switch (profile) {
          _MoodGlowProfile.soft => 0.36,
          _MoodGlowProfile.warm => 0.44,
          _MoodGlowProfile.sharp => 0.56,
        };
        final borderWidth = switch (profile) {
          _MoodGlowProfile.soft => 1.05,
          _MoodGlowProfile.warm => 1.2,
          _MoodGlowProfile.sharp => 1.35,
        };

        return SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: profileGlowColor.withOpacity(outerGlowOpacity),
                      blurRadius: outerGlowBlur,
                      spreadRadius: -1,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: profileGlowColor.withOpacity(innerGlowOpacity),
                      blurRadius: innerGlowBlur,
                      spreadRadius: -2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.glowTint.withOpacity(0.26),
                      widget.accent.withOpacity(0.11),
                    ],
                  ),
                  border: Border.all(
                    color: profileGlowColor.withOpacity(borderOpacity),
                    width: borderWidth,
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Opacity(
                      opacity: shimmerOpacity,
                      child: Transform.translate(
                        offset: Offset(shimmerX, 0),
                        child: Transform.rotate(
                          angle: -0.24,
                          child: Container(
                            width: shimmerBandWidth,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.78),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [topColor, bottomColor],
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Icon(widget.icon, size: 27, color: Colors.white),
              ),
              Positioned(
                top: 11,
                right: 11,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.42),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
