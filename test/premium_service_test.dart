import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparkio/services/premium_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('PremiumService', () {
    test('is inactive by default', () async {
      final service = PremiumService.instance;
      expect(await service.isPremiumActive(), isFalse);
      expect(await service.isNoAdsActive(), isFalse);
    });

    test('grantPremium activates premium', () async {
      final service = PremiumService.instance;
      await service.grantPremium(const Duration(minutes: 30));
      expect(await service.isPremiumActive(), isTrue);
    });

    test('grantPremium extends existing premium window', () async {
      final service = PremiumService.instance;
      await service.grantPremium(const Duration(minutes: 10));
      final firstUntil = await service.getPremiumUntilEpoch();
      await service.grantPremium(const Duration(minutes: 5));
      final secondUntil = await service.getPremiumUntilEpoch();

      expect(firstUntil, isNotNull);
      expect(secondUntil, isNotNull);
      expect(secondUntil!, greaterThan(firstUntil!));
    });

    test('grantNoAds activates ad-free period', () async {
      final service = PremiumService.instance;
      await service.grantNoAds(const Duration(minutes: 30));
      expect(await service.isNoAdsActive(), isTrue);
    });

    test('expired premium/no-ads are treated as inactive', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'premium_until_v1': now - 1000,
        'no_ads_until_v1': now - 1000,
      });
      final service = PremiumService.instance;
      expect(await service.isPremiumActive(), isFalse);
      expect(await service.isNoAdsActive(), isFalse);
    });
  });
}
