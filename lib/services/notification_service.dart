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

  static const String channelId = 'sparkio_daily_v2';
  static const String channelName = 'Daily Reminder';
  static const String channelDescription =
      'Daily reminder notifications for Sparkio';
  static const String taskTimerChannelId = 'sparkio_task_timers_v1';
  static const String taskTimerChannelName = 'Task Timer';
  static const String taskTimerChannelDescription =
      'Task timer completion notifications';
  static const int taskTimerOngoingId = 2001;

  static const int dailyReminderId = 1001;
  static const _dailyTitle = 'SPARKIO';
  static const _dailyBody =
      "Your daily sparks are ready. Let's keep the streak!";

  AndroidNotificationDetails _androidDetails(String body) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      // Avoid missing resource issues on some devices.
      styleInformation: BigTextStyleInformation(body),
    );
  }

  AndroidNotificationDetails _androidTaskTimerDetails(String body) {
    return AndroidNotificationDetails(
      taskTimerChannelId,
      taskTimerChannelName,
      channelDescription: taskTimerChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      styleInformation: BigTextStyleInformation(body),
    );
  }

  AndroidNotificationDetails _androidTaskTimerOngoingDetails({
    required String body,
    required int max,
    required int progress,
  }) {
    return AndroidNotificationDetails(
      taskTimerChannelId,
      taskTimerChannelName,
      channelDescription: taskTimerChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      icon: 'ic_notification',
      styleInformation: BigTextStyleInformation(body),
      onlyAlertOnce: true,
      ongoing: true,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      maxProgress: max,
      progress: progress,
      showProgress: true,
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 24 * 3600);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

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

      await _createAndroidChannels();

      // Android 13+ runtime permission request
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      // Request exact alarms permission on supported Android versions
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestExactAlarmsPermission();

      _initialized = true;
    } catch (e) {
      // Fallback: set UTC and mark initialized to avoid repeated crashes.
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
      await _createAndroidChannels();
      _initialized = true;
    }
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        taskTimerChannelId,
        taskTimerChannelName,
        description: taskTimerChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await init();
  }

  Future<bool> scheduleDailyReminder({int hour = 9, int minute = 0}) async {
    await _ensureInitialized();

    try {
      await _plugin.cancel(dailyReminderId);
      final androidDetails = _androidDetails(_dailyBody);
      const iosDetails = DarwinNotificationDetails();

      final details = NotificationDetails(
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
      // Debug log for scheduling
      // ignore: avoid_print
      print('NOTI: scheduleDailyReminder at $scheduled (local)');

      try {
        await _plugin.zonedSchedule(
          dailyReminderId,
          _dailyTitle,
          _dailyBody,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          matchDateTimeComponents:
              DateTimeComponents.time, // repeat daily at same time
        );
      } catch (_) {
        await _plugin.zonedSchedule(
          dailyReminderId,
          _dailyTitle,
          _dailyBody,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents:
              DateTimeComponents.time, // repeat daily at same time
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> scheduleQuickTest({int minutesFromNow = 1}) async {
    await _ensureInitialized();
    await _plugin.cancelAll();
    final androidDetails = _androidDetails(_dailyBody);
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(Duration(minutes: minutesFromNow));
    // Debug log for scheduling
    // ignore: avoid_print
    print('NOTI: now=$now scheduled=$scheduled (local)');
    final exactAllowed = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.canScheduleExactNotifications();
    // ignore: avoid_print
    print('NOTI: exactAllowed=$exactAllowed');

    try {
      await _plugin.zonedSchedule(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        _dailyTitle,
        _dailyBody,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
      final pending = await _plugin.pendingNotificationRequests();
      // ignore: avoid_print
      print('NOTI: pending=${pending.length}');
      return exactAllowed ?? false;
    } catch (_) {
      await _plugin.zonedSchedule(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        _dailyTitle,
        _dailyBody,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      final pending = await _plugin.pendingNotificationRequests();
      // ignore: avoid_print
      print('NOTI: pending=${pending.length}');
      return exactAllowed ?? false;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final enabled = await android?.areNotificationsEnabled();
    return enabled ?? true;
  }

  Future<void> cancelDailyReminder() async {
    await _ensureInitialized();
    await _plugin.cancel(dailyReminderId);
  }

  Future<String?> showTestNotification() async {
    try {
      await _ensureInitialized();

      final androidDetails = _androidDetails(_dailyBody);
      const iosDetails = DarwinNotificationDetails();

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        _dailyTitle,
        _dailyBody,
        details,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> showRemoteNotification({String? title, String? body}) async {
    await _ensureInitialized();
    final androidDetails = _androidDetails(body ?? _dailyBody);
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title ?? _dailyTitle,
      body ?? _dailyBody,
      details,
    );
  }

  Future<void> showTaskTimerNotification({
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();
    final androidDetails = _androidTaskTimerDetails(body);
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> scheduleTaskTimer({
    required int notificationId,
    required String title,
    required String body,
    required Duration duration,
  }) async {
    await _ensureInitialized();
    final androidDetails = _androidTaskTimerDetails(body);
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(duration);
    // ignore: avoid_print
    print('NOTI: taskTimer now=$now scheduled=$scheduled (local)');
    final exactAllowed = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.canScheduleExactNotifications();
    // ignore: avoid_print
    print('NOTI: taskTimer exactAllowed=$exactAllowed');
    final scheduleMode = exactAllowed == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: scheduleMode,
    );
    final pending = await _plugin.pendingNotificationRequests();
    // ignore: avoid_print
    print('NOTI: taskTimer pending=${pending.length}');
  }

  Future<void> showTaskTimerOngoing({
    required String taskTitle,
    required Duration remaining,
    required Duration total,
  }) async {
    await _ensureInitialized();
    final totalSeconds = total.inSeconds.clamp(1, 24 * 3600);
    final remainingSeconds = remaining.inSeconds.clamp(0, totalSeconds);
    final progress = (totalSeconds - remainingSeconds).clamp(0, totalSeconds);
    final body = 'Remaining: ${_formatDuration(remaining)}';
    final androidDetails = _androidTaskTimerOngoingDetails(
      body: body,
      max: totalSeconds,
      progress: progress,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(
      taskTimerOngoingId,
      'SPARKIO • $taskTitle',
      body,
      details,
    );
  }

  Future<void> cancelTaskTimerOngoing() async {
    await _ensureInitialized();
    await _plugin.cancel(taskTimerOngoingId);
  }

  Future<void> cancelTaskTimer(int notificationId) async {
    await _ensureInitialized();
    await _plugin.cancel(notificationId);
  }
}
