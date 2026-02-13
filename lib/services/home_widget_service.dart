import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HomeWidgetService {
  HomeWidgetService._();

  static final HomeWidgetService instance = HomeWidgetService._();
  static const MethodChannel _channel = MethodChannel('sparkio/home_widget');

  Future<void> updateSnapshot({
    required int remainingTasks,
    required bool timerActive,
    required bool timerFinished,
    String? timerTaskTitle,
    int timerRemainingSec = 0,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final safeRemaining = remainingTasks < 0 ? 0 : remainingTasks;
    final safeSeconds = timerRemainingSec < 0 ? 0 : timerRemainingSec;

    try {
      await _channel.invokeMethod<void>('updateHomeWidget', {
        'remainingTasks': safeRemaining,
        'timerActive': timerActive,
        'timerFinished': timerFinished,
        'timerTaskTitle': timerTaskTitle ?? '',
        'timerRemainingSec': safeSeconds,
      });
    } catch (_) {
      // Best-effort update. Ignore widget bridge errors.
    }
  }
}
