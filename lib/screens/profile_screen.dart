import 'dart:io';

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
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: Color.alphaBlend(
      (tint ?? scheme.primary).withValues(alpha: tintOpacity.clamp(0.0, 0.08)),
      scheme.surface,
    ),
    border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
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
    var weeklyProgress = 0;
    if (weeklyPlan != null) {
      final progress = await _repo.getWeeklyProgress(weekKey: weekKey);
      weeklyProgress = weeklyPlan.targets.entries
          .where((entry) => entry.value > 0)
          .fold<int>(0, (sum, entry) => sum + (progress.done[entry.key] ?? 0));
    }
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
                color: scheme.onPrimaryContainer,
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
                color: scheme.onPrimaryContainer,
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
        color: scheme.onPrimaryContainer,
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
      padding: const EdgeInsets.all(16),
      decoration: _profileNeoGlassDecoration(scheme, tint: scheme.onSurface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() => _referralExpanded = !_referralExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
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

    final nameEditor = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          autofocus: true,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            counterText: '',
            hintText: l10n.tr('Enter your first name'),
          ),
          onSubmitted: (_) => _saveInlineName(),
        ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          children: [
            TextButton(
              onPressed: _cancelInlineEdit,
              child: Text(l10n.tr('Cancel')),
            ),
            FilledButton(
              onPressed: _saveInlineName,
              child: Text(l10n.tr('Save')),
            ),
          ],
        ),
      ],
    );
    final nextBadge = FutureBuilder<_JourneySnapshot>(
      future: _journeySnapshotFuture,
      builder: (context, snapshot) {
        final label =
            snapshot.data?.safeNextUnlockLabel ??
            context.l10n.trf('{title} in {count} {unit}', {
              'title': context.l10n.tr('Focus Badge'),
              'count': 3,
              'unit': context.l10n.tr('sparks'),
            });

        return Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF030508)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF030508)
            : theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: _ProfileTopIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.tr('Profile'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _profileNeoGlassDecoration(
                      scheme,
                      tint: scheme.primary,
                      tintOpacity: 0.035,
                      radius: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              button: true,
                              label: l10n.tr('Choose avatar'),
                              child: InkWell(
                                onTap: _openAvatarPicker,
                                customBorder: const CircleBorder(),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: scheme.primaryContainer,
                                        border: Border.all(
                                          color: scheme.primary.withValues(
                                            alpha: hasStreakRing ? 0.7 : 0.25,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: _buildAvatarFace(
                                        theme: theme,
                                        scheme: scheme,
                                        avatar: avatar,
                                        initials: initials,
                                        size: 62,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: scheme.surface,
                                          border: Border.all(
                                            color: scheme.outline,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.edit_rounded,
                                          size: 12,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurface,
                                          height: 1.2,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.levelLabel(
                                      safeLevel,
                                      _levelTitle(safeLevel),
                                    ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_isEditingName)
                              IconButton(
                                onPressed: _startInlineEdit,
                                tooltip: l10n.tr('Edit'),
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: scheme.primary,
                                ),
                              ),
                          ],
                        ),
                        if (_isEditingName) ...[
                          const SizedBox(height: 16),
                          nameEditor,
                        ],
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            Text(
                              '$clampedXpInLevel / $safeXpToNext XP',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            Text(
                              l10n.trf('{xp} XP remaining to level {level}', {
                                'xp': safeXpToNext - clampedXpInLevel,
                                'level': safeLevel + 1,
                              }),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        AnimatedBuilder(
                          animation: _xpAnimation,
                          builder: (context, child) {
                            final t = _xpAnimation.value;
                            final animatedProgress = (levelProgress * t).clamp(
                              0.0,
                              1.0,
                            );
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: animatedProgress,
                                minHeight: 8,
                                backgroundColor: scheme.outline.withValues(
                                  alpha: 0.45,
                                ),
                                color: scheme.primary,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          LevelUnlocks.nextUnlockLabel(safeLevel),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                      final todayCount = data.safeRecentDailyCounts.isNotEmpty
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _NextStepCard(
                            message: nextStepMessage,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: _profileNeoGlassDecoration(
                              scheme,
                              radius: 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.tr('Your Stats'),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _WeeklyProgressCard(snapshot: data),
                                const Divider(height: 32),
                                _SevenDaySparkCard(
                                  dailyCounts: data.safeRecentDailyCounts,
                                  bestStreak: data.safeBestStreak,
                                ),
                                const Divider(height: 32),
                                _PersonalBestStrip(
                                  bestStreak: data.safeBestStreak,
                                  totalSparks: data.sparksLit,
                                  consistencyPercent:
                                      data.safeConsistencyPercent,
                                ),
                                if (showedUpToday) ...[
                                  const SizedBox(height: 16),
                                  const _MiniActivityFeedback(),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<Set<String>>(
                    future: _earnedFuture,
                    builder: (context, snapshot) {
                      final earned = snapshot.data ?? <String>{};
                      final defs = _allProfileBadges
                          .where((badge) => earned.contains(badge.id))
                          .toList();
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _profileNeoGlassDecoration(scheme),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BadgesScreen(),
                                ),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.emoji_events_outlined,
                                      color: scheme.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        l10n.tr('Journey'),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            nextBadge,
                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (defs.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.tr('Your journey just started.'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BadgesScreen(),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: Text(l10n.tr('Unlock first badge')),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                  ),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
                              for (
                                var index = 0;
                                index < defs.length;
                                index++
                              ) ...[
                                _JourneyBadgeRow(badge: defs[index]),
                                if (index < defs.length - 1)
                                  const Divider(height: 24),
                              ],
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildReferralCard(theme: theme, scheme: scheme),
                ],
              ),
            ),
          ),
        ),
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
          width: 48,
          height: 48,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              context.l10n.tr('Weekly progress'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: progress,
            color: scheme.primary,
            backgroundColor: scheme.outline.withValues(alpha: 0.4),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(16),
      decoration: _profileNeoGlassDecoration(
        scheme,
        tint: scheme.primary,
        tintOpacity: 0.06,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.flag_outlined, size: 20, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(
              context.l10n.tr('Back to today'),
              textAlign: TextAlign.center,
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
    return MaterialLocalizations.of(context).narrowWeekdays[weekday % 7];
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.tr('Last 7 days'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final pulseT = _pulse.value;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    : scheme.outline.withValues(alpha: 0.35);
                return Expanded(
                  child: Tooltip(
                    message:
                        '${MaterialLocalizations.of(context).formatMediumDate(day)}: $value',
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: dotColor,
                            borderRadius: BorderRadius.circular(9),
                            border: isToday
                                ? Border.all(
                                    color: scheme.primary.withValues(
                                      alpha: 0.65 + 0.2 * pulseT,
                                    ),
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: completed
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _weekdayShort(day.weekday),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isToday
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
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
    final l10n = context.l10n;
    final dayLabel = bestStreak == 1 ? l10n.tr('day') : l10n.tr('days');
    final metrics = [
      (
        Icons.local_fire_department_outlined,
        l10n.tr('Best streak'),
        '$bestStreak $dayLabel',
      ),
      (Icons.bolt_outlined, l10n.tr('Total sparks'), '$totalSparks'),
      (
        Icons.track_changes_rounded,
        l10n.tr('Consistency'),
        '$consistencyPercent%',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns = constraints.maxWidth >= 280 && scale <= 1.2
            ? 3
            : constraints.maxWidth >= 240 && scale <= 1.6
            ? 2
            : 1;
        final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 20,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      metric.$1,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      metric.$3,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metric.$2,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MiniActivityFeedback extends StatelessWidget {
  const _MiniActivityFeedback();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 16,
          color: scheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.tr('You showed up today.'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
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
