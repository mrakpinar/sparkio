import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  // Shared by every interstitial trigger for this process lifetime. Returning
  // from the background or rebuilding Home does not create another session.
  bool _sessionInterstitialShown = false;
  bool _interstitialRequestInProgress = false;
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
    if (hideAdsForScreenshots || _sessionInterstitialShown) return;
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
          if (_launchInterstitialPending && !_sessionInterstitialShown) {
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
    if (hideAdsForScreenshots || _sessionInterstitialShown) return;
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

  /// Compatibility entry point; all interstitials share the session limit.
  Future<bool> showInterstitialIfAllowed({required String dateKey}) {
    return _showSessionInterstitial(
      trigger: 'daily_gate',
      params: {'date_key': dateKey},
      waitUpTo: const Duration(seconds: 3),
    );
  }

  Future<bool> showInterstitialAfterTaskCompletion({
    required String dateKey,
    required int completedToday,
  }) async {
    // Keep the first task protected and the existing task-completion cadence.
    if (completedToday < 2 || completedToday.isOdd) {
      _track('interstitial_skipped', {
        'trigger': 'task_completion',
        'reason': completedToday < 2 ? 'first_task_protected' : 'cadence_skip',
        'completed_today': completedToday,
      });
      return false;
    }
    return _showSessionInterstitial(
      trigger: 'task_completion',
      params: {'date_key': dateKey, 'completed_today': completedToday},
      waitUpTo: const Duration(seconds: 2),
    );
  }

  /// Each cold start gets one opportunity, shared with task-completion ads.
  Future<bool> showInterstitialOnLaunch() async {
    if (_sessionInterstitialShown ||
        _launchInterstitialPending ||
        _interstitialRequestInProgress ||
        _interstitialShowing) {
      return false;
    }
    _launchInterstitialPending = true;
    final shown = await _showSessionInterstitial(
      trigger: 'launch',
      waitUpTo: Duration.zero,
    );
    if (!shown && _launchInterstitialPending) {
      _track('interstitial_queued', {'trigger': 'launch'});
    }
    return shown;
  }

  Future<void> _tryShowPendingLaunchInterstitial() async {
    if (!_launchInterstitialPending || _sessionInterstitialShown) return;
    await _showSessionInterstitial(
      trigger: 'launch',
      waitUpTo: Duration.zero,
    );
  }

  Future<bool> _showSessionInterstitial({
    required String trigger,
    required Duration waitUpTo,
    Map<String, Object?> params = const {},
  }) async {
    void skipped(String reason) {
      _track('interstitial_skipped', {
        ...params,
        'trigger': trigger,
        'reason': reason,
      });
    }

    if (hideAdsForScreenshots) {
      _launchInterstitialPending = false;
      skipped('hide_ads_define');
      return false;
    }
    if (_sessionInterstitialShown) {
      skipped('session_cap');
      return false;
    }
    if (_interstitialRequestInProgress || _interstitialShowing) {
      skipped('already_showing');
      return false;
    }

    // Reserve before the first await: launch, delayed load and task callbacks
    // must not pass the eligibility check concurrently.
    _interstitialRequestInProgress = true;
    InterstitialAd? ad;
    var released = false;
    void releaseAd() {
      if (released) return;
      released = true;
      _interstitialShowing = false;
      ad?.dispose();
    }

    try {
      if (await _isAdFreeActive()) {
        _launchInterstitialPending = false;
        skipped('ad_free_active');
        return false;
      }

      final readyAd = await _takeReadyInterstitial(waitUpTo: waitUpTo);
      ad = readyAd;
      if (readyAd == null) {
        skipped('not_ready');
        return false;
      }
      final outcome = Completer<bool>();
      void markShown() {
        if (!_sessionInterstitialShown) {
          _sessionInterstitialShown = true;
          _launchInterstitialPending = false;
          _interstitialRetryTimer?.cancel();
          _interstitialRetryTimer = null;
          _track('interstitial_shown', {...params, 'trigger': trigger});
        }
        if (!outcome.isCompleted) outcome.complete(true);
      }

      readyAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (_) => markShown(),
        onAdDismissedFullScreenContent: (_) {
          // Dismissal also confirms a display if the show callback was missed.
          markShown();
          releaseAd();
        },
        onAdFailedToShowFullScreenContent: (_, error) {
          releaseAd();
          _track('interstitial_skipped', {
            ...params,
            'trigger': trigger,
            'reason': 'failed_to_show',
            'error_code': error.code,
          });
          if (!outcome.isCompleted) outcome.complete(false);
          _scheduleInterstitialRetry();
        },
      );

      _interstitialShowing = true;
      await readyAd.show();
      return await outcome.future;
    } catch (error) {
      releaseAd();
      skipped('show_request_failed');
      // ignore: avoid_print
      print('AD: interstitial request failed ($trigger): $error');
      if (ad != null) _scheduleInterstitialRetry();
      return false;
    } finally {
      _interstitialRequestInProgress = false;
    }
  }

  /// Debug displays follow the same session limit as production triggers.
  Future<bool> showInterstitialNowForDebug() async {
    if (!kDebugMode) return false;
    return _showSessionInterstitial(
      trigger: 'debug',
      waitUpTo: const Duration(seconds: 5),
    );
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
