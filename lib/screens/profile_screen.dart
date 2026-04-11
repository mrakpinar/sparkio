import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../app_strings.dart';
import '../models/level_unlocks.dart';
import '../services/locale_service.dart';
import '../services/referral_service.dart';
import '../services/task_repository.dart';
import 'badges_screen.dart';

const double _kProfileCardRadius = 16;
const double _kProfileCardSurfaceAlpha = 0.84;

BoxDecoration _profileNeoGlassDecoration(
  ColorScheme scheme, {
  Color? tint,
  double radius = _kProfileCardRadius,
  double tintOpacity = 0.04,
  double surfaceOpacity = _kProfileCardSurfaceAlpha,
}) {
  final isDark = scheme.brightness == Brightness.dark;
  final base = Color.alphaBlend(
    scheme.onSurface.withOpacity(isDark ? 0.04 : 0.08),
    scheme.surface,
  );
  final effectiveTint = tint ?? scheme.onSurface;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(effectiveTint.withOpacity(tintOpacity), base),
        Color.alphaBlend(scheme.onSurface.withOpacity(tintOpacity * 0.5), base),
      ],
    ),
    border: Border.all(
        color: isDark 
            ? Colors.white.withOpacity(0.05) 
            : scheme.onSurface.withOpacity(0.08), 
        width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.16),
        blurRadius: 18,
        spreadRadius: -6,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

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
    this.openReferralOnLoad = false,
  });

  final String profileName;
  final String? profileAvatar;
  final int currentStreak;
  final int currentLevel;
  final int totalXp;
  final int xpInLevel;
  final int xpToNextLevel;
  final bool openReferralOnLoad;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final TaskRepository _repo = TaskRepository();
  final ReferralService _referral = ReferralService.instance;
  final ImagePicker _imagePicker = ImagePicker();
  late Future<Set<String>> _earnedFuture;
  late Future<_JourneySnapshot> _journeySnapshotFuture;
  late final AnimationController _xpController;
  late final Animation<double> _xpAnimation;
  late String _profileName;
  String? _profileAvatar;
  late final TextEditingController _nameController;
  final TextEditingController _referralCodeController = TextEditingController();
  final GlobalKey _referralCardKey = GlobalKey();
  ReferralStatus? _referralStatus;
  bool _referralLoaded = false;
  bool _referralBusy = false;
  bool _referralExpanded = false;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _profileName = TaskRepository.sanitizeProfileName(widget.profileName);
    _profileAvatar = _sanitizeAvatar(widget.profileAvatar);
    _referralExpanded = widget.openReferralOnLoad;
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
    if (widget.openReferralOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToReferralCard();
      });
    }
    _loadSavedProfileAvatar();
    _loadReferralStatus();
  }

  @override
  void dispose() {
    _xpController.dispose();
    _nameController.dispose();
    _referralCodeController.dispose();
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
    return AppLocalizations(
      Locale(LocaleService.instance.effectiveLanguageCode),
    ).levelTitle(level);
  }

  String _sparkHintLabel(String title, int remainingSparks) {
    final l10n = AppLocalizations(
      Locale(LocaleService.instance.effectiveLanguageCode),
    );
    if (remainingSparks <= 0) {
      return l10n.trf('{title} ready now', {'title': title});
    }
    final unit = remainingSparks == 1 ? l10n.tr('spark') : l10n.tr('sparks');
    return l10n.trf('{title} in {count} {unit}', {
      'title': title,
      'count': remainingSparks,
      'unit': unit,
    });
  }

  String _nextUnlockLabel({
    required Set<String> earnedBadges,
    required int totalCompleted,
    required Map<String, int> categoryCounts,
  }) {
    if (!earnedBadges.contains('cat_mind_10')) {
      final remaining = 10 - (categoryCounts['mind'] ?? 0);
      return _sparkHintLabel(
        AppLocalizations.lookup(
          LocaleService.instance.effectiveLanguageCode,
          'Focus Badge',
        ),
        remaining,
      );
    }
    if (!earnedBadges.contains('total_10')) {
      final remaining = 10 - totalCompleted;
      return _sparkHintLabel(
        AppLocalizations.lookup(
          LocaleService.instance.effectiveLanguageCode,
          'Spark Starter Badge',
        ),
        remaining,
      );
    }
    if (!earnedBadges.contains('cat_growth_10')) {
      final remaining = 10 - (categoryCounts['growth'] ?? 0);
      return _sparkHintLabel(
        AppLocalizations.lookup(
          LocaleService.instance.effectiveLanguageCode,
          'Growth Badge',
        ),
        remaining,
      );
    }
    if (!earnedBadges.contains('total_50')) {
      final remaining = 50 - totalCompleted;
      return _sparkHintLabel(
        AppLocalizations.lookup(
          LocaleService.instance.effectiveLanguageCode,
          'Momentum Badge',
        ),
        remaining,
      );
    }
    return AppLocalizations.lookup(
      LocaleService.instance.effectiveLanguageCode,
      'Mastery track active',
    );
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
          message = context.l10n.tr(
            'Camera permission is denied. Check app permissions.',
          );
        } else if (code.contains('no_available_camera') ||
            code.contains('camera_unavailable') ||
            code.contains('not_available')) {
          message = context.l10n.tr('Camera is not available on this device.');
        }
      } else {
        if (code.contains('denied') || code.contains('restricted')) {
          message = context.l10n.tr('Photo library permission is denied.');
        } else {
          message = context.l10n.tr('Unable to open gallery right now.');
        }
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          action: source == ImageSource.camera
              ? SnackBarAction(
                  label: context.l10n.tr('Gallery'),
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
                ? context.l10n.tr('Unable to open camera right now.')
                : context.l10n.tr('Unable to open gallery right now.'),
          ),
          behavior: SnackBarBehavior.floating,
          action: source == ImageSource.camera
              ? SnackBarAction(
                  label: context.l10n.tr('Gallery'),
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

  Future<void> _loadReferralStatus() async {
    final status = await _referral.getStatus();
    if (!mounted) return;
    setState(() {
      _referralStatus = status;
      _referralLoaded = true;
    });
  }

  Future<void> _scrollToReferralCard() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final targetContext = _referralCardKey.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
    );
  }

  Future<void> _copyReferralCode() async {
    final code = _referralStatus?.code.trim() ?? '';
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.tr('Invite code copied.')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _claimReferralCode() async {
    final input = _referralCodeController.text.trim().toUpperCase();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tr('Enter an invite code.')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (input == (_referralStatus?.code ?? '')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.tr('You cannot use your own invite code.'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _referralBusy = true);
    final result = await _referral.redeemCode(input);
    if (!mounted) return;
    setState(() => _referralBusy = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ??
                context.l10n.tr('Unable to claim invite code.'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _referralCodeController.clear();
    await _loadReferralStatus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.tr(
            'Referral reward unlocked: +1 extra spark slot and 1 day premium boost.',
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildReferralCard({
    required ThemeData theme,
    required ColorScheme scheme,
  }) {
    final status = _referralStatus;
    final code = status?.code ?? '';
    final hasRedeemed = (status?.redeemedCode ?? '').isNotEmpty;
    final sparkWord = (status?.extraSparkSlots ?? 0) == 1
        ? context.l10n.tr('slot')
        : context.l10n.tr('slots');

    return Container(
      key: _referralCardKey,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: _profileNeoGlassDecoration(
        scheme,
        tint: scheme.onSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() => _referralExpanded = !_referralExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: _profileNeoGlassDecoration(
                      scheme,
                      tint: scheme.onSurface,
                      radius: 8,
                      tintOpacity: 0.2,
                    ),
                    child: Icon(
                      Icons.group_add_rounded,
                      size: 16,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.tr('Referral rewards'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    _referralExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.referralBenefit,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (!_referralExpanded && _referralLoaded && status != null)
            Text(
              '${context.l10n.tr('Invites')}: ${status.invitedCount}  |  ${context.l10n.tr('Extra sparks')}: ${status.extraSparkSlots} $sparkWord',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (!_referralExpanded)
            Text(
              context.l10n.tr('Tap to open'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: !_referralLoaded
                  ? const SizedBox(
                      height: 36,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : status == null
                  ? Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.tr(
                              'Referral is unavailable right now.',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadReferralStatus,
                          child: Text(context.l10n.tr('Retry')),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: scheme.surfaceContainerHighest
                                      .withValues(alpha: 0.55),
                                ),
                                child: Text(
                                  code,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _copyReferralCode,
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: Text(context.l10n.tr('Copy')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${context.l10n.tr('Invites')}: ${status.invitedCount}  |  ${context.l10n.tr('Extra sparks')}: ${status.extraSparkSlots} $sparkWord',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (hasRedeemed)
                          Text(
                            context.l10n.trf('Invite used: {code}', {
                              'code': status.redeemedCode ?? '',
                            }),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _referralCodeController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(12),
                                    FilteringTextInputFormatter.allow(
                                      RegExp('[A-Za-z0-9]'),
                                    ),
                                  ],
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: context.l10n.tr(
                                      'Enter invite code',
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: _referralBusy
                                    ? null
                                    : _claimReferralCode,
                                child: _referralBusy
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(context.l10n.tr('Claim')),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
            crossFadeState: _referralExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cleanedName = TaskRepository.sanitizeProfileName(_profileName);
    final name = cleanedName.isEmpty ? l10n.friend : cleanedName;
    final initials = name.characters.first.toUpperCase();
    final avatar = _sanitizeAvatar(_profileAvatar);
    final safeLevel = widget.currentLevel <= 0 ? 1 : widget.currentLevel;
    final safeXpToNext = widget.xpToNextLevel <= 0 ? 1 : widget.xpToNextLevel;
    final clampedXpInLevel = widget.xpInLevel.clamp(0, safeXpToNext);
    final levelProgress = (clampedXpInLevel / safeXpToNext).clamp(0.0, 1.0);
    final hasStreakRing = widget.currentStreak > 0;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF030508)
          : theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF030508)
                      : theme.scaffoldBackgroundColor,
                ),
              ),
            ),
          ),
          Positioned(
            right: -150,
            bottom: -150,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        scheme.onSurface.withOpacity(isDark ? 0.04 : 0),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: false,
                  floating: true,
                  snap: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  toolbarHeight: 68,
                  titleSpacing: 16,
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: isDark ? const Color.fromRGBO(3, 5, 8, 0.96) : Colors.white.withOpacity(0.96),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.05) : scheme.onSurface.withOpacity(0.08),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.25),
                                blurRadius: 22,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _ProfileTopIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  title: Text(
                    l10n.tr('Profile'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(
                      height: 1,
                      margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        decoration: _profileNeoGlassDecoration(
                          scheme,
                          tint: scheme.onSurface,
                          radius: _kProfileCardRadius,
                          tintOpacity: 0.08,
                          surfaceOpacity: _kProfileCardSurfaceAlpha,
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
                                            color: Colors.white.withValues(
                                              alpha: hasStreakRing
                                                  ? (isDark ? 0.22 : 0.18)
                                                  : (isDark ? 0.12 : 0.1),
                                            ),
                                            width: 1.3,
                                          ),
                                          boxShadow: hasStreakRing
                                              ? [
                                                  BoxShadow(
                                                    color: scheme.onSurface
                                                        .withValues(
                                                          alpha: isDark
                                                              ? 0.2
                                                              : 0.14,
                                                        ),
                                                    blurRadius: 16,
                                                    spreadRadius: -2,
                                                  ),
                                                ]
                                              : [
                                                  BoxShadow(
                                                    color: scheme.onSurface
                                                        .withValues(
                                                          alpha: isDark
                                                              ? 0.08
                                                              : 0.05,
                                                        ),
                                                    blurRadius: 8,
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
                                                scheme.onSurface.withOpacity(0.9),
                                                scheme.onSurface,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: scheme.onSurface
                                                    .withValues(
                                                      alpha: isDark
                                                          ? 0.18
                                                          : 0.14,
                                                    ),
                                                blurRadius: 14,
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
                                            gradient: LinearGradient(
                                              colors: [
                                                scheme.surface,
                                                Color.alphaBlend(
                                                  scheme.onSurface.withValues(alpha: 0.12),
                                                  scheme.surface,
                                                ),
                                              ],
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.18,
                                              ),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.edit_rounded,
                                            size: 15,
                                            color: scheme.onSurface,
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
                                                  hintText: context.l10n.tr(
                                                    'Enter your first name',
                                                  ),
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
                                                color: scheme.onSurface,
                                                size: 20,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              tooltip: context.l10n.tr('Save'),
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
                                              tooltip: context.l10n.tr(
                                                'Cancel',
                                              ),
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
                                                                FontWeight.w600,
                                                            letterSpacing: 0.2,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Icon(
                                                    Icons.bolt_rounded,
                                                    size: 20,
                                                    color: scheme.onSurface,
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
                                                      color: scheme.onSurface
                                                          .withValues(
                                                            alpha: 0.9,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      l10n.tr('Edit'),
                                                      style: theme
                                                          .textTheme
                                                          .labelMedium
                                                          ?.copyWith(
                                                                color:
                                                                    scheme.onSurface,
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
                                        l10n.levelLabel(
                                          safeLevel,
                                          _levelTitle(safeLevel),
                                        ),
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
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.onSurface.withValues(
                                          alpha: trackGlow,
                                        ),
                                        blurRadius: 22,
                                        spreadRadius: -6,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: scheme.onSurface.withValues(
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
                                                      scheme.onSurface.withValues(
                                                        alpha: isDark ? 0.8 : 0.5,
                                                      ),
                                                      scheme.surface,
                                                    ),
                                                    scheme.onSurface,
                                                    Color.alphaBlend(
                                                      Colors.white.withValues(
                                                        alpha: isDark
                                                            ? 0.18
                                                            : 0.28,
                                                      ),
                                                      scheme.onSurface,
                                                    ),
                                                  ],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: scheme.onSurface
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
                              '$clampedXpInLevel / $safeXpToNext ${l10n.trf('XP to Level {level}', {'level': safeLevel + 1})}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              LevelUnlocks.nextUnlockLabel(safeLevel),
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
                                    context.l10n.trf(
                                      '{title} in {count} {unit}',
                                      {
                                        'title': context.l10n.tr('Focus Badge'),
                                        'count': 3,
                                        'unit': context.l10n.tr('sparks'),
                                      },
                                    );
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: scheme.onSurface.withValues(
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
                              ? l10n.tr(
                                  'Complete 1 spark to move your weekly plan forward.',
                                )
                              : todayCount <= 0
                              ? l10n.tr('Light your first spark today.')
                              : l10n.tr(
                                  'Do one more spark today to keep momentum.',
                                );
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
                      const SizedBox(height: 12),
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
                            decoration: _profileNeoGlassDecoration(
                              scheme,
                              tint: scheme.onSurface,
                              surfaceOpacity: 0.72,
                              tintOpacity: 0.1,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.tr('Journey'),
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
                                        l10n.tr('Your journey just started.'),
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
                                        label: Text(
                                          l10n.tr('Unlock first badge'),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 0,
                                            vertical: 4,
                                          ),
                                          foregroundColor: scheme.onSurface,
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
                      const SizedBox(height: 10),
                      _buildReferralCard(theme: theme, scheme: scheme),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  const Color(0xFF34D5FF).withValues(alpha: 0.12),
                  scheme.surface,
                ),
                Color.alphaBlend(
                  const Color(0xFF8B5CF6).withValues(alpha: 0.14),
                  scheme.surface,
                ),
              ],
            ),
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
                  context.l10n.tr('Choose avatar'),
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
                        label: Text(context.l10n.tr('Take photo')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(
                          sheetContext,
                        ).pop(_avatarActionGallery),
                        icon: const Icon(Icons.photo_library_rounded, size: 16),
                        label: Text(context.l10n.tr('Gallery')),
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
                      label: Text(context.l10n.tr('Remove avatar')),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(null),
                      child: Text(context.l10n.tr('Done button')),
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

class _ProfileTopIconButton extends StatelessWidget {
  const _ProfileTopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: scheme.primary.withOpacity(0.08),
        highlightColor: scheme.primary.withOpacity(0.03),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: scheme.onSurface.withOpacity(0.9)),
        ),
      ),
    );
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
      nextUnlockLabel ??
      "${AppLocalizations.lookup(LocaleService.instance.effectiveLanguageCode, 'Focus Badge')} in 3 ${AppLocalizations.lookup(LocaleService.instance.effectiveLanguageCode, 'sparks')}";
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
      decoration: _profileNeoGlassDecoration(
        scheme,
        tint: const Color(0xFF8B5CF6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: _profileNeoGlassDecoration(
                  scheme,
                  tint: const Color(0xFF34D5FF),
                  radius: 8,
                  tintOpacity: 0.18,
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
                  context.l10n.tr('Weekly progress'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                !hasPlan
                    ? context.l10n.tr('No plan')
                    : snapshot.safeWeeklyDone <= 0
                    ? context.l10n.tr('Week just started')
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
      decoration: _profileNeoGlassDecoration(
        scheme,
        tint: const Color(0xFF34D5FF),
        surfaceOpacity: _kProfileCardSurfaceAlpha + 0.06,
        tintOpacity: 0.2,
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: _profileNeoGlassDecoration(
              scheme,
              tint: const Color(0xFF8B5CF6),
              radius: 8,
              tintOpacity: 0.18,
              surfaceOpacity: 0.9,
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
            child: Text(context.l10n.tr('Back to today')),
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
      decoration: _profileNeoGlassDecoration(
        scheme,
        tint: const Color(0xFF34D5FF),
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
                  context.l10n.tr('Last 7 days'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                context.l10n.trf('Best streak: {count}', {
                  'count': widget.bestStreak,
                }),
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
                        SizedBox(
                          width: 38,
                          height: 38,
                          child: Center(
                            child: Transform.scale(
                              scale: scale,
                              child: Stack(
                                clipBehavior: Clip.none,
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
    final dayLabel = bestStreak == 1
        ? context.l10n.tr('day')
        : context.l10n.tr('days');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _profileNeoGlassDecoration(
        scheme,
        tint: const Color(0xFF8B5CF6),
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
                        context.l10n.trf('Best streak: {count} {dayLabel}', {
                          'count': bestStreak,
                          'dayLabel': dayLabel,
                        }),
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
                        context.l10n.trf('Total sparks: {count}', {
                          'count': totalSparks,
                        }),
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
                context.l10n.trf('Consistency: {count}%', {
                  'count': consistencyPercent,
                }),
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
      decoration: _profileNeoGlassDecoration(
        scheme,
        tint: const Color(0xFF34D5FF),
        surfaceOpacity: _kProfileCardSurfaceAlpha + 0.03,
        tintOpacity: 0.2,
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            context.l10n.tr('You showed up today.'),
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
