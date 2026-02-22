import 'dart:ui';

import 'package:flutter/material.dart';

// ─── Animation timing constants ───────────────────────────────────────────────
const double _kBenefitIntervalBase = 0.12;
const double _kBenefitIntervalStep = 0.16;
const double _kBenefitIntervalLength = 0.34;

// ─── Title animation constants ─────────────────────────────────────────────────
const double _kTitleLeftDivisor = 0.94;
const double _kTitleRightOffset = 0.06;
const double _kTitleRightDivisor = 0.92;
const double _kTitleSlideDistance = 14.0;
const double _kTitleSubtleYOffset = 8.0;

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
      title: 'Small actions. Real change.',
      description: '3 quick tasks a day to build momentum.',
      highlights: [
        '3 focused tasks',
        'Streak + XP motivation',
        'Quick daily wins',
      ],
      accentStart: Color(0xFF3B82F6),
      accentEnd: Color(0xFF2EA7D6),
      animateTitle: true,
    ),
    _OnboardingSlide(
      icon: Icons.timer_rounded,
      eyebrow: 'Focus Engine',
      title: 'Build your daily rhythm',
      description: 'A few minutes a day is enough to keep moving forward.',
      highlights: [
        'Stay focused for a few minutes',
        'See your progress grow daily',
        'Keep your routine on track',
      ],
      accentStart: Color(0xFF06B6D4),
      accentEnd: Color(0xFF3B82F6),
      animateTitle: true,
    ),
    _OnboardingSlide(
      icon: Icons.insights_rounded,
      eyebrow: 'Progress Clarity',
      title: 'Watch your momentum grow',
      description: 'Small actions add up faster than you think.',
      highlights: [
        'Notice your consistency build',
        'Feel the progress over time',
        'Turn effort into momentum',
      ],
      accentStart: Color(0xFF22C55E),
      accentEnd: Color(0xFF14B8A6),
      animateTitle: true,
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
    // Guard against calling after dispose
    if (!mounted) return;
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

    // withValues(alpha:) replaces deprecated withOpacity()
    final topColor = isDark
        ? Color.alphaBlend(
            activeSlide.accentStart.withValues(alpha: 0.26),
            const Color(0xFF060F1E),
          )
        : Color.alphaBlend(
            activeSlide.accentStart.withValues(alpha: 0.16),
            const Color(0xFFF5F9FF),
          );
    final bottomColor = isDark
        ? Color.alphaBlend(
            activeSlide.accentEnd.withValues(alpha: 0.24),
            const Color(0xFF0B1629),
          )
        : Color.alphaBlend(
            activeSlide.accentEnd.withValues(alpha: 0.12),
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
              color: activeSlide.accentStart.withValues(
                alpha: isDark ? 0.34 : 0.26,
              ),
              size: 220,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -30,
            child: _GlowOrb(
              color: activeSlide.accentEnd.withValues(
                alpha: isDark ? 0.32 : 0.22,
              ),
              size: 260,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                AnimatedPadding(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    _isLastPage ? 30 : 14,
                    20,
                    8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: scheme.surface.withValues(
                            alpha: isDark ? 0.12 : 0.58,
                          ),
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: activeSlide.accentStart.withValues(
                                alpha: 0.9,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SPARKIO',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.9,
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (!_isLastPage)
                        TextButton(
                          onPressed: _finishing ? null : _skipToLast,
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                            textStyle: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none,
                            ),
                          ),
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
                        isActive: index == _currentPage,
                        pageIndex: index,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 1.4, sigmaY: 1.4),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Color.alphaBlend(
                            activeSlide.accentStart.withValues(
                              alpha: isDark ? 0.04 : 0.018,
                            ),
                            scheme.surface.withValues(
                              alpha: isDark ? 0.068 : 0.22,
                            ),
                          ),
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.04),
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
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: selected ? 33 : 8,
                                  height: selected ? 10 : 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: selected
                                        ? Color.alphaBlend(
                                            Colors.white.withValues(
                                              alpha: isDark ? 0.14 : 0.24,
                                            ),
                                            activeSlide.accentStart,
                                          )
                                        : scheme.onSurfaceVariant.withValues(
                                            alpha: 0.7,
                                          ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return Center(
                                  child: SizedBox(
                                    width: constraints.maxWidth * 0.82,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _finishing ? null : _next,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            activeSlide.accentStart,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                        ),
                                      ),
                                      child: _finishing
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              // FIX: "Get started" only on the
                                              // last page, not the first.
                                              _isLastPage
                                                  ? 'Get started'
                                                  : 'Continue',
                                            ),
                                    ),
                                  ),
                                );
                              },
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

// ─── Data model ───────────────────────────────────────────────────────────────

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.highlights,
    required this.accentStart,
    required this.accentEnd,
    this.animateTitle = false, // opt-in per slide instead of hard-coded index
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final List<String> highlights;
  final Color accentStart;
  final Color accentEnd;

  /// When true, the title is split and animated in from opposite sides.
  final bool animateTitle;
}

