import 'package:flutter/material.dart';

/// The app logo, rendered from assets/icon/sparkio_svg.svg.
class SparkioLogo extends StatelessWidget {
  const SparkioLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/sparkio_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Sparkio',
    );
  }
}
