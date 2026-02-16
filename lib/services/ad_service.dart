import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';
import 'premium_service.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();
  static const bool hideAdsForScreenshots = bool.fromEnvironment(
    'HIDE_ADS',
    defaultValue: false,
  );

  // AdMob ad unit IDs.
  static const String bannerUnitId = 'ca-app-pub-9113236771764468/3264396817';
  static const String interstitialUnitId =
      'ca-app-pub-9113236771764468/2007155466';
  static const String rewardedUnitId = 'ca-app-pub-9113236771764468/3431422934';
  static const String _bannerTestUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _interstitialTestUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _rewardedTestUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static const _kLastInterstitialDate = 'last_interstitial_date_v1';
  static const _kLaunchGateDate = 'launch_interstitial_gate_date_v1';
  static const _kLaunchGateCount = 'launch_interstitial_gate_count_v1';

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _launchInterstitialShown = false;
  bool _launchInterstitialPending = false;
  bool _interstitialShowing = false;
  bool _interstitialLoading = false;
  Timer? _interstitialRetryTimer;
  int _interstitialRetryStep = 0;

  bool get interstitialReady => _interstitial != null;
  bool get rewardedReady => _rewarded != null;
  static String get effectiveBannerUnitId =>
      kReleaseMode ? bannerUnitId : _bannerTestUnitId;
  String get _effectiveInterstitialUnitId =>
      kReleaseMode ? interstitialUnitId : _interstitialTestUnitId;
  String get _effectiveRewardedUnitId =>
      kReleaseMode ? rewardedUnitId : _rewardedTestUnitId;

  void _track(String event, [Map<String, Object?> params = const {}]) {
    unawaited(AnalyticsService.instance.logEvent(event, params: params));
  }

  Future<bool> _isAdFreeActive() async {
    if (hideAdsForScreenshots) return true;
    final premium = await PremiumService.instance.isPremiumActive();
    if (premium) return true;
    final noAds = await PremiumService.instance.isNoAdsActive();
    return noAds;
  }

  Future<void> preloadAll() async {
    if (hideAdsForScreenshots) return;
    _loadInterstitial();
    _loadRewarded();
  }

  void _loadInterstitial() {
    if (hideAdsForScreenshots) return;
    if (_interstitial != null || _interstitialLoading) return;
    _interstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _effectiveInterstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          _interstitial = ad;
          _interstitial!.setImmersiveMode(true);
          _interstitialRetryStep = 0;
          _interstitialRetryTimer?.cancel();
          _interstitialRetryTimer = null;
          // ignore: avoid_print
          print('AD: interstitial loaded ($_effectiveInterstitialUnitId)');
          if (_launchInterstitialPending && !_launchInterstitialShown) {
            unawaited(_tryShowPendingLaunchInterstitial());
          }
        },
        onAdFailedToLoad: (error) {
          _interstitialLoading = false;
          // ignore: avoid_print
          print(
            'AD: interstitial failed to load ${error.code} ${error.message} ($_effectiveInterstitialUnitId)',
          );
          _interstitial = null;
          _scheduleInterstitialRetry();
        },
      ),
    );
  }

  void _scheduleInterstitialRetry() {
    if (hideAdsForScreenshots) return;
    if (_interstitialRetryTimer?.isActive == true) return;
    const steps = <int>[2, 4, 8, 15, 30, 60];
    final idx = _interstitialRetryStep.clamp(0, steps.length - 1);
    final delaySeconds = steps[idx];
    _interstitialRetryStep = (_interstitialRetryStep + 1).clamp(
      0,
      steps.length - 1,
    );
    _interstitialRetryTimer = Timer(Duration(seconds: delaySeconds), () {
      _interstitialRetryTimer = null;
      _loadInterstitial();
    });
  }

  Future<InterstitialAd?> _takeReadyInterstitial({
    Duration waitUpTo = const Duration(seconds: 4),
  }) async {
    if (_interstitial != null) {
      final ready = _interstitial;
      _interstitial = null;
      return ready;
    }

    _loadInterstitial();
    final endAt = DateTime.now().add(waitUpTo);
    while (DateTime.now().isBefore(endAt)) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (_interstitial != null) {
        final ready = _interstitial;
        _interstitial = null;
        return ready;
      }
    }
    return null;
  }

  void _loadRewarded() {
    if (hideAdsForScreenshots) return;
    if (_rewarded != null) return;

    RewardedAd.load(
      adUnitId: _effectiveRewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewarded!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (_) {
          _rewarded = null;
        },
      ),
    );
  }

  Future<bool> _canShowInterstitialToday(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    final last = sp.getString(_kLastInterstitialDate);
    return last != dateKey;
  }

  Future<void> _markInterstitialShown(String dateKey) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLastInterstitialDate, dateKey);
  }

  String _todayDateKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  /// Launch strategy:
  /// - show on the first launch of the day
  /// - then show after skipping two launches (1, 4, 7, ...)
  Future<bool> _shouldShowLaunchInterstitial() async {
    final sp = await SharedPreferences.getInstance();
    final todayKey = _todayDateKey();
    final savedDate = sp.getString(_kLaunchGateDate);
    var launchCount = sp.getInt(_kLaunchGateCount) ?? 0;

    if (savedDate != todayKey) {
      launchCount = 0;
      await sp.setString(_kLaunchGateDate, todayKey);
    }

    launchCount += 1;
    await sp.setInt(_kLaunchGateCount, launchCount);

    // 1st, 4th, 7th... launches of the day
    return ((launchCount - 1) % 3) == 0;
  }

  /// Allow at most 1 interstitial per day.
  Future<bool> showInterstitialIfAllowed({required String dateKey}) async {
    if (hideAdsForScreenshots) {
      _track('interstitial_skipped', {'reason': 'hide_ads_define'});
      return false;
    }
    if (_interstitialShowing) {
      // ignore: avoid_print
      print('AD: interstitial skipped (another ad is showing)');
      _track('interstitial_skipped', {'reason': 'already_showing'});
      return false;
    }

    final adFree = await _isAdFreeActive();
    if (adFree) {
      // ignore: avoid_print
      print('AD: interstitial skipped (premium/no-ads active)');
      _track('interstitial_skipped', {'reason': 'ad_free_active'});
      return false;
    }

    final can = await _canShowInterstitialToday(dateKey);
    if (!can) {
      // ignore: avoid_print
      print('AD: interstitial skipped (already shown today)');
      _track('interstitial_skipped', {'reason': 'daily_cap'});
      return false;
    }

    final ad = await _takeReadyInterstitial(
      waitUpTo: const Duration(seconds: 3),
    );
    if (ad == null) {
      // ignore: avoid_print
      print('AD: interstitial not ready, reloading');
      _track('interstitial_skipped', {'reason': 'not_ready'});
      _loadInterstitial();
      return false;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );

    await _markInterstitialShown(dateKey);
    // ignore: avoid_print
    print('AD: showing interstitial (daily gate)');
    _track('interstitial_shown', {'trigger': 'daily_gate'});
    ad.show();
    return true;
  }

  /// Show once per app launch (cold start). No persistence between runs.
  Future<bool> showInterstitialOnLaunch() async {
    if (hideAdsForScreenshots) {
      _track('interstitial_skipped', {'reason': 'hide_ads_define_launch'});
      return false;
    }
    if (_launchInterstitialShown || _launchInterstitialPending) return false;
    if (_interstitialShowing) return false;

    final adFree = await _isAdFreeActive();
    if (adFree) {
      // ignore: avoid_print
      print('AD: launch interstitial skipped (premium/no-ads active)');
      _track('interstitial_skipped', {'reason': 'ad_free_active_launch'});
      return false;
    }

    final shouldShow = await _shouldShowLaunchInterstitial();
    if (!shouldShow) {
      _track('interstitial_skipped', {'reason': 'launch_gate_skip'});
      return false;
    }

    final ad = _interstitial;
    if (ad != null) {
      _interstitial = null;
      return _showLaunchInterstitial(ad);
    }

    // Queue the launch ad so it auto-shows as soon as load succeeds.
    _launchInterstitialPending = true;
    _loadInterstitial();
    // ignore: avoid_print
    print('AD: launch interstitial queued');
    _track('interstitial_queued', {'trigger': 'launch'});
    return false;
  }

  Future<void> _tryShowPendingLaunchInterstitial() async {
    if (!_launchInterstitialPending || _launchInterstitialShown) return;
    if (_interstitialShowing) return;

    final adFree = await _isAdFreeActive();
    if (adFree) {
      _launchInterstitialPending = false;
      // ignore: avoid_print
      print(
        'AD: launch interstitial pending cancelled (premium/no-ads active)',
      );
      _track('interstitial_skipped', {'reason': 'ad_free_pending_launch'});
      return;
    }

    final ad = _interstitial;
    if (ad == null) return;

    _interstitial = null;
    _launchInterstitialPending = false;
    await _showLaunchInterstitial(ad);
  }

  Future<bool> _showLaunchInterstitial(InterstitialAd ad) async {
    _launchInterstitialShown = true;
    _interstitialShowing = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _interstitialShowing = false;
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _interstitialShowing = false;
        ad.dispose();
        _loadInterstitial();
        // ignore: avoid_print
        print('AD: launch interstitial failed to show ${error.message}');
      },
    );

    ad.show();
    // ignore: avoid_print
    print('AD: showing interstitial (launch)');
    _track('interstitial_shown', {'trigger': 'launch'});
    return true;
  }

  /// Debug helper to validate interstitial rendering without gates.
  Future<bool> showInterstitialNowForDebug() async {
    if (hideAdsForScreenshots) return false;
    if (!kDebugMode) return false;
    if (_interstitialShowing) return false;
    final ad = await _takeReadyInterstitial(
      waitUpTo: const Duration(seconds: 5),
    );
    if (ad == null) {
      _loadInterstitial();
      // ignore: avoid_print
      print('AD: debug interstitial not ready');
      return false;
    }

    _interstitialShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _interstitialShowing = false;
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _interstitialShowing = false;
        ad.dispose();
        _loadInterstitial();
        // ignore: avoid_print
        print('AD: debug interstitial failed to show ${error.message}');
      },
    );

    ad.show();
    // ignore: avoid_print
    print('AD: showing interstitial (debug)');
    return true;
  }

  /// Returns true if the rewarded ad was completed.
  Future<bool> showRewardedToUnlock() async {
    if (hideAdsForScreenshots) {
      _track('rewarded_skipped', {'reason': 'hide_ads_define'});
      return false;
    }
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }

    _rewarded = null;

    // Wait for the async result via Completer.
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        // If reward not earned yet, resolve false.
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewarded();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        // User earned the reward.
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
    );

    // Wait for callbacks to resolve.
    return completer.future;
  }
}
