import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparkio/app_strings.dart';
import 'package:sparkio/models/focus_session.dart';
import 'package:sparkio/models/task.dart';
import 'package:sparkio/screens/focus_screen.dart';
import 'package:sparkio/services/notification_service.dart';
import 'package:sparkio/services/task_repository.dart';

class _Audio extends Fake implements AudioPlayer {
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
  @override
  Future<void> setLoopMode(LoopMode mode) async {}
  @override
  Future<Duration?> setAsset(
    String assetPath, {
    String? package,
    bool preload = true,
    Duration? initialPosition,
    dynamic tag,
  }) async => const Duration(minutes: 1);
}

class _Notifications extends Fake implements NotificationService {
  @override
  Future<void> scheduleTaskTimer({
    required int notificationId,
    required String title,
    required String body,
    required Duration duration,
  }) async {}
  @override
  Future<void> showTaskTimerOngoing({
    required String taskTitle,
    required Duration remaining,
    required Duration total,
  }) async {}
  @override
  Future<void> cancelTaskTimer(int notificationId) async {}
  @override
  Future<void> cancelTaskTimerOngoing() async {}
}

class _Clock {
  DateTime value = DateTime(2026, 11, 10, 12);
  void advance(Duration duration) => value = value.add(duration);
}

const _task = Task(
  id: 'focus_task',
  title: 'Breathing break',
  category: 'calm',
  durationMinutes: 1,
);

