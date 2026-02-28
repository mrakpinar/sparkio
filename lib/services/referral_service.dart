import 'package:cloud_functions/cloud_functions.dart';

import 'analytics_service.dart';
import '../app_strings.dart';
import 'locale_service.dart';
import 'premium_service.dart';
import 'task_repository.dart';

class ReferralStatus {
  const ReferralStatus({
    required this.code,
    required this.invitedCount,
    required this.redeemedCode,
    required this.creditsGranted,
    required this.creditsClaimed,
    required this.extraSparkSlots,
  });

  final String code;
  final int invitedCount;
  final String? redeemedCode;
  final int creditsGranted;
  final int creditsClaimed;
  final int extraSparkSlots;
}

class ReferralClaimResult {
  const ReferralClaimResult({
    required this.success,
    required this.claimedCredits,
    required this.status,
    this.errorMessage,
  });

  final bool success;
  final int claimedCredits;
  final ReferralStatus? status;
  final String? errorMessage;
}

class ReferralRewardSyncResult {
  const ReferralRewardSyncResult({
    required this.claimedCredits,
    required this.status,
  });

  final int claimedCredits;
  final ReferralStatus? status;
}

class ReferralService {
  ReferralService._();
  static final ReferralService instance = ReferralService._();

  FirebaseFunctions get _functions => FirebaseFunctions.instance;
  final TaskRepository _repo = TaskRepository();
  final PremiumService _premium = PremiumService.instance;

  Future<ReferralStatus?> getStatus() async {
    try {
      final installId = await _repo.getOrCreateInstallId();
      final callable = _functions.httpsCallable('getOrCreateReferralCode');
      final response = await callable.call(<String, dynamic>{
        'installId': installId,
      });
      final data = _asMap(response.data);
      if (data == null) return null;
      final extraSlots = await _repo.getReferralExtraSparkSlots();
      return _statusFromPayload(data, extraSparkSlots: extraSlots);
    } catch (_) {
      return null;
    }
  }

  Future<ReferralClaimResult> redeemCode(String rawCode) async {
    final code = _normalizeCode(rawCode);
    if (code.isEmpty) {
      return const ReferralClaimResult(
        success: false,
        claimedCredits: 0,
        status: null,
        errorMessage: 'Enter a valid invite code.',
      );
    }

    try {
      final installId = await _repo.getOrCreateInstallId();
      final callable = _functions.httpsCallable('redeemReferralCode');
      await callable.call(<String, dynamic>{
        'installId': installId,
        'code': code,
      });
      final syncResult = await syncAndApplyRewards();
      return ReferralClaimResult(
        success: true,
        claimedCredits: syncResult.claimedCredits,
        status: syncResult.status,
      );
    } on FirebaseFunctionsException catch (e) {
      return ReferralClaimResult(
        success: false,
        claimedCredits: 0,
        status: null,
        errorMessage: _mapRedeemError(e),
      );
    } catch (_) {
      return const ReferralClaimResult(
        success: false,
        claimedCredits: 0,
        status: null,
        errorMessage: 'Unable to claim invite right now.',
      );
    }
  }

  Future<ReferralRewardSyncResult> syncAndApplyRewards() async {
    try {
      final installId = await _repo.getOrCreateInstallId();
      final callable = _functions.httpsCallable('syncReferralRewards');
      final response = await callable.call(<String, dynamic>{
        'installId': installId,
      });
      final data = _asMap(response.data);
      if (data == null) {
        return const ReferralRewardSyncResult(claimedCredits: 0, status: null);
      }

      final claimableCredits = _asInt(data['claimableCredits']);
      if (claimableCredits > 0) {
        await _repo.addReferralExtraSparkSlots(claimableCredits);
        await _premium.grantPremium(Duration(days: claimableCredits));
        await AnalyticsService.instance.logEvent(
          'referral_reward_claimed',
          params: {'credits': claimableCredits},
        );
      }

      final extraSlots = await _repo.getReferralExtraSparkSlots();
      return ReferralRewardSyncResult(
        claimedCredits: claimableCredits,
        status: _statusFromPayload(data, extraSparkSlots: extraSlots),
      );
    } catch (_) {
      return const ReferralRewardSyncResult(claimedCredits: 0, status: null);
    }
  }

  ReferralStatus _statusFromPayload(
    Map<String, dynamic> payload, {
    required int extraSparkSlots,
  }) {
    final code = (payload['code'] as String?)?.trim() ?? '';
    return ReferralStatus(
      code: code,
      invitedCount: _asInt(payload['invitedCount']),
      redeemedCode: (payload['redeemedCode'] as String?)?.trim(),
      creditsGranted: _asInt(payload['creditsGranted']),
      creditsClaimed: _asInt(payload['creditsClaimed']),
      extraSparkSlots: extraSparkSlots,
    );
  }

  String _normalizeCode(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  String _mapRedeemError(FirebaseFunctionsException e) {
    final message = (e.message ?? '').toLowerCase();
    final code = LocaleService.instance.effectiveLanguageCode;
    if (message.contains('already_redeemed')) {
      return AppLocalizations.lookup(code, 'You already used an invite code.');
    }
    if (message.contains('self_referral')) {
      return AppLocalizations.lookup(
        code,
        'You cannot use your own invite code.',
      );
    }
    if (message.contains('invalid_code')) {
      return AppLocalizations.lookup(code, 'Invite code is invalid.');
    }
    if (message.contains('code_required')) {
      return AppLocalizations.lookup(code, 'Enter a valid invite code.');
    }
    return AppLocalizations.lookup(code, 'Unable to claim invite right now.');
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}




