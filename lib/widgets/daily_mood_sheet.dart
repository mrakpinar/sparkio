import 'dart:math';

import 'package:flutter/material.dart';

import '../app_strings.dart';

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

class _DailyMoodSheetState extends State<DailyMoodSheet> {
  static String? _lastSuggestedMood;
  late final String _featuredMood = _pickFeaturedMood();

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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final maxSheetHeight = min(
      media.size.height * 0.78,
      media.size.height - media.padding.top - 44,
    );
    final horizontalPadding = media.size.width < 360 ? 16.0 : 20.0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outline,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: IconButton(
                          onPressed: widget.onSkip,
                          icon: const Icon(Icons.close_rounded),
                          color: scheme.onSurfaceVariant,
                          tooltip: l10n.tr('Close'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.tr("Let's  reset your day."),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.tr(
                          "Pick what you need. We'll handle the rest.",
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _MoodOption(
                        title: l10n.tr('Feeling stressed'),
                        subtitle: l10n.tr(
                          'Slow down. 2 minutes is enough.',
                        ),
                        outcome: l10n.tr('2-minute breathing reset'),
                        iconAsset: 'assets/in_app_icons/feeling_stressed.png',
                        accent: isDark
                            ? const Color(0xFF90CDBB)
                            : const Color(0xFF386E60),
                        isFeatured: _featuredMood == 'stressed',
                        onTap: () => widget.onSelect('stressed'),
                      ),
                      const SizedBox(height: 16),
                      _MoodOption(
                        title: l10n.tr('Low energy'),
                        subtitle: l10n.tr(
                          "Let's wake your brain up.",
                        ),
                        outcome: l10n.tr('2-minute energy reset'),
                        iconAsset: 'assets/in_app_icons/low_battery.png',
                        accent: isDark
                            ? const Color(0xFFD9B47C)
                            : const Color(0xFF895F2F),
                        isFeatured: _featuredMood == 'low_energy',
                        onTap: () => widget.onSelect('low_energy'),
                      ),
                      const SizedBox(height: 16),
                      _MoodOption(
                        title: l10n.tr('Need focus'),
                        subtitle: l10n.tr('One small win. Ready?'),
                        outcome: l10n.tr('2-minute focus reset'),
                        iconAsset: 'assets/in_app_icons/need_focus.png',
                        accent: isDark
                            ? const Color(0xFFB6A6E6)
                            : const Color(0xFF69539C),
                        isFeatured: _featuredMood == 'focus',
                        onTap: () => widget.onSelect('focus'),
                      ),
                    ],
                  ),
                ),
              ),
              // Reserve the footer's actual scaled height outside the list.
              // SafeArea also keeps the button clear of system navigation.
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    scheme.surfaceVariant.withOpacity(0.6),
                    scheme.surface,
                  ),
                  border: Border(
                    top: BorderSide(color: scheme.outline.withOpacity(0.8)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  minimum: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      20,
                      horizontalPadding,
                      0,
                    ),
                    child: OutlinedButton(
                      onPressed: widget.onSkip,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.onSurface,
                        backgroundColor: scheme.surface,
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        side: BorderSide(color: scheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(
                        l10n.tr('Maybe later'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodOption extends StatefulWidget {
  const _MoodOption({
    required this.title,
    required this.subtitle,
    required this.outcome,
    required this.iconAsset,
    required this.accent,
    this.isFeatured = false,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String outcome;
  final String iconAsset;
  final Color accent;
  final bool isFeatured;
  final VoidCallback onTap;

  @override
  State<_MoodOption> createState() => _MoodOptionState();
}

class _MoodOptionState extends State<_MoodOption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final cardColor = Color.alphaBlend(
      widget.accent.withOpacity(isDark ? 0.07 : 0.035),
      scheme.surface,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: scheme.outline.withOpacity(0.7)),
    );

    return AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) {
        final press = Curves.easeOutCubic.transform(_pressController.value);
        return Transform.scale(scale: 1 - (0.012 * press), child: child);
      },
      child: Semantics(
        button: true,
        child: Material(
          color: cardColor,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _handleTap,
            onTapDown: _onTapDown,
            onTapCancel: _onTapCancel,
            mouseCursor: SystemMouseCursors.click,
            customBorder: shape,
            hoverColor: widget.accent.withOpacity(0.04),
            focusColor: widget.accent.withOpacity(0.1),
            splashColor: widget.accent.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stackContent = constraints.maxWidth < 260 ||
                      MediaQuery.textScalerOf(context).scale(16) >= 24;
                  final icon = Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.accent.withOpacity(isDark ? 0.14 : 0.09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(
                      widget.iconAsset,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                      color: widget.accent,
                      colorBlendMode: BlendMode.srcIn,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                  );
                  final details = _buildDetails(context);
                  final arrow = Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                    textDirection: Directionality.of(context),
                  );

                  if (stackContent) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              icon,
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: arrow,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        details,
                      ],
                    );
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 100),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        icon,
                        const SizedBox(width: 12),
                        Expanded(child: details),
                        const SizedBox(width: 8),
                        arrow,
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final suggestion = Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        context.l10n.tr('Suggested for you'),
        style: theme.textTheme.labelSmall?.copyWith(
          color: widget.accent,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                Icons.schedule_rounded,
                size: 16,
                color: widget.accent,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.outcome,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        if (widget.isFeatured) suggestion,
      ],
    );
  }
}
