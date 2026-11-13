import 'package:flutter/material.dart';

class HomeCardStyle {
  const HomeCardStyle._();

  static const radius = 20.0;
  static const borderRadius = BorderRadius.all(Radius.circular(radius));
  static const gap = 16.0;

  static BoxDecoration decoration(ColorScheme scheme) => BoxDecoration(
    color: scheme.surface,
    borderRadius: borderRadius,
    border: Border.all(color: scheme.outline.withOpacity(0.55)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(
          scheme.brightness == Brightness.dark ? 0.12 : 0.045,
        ),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static LinearGradient heroGradient(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(
          scheme.primary.withOpacity(isDark ? 0.1 : 0.06),
          scheme.surface,
        ),
        Color.alphaBlend(
          scheme.primary.withOpacity(isDark ? 0.025 : 0.012),
          scheme.surface,
        ),
      ],
    );
  }

  static Color brandForeground(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark
          ? Color.lerp(scheme.primary, scheme.onSurface, 0.3)!
          : scheme.primary;

  static Color secondaryForeground(ColorScheme scheme) =>
      Color.lerp(scheme.onSurfaceVariant, scheme.onSurface, 0.22)!;
}
