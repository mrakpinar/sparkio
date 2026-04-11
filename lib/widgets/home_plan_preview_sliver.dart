import 'package:flutter/material.dart';
import '../app_strings.dart';

class HomePlanPreviewSliver extends StatelessWidget {
  const HomePlanPreviewSliver({
    super.key,
    required this.doneCount,
    required this.nowLabel,
    this.nowXp,
    required this.laterCount,
    required this.onTap,
  });

  final int doneCount;
  final String? nowLabel;
  final int? nowXp;
  final int laterCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final safeDone = doneCount.clamp(0, 99);
    const timelineSlotWidth = 14.0;
    const statusWidth = 42.0;
    const rowSpacing = 10.0;

    Widget flowRow({
      required String status,
      required String value,
      required Color color,
      required double iconOpacity,
      required double statusOpacity,
      required double textOpacity,
      required IconData icon,
      double scale = 1.0,
      FontWeight textWeight = FontWeight.w600,
      bool glowIcon = false,
      double bottomSpacing = rowSpacing,
      String? trailingLabel,
    }) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomSpacing),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: timelineSlotWidth,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 13,
                      color: color.withOpacity(iconOpacity),
                      shadows: glowIcon
                          ? [
                              Shadow(
                                color: color.withOpacity(0.46),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: statusWidth,
                child: Text(
                  status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color.withOpacity(statusOpacity),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(textOpacity),
                    fontWeight: textWeight,
                    height: 1.15,
                  ),
                ),
              ),
              if (trailingLabel != null) ...[
                const SizedBox(width: 8),
                _PreviewXpBadge(label: trailingLabel, color: color),
              ],
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 6, 2, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.youreInMotion,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withOpacity(0.44),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.todaysRhythm,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withOpacity(0.84),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: scheme.onSurfaceVariant.withOpacity(0.44),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Positioned(
                        left: 6,
                        top: 16,
                        bottom: 12,
                        child: IgnorePointer(
                          child: Container(
                            width: 2,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF8B7CFF).withOpacity(0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          flowRow(
                            status: l10n.done,
                            value: safeDone == 0
                                ? l10n.justGettingStarted
                                : l10n.stepCount(safeDone),
                            color: const Color(0xFFA7D4C8),
                            iconOpacity: 0.6,
                            statusOpacity: 0.6,
                            textOpacity: 0.6,
                            icon: Icons.check_circle_rounded,
                          ),
                          flowRow(
                            status: l10n.now,
                            value: nowLabel ?? l10n.nothingWaitingRightNow,
                            color: const Color(0xFF7ED9FF),
                            iconOpacity: 1.0,
                            statusOpacity: 1.0,
                            textOpacity: 1.0,
                            icon: Icons.play_arrow_rounded,
                            scale: 1.05,
                            textWeight: FontWeight.w500,
                            glowIcon: true,
                            trailingLabel: nowXp == null ? null : '+$nowXp XP',
                          ),
                          flowRow(
                            status: l10n.later,
                            value: l10n.optionalNoPressure,
                            color: scheme.onSurfaceVariant.withOpacity(0.56),
                            iconOpacity: 0.35,
                            statusOpacity: 0.35,
                            textOpacity: 0.35,
                            icon: Icons.circle_outlined,
                            bottomSpacing: 0,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewXpBadge extends StatelessWidget {
  const _PreviewXpBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 11, color: color.withOpacity(0.92)),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.92),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
