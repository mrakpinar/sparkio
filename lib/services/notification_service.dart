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
  // Separate silent channel for the ongoing countdown notification.
  // (Android 8+ uses channel sound settings, so per-notification flags aren't enough.)
  // NOTE: Channel settings are immutable after creation. Bump the ID if you
  // change sound/vibration/importance behavior.
  static const String taskTimerOngoingChannelId =
      'sparkio_task_timers_countdown_v8';
  static const String taskTimerOngoingChannelName = 'Task Timer (Countdown)';
  static const String taskTimerOngoingChannelDescription =
      'Ongoing task timer countdown (silent)';
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
    required int endAtMs,
    required int timeoutAfterMs,
  }) {
    return AndroidNotificationDetails(
      taskTimerOngoingChannelId,
      taskTimerOngoingChannelName,
      channelDescription: taskTimerOngoingChannelDescription,
      // Keep it clearly visible in the shade (but silent).
      // Channel settings control sound/vibration; we set those to none on v6.
      //
      // Some OEM skins aggressively hide DEFAULT/LOW notifications. Keep this
      // HIGH so it shows up reliably in the shade, but keep it silent via the channel.
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      onlyAlertOnce: true,
      // Pin while a task is active so the countdown is always visible.
      ongoing: true,
      autoCancel: false,
      // Use the system chronometer so the countdown stays live even if the app is backgrounded.
      showWhen: true,
      when: endAtMs,
      usesChronometer: true,
      chronometerCountDown: true,
      playSound: false,
      enableVibration: false,
      timeoutAfter: timeoutAfterMs,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.stopwatch,
    );
  }

  Future<void> init() async {
    if (_initialized) return;

    // Important: don't let timezone lookup failures skip plugin initialization.
    // If init() short-circuits, *all* scheduled notifications can silently fail,
    // especially in release / Play builds.
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));

    try {
      // flutter_timezone returns TimezoneInfo (not String) in recent versions.
      final TimezoneInfo currentTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTz.identifier));
    } catch (e) {
      // Best-effort: keep UTC. Scheduling "now + duration" still works correctly.
      // ignore: avoid_print
      print('NOTI: failed to read device timezone, falling back to UTC: $e');
    }

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

    try {
      await _plugin.initialize(initSettings);
      await _createAndroidChannels();

      // Android 13+ runtime permission request (best-effort).
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      // Request exact alarms permission on supported Android versions (best-effort).
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestExactAlarmsPermission();

      _initialized = true;
    } catch (e) {
      // If initialization fails, keep _initialized=false so future calls retry.
      // ignore: avoid_print
      print('NOTI: NotificationService.init failed: $e');
      rethrow;
    }
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    // Clean up old countdown channels to avoid duplicates in Android settings.
    // Channel settings are immutable, so we bump the ID when changing behavior.
    await android.deleteNotificationChannel('sparkio_task_timers_silent_v5');
    await android.deleteNotificationChannel('sparkio_task_timers_countdown_v6');
    await android.deleteNotificationChannel('sparkio_task_timers_countdown_v7');

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
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        taskTimerOngoingChannelId,
        taskTimerOngoingChannelName,
        description: taskTimerOngoingChannelDescription,
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
        showBadge: false,
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
      await _ensureExactAlarmPermission();
    } catch (e) {
      // ignore: avoid_print
      print('NOTI: exact alarm request failed (daily): $e');
    }

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

      final exactAllowed = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.canScheduleExactNotifications();

      final candidates = <AndroidScheduleMode>[
        // alarmClock is most reliable on OEM ROMs (MIUI/ColorOS) for daily.
        AndroidScheduleMode.alarmClock,
        if (exactAllowed == true) AndroidScheduleMode.exactAllowWhileIdle,
        AndroidScheduleMode.inexactAllowWhileIdle,
      ];

      Object? lastError;
      for (final mode in candidates.toSet()) {
        try {
          await _plugin.zonedSchedule(
            dailyReminderId,
            _dailyTitle,
            _dailyBody,
            scheduled,
            details,
            androidScheduleMode: mode,
            matchDateTimeComponents:
                DateTimeComponents.time, // repeat daily at same time
          );
          // ignore: avoid_print
          print('NOTI: dailyReminder scheduled with mode=$mode');
          lastError = null;
          break;
        } catch (e) {
          // ignore: avoid_print
          print('NOTI: dailyReminder schedule failed with mode=$mode error=$e');
          lastError = e;
        }
      }
      if (lastError != null) throw lastError;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> scheduleQuickTest({int minutesFromNow = 1}) async {
    await _ensureInitialized();
    try {
      await _ensureExactAlarmPermission();
    } catch (e) {
      // ignore: avoid_print
      print('NOTI: exact alarm request failed (quickTest): $e');
    }
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

    // For short timers, prefer alarmClock: it is exact on modern Android
    // without relying on the user-granted "Alarms & reminders" access, and
    // tends to be the most reliable in the wild.
    final candidates = <AndroidScheduleMode>[
      AndroidScheduleMode.alarmClock,
      if (exactAllowed == true) AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ];

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    Object? lastError;
    for (final mode in candidates.toSet()) {
      try {
        await _plugin.zonedSchedule(
          id,
          _dailyTitle,
          _dailyBody,
          scheduled,
          details,
          androidScheduleMode: mode,
        );
        // ignore: avoid_print
        print('NOTI: quickTest scheduled with mode=$mode');
        lastError = null;
        break;
      } catch (e) {
        // ignore: avoid_print
        print('NOTI: quickTest schedule failed mode=$mode error=$e');
        lastError = e;
      }
    }
    final pending = await _plugin.pendingNotificationRequests();
    // ignore: avoid_print
    print('NOTI: pending=${pending.length}');
    if (lastError != null) throw lastError;
    return exactAllowed ?? false;
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
    try {
      await _ensureExactAlarmPermission();
    } catch (e) {
      // ignore: avoid_print
      print('NOTI: exact alarm request failed (taskTimer): $e');
    }
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
    // Prefer exactAllowWhileIdle when possible. Some OEMs appear to accept
    // alarmClock scheduling calls but still never deliver them, so alarmClock
    // is a fallback (not the first attempt).
    final candidates = <AndroidScheduleMode>[
      // alarmClock first: most reliable on MIUI/ColorOS for timers.
      AndroidScheduleMode.alarmClock,
      if (exactAllowed == true) AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ];

    Object? lastError;
    for (final mode in candidates.toSet()) {
      try {
        await _plugin.zonedSchedule(
          notificationId,
          title,
          body,
          scheduled,
          details,
          androidScheduleMode: mode,
        );
        // ignore: avoid_print
        print('NOTI: taskTimer scheduled with mode=$mode');
        lastError = null;
        break;
      } catch (e) {
        // ignore: avoid_print
        print('NOTI: taskTimer schedule failed mode=$mode error=$e');
        lastError = e;
      }
    }
    if (lastError != null) {
      // Fallback: show immediate notification so kullanıcı uyarı alsın.
      try {
        await _plugin.show(notificationId, title, body, details);
        // ignore: avoid_print
        print('NOTI: fallback immediate notification shown');
      } catch (e) {
        // ignore: avoid_print
        print('NOTI: fallback show failed $e');
        throw lastError;
      }
    }
    final pending = await _plugin.pendingNotificationRequests();
    // ignore: avoid_print
    print('NOTI: taskTimer pending=${pending.length}');
  }

  /// Ensure exact-alarm permission is granted on Android 12+ before scheduling.
  /// Some OEM ROMs (ColorOS/EMUI) silently drop alarms unless this is enabled.
  Future<void> _ensureExactAlarmPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    final allowed = await android.canScheduleExactNotifications();
    // ignore: avoid_print
    print('NOTI: exact alarm permission current=$allowed');
    if (allowed != true) {
      await android.requestExactAlarmsPermission();
      final after = await android.canScheduleExactNotifications();
      // ignore: avoid_print
      print('NOTI: exact alarm permission afterRequest=$after');
    }
  }

  Future<void> showTaskTimerOngoing({
    required String taskTitle,
    required Duration remaining,
    required Duration total,
  }) async {
    await _ensureInitialized();
    // The system chronometer shows the live countdown; keep the body generic so
    // we don't display a stale "Remaining: 05:00" while the OS timer updates.
    const body = 'Time left';
    final timeoutAfterMs = remaining.inMilliseconds.clamp(0, 24 * 3600 * 1000);
    final endAtMs = DateTime.now().add(remaining).millisecondsSinceEpoch;
    final androidDetails = _androidTaskTimerOngoingDetails(
      body: body,
      endAtMs: endAtMs,
      timeoutAfterMs: timeoutAfterMs,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(
      taskTimerOngoingId,
      'SPARKIO - $taskTitle',
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
