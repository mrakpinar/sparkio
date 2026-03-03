import 'package:flutter/material.dart';

import '../app_strings.dart';
import '../services/locale_service.dart';

BoxDecoration _premiumNeoGlassDecoration(
  ColorScheme scheme, {
  Color tint = const Color(0xFF34D5FF),
  double radius = 16,
  double tintOpacity = 0.2,
  double surfaceOpacity = 0.88,
}) {
  final isDark = scheme.brightness == Brightness.dark;
  final baseSurface = isDark
      ? const Color(0xFF101827).withOpacity(surfaceOpacity)
      : Color.alphaBlend(
          Colors.white.withOpacity(0.78),
          scheme.surface.withOpacity(surfaceOpacity),
        );
  final base = Color.alphaBlend(
    (isDark ? Colors.black : Colors.white).withOpacity(isDark ? 0.34 : 0.28),
    baseSurface,
  );
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(tint.withOpacity(tintOpacity), base),
        Color.alphaBlend(const Color(0xFF8B5CF6).withOpacity(0.08), base),
      ],
    ),
    border: Border.all(
      color: (isDark ? Colors.white : scheme.outline).withOpacity(
        isDark ? 0.08 : 0.28,
      ),
      width: 0.85,
    ),
  );
}

BoxDecoration _premiumSheetSurfaceDecoration(ColorScheme scheme) {
  final isDark = scheme.brightness == Brightness.dark;
  final topColor = isDark
      ? const Color(0xFF101A2A)
      : Color.alphaBlend(
          const Color(0xFFEEF4FF).withOpacity(0.86),
          scheme.surface,
        );
  final bottomColor = isDark
      ? const Color(0xFF111B2B)
      : Color.alphaBlend(
          const Color(0xFFF7FAFF).withOpacity(0.92),
          scheme.surface,
        );

  return BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, bottomColor],
    ),
    border: Border.all(
      color: (isDark ? Colors.white : scheme.outline).withOpacity(
        isDark ? 0.08 : 0.16,
      ),
      width: 0.9,
    ),
    boxShadow: [
      BoxShadow(
        color: (isDark ? Colors.black : const Color(0xFF8B92A8)).withOpacity(
          isDark ? 0.22 : 0.1,
        ),
        blurRadius: 24,
        spreadRadius: -10,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

class PremiumPerksSheet extends StatelessWidget {
  final bool rewardBusy;
  final bool premiumActive;
  final bool noAdsActive;
  final String premiumStatus;
  final String noAdsStatus;
  final VoidCallback onWatchPremium;
  final VoidCallback onWatchNoAds;
  final VoidCallback onOpenSubscribe;
  final VoidCallback onExtraTask;
  final VoidCallback onRecoverStreak;

  const PremiumPerksSheet({
    super.key,
    required this.rewardBusy,
    required this.premiumActive,
    required this.noAdsActive,
    required this.premiumStatus,
    required this.noAdsStatus,
    required this.onWatchPremium,
    required this.onWatchNoAds,
    required this.onOpenSubscribe,
    required this.onExtraTask,
    required this.onRecoverStreak,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final maxSheetHeight = (media.size.height * 0.8).clamp(
      0.0,
      media.size.height - media.padding.top - 40,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        decoration: _premiumSheetSurfaceDecoration(scheme).copyWith(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(isDark ? 0.03 : 0.05),
                          Colors.transparent,
                          Colors.black.withOpacity(isDark ? 0.03 : 0.01),
                        ],
                        stops: const [0.0, 0.18, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                top: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 1,
                    color: Colors.white.withOpacity(isDark ? 0.05 : 0.22),
                  ),
                ),
              ),
              Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withOpacity(
                          isDark ? 0.16 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: isDark
                                  ? const Color(0xFF171B31)
                                  : Color.alphaBlend(
                                      const Color(0xFFF5F7FF).withOpacity(0.94),
                                      scheme.surface,
                                    ),
                              border: Border.all(
                                color: (isDark ? Colors.white : scheme.outline)
                                    .withOpacity(isDark ? 0.08 : 0.18),
                                width: 0.85,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: _premiumNeoGlassDecoration(
                                    scheme,
                                    tint: const Color(0xFF8B7CFF),
                                    radius: 14,
                                    tintOpacity: 0.16,
                                    surfaceOpacity: 0.94,
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Color(0xFF8B7CFF),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.tr('Boost center'),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: scheme.onSurface
                                                  .withOpacity(0.95),
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.tr(
                                          'If you want a little extra support today.',
                                        ),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant
                                                  .withOpacity(0.74),
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SectionHeader(
                            title: l10n.tr('Premium'),
                            subtitle: l10n.tr('Long-term support'),
                          ),
                          const SizedBox(height: 8),
                          _PremiumPlanCard(
                            premiumActive: premiumActive,
                            premiumStatus: premiumStatus,
                            onOpenSubscribe: onOpenSubscribe,
                          ),
                          const SizedBox(height: 22),
                          _SectionHeader(
                            title: l10n.tr('Today boosts'),
                            subtitle: l10n.tr('Short unlocks for now'),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _StaggerIn(
                                  delayMs: 0,
                                  child: _TodayBoostCard(
                                    title: l10n.tr('30 min Premium'),
                                    subtitle: l10n.tr(
                                      'Temporary premium access.',
                                    ),
                                    ctaLabel: premiumActive
                                        ? l10n.tr('Active now')
                                        : (rewardBusy
                                              ? l10n.tr('Preparing ad...')
                                              : l10n.tr(
                                                  'Unlock by watching a short ad',
                                                )),
                                    onPressed: premiumActive
                                        ? null
                                        : (rewardBusy ? null : onWatchPremium),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StaggerIn(
                                  delayMs: 30,
                                  child: _TodayBoostCard(
                                    title: l10n.tr('No ads for 1 day'),
                                    subtitle: l10n.tr(
                                      'Ad-free until tomorrow.',
                                    ),
                                    ctaLabel: noAdsActive
                                        ? l10n.tr('Active now')
                                        : (rewardBusy
                                              ? l10n.tr('Preparing ad...')
                                              : l10n.tr(
                                                  'Unlock by watching a short ad',
                                                )),
                                    onPressed: noAdsActive
                                        ? null
                                        : (rewardBusy ? null : onWatchNoAds),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _SectionHeader(
                            title: l10n.tr('Need a little help today?'),
                            subtitle: l10n.tr('Optional support tools'),
                            subdued: true,
                          ),
                          const SizedBox(height: 8),
                          _OptionalActionButton(
                            icon: Icons.add_circle_outline_rounded,
                            label: l10n.tr('Get one extra task'),
                            tone: const Color(0xFF22C55E),
                            onPressed: rewardBusy ? null : onExtraTask,
                          ),
                          const SizedBox(height: 8),
                          _OptionalActionButton(
                            icon: Icons.local_fire_department_rounded,
                            label: l10n.tr('Recover streak'),
                            tone: const Color(0xFFF97316),
                            onPressed: rewardBusy ? null : onRecoverStreak,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.subdued = false,
  });

  final String title;
  final String subtitle;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withOpacity(subdued ? 0.72 : 0.8)
                : scheme.onSurface.withOpacity(subdued ? 0.78 : 0.88),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? Colors.white.withOpacity(subdued ? 0.62 : 0.74)
                : scheme.onSurfaceVariant.withOpacity(subdued ? 0.78 : 0.9),
          ),
        ),
      ],
    );
  }
}

class _PremiumPlanCard extends StatelessWidget {
  const _PremiumPlanCard({
    required this.premiumActive,
    required this.premiumStatus,
    required this.onOpenSubscribe,
  });

  final bool premiumActive;
  final String premiumStatus;
  final VoidCallback onOpenSubscribe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const premiumAccent = Color(0xFF6E5BFF);
    const neonCyan = Color(0xFF5DE1FF);
    final titleColor = isDark
        ? Colors.white.withOpacity(0.98)
        : scheme.onSurface.withOpacity(0.96);
    final bodyColor = isDark
        ? Colors.white.withOpacity(0.82)
        : scheme.onSurface.withOpacity(0.78);
    final secondaryColor = isDark
        ? Colors.white.withOpacity(0.58)
        : scheme.onSurfaceVariant.withOpacity(0.82);

    return Container(
      decoration: _premiumNeoGlassDecoration(
        scheme,
        tint: premiumAccent,
        radius: 16,
        tintOpacity: isDark ? 0.12 : 0.1,
        surfaceOpacity: isDark ? 0.96 : 0.96,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: RadialGradient(
                    center: const Alignment(-0.8, -1.0),
                    radius: 1.16,
                    colors: [
                      premiumAccent.withOpacity(isDark ? 0.18 : 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        neonCyan.withOpacity(0.18),
                        premiumAccent.withOpacity(0.12),
                      ],
                    ),
                    border: Border.all(
                      color: neonCyan.withOpacity(isDark ? 0.52 : 0.34),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: neonCyan.withOpacity(0.34),
                        blurRadius: 18,
                        spreadRadius: -3,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: premiumAccent.withOpacity(0.24),
                        blurRadius: 16,
                        spreadRadius: -4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/in_app_icons/premium.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      color: neonCyan,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.tr('Premium plan'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        premiumActive
                            ? _friendlyStatus(
                                active: true,
                                status: premiumStatus,
                                idleLabel: context.l10n.tr('Active now'),
                              )
                            : context.l10n.tr(
                                'Auto-renewing monthly/yearly subscription.',
                              ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: bodyColor,
                          fontWeight: FontWeight.w600,
                          height: 1.28,
                        ),
                      ),
                      if (!premiumActive) ...[
                        const SizedBox(height: 5),
                        Text(
                          context.l10n.tr(
                            'Cancel anytime in Google Play > Payments & subscriptions.',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryColor,
                            fontWeight: FontWeight.w400,
                            height: 1.34,
                            letterSpacing: 0.05,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onOpenSubscribe,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: const Color(0xFF8B5CF6).withOpacity(0.34),
                  ),
                  child: Text(
                    premiumActive
                        ? context.l10n.tr('Manage')
                        : context.l10n.tr('See plans'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.94),
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

class _TodayBoostCard extends StatefulWidget {
  const _TodayBoostCard({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback? onPressed;

  @override
  State<_TodayBoostCard> createState() => _TodayBoostCardState();
}

class _TodayBoostCardState extends State<_TodayBoostCard> {
  bool _hovered = false;
  bool _actionHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final showGlow = _hovered && widget.onPressed != null;
    final cardTint = showGlow
        ? const Color(0xFF34D5FF)
        : const Color(0xFF8B5CF6);
    final titleColor = isDark
        ? Colors.white.withOpacity(0.965)
        : scheme.onSurface.withOpacity(0.95);
    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.72)
        : scheme.onSurfaceVariant.withOpacity(0.94);

    return MouseRegion(
      onEnter: (_) {
        if (_hovered) return;
        setState(() => _hovered = true);
      },
      onExit: (_) {
        if (!_hovered) return;
        setState(() => _hovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(11, 9, 11, 8),
        transform: Matrix4.translationValues(0, showGlow ? -1 : 0, 0),
        decoration: _premiumNeoGlassDecoration(
          scheme,
          tint: cardTint,
          radius: 14,
          tintOpacity: showGlow ? 0.18 : 0.13,
          surfaceOpacity: isDark ? 0.985 : 0.975,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: subtitleColor,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOutCubic,
              decoration: _premiumNeoGlassDecoration(
                scheme,
                tint: _actionHovered ? const Color(0xFF34D5FF) : cardTint,
                radius: 10,
                tintOpacity: _actionHovered ? 0.15 : 0.11,
                surfaceOpacity: 0.985,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onHover: (value) {
                    if (value == _actionHovered) return;
                    setState(() => _actionHovered = value);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.onPressed != null
                              ? Icons.play_circle_rounded
                              : Icons.check_circle_rounded,
                          size: 14,
                          color: widget.onPressed != null
                              ? Colors.white.withOpacity(0.76)
                              : scheme.onSurfaceVariant.withOpacity(0.52),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            widget.ctaLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: widget.onPressed != null
                                  ? (isDark
                                        ? Colors.white.withOpacity(0.9)
                                        : scheme.onSurface.withOpacity(0.88))
                                  : scheme.onSurfaceVariant.withOpacity(0.72),
                            ),
                          ),
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
    );
  }
}

class _StaggerIn extends StatefulWidget {
  const _StaggerIn({required this.delayMs, required this.child});

  final int delayMs;
  final Widget child;

  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.03),
        child: widget.child,
      ),
    );
  }
}

class _OptionalActionButton extends StatelessWidget {
  const _OptionalActionButton({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final calmTone = Color.alphaBlend(
      tone.withOpacity(0.36),
      scheme.onSurface.withOpacity(0.96),
    );
    final buttonBackground = Color.alphaBlend(
      tone.withOpacity(isDark ? 0.14 : 0.12),
      Color.alphaBlend(
        (isDark ? Colors.black : Colors.white).withOpacity(
          isDark ? 0.28 : 0.28,
        ),
        (isDark ? const Color(0xFF101726) : theme.colorScheme.surface)
            .withOpacity(isDark ? 0.96 : 0.94),
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color.alphaBlend(
              tone.withOpacity(isDark ? 0.3 : 0.2),
              (isDark ? Colors.white : scheme.outline).withOpacity(
                isDark ? 0.08 : 0.16,
              ),
            ),
            width: 0.7,
          ),
        ),
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            foregroundColor: calmTone,
            backgroundColor: buttonBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

String _friendlyStatus({
  required bool active,
  required String status,
  required String idleLabel,
}) {
  final lang = LocaleService.instance.effectiveLanguageCode;
  final raw = status.trim();
  final lower = raw.toLowerCase();

  if (active) {
    if (raw.isEmpty || lower == 'inactive' || lower == 'expired') {
      return AppLocalizations.lookup(lang, 'Active now');
    }
    return 'Active - $raw left';
  }

  if (raw.isNotEmpty && lower != 'inactive' && lower != 'expired') {
    return raw;
  }
  return idleLabel;
}
