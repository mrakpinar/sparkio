import 'dart:ui';

import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final Future<void> Function() onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: Icons.flash_on_rounded,
      eyebrow: 'Daily Momentum',
      title: 'Welcome to Sparkio',
      description:
          'Build momentum with short, practical tasks designed to fit your day.',
      highlights: ['3 focused tasks', 'Quick wins'],
      accentStart: Color(0xFF3B82F6),
      accentEnd: Color(0xFF2EA7D6),
    ),
    _OnboardingSlide(
      icon: Icons.timer_rounded,
      eyebrow: 'Focus Engine',
      title: 'Stay Consistent',
      description:
          'Use timers, streaks, and weekly plans to stay focused and finish more.',
      highlights: ['Built-in timers', 'Streak tracking'],
      accentStart: Color(0xFF06B6D4),
      accentEnd: Color(0xFF3B82F6),
    ),
    _OnboardingSlide(
      icon: Icons.insights_rounded,
      eyebrow: 'Progress Clarity',
      title: 'Track Your Progress',
      description:
          'See your progress over time and keep your routine moving forward.',
      highlights: ['Weekly insights', 'Smarter habits'],
      accentStart: Color(0xFF22C55E),
      accentEnd: Color(0xFF14B8A6),
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _finishing = false;

  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_isLastPage) {
      await _finish();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skipToLast() async {
    await _pageController.animateToPage(
      _slides.length - 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.onFinished();
    if (!mounted) return;
    setState(() => _finishing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final activeSlide = _slides[_currentPage];
    final topColor = isDark
        ? Color.alphaBlend(
            activeSlide.accentStart.withOpacity(0.26),
            const Color(0xFF060F1E),
          )
        : Color.alphaBlend(
            activeSlide.accentStart.withOpacity(0.16),
            const Color(0xFFF5F9FF),
          );
    final bottomColor = isDark
        ? Color.alphaBlend(
            activeSlide.accentEnd.withOpacity(0.24),
            const Color(0xFF0B1629),
          )
        : Color.alphaBlend(
            activeSlide.accentEnd.withOpacity(0.12),
            Colors.white,
          );

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [topColor, bottomColor],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: _GlowOrb(
              color: activeSlide.accentStart.withOpacity(isDark ? 0.34 : 0.26),
              size: 220,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -30,
            child: _GlowOrb(
              color: activeSlide.accentEnd.withOpacity(isDark ? 0.32 : 0.22),
              size: 260,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: scheme.surface.withOpacity(isDark ? 0.16 : 0.72),
                          border: Border.all(
                            color: scheme.outline.withOpacity(0.24),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 16,
                              color: activeSlide.accentStart,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SPARKIO',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (!_isLastPage)
                        TextButton(
                          onPressed: _finishing ? null : _skipToLast,
                          child: const Text('Skip'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return _OnboardingPage(
                        slide: slide,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: scheme.surface.withOpacity(isDark ? 0.16 : 0.72),
                          border: Border.all(
                            color: scheme.outline.withOpacity(0.24),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_slides.length, (index) {
                                final selected = index == _currentPage;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: selected ? 26 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: selected
                                        ? activeSlide.accentStart
                                        : scheme.onSurfaceVariant.withOpacity(0.32),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Text(
                                  '${_currentPage + 1}/${_slides.length}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: _finishing ? null : _next,
                                    icon: _finishing
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            _isLastPage
                                                ? Icons.rocket_launch_rounded
                                                : Icons.arrow_forward_rounded,
                                            size: 18,
                                          ),
                                    label: Text(
                                      _isLastPage ? 'Get Started' : 'Next',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: activeSlide.accentStart,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.highlights,
    required this.accentStart,
    required this.accentEnd,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final List<String> highlights;
  final Color accentStart;
  final Color accentEnd;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.slide,
    required this.isDark,
  });

  final _OnboardingSlide slide;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                colors: [
                  slide.accentStart.withOpacity(isDark ? 0.34 : 0.24),
                  slide.accentEnd.withOpacity(isDark ? 0.28 : 0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.24)),
              boxShadow: [
                BoxShadow(
                  color: slide.accentStart.withOpacity(isDark ? 0.32 : 0.18),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [slide.accentStart, slide.accentEnd],
                    ),
                  ),
                  child: Icon(slide.icon, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slide.eyebrow.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        slide.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            slide.description,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slide.highlights.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: scheme.surface.withOpacity(isDark ? 0.2 : 0.78),
                  border: Border.all(color: scheme.outline.withOpacity(0.22)),
                ),
                child: Text(
                  item,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0.0)],
          ),
        ),
      ),
    );
  }
}
