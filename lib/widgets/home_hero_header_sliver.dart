import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import '../app_strings.dart';
import '../services/locale_service.dart';

class HomeHeroHeaderSliver extends StatelessWidget {
  const HomeHeroHeaderSliver({
    super.key,
    required this.userName,
    required this.totalSparksLit,
    required this.streak,
    this.lockCollapsed = false,
    this.onExpandFromCollapsed,
    required this.onOpenStats,
    required this.onShare,
  });

  final String userName;
  final int totalSparksLit;
  final int streak;
  final bool lockCollapsed;
  final VoidCallback? onExpandFromCollapsed;
  final VoidCallback onOpenStats;
  final VoidCallback onShare;
  static const double _collapsedToolbarHeight = 56;
  static const double _minimumExpandedHeight = 220;

  static double minExtentFor(MediaQueryData media) {
    return media.padding.top + _collapsedToolbarHeight;
  }

  static double maxExtentFor(MediaQueryData media) {
    final minExtent = minExtentFor(media);
    return math.max(minExtent + _minimumExpandedHeight, media.size.height);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final minExtent = minExtentFor(media);
    final maxExtent = lockCollapsed ? minExtent : maxExtentFor(media);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _HomeHeroHeaderDelegate(
        minHeight: minExtent,
        maxHeight: maxExtent,
        userName: userName,
        totalSparksLit: totalSparksLit,
        streak: streak,
        lockCollapsed: lockCollapsed,
        onExpandFromCollapsed: onExpandFromCollapsed,
        onOpenStats: onOpenStats,
        onShare: onShare,
      ),
    );
  }
}

