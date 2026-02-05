import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'premium_service.dart';

class IapState {
  const IapState({
    required this.available,
    required this.loading,
    required this.products,
    required this.message,
  });

  final bool available;
  final bool loading;
  final List<ProductDetails> products;
  final String? message;

  IapState copyWith({
    bool? available,
    bool? loading,
    List<ProductDetails>? products,
    String? message,
  }) {
    return IapState(
      available: available ?? this.available,
      loading: loading ?? this.loading,
      products: products ?? this.products,
      message: message,
    );
  }
}

class IapService {
  IapService._();
  static final IapService instance = IapService._();

  static const Set<String> productIds = {'premium_monthly', 'premium_yearly'};
  static const String packageName = 'com.mrahmiakpinar.sparkio';

  final InAppPurchase _iap = InAppPurchase.instance;
  final PremiumService _premium = PremiumService.instance;

  final ValueNotifier<IapState> state = ValueNotifier<IapState>(
    const IapState(
      available: false,
      loading: true,
      products: [],
      message: null,
    ),
  );

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> init() async {
    if (state.value.loading == false && state.value.available) {
      return;
    }

    final available = await _iap.isAvailable();
    state.value = state.value.copyWith(available: available, loading: true);

    if (!available) {
      state.value = state.value.copyWith(
        loading: false,
        message: 'Store not available.',
      );
      return;
    }

    await _queryProducts();

    _subscription ??= _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        state.value = state.value.copyWith(
          loading: false,
          message: 'Purchase error.',
        );
      },
    );
  }

  Future<void> _queryProducts() async {
    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      state.value = state.value.copyWith(
        loading: false,
        message: 'Unable to load products.',
      );
      return;
    }

    final products = response.productDetails.toList()
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

    state.value = state.value.copyWith(
      loading: false,
      products: products,
      message: products.isEmpty ? 'No products found.' : null,
    );
  }

  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        state.value = state.value.copyWith(message: 'Purchase pending...');
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        state.value = state.value.copyWith(message: 'Purchase failed.');
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final valid = await _verifyPurchase(purchase);
        if (valid) {
          await _grantPremiumForProduct(purchase.productID);
          state.value = state.value.copyWith(message: 'Premium active.');
        } else {
          state.value = state.value.copyWith(message: 'Purchase invalid.');
        }
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    if (kDebugMode) return true;
    try {
      final token = purchase.verificationData.serverVerificationData;
      if (token.isEmpty) return false;
      final callable =
          FirebaseFunctions.instance.httpsCallable('verifyPurchase');
      final response = await callable.call(<String, dynamic>{
        'packageName': packageName,
        'productId': purchase.productID,
        'purchaseToken': token,
      });
      final data = response.data;
      return data is Map && data['valid'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _grantPremiumForProduct(String productId) async {
    if (productId == 'premium_yearly') {
      await _premium.grantPremium(const Duration(days: 365));
      await _premium.grantNoAds(const Duration(days: 365));
      return;
    }

    await _premium.grantPremium(const Duration(days: 30));
    await _premium.grantNoAds(const Duration(days: 30));
  }
}
