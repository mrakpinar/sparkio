import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent(
    String name, {
    Map<String, Object?> params = const {},
  }) async {
    try {
      final clean = <String, Object>{};
      params.forEach((key, value) {
        if (value == null) return;
        if (value is String || value is num) {
          clean[key] = value;
          return;
        }
        if (value is bool) {
          clean[key] = value ? 1 : 0;
          return;
        }
        clean[key] = value.toString();
      });
      await _analytics.logEvent(
        name: name,
        parameters: clean.isEmpty ? null : clean,
      );
    } catch (_) {
      // Best-effort analytics.
    }
  }

  Future<void> setUserProperty({
    required String name,
    String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (_) {
      // Best-effort analytics.
    }
  }
}