class _HomeHeroHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HomeHeroHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.userName,
    required this.totalSparksLit,
    required this.streak,
    required this.lockCollapsed,
    required this.onExpandFromCollapsed,
    required this.onOpenStats,
    required this.onShare,
  });

  final double minHeight;
  final double maxHeight;
  final String userName;
  final int totalSparksLit;
  final int streak;
  final bool lockCollapsed;
  final VoidCallback? onExpandFromCollapsed;
  final VoidCallback onOpenStats;
  final VoidCallback onShare;

  static const _quotes = <(String, String)>[
    ('We are what we repeatedly do.', 'Aristotle'),
    ('Small steps compound.', 'James Clear'),
    ('Action brings clarity.', 'Marie Forleo'),
    ('Consistency creates trust in yourself.', 'Unknown'),
    ('Calm mind. Clear move.', 'Sparkio'),
  ];

  String _displayName() {
    final cleaned = userName.trim();
    return cleaned.isEmpty ? 'Friend' : cleaned;
  }

  String _greeting() {
    final code = LocaleService.instance.effectiveLanguageCode;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return AppLocalizations.lookup(code, 'Good morning');
    }
    if (hour < 18) {
      return AppLocalizations.lookup(code, 'Good afternoon');
    }
    return AppLocalizations.lookup(code, 'Good evening');
  }

  ({String text, String author}) _quoteForToday() {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(yearStart).inDays;
    final bucket = dayOfYear ~/ 3;
    final index = (bucket + now.year) % _quotes.length;
    final q = _quotes[index];
    return (text: q.$1, author: q.$2);
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final delta = (maxExtent - minExtent).clamp(1, double.infinity);
    final rawT = (shrinkOffset / delta).clamp(0.0, 1.0);
    final easedT = Curves.easeOutCubic.transform(rawT);
    final t = lockCollapsed ? 1.0 : easedT;
    final topInset = MediaQuery.of(context).padding.top;
    final blur = lerpDouble(0, 8, t)!;
    final expandedOpacity = (1 - (t * 1.2)).clamp(0.0, 1.0);
    final quoteOpacity = (1 - (t * 2.35)).clamp(0.0, 1.0);
    final brandOpacity = (1 - (t * 1.4)).clamp(0.0, 1.0);
    final collapsedTitleOpacity = (t * 1.45 - 0.45).clamp(0.0, 1.0);
    final greetingMotionT = (t / 0.18).clamp(0.0, 1.0);
    final greetingOpacity = lerpDouble(0.7, 1.0, greetingMotionT)!;
    final greetingTranslateY = lerpDouble(0.0, -6.0, greetingMotionT)!;
    final name = _displayName();
    final greeting = _greeting();
    final quote = _quoteForToday();
    final isDark = theme.brightness == Brightness.dark;
    final baseStart = Color.alphaBlend(
      Colors.black.withOpacity(
        isDark ? lerpDouble(0.48, 0.58, t)! : lerpDouble(0.2, 0.3, t)!,
      ),
      scheme.surface,
    );
    final baseEnd = Color.alphaBlend(
      Colors.black.withOpacity(
        isDark ? lerpDouble(0.36, 0.46, t)! : lerpDouble(0.16, 0.24, t)!,
      ),
      scheme.surface,
    );
    final topLeftGlow = const Color(
      0xFF34D5FF,
    ).withOpacity(lerpDouble(0.16, 0.05, t)!);
    final topRightGlow = const Color(
      0xFF8B5CF6,
    ).withOpacity(lerpDouble(0.14, 0.045, t)!);
    final hazeOpacity = lerpDouble(0.07, 0.03, t)!;
    final surfaceScale = lerpDouble(1.03, 1.0, t)!;
    final surfaceDarkenOpacity = lerpDouble(0.02, 0.15, t)!;
    final bodyTextTranslateY = lerpDouble(0.0, -8.0, t)!;
    final ctaTranslateY = lerpDouble(0.0, 14.0, t)!;
    final headerTopExtra = lerpDouble(8.0, 2.0, t)!;
    final headerBottomPadding = lerpDouble(12.0, 4.0, t)!;
    final topRowHeight = lerpDouble(42.0, 40.0, t)!;
    final topToBodyGap = lerpDouble(18.0, 0.0, t)!;

    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scale: surfaceScale,
          alignment: Alignment.topCenter,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [baseStart, baseEnd],
                  ),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.86, -1.08),
                      radius: 1.06,
                      colors: [topLeftGlow, Colors.transparent],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.98, -0.92),
                      radius: 1.08,
                      colors: [topRightGlow, Colors.transparent],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Opacity(
                  opacity: hazeOpacity,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0x22FFFFFF),
                          Color(0x00000000),
                          Color(0x14FFFFFF),
                          Color(0x00000000),
                        ],
                        stops: [0.0, 0.36, 0.74, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(surfaceDarkenOpacity),
            ),
          ),
        ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, headerBottomPadding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: topInset + headerTopExtra),
                      SizedBox(
                        height: topRowHeight,
                        child: Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: lockCollapsed
                                      ? onExpandFromCollapsed
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      Opacity(
                                        opacity: brandOpacity,
                                        child: const _BrandHeader(),
                                      ),
                                      Opacity(
                                        opacity: collapsedTitleOpacity,
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'Hello, $name',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: scheme.onSurface
                                                          .withOpacity(0.92),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 19,
                                                    ),
                                              ),
                                            ),
                                            if (lockCollapsed) ...[
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                size: 20,
                                                color: scheme.onSurface
                                                    .withOpacity(0.72),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _HeroTopActionButton(
                                  icon: Icons.insights_outlined,
                                  onTap: onOpenStats,
                                  semanticLabel: 'Open stats',
                                ),
                                const SizedBox(width: 4),
                                _HeroTopActionButton(
                                  icon: Icons.ios_share_rounded,
                                  onTap: onShare,
                                  semanticLabel: 'Share',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: topToBodyGap),
                      Expanded(
                        child: Opacity(
                          opacity: expandedOpacity,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 460),
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Transform.translate(
                                      offset: Offset(0, greetingTranslateY),
                                      child: Text(
                                        '$greeting, $name.',
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                              color: scheme.onSurface
                                                  .withOpacity(
                                                    0.96 * greetingOpacity,
                                                  ),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 30,
                                              height: 1.08,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Transform.translate(
                                      offset: Offset(0, bodyTextTranslateY),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'You\'ve completed $totalSparksLit sparks so far.',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  color: scheme.onSurfaceVariant
                                                      .withOpacity(0.86),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          const SizedBox(height: 12),
                                          Opacity(
                                            opacity: quoteOpacity,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '"${quote.text}"',
                                                  style: theme
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                        color: scheme.onSurface
                                                            .withOpacity(0.65),
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        letterSpacing: 0.32,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '- ${quote.author}',
                                                  style: theme
                                                      .textTheme
                                                      .labelMedium
                                                      ?.copyWith(
                                                        color: scheme
                                                            .onSurfaceVariant
                                                            .withOpacity(0.58),
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        letterSpacing: 0.22,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Transform.translate(
                                      offset: Offset(0, ctaTranslateY),
                                      child: _RhythmPill(streak: streak),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  bool shouldRebuild(covariant _HomeHeroHeaderDelegate oldDelegate) {
    return userName != oldDelegate.userName ||
        totalSparksLit != oldDelegate.totalSparksLit ||
        streak != oldDelegate.streak ||
        lockCollapsed != oldDelegate.lockCollapsed ||
        minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight;
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.alphaBlend(
              const Color(0xFF8B5CF6).withOpacity(0.18),
              scheme.surface,
            ),
          ),
          child: Icon(
            Icons.bolt_rounded,
            size: 18,
            color: scheme.onSurface.withOpacity(0.94),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Sparkio',
          style: theme.textTheme.titleSmall?.copyWith(
            color: scheme.onSurface.withOpacity(0.92),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _RhythmPill extends StatelessWidget {
  const _RhythmPill({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dayWord = streak == 1 ? 'day' : 'days';
    final text = streak <= 0 ? 'Start your rhythm' : '$streak $dayWord rhythm';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Color.alphaBlend(
          Colors.white.withOpacity(0.09),
          scheme.surface.withOpacity(0.78),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant.withOpacity(0.82),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HeroTopActionButton extends StatefulWidget {
  const _HeroTopActionButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  State<_HeroTopActionButton> createState() => _HeroTopActionButtonState();
}

class _HeroTopActionButtonState extends State<_HeroTopActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconOpacity = _hovered ? 1.0 : 0.6;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        label: widget.semanticLabel,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: scheme.onSurface.withOpacity(iconOpacity),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
