import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/analytics_service.dart';
import '../services/ad_service.dart';
import '../services/premium_service.dart';

class BannerAdBar extends StatefulWidget {
  const BannerAdBar({super.key, this.onOpenRemoveAds});

  final VoidCallback? onOpenRemoveAds;

  @override
  State<BannerAdBar> createState() => _BannerAdBarState();
}

class _BannerAdBarState extends State<BannerAdBar> with WidgetsBindingObserver {
  BannerAd? _banner;
  bool _hideAds = false;
  Timer? _retryTimer;
  int _bannerRetryCount = 0;

  void _track(String event, [Map<String, Object?> params = const {}]) {
    unawaited(AnalyticsService.instance.logEvent(event, params: params));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshNoAdsAndLoad();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNoAdsAndLoad();
    }
  }

  Future<void> _refreshNoAdsAndLoad() async {
    if (AdService.hideAdsForScreenshots) {
      if (mounted) {
        setState(() => _hideAds = true);
      }
      _track('ad_banner_hidden', {'reason': 'hide_ads_define'});
      return;
    }
    final premiumActive = await PremiumService.instance.isPremiumActive();
    final noAds = await PremiumService.instance.isNoAdsActive();
    if (!mounted) return;
    if (premiumActive || noAds) {
      setState(() {
        _hideAds = true;
      });
      _track('ad_banner_hidden', {
        'reason': premiumActive ? 'premium_active' : 'no_ads_active',
      });
      return;
    }

    if (_hideAds) {
      setState(() => _hideAds = false);
    }

    if (_banner == null) {
      _loadBanner();
    }
  }

  void _loadBanner() {
    _retryTimer?.cancel();
    _track('ad_banner_request', {
      'unit_mode': AdService.effectiveBannerUnitId == AdService.bannerUnitId
          ? 'live'
          : 'test',
      'retry_count': _bannerRetryCount,
    });

    _banner = BannerAd(
      adUnitId: AdService.effectiveBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _bannerRetryCount = 0;
          _track('ad_banner_loaded');
          if (mounted) setState(() {});
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _banner = null;
          _bannerRetryCount += 1;
          _track('ad_banner_failed', {
            'error_code': error.code,
            'error_domain': error.domain,
            'retry_count': _bannerRetryCount,
          });
          if (mounted) setState(() {});
          _scheduleRetry();
        },
        onAdImpression: (_) {
          _track('ad_banner_impression');
        },
      ),
    )..load();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_hideAds) return;
      if (_banner != null) return;
      _loadBanner();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _banner?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (AdService.hideAdsForScreenshots) return const SizedBox.shrink();
    if (_hideAds) return const SizedBox.shrink();

    final ad = _banner;
    if (ad == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            Colors.white.withOpacity(0.015),
            const Color(0xFF0E1523),
          ),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                scheme.primary.withOpacity(0.015),
                const Color(0xFF101726),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: ad.size.width.toDouble(),
                height: ad.size.height.toDouble(),
                child: AdWidget(key: ValueKey(ad), ad: ad),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
