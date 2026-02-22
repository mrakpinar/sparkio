import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../services/task_repository.dart';
import 'badges_screen.dart';

const double _kProfileCardRadius = 16;
const double _kProfileCardSurfaceAlpha = 0.78;
const double _kProfileCardBorderAlpha = 0.18;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profileName,
    this.profileAvatar,
    required this.currentStreak,
    required this.currentLevel,
    required this.totalXp,
    required this.xpInLevel,
    required this.xpToNextLevel,
  });

  final String profileName;
  final String? profileAvatar;
  final int currentStreak;
  final int currentLevel;
  final int totalXp;
  final int xpInLevel;
  final int xpToNextLevel;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final TaskRepository _repo = TaskRepository();
  final ImagePicker _imagePicker = ImagePicker();
  late Future<Set<String>> _earnedFuture;
  late Future<_JourneySnapshot> _journeySnapshotFuture;
  late final AnimationController _xpController;
  late final Animation<double> _xpAnimation;
  late String _profileName;
  String? _profileAvatar;
  late final TextEditingController _nameController;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _profileName = TaskRepository.sanitizeProfileName(widget.profileName);
    _profileAvatar = _sanitizeAvatar(widget.profileAvatar);
    _nameController = TextEditingController(text: _profileName);
    _earnedFuture = _repo.getEarnedBadges();
    _journeySnapshotFuture = _loadJourneySnapshot();
    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    _xpAnimation = CurvedAnimation(
      parent: _xpController,
      curve: Curves.easeOutQuart,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _xpController.forward(from: 0);
    });
    _loadSavedProfileAvatar();
  }

  @override
  void dispose() {
    _xpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<_JourneySnapshot> _loadJourneySnapshot() async {
    final earned = await _repo.getEarnedBadges();
    final totalCompleted = await _repo.getTotalCompleted();
    final categoryCounts = await _repo.getCategoryCounts();
    final bestStreak = await _repo.getBestStreak();
    final weekKey = _repo.currentWeekKey();
    final weeklyPlan = await _repo.getWeeklyPlan(weekKey: weekKey);
    final weeklyProgress = weeklyPlan == null
        ? 0
        : (await _repo.getWeeklyProgress(weekKey: weekKey)).totalDone;
    final history = await _repo.getDailyHistory(days: 7);
    return _JourneySnapshot(
      earnedBadges: earned.length,
      sparksLit: totalCompleted,
      bestStreak: bestStreak,
      weeklyDone: weeklyProgress,
      weeklyTarget: weeklyPlan?.totalTarget ?? 0,
      recentDailyCounts: _recentDailyCounts(history),
      nextUnlockLabel: _nextUnlockLabel(
        earnedBadges: earned,
        totalCompleted: totalCompleted,
        categoryCounts: categoryCounts,
      ),
    );
  }

  List<int> _recentDailyCounts(Map<String, int> history) {
    final now = DateTime.now();
    return List<int>.generate(7, (index) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index));
      final key = _dateKey(day);
      return history[key] ?? 0;
    });
  }

  String _dateKey(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _levelTitle(int level) {
    if (level >= 20) return 'Flow Master';
    if (level >= 14) return 'Momentum Maker';
    if (level >= 9) return 'Consistency Builder';
    if (level >= 5) return 'Habit Starter';
    return 'First Spark';
  }

  String _levelUnlockPreview(int level) {
    switch (level) {
      case 2:
        return 'Weekly Insights';
      case 3:
        return 'Streak Highlights';
      case 4:
        return 'Deeper Progress';
      default:
        return 'New Insights';
    }
  }

  String _sparkHintLabel(String title, int remainingSparks) {
    if (remainingSparks <= 0) return '🔓 $title ready now';
    final unit = remainingSparks == 1 ? 'spark' : 'sparks';
    return '🔓 $title in $remainingSparks $unit';
  }

  String _nextUnlockLabel({
    required Set<String> earnedBadges,
    required int totalCompleted,
    required Map<String, int> categoryCounts,
  }) {
    if (!earnedBadges.contains('cat_mind_10')) {
      final remaining = 10 - (categoryCounts['mind'] ?? 0);
      return _sparkHintLabel('Focus Badge', remaining);
    }
    if (!earnedBadges.contains('total_10')) {
      final remaining = 10 - totalCompleted;
      return _sparkHintLabel('Spark Starter Badge', remaining);
    }
    if (!earnedBadges.contains('cat_growth_10')) {
      final remaining = 10 - (categoryCounts['growth'] ?? 0);
      return _sparkHintLabel('Growth Badge', remaining);
    }
    if (!earnedBadges.contains('total_50')) {
      final remaining = 50 - totalCompleted;
      return _sparkHintLabel('Momentum Badge', remaining);
    }
    return '🔓 Mastery track active';
  }

  String? _sanitizeAvatar(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  bool _isAssetAvatar(String? avatar) {
    final value = avatar?.trim();
    return value != null && value.startsWith('assets/avatars/');
  }

  bool _isFileAvatar(String? avatar) {
    final value = avatar?.trim();
    if (value == null || value.isEmpty) return false;
    if (value.startsWith('assets/')) return false;
    return value.contains('/') || value.contains('\\');
  }

  bool _isManagedAvatarFile(String? avatar) {
    final value = avatar?.replaceAll('\\', '/');
    if (value == null || value.isEmpty) return false;
    return value.contains('/profile_avatars/');
  }

  String _avatarFileExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot <= 0 || dot == path.length - 1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    const allowed = <String>{'.jpg', '.jpeg', '.png', '.webp', '.heic'};
    return allowed.contains(ext) ? ext : '.jpg';
  }

  Future<String?> _copyAvatarToAppStorage(XFile picked) async {
    try {
      final root = await getApplicationDocumentsDirectory();
      final dir = Directory(
        '${root.path}${Platform.pathSeparator}profile_avatars',
      );
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final ext = _avatarFileExtension(picked.path);
      final path =
          '${dir.path}${Platform.pathSeparator}avatar_${DateTime.now().millisecondsSinceEpoch}$ext';
      final saved = await File(picked.path).copy(path);
      return saved.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickAvatarFromSource(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 88,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked == null) return;

      final savedPath = await _copyAvatarToAppStorage(picked);
      if (savedPath == null || savedPath.isEmpty) return;

      final previous = _sanitizeAvatar(_profileAvatar);
      await _repo.setProfileAvatar(savedPath);
      if (!mounted) return;
      setState(() => _profileAvatar = savedPath);

      if (_isManagedAvatarFile(previous) && previous != savedPath) {
        try {
          final oldFile = File(previous!);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (_) {}
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      final code = e.code.toLowerCase();
      String message = 'Unable to open camera right now.';
      if (source == ImageSource.camera) {
        if (code.contains('denied') || code.contains('restricted')) {
          message = 'Camera permission is denied. Check app permissions.';
        } else if (code.contains('no_available_camera') ||
            code.contains('camera_unavailable') ||
            code.contains('not_available')) {
          message = 'Camera is not available on this device.';
        }
      } else {
        if (code.contains('denied') || code.contains('restricted')) {
          message = 'Photo library permission is denied.';
        } else {
          message = 'Unable to open gallery right now.';
        }
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          action: source == ImageSource.camera
              ? SnackBarAction(
                  label: 'Gallery',
                  onPressed: () {
                    _pickAvatarFromSource(ImageSource.gallery);
                  },
                )
              : null,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Unable to open camera right now.'
                : 'Unable to open gallery right now.',
          ),
          behavior: SnackBarBehavior.floating,
          action: source == ImageSource.camera
              ? SnackBarAction(
                  label: 'Gallery',
                  onPressed: () {
                    _pickAvatarFromSource(ImageSource.gallery);
                  },
                )
              : null,
        ),
      );
    }
  }

  Widget _buildAvatarFace({
    required ThemeData theme,
    required ColorScheme scheme,
    required String? avatar,
    required String initials,
    required double size,
  }) {
    if (_isAssetAvatar(avatar)) {
      final path = avatar!;
      return ClipOval(
        child: Image.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) {
            return Text(
              initials,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            );
          },
        ),
      );
    }
    if (_isFileAvatar(avatar)) {
      final path = avatar!;
      return ClipOval(
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) {
            return Text(
              initials,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            );
          },
        ),
      );
    }
    if (avatar != null && avatar.isNotEmpty) {
      return Text(
        avatar,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return Text(
      initials,
      style: theme.textTheme.headlineSmall?.copyWith(
        color: scheme.onPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Future<void> _loadSavedProfileAvatar() async {
    final saved = _sanitizeAvatar(await _repo.getProfileAvatar());
    if (!mounted) return;
    if (saved != _profileAvatar) {
      setState(() => _profileAvatar = saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cleanedName = TaskRepository.sanitizeProfileName(_profileName);
    final name = cleanedName.isEmpty ? 'Friend' : cleanedName;
    final initials = name.characters.first.toUpperCase();
    final avatar = _sanitizeAvatar(_profileAvatar);
    final safeLevel = widget.currentLevel <= 0 ? 1 : widget.currentLevel;
    final safeXpToNext = widget.xpToNextLevel <= 0 ? 1 : widget.xpToNextLevel;
    final clampedXpInLevel = widget.xpInLevel.clamp(0, safeXpToNext);
    final levelProgress = (clampedXpInLevel / safeXpToNext).clamp(0.0, 1.0);
    final hasStreakRing = widget.currentStreak > 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
                      scheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -130,
            left: -70,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scheme.primary.withValues(alpha: isDark ? 0.11 : 0.06),
                      scheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Profile',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            _kProfileCardRadius,
                          ),
                          color: scheme.surface.withValues(
                            alpha: _kProfileCardSurfaceAlpha,
                          ),
                          border: Border.all(
                            color: scheme.outline.withValues(
                              alpha: _kProfileCardBorderAlpha,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _openAvatarPicker,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 260,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        width: 91,
                                        height: 91,
                                        padding: const EdgeInsets.all(3.2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: scheme.primary.withValues(
                                              alpha: hasStreakRing
                                                  ? (isDark ? 0.48 : 0.38)
                                                  : (isDark ? 0.16 : 0.13),
                                            ),
                                            width: 1.3,
                                          ),
                                          boxShadow: hasStreakRing
                                              ? [
                                                  BoxShadow(
                                                    color: scheme.primary
                                                        .withValues(
                                                          alpha: isDark
                                                              ? 0.34
                                                              : 0.24,
                                                        ),
                                                    blurRadius: 18,
                                                    spreadRadius: -2,
                                                  ),
                                                ]
                                              : [
                                                  BoxShadow(
                                                    color: scheme.primary
                                                        .withValues(
                                                          alpha: isDark
                                                              ? 0.1
                                                              : 0.06,
                                                        ),
                                                    blurRadius: 10,
                                                    spreadRadius: -5,
                                                  ),
                                                ],
                                        ),
                                        child: Container(
                                          width: 84,
                                          height: 84,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                scheme.primary.withValues(
                                                  alpha: isDark ? 0.86 : 0.92,
                                                ),
                                                scheme.primary.withValues(
                                                  alpha: isDark ? 0.62 : 0.72,
                                                ),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: scheme.primary
                                                    .withValues(
                                                      alpha: isDark
                                                          ? 0.34
                                                          : 0.2,
                                                    ),
                                                blurRadius: 20,
                                                spreadRadius: -8,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: _buildAvatarFace(
                                            theme: theme,
                                            scheme: scheme,
                                            avatar: avatar,
                                            initials: initials,
                                            size: 84,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: scheme.surface,
                                            border: Border.all(
                                              color: scheme.primary.withValues(
                                                alpha: 0.35,
                                              ),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.edit_rounded,
                                            size: 15,
                                            color: scheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (_isEditingName)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _nameController,
                                                autofocus: true,
                                                maxLength: 24,
                                                textCapitalization:
                                                    TextCapitalization.words,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  counterText: '',
                                                  hintText:
                                                      'Enter your first name',
                                                  hintStyle: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: scheme
                                                            .onSurfaceVariant,
                                                      ),
                                                  border: InputBorder.none,
                                                ),
                                                style: theme
                                                    .textTheme
                                                    .headlineSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                onSubmitted: (_) =>
                                                    _saveInlineName(),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: _saveInlineName,
                                              icon: Icon(
                                                Icons.check_rounded,
                                                color: scheme.primary,
                                                size: 20,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              tooltip: 'Save',
                                            ),
                                            IconButton(
                                              onPressed: _cancelInlineEdit,
                                              icon: Icon(
                                                Icons.close_rounded,
                                                color: scheme.onSurfaceVariant,
                                                size: 20,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              tooltip: 'Cancel',
                                            ),
                                          ],
                                        )
                                      else
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      name,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: theme
                                                          .textTheme
                                                          .headlineMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Icon(
                                                    Icons.bolt_rounded,
                                                    size: 20,
                                                    color: scheme.primary,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            InkWell(
                                              onTap: _startInlineEdit,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 2,
                                                      vertical: 1,
                                                    ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.edit_rounded,
                                                      size: 14,
                                                      color: scheme.primary
                                                          .withValues(
                                                            alpha: 0.9,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Edit',
                                                      style: theme
                                                          .textTheme
                                                          .labelMedium
                                                          ?.copyWith(
                                                            color:
                                                                scheme.primary,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Level $safeLevel - ${_levelTitle(safeLevel)}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AnimatedBuilder(
                              animation: _xpAnimation,
                              builder: (context, child) {
                                final t = _xpAnimation.value;
                                final animatedProgress = (levelProgress * t)
                                    .clamp(0.0, 1.0);
                                final trackGlow =
                                    (isDark ? 0.3 : 0.2) +
                                    (0.18 * animatedProgress);
                                final fillGlow =
                                    (isDark ? 0.46 : 0.34) +
                                    (0.24 * animatedProgress);
                                return Container(
                                  height: 18,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: scheme.surfaceContainerHighest
                                        .withValues(alpha: 0.84),
                                    border: Border.all(
                                      color: scheme.primary.withValues(
                                        alpha: isDark ? 0.34 : 0.28,
                                      ),
                                      width: 0.8,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary.withValues(
                                          alpha: trackGlow,
                                        ),
                                        blurRadius: 22,
                                        spreadRadius: -6,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: scheme.primary.withValues(
                                          alpha: isDark ? 0.18 : 0.1,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: -4,
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: animatedProgress,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                gradient: LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    Color.alphaBlend(
                                                      Colors.black.withValues(
                                                        alpha: 0.06,
                                                      ),
                                                      scheme.primary,
                                                    ),
                                                    scheme.primary,
                                                    Color.alphaBlend(
                                                      Colors.white.withValues(
                                                        alpha: isDark
                                                            ? 0.18
                                                            : 0.28,
                                                      ),
                                                      scheme.primary,
                                                    ),
                                                  ],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: scheme.primary
                                                        .withValues(
                                                          alpha: fillGlow,
                                                        ),
                                                    blurRadius: 14,
                                                    spreadRadius: -2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.topCenter,
                                              child: Container(
                                                height: 3,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                  color: Colors.white
                                                      .withValues(
                                                        alpha: isDark
                                                            ? 0.28
                                                            : 0.34,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$clampedXpInLevel / $safeXpToNext XP to Level ${safeLevel + 1}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Level ${safeLevel + 1} unlocks ${_levelUnlockPreview(safeLevel + 1)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.9,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Divider(
                              height: 1,
                              thickness: 0.8,
                              color: scheme.outline.withValues(alpha: 0.18),
                            ),
                            const SizedBox(height: 6),
                            FutureBuilder<_JourneySnapshot>(
                              future: _journeySnapshotFuture,
                              builder: (context, snapshot) {
                                final label =
                                    snapshot.data?.safeNextUnlockLabel ??
                                    '🔓 Focus Badge in 3 sparks';
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: scheme.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      border: Border.all(
                                        color: scheme.primary.withValues(
                                          alpha: 0.24,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: scheme.primary.withValues(
                                              alpha: 0.95,
                                            ),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<_JourneySnapshot>(
                        future: _journeySnapshotFuture,
                        builder: (context, snapshot) {
                          final data =
                              snapshot.data ??
                              const _JourneySnapshot(
                                earnedBadges: 0,
                                sparksLit: 0,
                                bestStreak: 0,
                                weeklyDone: 0,
                                weeklyTarget: 0,
                                recentDailyCounts: <int>[0, 0, 0, 0, 0, 0, 0],
                              );
                          final todayCount =
                              data.safeRecentDailyCounts.isNotEmpty
                              ? data.safeRecentDailyCounts.last
                              : 0;
                          final weeklyRemaining =
                              data.safeWeeklyTarget - data.safeWeeklyDone;
                          final nextStepMessage =
                              data.safeWeeklyTarget > 0 && weeklyRemaining > 0
                              ? 'Complete 1 spark to move your weekly plan forward.'
                              : todayCount <= 0
                              ? 'Light your first spark today.'
                              : 'Do one more spark today to keep momentum.';
                          final showedUpToday =
                              data.safeRecentDailyCounts.isNotEmpty &&
                              data.safeRecentDailyCounts.last > 0;
                          return Column(
                            children: [
                              _NextStepCard(
                                message: nextStepMessage,
                                onTap: () => Navigator.of(context).maybePop(),
                              ),
                              const SizedBox(height: 10),
                              _WeeklyProgressCard(snapshot: data),
                              const SizedBox(height: 10),
                              _SevenDaySparkCard(
                                dailyCounts: data.safeRecentDailyCounts,
                                bestStreak: data.safeBestStreak,
                              ),
                              const SizedBox(height: 10),
                              _PersonalBestStrip(
                                bestStreak: data.safeBestStreak,
                                totalSparks: data.sparksLit,
                                consistencyPercent: data.safeConsistencyPercent,
                              ),
                              if (showedUpToday) ...[
                                const SizedBox(height: 8),
                                const _MiniActivityFeedback(),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      FutureBuilder<Set<String>>(
                        future: _earnedFuture,
                        builder: (context, snapshot) {
                          final earned = snapshot.data ?? <String>{};
                          final defs = _allProfileBadges
                              .where((badge) => earned.contains(badge.id))
                              .toList();

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return Container(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                _kProfileCardRadius,
                              ),
                              color: scheme.surface.withValues(alpha: 0.72),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Journey',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.92,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (defs.isEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your journey just started.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: scheme.onSurface,
                                              height: 1.35,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const BadgesScreen(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.emoji_events_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('Unlock first badge'),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 0,
                                            vertical: 4,
                                          ),
                                          foregroundColor: scheme.primary,
                                          textStyle: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          minimumSize: Size.zero,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    children: List.generate(defs.length, (
                                      index,
                                    ) {
                                      final badge = defs[index];
                                      return Column(
                                        children: [
                                          _JourneyBadgeRow(badge: badge),
                                          if (index != defs.length - 1)
                                            Divider(
                                              height: 14,
                                              color: scheme.outline.withValues(
                                                alpha: 0.16,
                                              ),
                                            ),
                                        ],
                                      );
                                    }),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startInlineEdit() {
    setState(() {
      _isEditingName = true;
      _nameController.text = TaskRepository.sanitizeProfileName(_profileName);
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nameController.text.length),
      );
    });
  }

  void _cancelInlineEdit() {
    setState(() {
      _isEditingName = false;
      _nameController.text = TaskRepository.sanitizeProfileName(_profileName);
    });
  }

  Future<void> _saveInlineName() async {
    final value = TaskRepository.sanitizeProfileName(_nameController.text);
    if (value.isEmpty) return;
    await _repo.setProfileName(value);
    if (!mounted) return;
    setState(() {
      _profileName = value;
      _nameController.text = value;
      _isEditingName = false;
    });
  }

  Future<void> _openAvatarPicker() async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose avatar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(_avatarActionCamera),
                        icon: const Icon(Icons.photo_camera_rounded, size: 16),
                        label: const Text('Take photo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(
                          sheetContext,
                        ).pop(_avatarActionGallery),
                        icon: const Icon(Icons.photo_library_rounded, size: 16),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _avatarAssetOptions.map((avatarPath) {
                    final active = _profileAvatar == avatarPath;
                    return InkWell(
                      onTap: () => Navigator.of(sheetContext).pop(avatarPath),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? scheme.primary.withValues(alpha: 0.2)
                              : scheme.surfaceContainerHigh,
                          border: Border.all(
                            color: active
                                ? scheme.primary
                                : scheme.outline.withValues(alpha: 0.22),
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            avatarPath,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stackTrace) {
                              return Icon(
                                Icons.person_rounded,
                                color: scheme.onSurfaceVariant,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop(''),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Remove avatar'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(null),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    if (selected == _avatarActionCamera) {
      await _pickAvatarFromSource(ImageSource.camera);
      return;
    }
    if (selected == _avatarActionGallery) {
      await _pickAvatarFromSource(ImageSource.gallery);
      return;
    }
    final value = selected.trim();
    final previous = _sanitizeAvatar(_profileAvatar);
    final nextAvatar = value.isEmpty ? null : value;
    await _repo.setProfileAvatar(nextAvatar);
    if (_isManagedAvatarFile(previous) &&
        previous != nextAvatar &&
        value.isEmpty) {
      try {
        final oldFile = File(previous!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _profileAvatar = nextAvatar);
  }
}

class _JourneySnapshot {
  const _JourneySnapshot({
    required this.earnedBadges,
    required this.sparksLit,
    this.bestStreak,
    this.weeklyDone,
    this.weeklyTarget,
    this.recentDailyCounts,
    this.nextUnlockLabel,
  });

  final int earnedBadges;
  final int sparksLit;
  final int? bestStreak;
  final int? weeklyDone;
  final int? weeklyTarget;
  final List<int>? recentDailyCounts;
  final String? nextUnlockLabel;

  int get safeBestStreak => bestStreak ?? 0;
  int get safeWeeklyDone => weeklyDone ?? 0;
  int get safeWeeklyTarget => weeklyTarget ?? 0;
  List<int> get safeRecentDailyCounts =>
      recentDailyCounts ?? const <int>[0, 0, 0, 0, 0, 0, 0];
  String get safeNextUnlockLabel =>
      nextUnlockLabel ?? '🔓 Focus Badge in 3 sparks';
  int get safeConsistencyPercent {
    final values = safeRecentDailyCounts;
    if (values.isEmpty) return 0;
    final activeDays = values.where((value) => value > 0).length;
    return ((activeDays / values.length) * 100).round();
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard({required this.snapshot});

  final _JourneySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasPlan = snapshot.safeWeeklyTarget > 0;
    final safeTarget = snapshot.safeWeeklyTarget <= 0
        ? 1
        : snapshot.safeWeeklyTarget;
    final progress = hasPlan
        ? (snapshot.safeWeeklyDone / safeTarget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kProfileCardRadius),
        color: scheme.surface.withValues(alpha: _kProfileCardSurfaceAlpha),
        border: Border.all(
          color: scheme.outline.withValues(alpha: _kProfileCardBorderAlpha),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: scheme.primary.withValues(alpha: 0.14),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/in_app_icons/calendar.png',
                    width: 15,
                    height: 15,
                    fit: BoxFit.contain,
                    color: scheme.primary,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Weekly progress',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                !hasPlan
                    ? 'No plan'
                    : snapshot.safeWeeklyDone <= 0
                    ? 'Week just started'
                    : '${snapshot.safeWeeklyDone}/${snapshot.safeWeeklyTarget}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: scheme.surfaceContainerHighest.withValues(
                alpha: 0.7,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.message, required this.onTap});

  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kProfileCardRadius),
        color: scheme.surface.withValues(
          alpha: _kProfileCardSurfaceAlpha + 0.06,
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: scheme.primary.withValues(alpha: 0.17),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.34),
                  blurRadius: 10,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.2),
                  blurRadius: 6,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Icon(
              Icons.flag_rounded,
              size: 15,
              color: scheme.primary.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Back to today'),
          ),
        ],
      ),
    );
  }
}

class _SevenDaySparkCard extends StatefulWidget {
  const _SevenDaySparkCard({
    required this.dailyCounts,
    required this.bestStreak,
  });

  final List<int> dailyCounts;
  final int bestStreak;

  @override
  State<_SevenDaySparkCard> createState() => _SevenDaySparkCardState();
}

class _SevenDaySparkCardState extends State<_SevenDaySparkCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  )..repeat(reverse: true);

  late final Animation<double> _pulse = CurvedAnimation(
    parent: _pulseController,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _weekdayShort(int weekday) {
    const labels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[(weekday - 1).clamp(0, labels.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final values = widget.dailyCounts.length == 7
        ? widget.dailyCounts
        : List<int>.filled(7, 0);
    final maxCount = values.fold<int>(0, (max, value) {
      return value > max ? value : max;
    });
    final safeMax = maxCount <= 0 ? 1 : maxCount;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kProfileCardRadius),
        color: scheme.surface.withValues(alpha: _kProfileCardSurfaceAlpha),
        border: Border.all(
          color: scheme.outline.withValues(alpha: _kProfileCardBorderAlpha),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Last 7 days',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Best streak: ${widget.bestStreak}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final pulseT = _pulse.value;
              return Row(
                children: List.generate(values.length, (index) {
                  final value = values[index];
                  final completed = value > 0;
                  final intensity = completed ? (value / safeMax) : 0.0;
                  final isToday = index == values.length - 1;
                  final day = DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).subtract(Duration(days: 6 - index));

                  final dotColor = completed
                      ? Color.alphaBlend(
                          scheme.primary.withValues(
                            alpha: 0.62 + (0.3 * intensity),
                          ),
                          scheme.surface,
                        )
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.2);
                  final scale = isToday
                      ? 1 + ((completed ? 0.12 : 0.08) * pulseT)
                      : 1.0;
                  final shadows = <BoxShadow>[
                    if (completed)
                      BoxShadow(
                        color: scheme.primary.withValues(
                          alpha: 0.5 + (0.28 * intensity),
                        ),
                        blurRadius: 18,
                        spreadRadius: -0.5,
                      ),
                    if (completed)
                      BoxShadow(
                        color: scheme.primary.withValues(
                          alpha: 0.26 + (0.18 * intensity),
                        ),
                        blurRadius: 10,
                        spreadRadius: -1.5,
                      ),
                    if (isToday)
                      BoxShadow(
                        color: scheme.primary.withValues(
                          alpha: (completed ? 0.32 : 0.18) + (0.2 * pulseT),
                        ),
                        blurRadius: 18 + (9 * pulseT),
                        spreadRadius: completed ? 0.8 : -0.5,
                      ),
                  ];

                  return Expanded(
                    child: Column(
                      children: [
                        Transform.scale(
                          scale: scale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isToday)
                                Container(
                                  width: 34 + (4 * pulseT),
                                  height: 34 + (4 * pulseT),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: scheme.primary.withValues(
                                      alpha: completed
                                          ? 0.1 + (0.08 * pulseT)
                                          : 0.06 + (0.05 * pulseT),
                                    ),
                                  ),
                                ),
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: dotColor,
                                  border: Border.all(
                                    color: scheme.primary.withValues(
                                      alpha: completed
                                          ? 0.52 + (0.32 * intensity)
                                          : 0.22,
                                    ),
                                  ),
                                  boxShadow: shadows,
                                ),
                                child: completed
                                    ? Align(
                                        alignment: const Alignment(
                                          -0.25,
                                          -0.25,
                                        ),
                                        child: Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(
                                              alpha: 0.34,
                                            ),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _weekdayShort(day.weekday),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.86,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PersonalBestStrip extends StatelessWidget {
  const _PersonalBestStrip({
    required this.bestStreak,
    required this.totalSparks,
    required this.consistencyPercent,
  });

  final int bestStreak;
  final int totalSparks;
  final int consistencyPercent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dayLabel = bestStreak == 1 ? 'day' : 'days';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kProfileCardRadius),
        color: scheme.surface.withValues(alpha: _kProfileCardSurfaceAlpha),
        border: Border.all(
          color: scheme.outline.withValues(alpha: _kProfileCardBorderAlpha),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 17,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Best streak: $bestStreak $dayLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 17, color: scheme.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Total sparks: $totalSparks',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            thickness: 0.8,
            color: scheme.outline.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(
                Icons.track_changes_rounded,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Consistency: $consistencyPercent%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniActivityFeedback extends StatelessWidget {
  const _MiniActivityFeedback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kProfileCardRadius),
        color: scheme.surface.withValues(alpha: _kProfileCardSurfaceAlpha),
        border: Border.all(
          color: scheme.outline.withValues(alpha: _kProfileCardBorderAlpha),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            'You showed up today.',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyBadgeRow extends StatelessWidget {
  const _JourneyBadgeRow({required this.badge});

  final _ProfileBadge badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = scheme.primary;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.16),
          ),
          alignment: Alignment.center,
          child: Icon(badge.icon, size: 18, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                badge.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileBadge {
  const _ProfileBadge({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
}

const _allProfileBadges = <_ProfileBadge>[
  _ProfileBadge(
    id: 'total_10',
    label: 'Complete 10 sparks',
    description: 'Build momentum with 10 completed sparks.',
    icon: Icons.bolt_rounded,
  ),
  _ProfileBadge(
    id: 'total_50',
    label: 'Build 50 sparks',
    description: 'Keep showing up and reach 50 sparks.',
    icon: Icons.timeline_rounded,
  ),
  _ProfileBadge(
    id: 'total_100',
    label: 'Complete 100 sparks',
    description: 'Turn consistency into a 100 spark streak of effort.',
    icon: Icons.auto_graph_rounded,
  ),
  _ProfileBadge(
    id: 'streak_3',
    label: 'Keep rhythm for 3 days',
    description: 'Show up three days in a row.',
    icon: Icons.local_fire_department_rounded,
  ),
  _ProfileBadge(
    id: 'streak_7',
    label: 'Hold a 7-day flow',
    description: 'Keep your rhythm for seven days.',
    icon: Icons.whatshot_rounded,
  ),
  _ProfileBadge(
    id: 'cat_mind_10',
    label: 'Complete 10 Mind sparks',
    description: 'Give your mind ten focused resets.',
    icon: Icons.psychology_rounded,
  ),
  _ProfileBadge(
    id: 'cat_body_10',
    label: 'Complete 10 Body sparks',
    description: 'Move and recharge with ten body sparks.',
    icon: Icons.fitness_center_rounded,
  ),
  _ProfileBadge(
    id: 'cat_growth_10',
    label: 'Complete 10 Growth sparks',
    description: 'Create progress with ten growth sparks.',
    icon: Icons.trending_up_rounded,
  ),
  _ProfileBadge(
    id: 'cat_calm_10',
    label: 'Complete 10 Calm sparks',
    description: 'Protect calm moments with ten calm sparks.',
    icon: Icons.spa_rounded,
  ),
  _ProfileBadge(
    id: 'cat_health_10',
    label: 'Complete 10 Health sparks',
    description: 'Support your energy with ten health sparks.',
    icon: Icons.favorite_rounded,
  ),
];

const _avatarAssetOptions = <String>[
  'assets/avatars/10491830.jpg',
  'assets/avatars/10491845.jpg',
  'assets/avatars/11475221.jpg',
  'assets/avatars/9334415.jpg',
  'assets/avatars/9434937.jpg',
  'assets/avatars/9439727.jpg',
  'assets/avatars/9439775.jpg',
  'assets/avatars/9440461.jpg',
  'assets/avatars/androgynous-avatar-non-binary-queer-person.jpg',
  'assets/avatars/e67eb556-f125-4e24-95ad-8aff21b9926a.jpg',
];

const _avatarActionCamera = '__camera__';
const _avatarActionGallery = '__gallery__';
