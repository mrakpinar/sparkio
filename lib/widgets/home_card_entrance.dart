import 'package:flutter/material.dart';

/// A brief entrance that keeps its progress across ordinary parent rebuilds.
class HomeCardEntrance extends StatelessWidget {
  const HomeCardEntrance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: reduceMotion ? 0 : 260),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        final progress = reduceMotion ? 1.0 : value;
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - progress)),
            child: child,
          ),
        );
      },
    );
  }
}
