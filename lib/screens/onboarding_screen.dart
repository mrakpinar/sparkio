import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_strings.dart';
import '../services/task_repository.dart';
import '../widgets/spark_particles_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final Future<void> Function() onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();

  bool _finishing = false;
  String _selectedGoal = '';

  int _loadingStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _onGoalSelected(String goal) {
    HapticFeedback.selectionClick();
    setState(() => _selectedGoal = goal);
  }

  Future<void> _startMagicAssembly() async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    // Switch to the loading page immediately
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    // Save the user's name secretly in the background
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final repo = TaskRepository();
      await repo.setProfileName(name);
    }

    // Run the fake cinematic loading flow
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _loadingStep = 1);
      HapticFeedback.selectionClick();
    }

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _loadingStep = 2);
      HapticFeedback.selectionClick();
    }

    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      setState(() => _loadingStep = 3);
      HapticFeedback.heavyImpact();
    }

    await Future.delayed(const Duration(milliseconds: 400));
    _finish();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.onFinished();
    if (!mounted) return;
    setState(() => _finishing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final topColor = isDark
        ? const Color(0xFF0C1220)
        : const Color(0xFFF3F5FA);
    
    final bottomColor = isDark
        ? scheme.background
        : scheme.surface;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Base
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [topColor, bottomColor],
                ),
              ),
            ),
          ),
          // Premium Ambient Background
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.8,
                child: SparkParticlesBackground(
                  streak: 15, // Forces particles to look lush & heavy
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top App Style Pill
                Padding(
                  padding: const EdgeInsets.only(top: 14.0, bottom: 8.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: scheme.surface.withOpacity(isDark ? 0.2 : 0.6),
                        border: Border.all(color: scheme.outline.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 16, color: scheme.onSurface),
                          const SizedBox(width: 8),
                          Text(
                            'Sparkio',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: scheme.onSurfaceVariant.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Only manual transitions
                    children: [
                      _buildGoalSelectionPage(theme, scheme),
                      _buildNameInputPage(theme, scheme),
                      _buildLoadingPage(theme, scheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// STEP 1: Goal Selection
  Widget _buildGoalSelectionPage(ThemeData theme, ColorScheme scheme) {
    final l10n = context.l10n;
    final goals = [
      {'title': l10n.goalConsistency, 'icon': Icons.repeat_rounded},
      {'title': l10n.goalBurnout, 'icon': Icons.spa_rounded},
      {'title': l10n.goalFocus, 'icon': Icons.center_focus_strong_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Text(
            l10n.onboardingGoalTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingGoalSubtitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ...goals.map((g) {
            final isSelected = _selectedGoal == g['title'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: InkWell(
                onTap: () => _onGoalSelected(g['title'] as String),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.onSurface.withOpacity(0.08)
                        : scheme.surface.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? scheme.onSurface.withOpacity(0.6)
                          : scheme.outline.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        g['icon'] as IconData,
                        color: isSelected
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        g['title'] as String,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 32),
          AnimatedOpacity(
            opacity: _selectedGoal.isNotEmpty ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton(
              onPressed: _selectedGoal.isNotEmpty ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.onSurface,
                foregroundColor: scheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                l10n.onboardingContinue,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.surface,
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  /// STEP 2: Name Input
  Widget _buildNameInputPage(ThemeData theme, ColorScheme scheme) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Text(
            l10n.onboardingNameTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingNameSubtitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: l10n.onboardingNameHint,
              hintStyle: theme.textTheme.displaySmall?.copyWith(
                color: scheme.onSurfaceVariant.withOpacity(0.4),
              ),
              border: InputBorder.none,
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: scheme.onSurface, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                _startMagicAssembly();
              } else {
                HapticFeedback.vibrate();
                // Just force them to the next step anyway as "Spark" default if they skip.
                // In a true app you can block, but we will allow skipping for UX.
                _nameController.text = "Spark";
                _startMagicAssembly();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.onSurface,
              foregroundColor: scheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              l10n.beginJourney,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.surface,
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  /// STEP 3: The Cinematic Magic Assembly
  Widget _buildLoadingPage(ThemeData theme, ColorScheme scheme) {
    final l10n = context.l10n;
    
    String getLoadingMessage() {
      switch (_loadingStep) {
        case 1: return l10n.generatingCalibrating;
        case 2: return l10n.generatingBuilding;
        case 3: return l10n.generatingReady;
        default: return l10n.generatingAnalyzing;
      }
    }
    
    final message = getLoadingMessage();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 48),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            message,
            key: ValueKey<String>(message),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
