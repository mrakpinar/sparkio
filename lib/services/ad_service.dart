import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'premium_service.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // AdMob ad unit IDs.
  static const String bannerUnitId = 'ca-app-pub-9113236771764468/3264396817';
  static const String interstitialUnitId =
      'ca-app-pub-9113236771764468/2007155466';
  static const String rewardedUnitId = 'ca-app-pub-9113236771764468/3431422934';

  static const _kLastInterstitialDate = 'last_interstitial_date_v1';

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _launchInterstitialShown = false;

  bool get interstitialReady => _interstitial != null;
  bool get rewardedReady => _rewarded != null;

  Future<void> preloadAll() async {
    _loadInterstitial();
    _loadRewarded();
  }

  void _loadInterstitial() {
    if (_interstitial != null) return;

    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitial!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (_) {
          _interstitial = null;
        },
      ),
    );
  }

  void _loadRewarded() {
    if (_rewarded != null) return;

    RewardedAd.load(
      adUnitId: rewardedUnitId,
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

  /// Allow at most 1 interstitial per day.
  Future<bool> showInterstitialIfAllowed({required String dateKey}) async {
    final noAds = await PremiumService.instance.isNoAdsActive();
    if (noAds) return false;

    final can = await _canShowInterstitialToday(dateKey);
    if (!can) return false;

    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return false;
    }

    _interstitial = null;

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
    ad.show();
    return true;
  }

  /// Show once per app launch (cold start). No persistence between runs.
  Future<bool> showInterstitialOnLaunch() async {
    if (_launchInterstitialShown) return false;
    final noAds = await PremiumService.instance.isNoAdsActive();
    if (noAds) return false;

    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial(); // trigger load for next time in this session
      return false;
    }

    _launchInterstitialShown = true;
    _interstitial = null;

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

    ad.show();
    return true;
  }

  /// Returns true if the rewarded ad was completed.
  Future<bool> showRewardedToUnlock() async {
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
