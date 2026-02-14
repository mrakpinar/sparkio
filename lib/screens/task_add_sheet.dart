import 'package:flutter/material.dart';

class TaskAddSheet extends StatefulWidget {
  final bool canAddTask;
  final String addLimitLabel;
  final String initialCategory;
  final String initialDifficulty;
  final int initialDurationMinutes;
  final bool premiumActive;
  final Future<bool> Function(
    String title,
    String category,
    String difficulty,
    int durationMinutes,
  )
  onAdd;
  final Future<void> Function()? onGenerateAi;
  final Future<void> Function(String mood)? onGenerateAiMood;

  const TaskAddSheet({
    super.key,
    required this.canAddTask,
    required this.addLimitLabel,
    required this.initialCategory,
    required this.initialDifficulty,
    required this.initialDurationMinutes,
    required this.premiumActive,
    required this.onAdd,
    this.onGenerateAi,
    this.onGenerateAiMood,
  });

  @override
  State<TaskAddSheet> createState() => _TaskAddSheetState();
}

class _TaskAddSheetState extends State<TaskAddSheet>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _durationController = TextEditingController();
  late String _category;
  late String _difficulty;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _difficulty = widget.initialDifficulty;
    _durationController.text = widget.initialDurationMinutes.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a task title.')));
      return;
    }

    final duration = int.tryParse(_durationController.text.trim()) ?? 5;
    final ok = await widget.onAdd(
      title,
      _category,
      _difficulty,
      duration.clamp(1, 120),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleMoodGenerate(String mood) async {
    await widget.onGenerateAiMood?.call(mood);
    if (!mounted) return;
    _showMiniSuccess('AI tasks added.');
    Navigator.of(context).pop();
  }

  void _showMiniSuccess(String message) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 220),
    );
    final fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);

    final entry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          child: Center(
            child: FadeTransition(
              opacity: fade,
              child: _MiniSuccessBanner(message: message),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(entry);
    controller.forward();
    Future.delayed(const Duration(milliseconds: 1000), () async {
      await controller.reverse();
      entry.remove();
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1628) : scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : scheme.shadow.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: (isDark
                      ? Colors.white.withOpacity(0.2)
                      : scheme.onSurface.withOpacity(0.18)),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isDark
                    ? const Color(0xFF0D1B2E)
                    : scheme.surfaceVariant.withOpacity(0.5),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E3A5F).withOpacity(0.4)
                      : scheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(isDark ? 0.15 : 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.primary.withOpacity(isDark ? 0.2 : 0.25),
                      ),
                    ),
                    child: Icon(Icons.add_task_rounded, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create a task',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white.withOpacity(0.95)
                                : scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Keep it small and doable.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF080F1C) : scheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E3A5F).withOpacity(0.4)
                            : scheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.addLimitLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: widget.canAddTask
                            ? (isDark
                                  ? Colors.white.withOpacity(0.7)
                                  : scheme.onSurfaceVariant)
                            : scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D1B2E) : scheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E3A5F).withOpacity(0.4)
                      : scheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.95)
                          : scheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. 10-minute walk',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.4)
                            : scheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF080F1C)
                          : scheme.surface,
                      prefixIcon: Icon(
                        Icons.edit_note_rounded,
                        color: isDark
                            ? Colors.white.withOpacity(0.6)
                            : scheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF1E3A5F).withOpacity(0.3)
                              : scheme.outline.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF1E3A5F).withOpacity(0.3)
                              : scheme.outline.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: scheme.primary, width: 2),
                      ),
                    ),
                    onSubmitted: (_) => _handleAdd(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _difficulty,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.95)
                                : scheme.onSurface,
                          ),
                          dropdownColor: isDark
                              ? const Color(0xFF0D1B2E)
                              : scheme.surface,
                          decoration: InputDecoration(
                            labelText: 'Difficulty',
                            labelStyle: TextStyle(
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : scheme.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF080F1C)
                                : scheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF1E3A5F).withOpacity(0.3)
                                    : scheme.outline.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF1E3A5F).withOpacity(0.3)
                                    : scheme.outline.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: scheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'easy',
                              child: Text('Easy'),
                            ),
                            DropdownMenuItem(
                              value: 'medium',
                              child: Text('Medium'),
                            ),
                            DropdownMenuItem(
                              value: 'hard',
                              child: Text('Hard'),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _difficulty = v ?? 'easy';
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.95)
                                : scheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Duration (min)',
                            labelStyle: TextStyle(
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : scheme.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF080F1C)
                                : scheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF1E3A5F).withOpacity(0.3)
                                    : scheme.outline.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF1E3A5F).withOpacity(0.3)
                                    : scheme.outline.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: scheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (widget.onGenerateAi != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.premiumActive
                      ? () async {
                          await widget.onGenerateAi?.call();
                          if (!mounted) return;
                          _showMiniSuccess('AI task added.');
                          Navigator.of(context).pop();
                        }
                      : null,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    widget.premiumActive
                        ? 'Generate AI Task'
                        : 'AI (Premium only)',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    backgroundColor: isDark
                        ? const Color(0xFF8B5CF6).withOpacity(0.1)
                        : scheme.primary.withOpacity(0.08),
                    foregroundColor: isDark
                        ? const Color(0xFF8B5CF6)
                        : scheme.primary,
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF8B5CF6).withOpacity(0.3)
                          : scheme.primary.withOpacity(0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.onGenerateAiMood != null) ...[
              Text(
                'How are you feeling?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withOpacity(0.9)
                      : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _GradientChip(
                    label: 'Feeling stressed',
                    colors: _chipGradient(
                      scheme,
                      isDark: isDark,
                      key: 'stressed',
                      selected: false,
                    ),
                    onTap: widget.premiumActive
                        ? () => _handleMoodGenerate('stressed')
                        : null,
                  ),
                  _GradientChip(
                    label: 'Low energy',
                    colors: _chipGradient(
                      scheme,
                      isDark: isDark,
                      key: 'low_energy',
                      selected: false,
                    ),
                    onTap: widget.premiumActive
                        ? () => _handleMoodGenerate('low_energy')
                        : null,
                  ),
                  _GradientChip(
                    label: 'Need focus',
                    colors: _chipGradient(
                      scheme,
                      isDark: isDark,
                      key: 'focus',
                      selected: false,
                    ),
                    onTap: widget.premiumActive
                        ? () => _handleMoodGenerate('focus')
                        : null,
                  ),
                ],
              ),
              if (!widget.premiumActive) ...[
                const SizedBox(height: 6),
                Text(
                  'AI mood tasks are Premium only.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in ['mind', 'body', 'growth', 'calm', 'health'])
                  _GradientChip(
                    label: c.toUpperCase(),
                    selected: _category == c,
                    colors: _chipGradient(
                      scheme,
                      isDark: isDark,
                      key: c,
                      selected: _category == c,
                    ),
                    onTap: () => setState(() {
                      _category = c;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _PrimaryGradientButton(
                label: 'Add task',
                icon: Icons.add_rounded,
                onTap: widget.canAddTask ? _handleAdd : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSuccessBanner extends StatelessWidget {
  final String message;

  const _MiniSuccessBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B2E) : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E3A5F).withOpacity(0.4)
              : scheme.outline,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : scheme.shadow.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: scheme.primary),
          const SizedBox(width: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withOpacity(0.95) : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

List<Color> _chipGradient(
  ColorScheme scheme, {
  required bool isDark,
  required String key,
  required bool selected,
}) {
  Color base;
  switch (key) {
    case 'mind':
      base = const Color(0xFF8B5CF6);
      break;
    case 'body':
      base = const Color(0xFFF97316);
      break;
    case 'growth':
      base = const Color(0xFF22C55E);
      break;
    case 'calm':
      base = const Color(0xFF06B6D4);
      break;
    case 'health':
      base = const Color(0xFF3B82F6);
      break;
    case 'stressed':
      base = const Color(0xFFF43F5E);
      break;
    case 'low_energy':
      base = const Color(0xFF38BDF8);
      break;
    case 'focus':
      base = const Color(0xFF60A5FA);
      break;
    default:
      base = scheme.primary;
  }

  if (isDark) {
    return [
      base.withOpacity(selected ? 0.2 : 0.12),
      base.withOpacity(selected ? 0.15 : 0.08),
    ];
  } else {
    return [
      base.withOpacity(selected ? 0.25 : 0.15),
      base.withOpacity(selected ? 0.2 : 0.1),
    ];
  }
}

class _GradientChip extends StatelessWidget {
  const _GradientChip({
    required this.label,
    required this.colors,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final List<Color> colors;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? scheme.primary.withOpacity(isDark ? 0.5 : 0.6)
                : (isDark
                      ? const Color(0xFF1E3A5F).withOpacity(0.4)
                      : scheme.outline.withOpacity(0.3)),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white.withOpacity(0.9) : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = LinearGradient(
      colors: isDark
          ? [scheme.primary, scheme.primary.withOpacity(0.85)]
          : [const Color(0xFF7DBBFF), const Color(0xFF9CCBFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: BoxDecoration(
            gradient: onTap != null ? gradient : null,
            color: onTap == null
                ? (isDark
                      ? const Color(0xFF1E3A5F).withOpacity(0.3)
                      : scheme.surfaceVariant)
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: onTap != null
                  ? scheme.primary.withOpacity(isDark ? 0.4 : 0.5)
                  : (isDark
                        ? const Color(0xFF1E3A5F).withOpacity(0.3)
                        : scheme.outline.withOpacity(0.3)),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: onTap != null
                    ? scheme.onPrimary
                    : (isDark
                          ? Colors.white.withOpacity(0.4)
                          : scheme.onSurfaceVariant.withOpacity(0.5)),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: onTap != null
                      ? scheme.onPrimary
                      : (isDark
                            ? Colors.white.withOpacity(0.4)
                            : scheme.onSurfaceVariant.withOpacity(0.5)),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
