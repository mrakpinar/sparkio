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
  AdSize? _bannerSize;
  bool _hideAds = false;
  bool _bannerLoading = false;
  Timer? _retryTimer;
  int _bannerRetryCount = 0;
  int? _lastRequestedWidth;
  int? _currentWidth;

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
      _disposeBanner();
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
      _disposeBanner();
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

    final width = _currentWidth;
    if (width != null && width > 0) {
      unawaited(_ensureBannerForWidth(width));
    }
  }

  Future<void> _ensureBannerForWidth(int width) async {
    final normalizedWidth = width.clamp(1, 1200);
    if (_hideAds || !mounted) return;
    if (_bannerLoading) return;
    if (_banner != null && _lastRequestedWidth == normalizedWidth) return;
    await _loadBanner(normalizedWidth);
  }

  Future<void> _loadBanner(int width) async {
    _retryTimer?.cancel();
    _bannerLoading = true;
    _lastRequestedWidth = width;

    final adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || _hideAds) {
      _bannerLoading = false;
      return;
    }

    final size = adaptiveSize ?? AdSize.banner;
    _track('ad_banner_request', {
      'unit_mode': AdService.effectiveBannerUnitId == AdService.bannerUnitId
          ? 'live'
          : 'test',
      'retry_count': _bannerRetryCount,
      'width': width,
      'adaptive': adaptiveSize != null,
    });

    final nextBanner = BannerAd(
      adUnitId: AdService.effectiveBannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _disposeBanner(cancelRetry: false);
          _banner = ad as BannerAd;
          _bannerSize = size;
          _bannerLoading = false;
          _bannerRetryCount = 0;
          _track('ad_banner_loaded', {
            'width': width,
            'height': size.height,
            'adaptive': adaptiveSize != null,
          });
          if (mounted) setState(() {});
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (identical(_banner, ad)) {
            _banner = null;
            _bannerSize = null;
          }
          _bannerLoading = false;
          _bannerRetryCount += 1;
          _track('ad_banner_failed', {
            'error_code': error.code,
            'error_domain': error.domain,
            'error_message': error.message,
            'retry_count': _bannerRetryCount,
            'width': width,
            'adaptive': adaptiveSize != null,
          });
          if (mounted) setState(() {});
          _scheduleRetry(error);
        },
        onAdImpression: (_) {
          _track('ad_banner_impression');
        },
      ),
    );

    nextBanner.load();
  }

  void _scheduleRetry(LoadAdError error) {
    _retryTimer?.cancel();
    final steps = error.code == 3
        ? const <int>[30, 60, 120, 300]
        : const <int>[10, 20, 40, 80];
    final index = (_bannerRetryCount - 1).clamp(0, steps.length - 1);
    final delay = Duration(seconds: steps[index]);
    _track('ad_banner_retry_scheduled', {
      'error_code': error.code,
      'retry_count': _bannerRetryCount,
      'delay_sec': delay.inSeconds,
    });
    _retryTimer = Timer(delay, () {
      if (!mounted) return;
      if (_hideAds) return;
      if (_banner != null) return;
      final width = _currentWidth;
      if (width == null || width <= 0) return;
      unawaited(_loadBanner(width));
    });
  }

  void _disposeBanner({bool cancelRetry = true}) {
    if (cancelRetry) {
      _retryTimer?.cancel();
    }
    _banner?.dispose();
    _banner = null;
    _bannerSize = null;
    _bannerLoading = false;
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _disposeBanner(cancelRetry: false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (AdService.hideAdsForScreenshots) return const SizedBox.shrink();
    if (_hideAds) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.floor();
        if (width > 0 && width != _currentWidth) {
          _currentWidth = width;
          final shouldReload = _banner != null && _lastRequestedWidth != width;
          if (shouldReload) {
            _disposeBanner();
          }
          if (_banner == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              unawaited(_ensureBannerForWidth(width));
            });
          }
        }

        final ad = _banner;
        final size = _bannerSize;
        if (ad == null || size == null) return const SizedBox.shrink();

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
                    width: size.width.toDouble(),
                    height: size.height.toDouble(),
                    child: AdWidget(key: ValueKey(ad), ad: ad),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
