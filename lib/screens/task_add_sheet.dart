import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui' show ImageFilter;

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
  final Future<void> Function()? onOpenPremium;
  final String ctaVariant;
  final String ctaLabel;
  final String ctaSubtitle;
  final void Function(String event, String variant)? onCtaEvent;

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
    this.onOpenPremium,
    this.ctaVariant = 'a',
    this.ctaLabel = 'Ignite Spark',
    this.ctaSubtitle = 'Takes less than 5 seconds',
    this.onCtaEvent,
  });

  @override
  State<TaskAddSheet> createState() => _TaskAddSheetState();
}

class _TaskAddSheetState extends State<TaskAddSheet>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  static const List<String> _taskHintIdeas = [
    'Try: Read 5 pages',
    'Try: Drink 2 glasses of water',
    'Try: Stretch for 3 min',
    'Try: Write one small goal',
    'Try: Take a 10-minute walk',
  ];
  late final String _hintExample;
  late String _category;
  late String _difficulty;
  late int _durationMinutes;
  bool _showAdvancedOptions = false;
  bool _ctaViewTracked = false;

  @override
  void initState() {
    super.initState();
    _hintExample = _taskHintIdeas[Random().nextInt(_taskHintIdeas.length)];
    _category = widget.initialCategory;
    _difficulty = widget.initialDifficulty;
    _durationMinutes = widget.initialDurationMinutes.clamp(5, 30);
    _controller.addListener(_handleTaskNameChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTaskNameChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleTaskNameChanged() {
    final hasValue = _controller.text.trim().isNotEmpty;
    if (hasValue == _showAdvancedOptions) return;
    setState(() => _showAdvancedOptions = hasValue);
    if (hasValue && !_ctaViewTracked) {
      _ctaViewTracked = true;
      _emitCtaEvent('viewed');
    }
  }

  Future<void> _handleAdd() async {
    _emitCtaEvent('tapped');
    final title = _controller.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a task title.')));
      return;
    }

    final ok = await widget.onAdd(
      title,
      _category,
      _difficulty,
      _durationMinutes.clamp(5, 30),
    );
    if (!mounted) return;
    if (ok) {
      await _showTaskAddCelebration();
      if (!mounted) return;
      _emitCtaEvent('success');
      Navigator.of(context).pop();
    }
  }

  void _emitCtaEvent(String event) {
    widget.onCtaEvent?.call(event, widget.ctaVariant);
  }

  Future<void> _showTaskAddCelebration() async {
    final overlay = Overlay.of(context, rootOverlay: true);

    HapticFeedback.mediumImpact();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );

    final curved = CurvedAnimation(parent: controller, curve: Curves.easeOut);
    final fadeOut = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.58, 1, curve: Curves.easeIn),
    );

    final entry = OverlayEntry(
      builder: (overlayContext) {
        final scheme = Theme.of(overlayContext).colorScheme;
        final isDark = Theme.of(overlayContext).brightness == Brightness.dark;
        return IgnorePointer(
          child: Material(
            type: MaterialType.transparency,
            child: Center(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final t = curved.value;
                  final fade = (1 - fadeOut.value).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: fade,
                    child: SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(170, 170),
                            painter: _MiniConfettiBurstPainter(
                              t: t,
                              primary: scheme.primary,
                              accent: scheme.secondary,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.78 + (0.26 * t),
                            child: Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    scheme.primary.withOpacity(
                                      isDark ? 0.95 : 0.85,
                                    ),
                                    scheme.secondary.withOpacity(
                                      isDark ? 0.95 : 0.82,
                                    ),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: scheme.primary.withOpacity(
                                      isDark ? 0.4 : 0.28,
                                    ),
                                    blurRadius: 22,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    await controller.forward();
    entry.remove();
    controller.dispose();
  }

  Future<void> _handleMoodGenerate(String mood) async {
    await widget.onGenerateAiMood?.call(mood);
    if (!mounted) return;
    _showMiniSuccess('AI tasks added.');
    Navigator.of(context).pop();
  }

  Future<void> _handleAiCta() async {
    if (widget.premiumActive) {
      await widget.onGenerateAi?.call();
      if (!mounted) return;
      _showMiniSuccess('AI task added.');
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    await widget.onOpenPremium?.call();
  }

  Future<void> _handleLimitBadgeTap() async {
    final canUpsell =
        !widget.canAddTask &&
        !widget.premiumActive &&
        widget.onOpenPremium != null;
    if (!canUpsell) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    await widget.onOpenPremium?.call();
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
    final canUpsell =
        !widget.canAddTask &&
        !widget.premiumActive &&
        widget.onOpenPremium != null;

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
                          'Small wins -> Big change.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: canUpsell ? _handleLimitBadgeTap : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: canUpsell
                            ? (isDark
                                  ? const Color(0xFF2A1338)
                                  : scheme.primary.withOpacity(0.12))
                            : (isDark
                                  ? const Color(0xFF080F1C)
                                  : scheme.surface),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: canUpsell
                              ? scheme.primary.withOpacity(isDark ? 0.62 : 0.5)
                              : (isDark
                                    ? const Color(0xFF1E3A5F).withOpacity(0.4)
                                    : scheme.outline.withOpacity(0.3)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.addLimitLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: canUpsell
                                  ? scheme.primary
                                  : (isDark
                                        ? Colors.white.withOpacity(
                                            widget.canAddTask ? 0.72 : 0.58,
                                          )
                                        : scheme.onSurfaceVariant),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (canUpsell) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: scheme.primary,
                            ),
                          ],
                        ],
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
                      labelText: 'What do you want to improve today?',
                      labelStyle: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.62)
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      hintText: _hintExample,
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
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          axisAlignment: -1,
                          child: child,
                        ),
                      );
                    },
                    child: _showAdvancedOptions
                        ? Column(
                            key: const ValueKey('task_sheet_meta_open'),
                            children: [
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  12,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF080F1C)
                                      : scheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(
                                            0xFF1E3A5F,
                                          ).withOpacity(0.3)
                                        : scheme.outline.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'How challenging?',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.8)
                                                : scheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _DifficultyOptionChip(
                                          emoji: '😌',
                                          label: 'Chill',
                                          selected: _difficulty == 'easy',
                                          accent: const Color(0xFF14B8A6),
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setState(
                                              () => _difficulty = 'easy',
                                            );
                                          },
                                        ),
                                        _DifficultyOptionChip(
                                          emoji: '💪',
                                          label: 'Focus',
                                          selected: _difficulty == 'medium',
                                          accent: const Color(0xFF3B82F6),
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setState(
                                              () => _difficulty = 'medium',
                                            );
                                          },
                                        ),
                                        _DifficultyOptionChip(
                                          emoji: '🔥',
                                          label: 'Beast',
                                          selected: _difficulty == 'hard',
                                          accent: const Color(0xFFF97316),
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setState(
                                              () => _difficulty = 'hard',
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _DurationSliderCard(
                                minutes: _durationMinutes,
                                onChanged: (value) {
                                  setState(
                                    () => _durationMinutes = value.round(),
                                  );
                                },
                              ),
                            ],
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('task_sheet_meta_closed'),
                          ),
                  ),
                ],
              ),
            ),
            if (_showAdvancedOptions) ...[
              const SizedBox(height: 12),
              if (widget.onGenerateAi != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Color.alphaBlend(
                      const Color(0xFF8B5CF6).withOpacity(isDark ? 0.16 : 0.1),
                      isDark ? const Color(0xFF080F1C) : scheme.surface,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: const Color(0xFF8B5CF6),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Coach',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white.withOpacity(0.94)
                                  : scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.premiumActive
                            ? 'Generate personalized daily sparks in one tap.'
                            : 'Create smart habits for you.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Colors.white.withOpacity(0.65)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AiCoachPreview(
                        lines: const [
                          'Drink water every 2h \uD83D\uDCA7',
                          '5-min stretch at night \uD83C\uDF19',
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleAiCta,
                          icon: Icon(
                            widget.premiumActive
                                ? Icons.flash_on_rounded
                                : Icons.workspace_premium_rounded,
                          ),
                          label: Text(
                            widget.premiumActive
                                ? 'Generate with AI'
                                : 'Try Premium',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
                  label: widget.ctaLabel,
                  subtitle: widget.ctaSubtitle,
                  icon: Icons.bolt_rounded,
                  onTap: widget.canAddTask ? _handleAdd : null,
                ),
              ),
            ],
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

class _AiCoachPreview extends StatelessWidget {
  const _AiCoachPreview({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : scheme.surface.withOpacity(0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : scheme.outline.withOpacity(0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Example sparks',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white.withOpacity(0.72)
                  : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: const Color(0xFF8B5CF6).withOpacity(0.9),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      line,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.86)
                            : scheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniConfettiBurstPainter extends CustomPainter {
  const _MiniConfettiBurstPainter({
    required this.t,
    required this.primary,
    required this.accent,
  });

  final double t;
  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = accent.withOpacity(0.45 * (1 - t));

    final burstRadius = 14 + (56 * t);
    canvas.drawCircle(center, burstRadius, ringPaint);

    const total = 18;
    for (var i = 0; i < total; i++) {
      final angle = (2 * pi * i) / total;
      final wobble = sin((t * 4.2) + i) * 4;
      final distance = (22 + (62 * t)) + wobble;
      final dotSize = 6.2 - (3.6 * t);
      final offset = Offset(cos(angle) * distance, sin(angle) * distance);
      final color = (i % 2 == 0 ? primary : accent).withOpacity(0.85 * (1 - t));
      particlePaint.color = color;

      canvas.save();
      canvas.translate(center.dx + offset.dx, center.dy + offset.dy);
      canvas.rotate(angle + (t * 1.4));
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: dotSize,
          height: dotSize * 1.6,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, particlePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MiniConfettiBurstPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.primary != primary ||
        oldDelegate.accent != accent;
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

class _DurationSliderCard extends StatelessWidget {
  const _DurationSliderCard({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const minMinutes = 5;
    const maxMinutes = 30;
    final normalized = ((minutes - minMinutes) / (maxMinutes - minMinutes))
        .clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF080F1C) : scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E3A5F).withOpacity(0.3)
              : scheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'How long will it take?',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark
                  ? Colors.white.withOpacity(0.8)
                  : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '⏱ $minutes minutes',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: isDark ? Colors.white.withOpacity(0.95) : scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              const bubbleWidth = 68.0;
              const sidePadding = 14.0;
              final trackWidth = max(
                0.0,
                constraints.maxWidth - (sidePadding * 2),
              );
              final centerX = sidePadding + (trackWidth * normalized);
              final bubbleLeft = (centerX - (bubbleWidth / 2))
                  .clamp(0.0, max(0.0, constraints.maxWidth - bubbleWidth))
                  .toDouble();

              return SizedBox(
                height: 66,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      left: bubbleLeft,
                      top: 0,
                      child: Container(
                        width: bubbleWidth,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A2B45)
                              : scheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: scheme.primary.withOpacity(
                              isDark ? 0.46 : 0.4,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withOpacity(
                                isDark ? 0.28 : 0.14,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '$minutes min',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? Colors.white.withOpacity(0.92)
                                : scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: 22,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 5,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                        ),
                        child: Slider(
                          value: minutes.toDouble(),
                          min: minMinutes.toDouble(),
                          max: maxMinutes.toDouble(),
                          divisions: maxMinutes - minMinutes,
                          activeColor: scheme.primary,
                          inactiveColor: scheme.surfaceContainerHighest
                              .withOpacity(0.6),
                          onChanged: onChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
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
    final glowColor = colors.first;
    final chipSurface = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
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
              ? scheme.primary.withOpacity(isDark ? 0.42 : 0.46)
              : (isDark
                    ? const Color(0xFF1E3A5F).withOpacity(0.4)
                    : scheme.outline.withOpacity(0.3)),
          width: selected ? 1.2 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(isDark ? 0.22 : 0.14),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white.withOpacity(0.9) : scheme.onSurface,
        ),
      ),
    );

    return AnimatedScale(
      scale: selected ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: selected
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: chipSurface,
                )
              : chipSurface,
        ),
      ),
    );
  }
}

class _DifficultyOptionChip extends StatelessWidget {
  const _DifficultyOptionChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: selected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? accent.withOpacity(isDark ? 0.22 : 0.16)
                : (isDark ? const Color(0xFF0D1B2E) : scheme.surface),
            border: Border.all(
              color: selected
                  ? accent.withOpacity(isDark ? 0.88 : 0.72)
                  : (isDark
                        ? const Color(0xFF1E3A5F).withOpacity(0.42)
                        : scheme.outline.withOpacity(0.34)),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withOpacity(isDark ? 0.32 : 0.2),
                      blurRadius: 12,
                      spreadRadius: 0.2,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '$emoji $label',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected
                  ? (isDark ? Colors.white.withOpacity(0.95) : scheme.onSurface)
                  : (isDark
                        ? Colors.white.withOpacity(0.8)
                        : scheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
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
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap?.call();
            },
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: onTap != null
                            ? scheme.onPrimary.withOpacity(0.86)
                            : (isDark
                                  ? Colors.white.withOpacity(0.36)
                                  : scheme.onSurfaceVariant.withOpacity(0.48)),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