Future<void> _host(
  WidgetTester tester,
  _Clock clock,
  List<bool?> results, {
  String language = 'en',
  void Function(FocusSessionResult)? onResult,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                final result = await Navigator.of(context)
                    .push<FocusSessionResult>(
                      MaterialPageRoute(
                        builder: (_) => FocusScreen(
                          task: _task,
                          audioPlayer: _Audio(),
                          notifications: _Notifications(),
                          now: () => clock.value,
                        ),
                      ),
                    );
                results.add(result?.completed);
                if (result != null) onResult?.call(result);
              },
              child: const Text('Open focus'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open focus'));
  await tester.pumpAndSettle();
  expect(find.byType(FocusScreen), findsOneWidget);
}

Future<void> _leave(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Leave session'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TextButton, 'Leave session'));
  await tester.pumpAndSettle();
  expect(find.byType(FocusScreen), findsNothing);
}

Future<void> _expectProgressUnchanged() async {
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getInt('total_xp_v1'), 17);
  expect(prefs.getInt('total_completed_v1'), 4);
  expect(prefs.getInt('streak_count_v1'), 3);
  expect(prefs.getString('completed_map_v1'), '{}');
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'total_xp_v1': 17,
      'total_completed_v1': 4,
      'streak_count_v1': 3,
      'completed_map_v1': '{}',
    }),
  );

  testWidgets(
    'back can continue the session or save and leave without completing',
    (tester) async {
      final clock = _Clock();
      final results = <bool?>[];
      await _host(tester, clock, results);
      await _open(tester);
      clock.advance(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('00:40'), findsOneWidget);
      final back = tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Continue'));
      await tester.pumpAndSettle();
      await back;
      expect(find.byType(FocusScreen), findsOneWidget);
      expect(results, isEmpty);
      final leaveBack = tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Leave session'));
      await tester.pumpAndSettle();
      await leaveBack;
      expect(find.byType(FocusScreen), findsNothing);
      expect(results, [false]);
      final saved = await TaskRepository().getFocusSession(
        taskId: _task.id,
        dateKey: '2026-11-10',
      );
      expect(saved!.remainingSeconds, 40);
      expect(saved.isPaused, isTrue);
      await _expectProgressUnchanged();

      clock.advance(const Duration(minutes: 5));
      await _open(tester);
      expect(find.text('00:40'), findsOneWidget);
      expect(find.byTooltip('Resume timer'), findsOneWidget);
      await tester.tap(find.byTooltip('Resume timer'));
      await tester.pump();
      clock.advance(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('00:30'), findsOneWidget);
      await _leave(tester);
    },
  );

  testWidgets(
    'paused timer and ambient selection survive leaving and reopening',
    (tester) async {
      final clock = _Clock();
      await _host(tester, clock, <bool?>[]);
      await _open(tester);
      await tester.tap(find.widgetWithText(ActionChip, 'Rain'));
      await tester.pumpAndSettle();
      clock.advance(const Duration(seconds: 12));
      await tester.pump(const Duration(seconds: 12));
      await tester.tap(find.byTooltip('Pause timer'));
      await tester.pumpAndSettle();
      await _leave(tester);
      clock.advance(const Duration(minutes: 5));
      await _open(tester);
      expect(find.text('00:48'), findsOneWidget);
      expect(find.byTooltip('Resume timer'), findsOneWidget);
      final rain = tester.widget<ActionChip>(
        find.widgetWithText(ActionChip, 'Rain'),
      );
      expect(rain.labelStyle!.fontWeight, FontWeight.bold);
      await _leave(tester);
    },
  );

  testWidgets(
    'a restored running deadline that has elapsed still requires explicit completion',
    (tester) async {
      final clock = _Clock();
      await TaskRepository().saveFocusSession(
        FocusSession(
          taskId: _task.id,
          dateKey: '2026-11-10',
          totalSeconds: 60,
          remainingSeconds: 60,
          isPaused: false,
          endAt: clock.value.subtract(const Duration(seconds: 5)),
        ),
      );
      final results = <bool?>[];
      await _host(tester, clock, results);
      await _open(tester);
      expect(find.text('00:00'), findsOneWidget);
      expect(results, isEmpty);
      await _leave(tester);
      expect(results, [false]);
      await _expectProgressUnchanged();
    },
  );

  testWidgets(
    'zero and leaving never complete; explicit completion returns true and clears the session',
    (tester) async {
      final clock = _Clock();
      final results = <bool?>[];
      await _host(tester, clock, results);
      await _open(tester);
      clock.advance(const Duration(seconds: 60));
      await tester.pump(const Duration(seconds: 60));
      await tester.pumpAndSettle();
      expect(find.text('00:00'), findsOneWidget);
      expect(results, isEmpty);
      await _expectProgressUnchanged();
      await _leave(tester);
      expect(results, [false]);
      clock.advance(const Duration(minutes: 10));
      await _open(tester);
      expect(find.text('00:00'), findsOneWidget);
      await _expectProgressUnchanged();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Complete task'));
      await tester.pumpAndSettle();
      expect(results, [false, true]);
      expect(
        await TaskRepository().getFocusSession(
          taskId: _task.id,
          dateKey: '2026-11-10',
        ),
        isNull,
      );
    },
  );

  testWidgets(
    'explicit early completion keeps the existing true return contract',
    (tester) async {
      final results = <bool?>[];
      await _host(tester, _Clock(), results);
      await _open(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Finish early'));
      await tester.pumpAndSettle();
      expect(results, [true]);
      expect(
        await TaskRepository().getFocusSession(
          taskId: _task.id,
          dateKey: '2026-11-10',
        ),
        isNull,
      );
    },
  );

  testWidgets(
    'a recreated screen recovers a running deadline without claiming completion',
    (tester) async {
      final clock = _Clock();
      final results = <bool?>[];
      await _host(tester, clock, results);
      await _open(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      clock.advance(const Duration(seconds: 25));
      await _host(tester, clock, results);
      await _open(tester);
      expect(find.text('00:35'), findsOneWidget);
      expect(find.byTooltip('Pause timer'), findsOneWidget);
      expect(results, isEmpty);
      await _expectProgressUnchanged();
      await _leave(tester);
    },
  );

  testWidgets('yesterday\'s saved zero is not restored as today\'s task', (
    tester,
  ) async {
    await TaskRepository().saveFocusSession(
      const FocusSession(
        taskId: 'focus_task',
        dateKey: '2026-11-09',
        totalSeconds: 60,
        remainingSeconds: 0,
        isPaused: true,
      ),
    );
    await _host(tester, _Clock(), <bool?>[]);
    await _open(tester);
    expect(find.text('01:00'), findsOneWidget);
    expect(find.byTooltip('Pause timer'), findsOneWidget);
    await _leave(tester);
  });

  testWidgets(
    'crossing midnight saves the original day without completing or restoring it into today',
    (tester) async {
      final clock = _Clock()..value = DateTime(2026, 11, 10, 23, 59, 30);
      final results = <bool?>[];
      await _host(tester, clock, results);
      await _open(tester);
      clock.advance(const Duration(seconds: 45));
      await tester.pump(const Duration(seconds: 45));
      expect(find.text('00:15'), findsOneWidget);
      await tester.tap(find.byTooltip('Leave session'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This session belongs to an earlier day. Leaving will not complete the task or carry this session into today.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Leave session'));
      await tester.pumpAndSettle();
      expect(results, [false]);
      final previousDay = await TaskRepository().getFocusSession(
        taskId: _task.id,
        dateKey: '2026-11-10',
      );
      expect(previousDay!.remainingSeconds, 15);
      expect(previousDay.isPaused, isTrue);
      await _expectProgressUnchanged();
      await _open(tester);
      expect(find.text('01:00'), findsOneWidget);
      await _leave(tester);
    },
  );

  testWidgets(
    'completion after midnight returns its original day and keeps the old session',
    (tester) async {
      final clock = _Clock()..value = DateTime(2026, 11, 10, 23, 59, 30);
      FocusSessionResult? result;
      await _host(
        tester,
        clock,
        <bool?>[],
        onResult: (value) => result = value,
      );
      await _open(tester);
      clock.advance(const Duration(minutes: 1));
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Complete task'));
      await tester.pumpAndSettle();
      expect(result!.dateKey, '2026-11-10');
      expect(result!.completed, isTrue);
      expect(
        (await TaskRepository().getFocusSession(
          taskId: _task.id,
          dateKey: '2026-11-10',
        ))!.remainingSeconds,
        0,
      );
      await _expectProgressUnchanged();
    },
  );

  testWidgets(
    'Turkish exit choices and explicit completion labels are localized',
    (tester) async {
      final results = <bool?>[];
      await _host(tester, _Clock(), results, language: 'tr');
      await _open(tester);
      expect(find.text('Erken tamamla'), findsOneWidget);
      await tester.tap(find.byTooltip('Oturumdan çık'));
      await tester.pumpAndSettle();
      expect(find.text('Odak oturumundan çıkılsın mı?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Devam et'));
      await tester.pumpAndSettle();
      expect(results, isEmpty);
      await tester.tap(find.byTooltip('Oturumdan çık'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Oturumdan çık'));
      await tester.pumpAndSettle();
      expect(results, [false]);
    },
  );
}
