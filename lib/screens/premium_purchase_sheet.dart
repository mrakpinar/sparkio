import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../app_strings.dart';
import '../services/analytics_service.dart';
import '../services/iap_service.dart';

BoxDecoration _premiumNeoGlassDecoration(
  ColorScheme scheme, {
  Color tint = const Color(0xFF34D5FF),
  double radius = 16,
  double tintOpacity = 0.14,
  double surfaceOpacity = 0.94,
}) {
  final isDark = scheme.brightness == Brightness.dark;
  final baseSurface = isDark
      ? const Color(0xFF101827).withOpacity(surfaceOpacity)
      : Color.alphaBlend(
          Colors.white.withOpacity(0.78),
          scheme.surface.withOpacity(surfaceOpacity),
        );
  final base = Color.alphaBlend(
    (isDark ? Colors.black : Colors.white).withOpacity(isDark ? 0.34 : 0.28),
    baseSurface,
  );
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(tint.withOpacity(tintOpacity), base),
        Color.alphaBlend(const Color(0xFF8B5CF6).withOpacity(0.08), base),
      ],
    ),
    border: Border.all(
      color: (isDark ? Colors.white : scheme.outline).withOpacity(
        isDark ? 0.08 : 0.28,
      ),
    ),
    boxShadow: [
      BoxShadow(
        color: (isDark ? Colors.black : const Color(0xFF8B92A8)).withOpacity(
          isDark ? 0.18 : 0.12,
        ),
        blurRadius: 22,
        spreadRadius: -8,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

class PremiumPurchaseSheet extends StatelessWidget {
  const PremiumPurchaseSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: media.size.height - media.padding.top - 18,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        decoration:
            _premiumNeoGlassDecoration(
              scheme,
              tint: const Color(0xFF34D5FF),
              radius: 24,
              tintOpacity: 0.12,
              surfaceOpacity: isDark ? 0.98 : 0.98,
            ).copyWith(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
        child: SafeArea(
          top: false,
          child: ValueListenableBuilder<IapState>(
            valueListenable: IapService.instance.state,
            builder: (context, state, _) {
              if (state.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!state.available) {
                return _MessageBlock(
                  title: l10n.tr('Store not available'),
                  message: l10n.tr('Please try again later.'),
                );
              }

              if (state.products.isEmpty) {
                return _MessageBlock(
                  title: l10n.tr('No subscriptions found'),
                  message:
                      state.message ??
                      l10n.tr('Create subscriptions in Play Console.'),
                );
              }

              return Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: _premiumNeoGlassDecoration(
                              scheme,
                              tint: const Color(0xFF8B7CFF),
                              radius: 18,
                              tintOpacity: 0.1,
                              surfaceOpacity: isDark ? 0.96 : 0.97,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: _premiumNeoGlassDecoration(
                                    scheme,
                                    tint: const Color(0xFF8B7CFF),
                                    radius: 14,
                                    tintOpacity: 0.16,
                                    surfaceOpacity: 0.94,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/in_app_icons/premium.png',
                                      width: 22,
                                      height: 22,
                                      fit: BoxFit.contain,
                                      color: scheme.primary,
                                      colorBlendMode: BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.tr('Go Premium'),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: scheme.onSurface
                                                  .withOpacity(0.95),
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.tr(
                                          'Monthly or yearly auto-renewing subscription.',
                                        ),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant
                                                  .withOpacity(0.74),
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _FeatureChip(
                                            label: l10n.tr('Unlimited tasks'),
                                          ),
                                          _FeatureChip(
                                            label: l10n.tr('No ads'),
                                          ),
                                          _FeatureChip(
                                            label: l10n.tr('AI tasks'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...state.products.map(
                            (product) => _ProductTile(
                              product: product,
                              highlight: product.id.contains('year'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => IapService.instance.restore(),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isDark
                                    ? const Color(0xFF101726)
                                    : scheme.surfaceVariant.withOpacity(0.72),
                                side: BorderSide(
                                  color:
                                      (isDark ? Colors.white : scheme.outline)
                                          .withOpacity(isDark ? 0.08 : 0.26),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                              child: Text(
                                l10n.tr('Restore purchases'),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: scheme.onSurface.withOpacity(0.88),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.tr(
                              'Cancel anytime in Google Play > Payments & subscriptions.',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.tr(
                              'By subscribing, you authorize recurring charges based on the plan you choose. Any trial or intro offer is shown before purchase confirmation.',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant.withOpacity(0.66),
                            ),
                          ),
                          if (state.message != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              state.message!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant.withOpacity(
                                  0.72,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.highlight});

  final ProductDetails product;
  final bool highlight;

  String _billingLabel(BuildContext context, String id) {
    final l10n = context.l10n;
    final value = id.toLowerCase();
    if (value.contains('year')) {
      return l10n.tr('Billed yearly, auto-renews every year.');
    }
    if (value.contains('month')) {
      return l10n.tr('Billed monthly, auto-renews every month.');
    }
    return l10n.tr('Recurring subscription, auto-renews until canceled.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _premiumNeoGlassDecoration(
        scheme,
        tint: highlight ? const Color(0xFF8B5CF6) : const Color(0xFF34D5FF),
        radius: 14,
        tintOpacity: highlight ? 0.22 : 0.1,
        surfaceOpacity: isDark ? 0.94 : 0.96,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withOpacity(0.94),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _billingLabel(context, product.id),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant.withOpacity(0.66),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (highlight) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: _premiumNeoGlassDecoration(
                      scheme,
                      tint: const Color(0xFF8B5CF6),
                      radius: 999,
                      tintOpacity: 0.24,
                      surfaceOpacity: 0.9,
                    ),
                    child: Text(
                      context.l10n.tr('Best value'),
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () {
              unawaited(
                AnalyticsService.instance.logEvent(
                  'premium_clicked',
                  params: {
                    'product_id': product.id,
                    'price': product.rawPrice,
                    'currency': product.currencyCode,
                  },
                ),
              );
              IapService.instance.buy(product);
            },
            style: FilledButton.styleFrom(
              backgroundColor: highlight
                  ? const Color(0xFF8B7CFF)
                  : const Color(0xFF5B6CFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              product.price,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBlock extends StatelessWidget {
  const _MessageBlock({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _premiumNeoGlassDecoration(
          scheme,
          tint: const Color(0xFF34D5FF),
          radius: 14,
          tintOpacity: 0.12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: _premiumNeoGlassDecoration(
        scheme,
        tint: const Color(0xFF8B5CF6),
        radius: 999,
        tintOpacity: 0.1,
        surfaceOpacity: 0.9,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.86),
        ),
      ),
    );
  }
}
