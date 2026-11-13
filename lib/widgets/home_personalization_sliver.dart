import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_strings.dart';
import '../theme/home_card_style.dart';

class HomePersonalizationSliver extends StatelessWidget {
  const HomePersonalizationSliver({
    super.key,
    required this.selectedMood,
    required this.onSelectMood,
  });

  final int? selectedMood;
  final ValueChanged<int>? onSelectMood;

  static const _moods = <(int, String, String)>[
    (1, '😖', 'Feeling very low'),
    (2, '😕', 'Feeling low'),
    (3, '😐', 'Feeling okay'),
    (4, '🙂', 'Feeling good'),
    (5, '🤩', 'Feeling great'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final hasCheckIn = selectedMood != null &&
        selectedMood! >= 1 && selectedMood! <= 5;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasCheckIn) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      l10n.tr('How are you feeling today?'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.tr('Optional check-in'),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: HomeCardStyle.secondaryForeground(scheme),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < _moods.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _moodButton(context, _moods[i]),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: HomeCardStyle.gap),
          ],
        ),
      ),
    );
  }

  Widget _moodButton(BuildContext context, (int, String, String) mood) {
    final scheme = Theme.of(context).colorScheme;
    final selected = selectedMood == mood.$1;
    final label = context.l10n.tr(mood.$3);
    void select() {
      HapticFeedback.selectionClick();
      onSelectMood?.call(mood.$1);
    }

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      enabled: onSelectMood != null,
      onTap: onSelectMood == null ? null : select,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withOpacity(0.12)
                : scheme.onSurfaceVariant.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? HomeCardStyle.brandForeground(scheme)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onSelectMood == null ? null : select,
              excludeFromSemantics: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: ExcludeSemantics(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(mood.$2, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
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
