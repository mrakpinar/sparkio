import 'package:flutter/material.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceVariant.withOpacity(0.6);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _SkeletonBox(width: 44, height: 44, radius: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _SkeletonBox(width: 140, height: 16),
                      SizedBox(height: 8),
                      _SkeletonBox(width: 100, height: 12),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const _SkeletonBox(width: 34, height: 34, radius: 12),
              ],
            ),
            const SizedBox(height: 16),
            const _SkeletonBox(width: double.infinity, height: 170, radius: 20),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: _SkeletonBox(height: 58, radius: 16)),
                SizedBox(width: 12),
                Expanded(child: _SkeletonBox(height: 58, radius: 16)),
              ],
            ),
            const SizedBox(height: 20),
            const _SkeletonBox(width: 120, height: 14),
            const SizedBox(height: 12),
            ...List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _SkeletonBox(height: 96, radius: 18),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 120,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width = double.infinity,
    this.height = 12,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
