import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1628) : scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : scheme.shadow.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.14)
                      : scheme.onSurface.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'Boost center',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? Colors.white.withOpacity(0.95)
                    : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'If you want a little extra support today.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? Colors.white.withOpacity(0.64)
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            const _SectionHeader(
              title: 'Premium',
              subtitle: 'Long-term support',
            ),
            const SizedBox(height: 8),
            _PremiumPlanCard(
              premiumActive: premiumActive,
              premiumStatus: premiumStatus,
              onOpenSubscribe: onOpenSubscribe,
            ),
            const SizedBox(height: 26),
            const _SectionHeader(
              title: 'Today boosts',
              subtitle: 'Short unlocks for now',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StaggerIn(
                    delayMs: 0,
                    child: _TodayBoostCard(
                      title: '30 min Premium',
                      subtitle: 'Temporary premium access.',
                      ctaLabel: premiumActive
                          ? 'Active now'
                          : (rewardBusy
                                ? 'Preparing ad...'
                                : 'Unlock by watching a short ad'),
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
                      title: 'No ads for 1 day',
                      subtitle: 'Ad-free until tomorrow.',
                      ctaLabel: noAdsActive
                          ? 'Active now'
                          : (rewardBusy
                                ? 'Preparing ad...'
                                : 'Unlock by watching a short ad'),
                      onPressed: noAdsActive
                          ? null
                          : (rewardBusy ? null : onWatchNoAds),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _SectionHeader(
              title: 'Need a little help today?',
              subtitle: 'Optional support tools',
              subdued: true,
            ),
            const SizedBox(height: 8),
            _OptionalActionButton(
              icon: Icons.add_circle_outline_rounded,
              label: 'Get one extra task',
              tone: const Color(0xFF22C55E),
              onPressed: rewardBusy ? null : onExtraTask,
            ),
            const SizedBox(height: 8),
            _OptionalActionButton(
              icon: Icons.local_fire_department_rounded,
              label: 'Recover streak',
              tone: const Color(0xFFF97316),
              onPressed: rewardBusy ? null : onRecoverStreak,
            ),
          ],
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
            fontWeight: FontWeight.w700,
            color: isDark
                ? Colors.white.withOpacity(subdued ? 0.82 : 0.92)
                : scheme.onSurface.withOpacity(subdued ? 0.84 : 1),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? Colors.white.withOpacity(subdued ? 0.48 : 0.56)
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
    final foundationSurface = Color.alphaBlend(
      premiumAccent.withOpacity(isDark ? 0.08 : 0.05),
      scheme.surface,
    );

    return Container(
      decoration: BoxDecoration(
        color: foundationSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outline.withOpacity(isDark ? 0.072 : 0.054),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: premiumAccent.withOpacity(0.055),
            blurRadius: 10,
            spreadRadius: -8,
            offset: const Offset(0, 6),
          ),
        ],
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
                      premiumAccent.withOpacity(isDark ? 0.09 : 0.07),
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
                    color: scheme.surface.withOpacity(isDark ? 0.42 : 0.72),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 22,
                    color: premiumAccent.withOpacity(0.86),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium plan',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white.withOpacity(0.95)
                              : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        premiumActive
                            ? _friendlyStatus(
                                active: true,
                                status: premiumStatus,
                                idleLabel: 'Active now',
                              )
                            : 'Unlock all premium support options.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Colors.white.withOpacity(0.64)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onOpenSubscribe,
                  style: FilledButton.styleFrom(
                    backgroundColor: premiumAccent.withOpacity(0.82),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    premiumActive ? 'Manage' : 'See plans',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w400,
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
        decoration: BoxDecoration(
          color: isDark
              ? Color.alphaBlend(
                  scheme.primary.withOpacity(0.06),
                  const Color(0xFF0D1B2E).withOpacity(0.78),
                )
              : scheme.surfaceContainerHighest.withOpacity(0.46),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (showGlow)
              BoxShadow(
                color: scheme.primary.withOpacity(isDark ? 0.24 : 0.16),
                blurRadius: 16,
                spreadRadius: -5,
                offset: Offset.zero,
              ),
          ],
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
                color: isDark
                    ? Colors.white.withOpacity(0.94)
                    : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : scheme.onSurfaceVariant,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  if (_actionHovered && widget.onPressed != null)
                    BoxShadow(
                      color: scheme.primary.withOpacity(isDark ? 0.14 : 0.1),
                      blurRadius: 12,
                      spreadRadius: -7,
                      offset: Offset.zero,
                    ),
                ],
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
                          color: scheme.onSurfaceVariant.withOpacity(
                            widget.onPressed != null ? 0.54 : 0.46,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            widget.ctaLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w400,
                              color: widget.onPressed != null
                                  ? (isDark
                                        ? Colors.white.withOpacity(0.64)
                                        : scheme.onSurface.withOpacity(0.66))
                                  : scheme.onSurfaceVariant.withOpacity(0.58),
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
    final neutralSurface = isDark
        ? Color.alphaBlend(
            Colors.white.withOpacity(0.01),
            const Color(0xFF0D1B2E).withOpacity(0.58),
          )
        : scheme.surface.withOpacity(0.72);
    final calmTone = Color.alphaBlend(
      tone.withOpacity(0.16),
      scheme.onSurfaceVariant.withOpacity(0.84),
    );

    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          foregroundColor: calmTone.withOpacity(0.92),
          backgroundColor: neutralSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: scheme.outline.withOpacity(isDark ? 0.03 : 0.02),
              width: 0.7,
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
  final raw = status.trim();
  final lower = raw.toLowerCase();

  if (active) {
    if (raw.isEmpty || lower == 'inactive' || lower == 'expired') {
      return 'Active now';
    }
    return 'Active - $raw left';
  }

  if (raw.isNotEmpty && lower != 'inactive' && lower != 'expired') {
    return raw;
  }
  return idleLabel;
}
