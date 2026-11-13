import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_strings.dart';
import '../theme/home_card_style.dart';
import 'sparkio_logo.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    required this.userName,
    required this.isDark,
    required this.streak,
    required this.onOpenProfile,
    required this.onOpenStats,
    required this.onOpenMenu,
    this.level = 1,
    this.levelProgress = 0,
  });

  final String userName;
  final bool isDark;
  final int streak;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenMenu;
  final int level;
  final double levelProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final cleanName = userName.trim();
    final displayName = cleanName.isEmpty ? l10n.friend : cleanName;
    final now = DateTime.now();
    final greeting = l10n.greetingForHour(now.hour);
    final slogan = l10n.dailyEncouragement(now);
    final textScaler = MediaQuery.textScalerOf(context);
    final compact =
        MediaQuery.sizeOf(context).width < 380 ||
        textScaler.scale(16) > 21;
    final toolbarHeight =
        (textScaler.scale(13) * 1.2 + textScaler.scale(17.5) * 1.1 + 16)
            .clamp(56.0, double.infinity)
            .toDouble();
    final sloganStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 13,
      height: 1.35,
      fontWeight: FontWeight.w400,
      color: Color.lerp(scheme.onSurfaceVariant, scheme.onSurface, 0.45),
    );
    // Use the full width below the toolbar, aligned with the name at 76px.
    final sloganPainter = TextPainter(
      text: TextSpan(text: slogan, style: sloganStyle),
      textDirection: Directionality.of(context),
      textScaler: textScaler,
      locale: Localizations.localeOf(context),
    )..layout(
      maxWidth: (MediaQuery.sizeOf(context).width - 76 - 16)
          .clamp(1.0, double.infinity).toDouble(),
    );
    final bottomHeight = sloganPainter.height + 8 + (compact ? 52 : 0);
    sloganPainter.dispose();
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LevelBadge(
          level: level,
          progress: levelProgress,
          onTap: onOpenProfile,
        ),
        const SizedBox(width: 4),
        _HeaderActionButton(
          tooltip: l10n.stats,
          onTap: onOpenStats,
          child: Icon(Icons.bar_chart_rounded, size: 20, color: scheme.onSurface),
        ),
        const SizedBox(width: 4),
        _HeaderActionButton(
          tooltip: l10n.menu,
          onTap: onOpenMenu,
          child: Icon(Icons.menu_rounded, size: 20, color: scheme.onSurface),
        ),
        const SizedBox(width: 12),
      ],
    );

    return SliverAppBar(
      systemOverlayStyle: (isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: theme.scaffoldBackgroundColor,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      floating: true,
      snap: true,
      pinned: false,
      centerTitle: false,
      toolbarHeight: toolbarHeight,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      flexibleSpace: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface.withOpacity(isDark ? 0.72 : 0.7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: scheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      title: SizedBox(
        height: toolbarHeight - 8,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpenProfile,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox.square(
                    dimension: 48,
                    child: Center(child: SparkioLogo(size: 44)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 13,
                            height: 1.2,
                            fontWeight: FontWeight.w400,
                            color: HomeCardStyle.secondaryForeground(scheme),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 17.5,
                            height: 1.1,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: compact ? const [SizedBox.shrink()] : [controls],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(bottomHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 76, end: 16, bottom: 8,
              ),
              child: Text(slogan, style: sloganStyle),
            ),
            if (compact)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Align(alignment: Alignment.centerRight, child: controls),
              ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({
    required this.level,
    required this.progress,
    required this.onTap,
  });

  final int level;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final label = l10n.levelLabel(level, l10n.levelTitle(level));
    return _HeaderActionButton(
      tooltip: label,
      onTap: onTap,
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.trf('Lv {level}', {'level': level}),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: HomeCardStyle.brandForeground(scheme),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 22,
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0).toDouble(),
                  minHeight: 2,
                  borderRadius: BorderRadius.circular(2),
                  color: HomeCardStyle.brandForeground(scheme),
                  backgroundColor: scheme.primary.withOpacity(0.26),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatefulWidget {
  const _HeaderActionButton({
    required this.child,
    required this.tooltip,
    required this.onTap,
  });

  final Widget child;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_HeaderActionButton> createState() => _HeaderActionButtonState();
}

class _HeaderActionButtonState extends State<_HeaderActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Tooltip(
      message: widget.tooltip,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            borderRadius: BorderRadius.circular(14),
            child: SizedBox.square(
              dimension: 48,
              child: Center(
                child: AnimatedScale(
                  duration: Duration(milliseconds: reduceMotion ? 0 : 160),
                  curve: Curves.easeOutCubic,
                  scale: _pressed ? 0.96 : 1,
                  child: Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Color.alphaBlend(
                        scheme.onSurface.withOpacity(
                          scheme.brightness == Brightness.dark ? 0.07 : 0.04,
                        ),
                        scheme.surface,
                      ),
                      border: Border.all(
                        color: scheme.outline.withOpacity(0.6),
                      ),
                    ),
                    child: Center(child: widget.child),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
