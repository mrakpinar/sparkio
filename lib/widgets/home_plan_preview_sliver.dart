import 'package:flutter/material.dart';

import '../app_strings.dart';
import '../theme/home_card_style.dart';
import 'home_card_entrance.dart';

class HomePlanPreviewSliver extends StatelessWidget {
  const HomePlanPreviewSliver({
    super.key,
    required this.laterCount,
    required this.onTap,
  });

  final int laterCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final safeLater = laterCount.clamp(0, 99);

    return SliverToBoxAdapter(
      child: HomeCardEntrance(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DecoratedBox(
            decoration: HomeCardStyle.decoration(scheme),
            child: Material(
              color: Colors.transparent,
              borderRadius: HomeCardStyle.borderRadius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                borderRadius: HomeCardStyle.borderRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.list_alt_rounded,
                          size: 22,
                          color: HomeCardStyle.brandForeground(scheme),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.todaysRhythm,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.otherTasksTodayLabel(safeLater),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: HomeCardStyle.secondaryForeground(scheme),
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
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
