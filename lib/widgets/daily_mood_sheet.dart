import 'package:flutter/material.dart';

class DailyMoodSheet extends StatelessWidget {
  const DailyMoodSheet({
    super.key,
    required this.onSelect,
    required this.onSkip,
  });

  final ValueChanged<String> onSelect;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.surface, scheme.surfaceContainerHighest],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary,
                          scheme.primary.withOpacity(0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.waving_hand_rounded,
                      color: scheme.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How are you feeling?',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "We'll tailor one spark for you.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: onSkip,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mood options
              _MoodOption(
                value: 'stressed',
                title: 'Feeling stressed',
                subtitle: 'Pick a calmer spark.',
                icon: Icons.spa_rounded,
                accent: const Color(0xFF38BDF8),
                onTap: () => onSelect('stressed'),
              ),
              const SizedBox(height: 12),
              _MoodOption(
                value: 'low_energy',
                title: 'Low energy',
                subtitle: 'Something light to reboot.',
                icon: Icons.battery_2_bar_rounded,
                accent: const Color(0xFF60A5FA),
                onTap: () => onSelect('low_energy'),
              ),
              const SizedBox(height: 12),
              _MoodOption(
                value: 'focus',
                title: 'Need focus',
                subtitle: 'A clear, quick win.',
                icon: Icons.center_focus_strong_rounded,
                accent: const Color(0xFF22D3EE),
                onTap: () => onSelect('focus'),
              ),
              const SizedBox(height: 20),

              // Skip button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSkip,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: scheme.outline.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Not now',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodOption extends StatefulWidget {
  const _MoodOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_MoodOption> createState() => _MoodOptionState();
}

class _MoodOptionState extends State<_MoodOption>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: scheme.surface,
              border: Border.all(
                color: scheme.outline.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [widget.accent.withOpacity(0.08), scheme.surface],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.accent.withOpacity(0.2),
                        widget.accent.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: widget.accent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
