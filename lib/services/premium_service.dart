import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  static const _kPremiumUntil = 'premium_until_v1';
  static const _kNoAdsUntil = 'no_ads_until_v1';

  Future<int?> getPremiumUntilEpoch() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kPremiumUntil);
  }

  Future<int?> getNoAdsUntilEpoch() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kNoAdsUntil);
  }

  Future<bool> isPremiumActive() async {
    final until = await getPremiumUntilEpoch();
    if (until == null) return false;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  Future<bool> isNoAdsActive() async {
    final until = await getNoAdsUntilEpoch();
    if (until == null) return false;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  Future<void> grantPremium(Duration duration) async {
    await _extendUntil(_kPremiumUntil, duration);
  }

  Future<void> grantNoAds(Duration duration) async {
    await _extendUntil(_kNoAdsUntil, duration);
  }

  Future<void> _extendUntil(String key, Duration duration) async {
    final sp = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final current = sp.getInt(key);
    final base = (current != null && current > now) ? current : now;
    final next = base + duration.inMilliseconds;
    await sp.setInt(key, next);
  }
}