// ─── Page widget ──────────────────────────────────────────────────────────────

class _OnboardingPage extends StatefulWidget {
  const _OnboardingPage({
    required this.slide,
    required this.isDark,
    required this.isActive,
    required this.pageIndex,
  });

  final _OnboardingSlide slide;
  final bool isDark;
  final bool isActive;
  final int pageIndex;

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with TickerProviderStateMixin {
  late final AnimationController _benefitController;
  late final AnimationController _titleController;

  bool get _shouldAnimateTitle => widget.slide.animateTitle;

  @override
  void initState() {
    super.initState();
    _benefitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Non-animated slides start at completed state immediately
    if (!_shouldAnimateTitle) {
      _titleController.value = 1;
    }

    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _benefitController.forward(from: 0);
        if (_shouldAnimateTitle) {
          _titleController.forward(from: 0);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_shouldAnimateTitle) {
      _titleController.value = 1;
    }

    if (!oldWidget.isActive && widget.isActive) {
      _benefitController.forward(from: 0);
      if (_shouldAnimateTitle) {
        _titleController.forward(from: 0);
      }
    } else if (oldWidget.isActive && !widget.isActive) {
      _benefitController.value = 0;
      if (_shouldAnimateTitle || oldWidget.slide.animateTitle) {
        _titleController.value = 0;
      }
    }
  }

  Animation<double> _benefitAnimation(int index) {
    final start = (_kBenefitIntervalBase + (index * _kBenefitIntervalStep))
        .clamp(0.0, 0.8);
    final end = (start + _kBenefitIntervalLength).clamp(start + 0.01, 1.0);
    return CurvedAnimation(
      parent: _benefitController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _benefitController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  /// Splits title on explicit '\n' first; falls back to word-count pivot.
  List<String> _titleParts(String title) {
    if (title.contains('\n')) {
      final parts = title.split('\n');
      return [parts.first, parts.sublist(1).join('\n')];
    }
    final words = title.trim().split(RegExp(r'\s+'));
    if (words.length < 2) return [title, ''];
    final pivot = words.length ~/ 2;
    return [words.sublist(0, pivot).join(' '), words.sublist(pivot).join(' ')];
  }

  Widget _buildTitle(TextStyle? style) {
    if (!_shouldAnimateTitle) {
      return Text(
        widget.slide.title,
        textAlign: TextAlign.center,
        style: style,
      );
    }

    if (widget.pageIndex != 2) {
      return AnimatedBuilder(
        animation: _titleController,
        builder: (context, child) {
          final progress = Curves.easeOutCubic.transform(
            _titleController.value.clamp(0.0, 1.0),
          );
          return Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(0, lerpDouble(_kTitleSubtleYOffset, 0, progress)!),
              child: Text(
                widget.slide.title,
                textAlign: TextAlign.center,
                style: style,
              ),
            ),
          );
        },
      );
    }

    final parts = _titleParts(widget.slide.title);
    return AnimatedBuilder(
      animation: _titleController,
      builder: (context, child) {
        final leftProgress = Curves.easeInOutCubic.transform(
          (_titleController.value / _kTitleLeftDivisor).clamp(0.0, 1.0),
        );
        final rightProgress = Curves.easeInOutCubic.transform(
          ((_titleController.value - _kTitleRightOffset) / _kTitleRightDivisor)
              .clamp(0.0, 1.0),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: leftProgress,
              child: Transform.translate(
                offset: Offset(
                  lerpDouble(-_kTitleSlideDistance, 0, leftProgress)!,
                  0,
                ),
                child: Text(
                  parts[0],
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
            ),
            if (parts[1].isNotEmpty) ...[
              const SizedBox(height: 2),
              Opacity(
                opacity: rightProgress,
                child: Transform.translate(
                  offset: Offset(
                    lerpDouble(_kTitleSlideDistance, 0, rightProgress)!,
                    0,
                  ),
                  child: Text(
                    parts[1],
                    textAlign: TextAlign.center,
                    style: style,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final benefits = widget.slide.highlights.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                const Spacer(),
                if (widget.pageIndex == 2) const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: _buildTitle(
                    theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.02,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Text(
                    widget.slide.description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(benefits.length, (index) {
                      final animation = _benefitAnimation(index);
                      final item = benefits[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.16),
                              end: Offset.zero,
                            ).animate(animation),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: widget.slide.accentStart.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: widget.isDark
                                        ? const Color(0xFFCFE1F8)
                                        : Color.alphaBlend(
                                            const Color(
                                              0xFFCFE1F8,
                                            ).withValues(alpha: 0.36),
                                            scheme.onSurfaceVariant,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const Spacer(flex: 4),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Glow orb ─────────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates the orb's repaints from the rest of the tree
    return RepaintBoundary(
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0.0)],
            ),
          ),
        ),
      ),
    );
  }
}
