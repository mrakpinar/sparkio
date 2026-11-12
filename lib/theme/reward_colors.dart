import 'package:flutter/material.dart';

/// Shared warm accents for earned progress, XP and streaks.
class RewardColors {
  const RewardColors._();

  static Color accent(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark
          ? const Color(0xFFFF9B6B)
          : const Color(0xFFE85F31);

  static Color foreground(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark
          ? const Color(0xFFFFC5A5)
          : const Color(0xFFAC3C1F);

  static Color background(ColorScheme scheme) => Color.alphaBlend(
    accent(scheme).withOpacity(0.12),
    scheme.surface,
  );
}
