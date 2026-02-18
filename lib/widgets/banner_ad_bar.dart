import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
      return;
    }
    final premiumActive = await PremiumService.instance.isPremiumActive();
    final noAds = await PremiumService.instance.isNoAdsActive();
    if (!mounted) return;
    if (premiumActive || noAds) {
      setState(() {
        _hideAds = true;
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
    _banner = BannerAd(
      adUnitId: AdService.effectiveBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() {});
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _banner = null;
          if (mounted) setState(() {});
          _scheduleRetry();
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (AdService.hideAdsForScreenshots) return const SizedBox.shrink();
    if (_hideAds) return const SizedBox.shrink();

    final ad = _banner;
    if (ad == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Color.alphaBlend(
              scheme.primary.withOpacity(0.05),
              scheme.surface,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: scheme.surfaceContainerHighest.withOpacity(0.35),
                    ),
                    child: Text(
                      'Sponsored',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onOpenRemoveAds,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: scheme.primary,
                      textStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Remove Ads'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: ad.size.width.toDouble(),
                  height: ad.size.height.toDouble(),
                  child: AdWidget(key: ValueKey(ad), ad: ad),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
