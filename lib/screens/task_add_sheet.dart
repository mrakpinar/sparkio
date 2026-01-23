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

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 20 + bottomInset),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Add a custom task', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  widget.addLimitLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: widget.canAddTask
                        ? scheme.onSurfaceVariant
                        : scheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'e.g. 10-minute walk',
                filled: true,
                fillColor: scheme.surfaceVariant,
              ),
              onSubmitted: (_) => _handleAdd(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'hard', child: Text('Hard')),
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
                    decoration: const InputDecoration(
                      labelText: 'Duration (min)',
                    ),
                  ),
                ),
              ],
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
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.onGenerateAiMood != null) ...[
              Text(
                'How are you feeling?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Feeling stressed'),
                    selected: false,
                    onSelected: widget.premiumActive
                        ? (_) => _handleMoodGenerate('stressed')
                        : null,
                  ),
                  ChoiceChip(
                    label: const Text('Low energy'),
                    selected: false,
                    onSelected: widget.premiumActive
                        ? (_) => _handleMoodGenerate('low_energy')
                        : null,
                  ),
                  ChoiceChip(
                    label: const Text('Need focus'),
                    selected: false,
                    onSelected: widget.premiumActive
                        ? (_) => _handleMoodGenerate('focus')
                        : null,
                  ),
                ],
              ),
              if (!widget.premiumActive) ...[
                const SizedBox(height: 6),
                Text(
                  'AI mood tasks are Premium only.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  ChoiceChip(
                    label: Text(c.toUpperCase()),
                    selected: _category == c,
                    onSelected: (_) => setState(() {
                      _category = c;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.canAddTask ? _handleAdd : null,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add task'),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded),
          const SizedBox(width: 10),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
