import 'package:flutter/material.dart';

import 'home_all_done_bits.dart';
import 'pulse_icon.dart';

class HomeAllDoneSliver extends StatelessWidget {
  const HomeAllDoneSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary.withOpacity(0.16),
                scheme.secondary.withOpacity(0.08),
                scheme.surface.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: scheme.outline.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -8,
                right: -8,
                child: MiniConfetti(
                  primary: scheme.primary,
                  secondary: scheme.secondary,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main content row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              scheme.primary.withOpacity(0.25),
                              scheme.secondary.withOpacity(0.18),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: scheme.primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: PulseIcon(
                          icon: Icons.check_circle_rounded,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              'All done for today',
                              style: text.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Great consistency. Keep the momentum.',
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Accent line
                  Container(
                    width: 80,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withOpacity(0.8),
                          scheme.secondary.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description text
                  Text(
                    'Take a breather. Your sparks are complete -- see you tomorrow.',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(0.85),
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Achievement pills
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _AllDonePill(
                        label: 'Streak +1',
                        icon: Icons.local_fire_department_rounded,
                      ),
                      _AllDonePill(
                        label: 'Daily goal hit',
                        icon: Icons.task_alt_rounded,
                      ),
                      _AllDonePill(
                        label: 'Progress saved',
                        icon: Icons.bookmark_rounded,
                      ),
                    ],
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

class _AllDonePill extends StatelessWidget {
  const _AllDonePill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: scheme.primary),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
