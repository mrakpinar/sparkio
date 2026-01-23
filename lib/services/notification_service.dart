import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int dailyReminderId = 1001;

  Future<void> init() async {
    if (_initialized) return;

    try {
      // Timezone init
      tz.initializeTimeZones();

      // flutter_timezone now returns TimezoneInfo (not String)
      final TimezoneInfo currentTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTz.identifier));

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _plugin.initialize(initSettings);

      // Android 13+ runtime permission request
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      _initialized = true;
    } catch (e) {
      // Fallback: set UTC and mark initialized to avoid repeated crashes.
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
      _initialized = true;
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await init();
  }

  Future<void> scheduleDailyReminder({int hour = 9, int minute = 0}) async {
    await _ensureInitialized();

    try {
      const androidDetails = AndroidNotificationDetails(
        'sparkio_daily',
        'Daily Reminder',
        channelDescription: 'Daily reminder notifications for Sparkio',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        dailyReminderId,
        'SPARKIO',
        "Today's Sparks are ready.",
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents:
            DateTimeComponents.time, // repeat daily at same time
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<void> cancelDailyReminder() async {
    await _ensureInitialized();
    await _plugin.cancel(dailyReminderId);
  }
}
