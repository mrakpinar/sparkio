import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparkio/controllers/home_calendar_controller.dart';
import 'package:sparkio/controllers/home_controller.dart';
import 'package:sparkio/models/task.dart';
import 'package:sparkio/models/weekly_plan.dart';
import 'package:sparkio/services/ad_service.dart';
import 'package:sparkio/services/notification_service.dart';
import 'package:sparkio/services/premium_service.dart';
import 'package:sparkio/services/task_engine.dart';
import 'package:sparkio/services/task_repository.dart';

// Any opening-side-effect call fails: calendar loading must only use the repo.
class _Ads extends Fake implements AdService {}

class _Premium extends Fake implements PremiumService {}

class _Notifications extends Fake implements NotificationService {}

class _Repo extends TaskRepository {
  int loads = 0;
  Completer<void>? hold;
  bool fail = false;

  @override
  Future<List<Task>> loadPool() async {
    loads++;
    await hold?.future;
    if (fail) throw StateError('Calendar unavailable');
    return List.generate(
      8,
      (i) => Task(
        id: 'task_$i',
        title: 'Task $i',
        category: 'mind',
        durationMinutes: 1,
      ),
    );
  }
}

class _Harness {
  DateTime now = DateTime(2026, 11, 10, 12);
  final repo = _Repo();
  late final home = HomeController(
    repo: repo,
    engine: TaskEngine(),
    premium: _Premium(),
    adService: _Ads(),
    notifications: _Notifications(),
  );
  late HomeCalendarSnapshot visible;
  int applies = 0;
  int errors = 0;
  late final calendar = HomeCalendarController<HomeCalendarSnapshot>(
    now: () => now,
    load: (period) => home.loadCalendar(period: period, premiumActive: false),
    apply: (snapshot) {
      visible = snapshot;
      applies++;
    },
    onError: (_) => errors++,
  );

  Future<void> open() async {
    visible = await home.loadCalendar(
      period: LocalCalendarPeriod(now),
      premiumActive: false,
    );
    calendar.start(visible.period);
    await calendar.check();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('resuming in the same day does not reload or write daily state', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.calendar.dispose);
    await h.open();
    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getString('selected_tasks_v1');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await h.calendar.check();
    expect(h.repo.loads, 1);
    expect(h.applies, 0);
    expect(prefs.getString('selected_tasks_v1'), selected);
    expect(h.errors, 0);
    h.calendar.dispose();
  });

  testWidgets(
    'resuming on a new day replaces tasks and completed appearance together',
    (tester) async {
      final h = _Harness();
      addTearDown(h.calendar.dispose);
      await h.open();
      final oldStarter = h.visible.today.first.id;
      await h.repo.saveCompletedMap({oldStarter: true});
      await h.repo.incrementDailyCompleted('2026-11-10', delta: 2);
      await h.repo.addXp(17);
      final history = await h.repo.getDailyHistory(days: 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      h.now = DateTime(2026, 11, 11, 8);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await h.calendar.check();
      expect(h.repo.loads, 2);
      expect(h.applies, 1);
      expect(h.visible.period.dayKey, '2026-11-11');
      expect(h.visible.today.first.id, 'starter_2026-11-11');
      expect(h.visible.completed, isEmpty);
      expect(h.visible.todayCompleted, 0);
      expect(await h.repo.getCompletedMap(), isEmpty);
      expect(await h.repo.getDailyHistory(days: 0), history);
      expect((await h.repo.getXpProgress()).totalXp, 17);
      h.calendar.dispose();
    },
  );

  test(
    'Monday applies the queued plan and uses only the new week progress',
    () async {
      final h = _Harness()..now = DateTime(2026, 11, 15, 23, 59);
      addTearDown(h.calendar.dispose);
      await h.repo.saveWeeklyPlan(
        const WeeklyPlan(weekKey: '2026-11-09', targets: {'mind': 8}),
      );
      await h.repo.incrementWeeklyProgress(
        weekKey: '2026-11-09',
        category: 'mind',
        delta: 4,
      );
      await h.repo.queueWeeklyPlan(
        const WeeklyPlan(weekKey: '2026-11-16', targets: {'body': 5}),
      );
      await h.open();
      expect(h.visible.weeklyDone, {'mind': 4});
      h.now = DateTime(2026, 11, 16, 0, 1);
      await h.calendar.check();
      expect(h.visible.period.weekKey, '2026-11-16');
      expect(h.visible.weeklyTargets, {'body': 5});
      expect(h.visible.weeklyDone, isEmpty);
      expect(await h.repo.getQueuedWeeklyPlan(), isNull);
    },
  );

  testWidgets('foreground midnight reloads without a resume event', (
    tester,
  ) async {
    final h = _Harness()..now = DateTime(2026, 11, 10, 23, 59, 30);
    addTearDown(h.calendar.dispose);
    await h.open();
    h.now = DateTime(2026, 11, 11, 0, 0, 1);
    await tester.pump(const Duration(seconds: 31));
    await h.calendar.check();
    expect(h.repo.loads, 2);
    expect(h.visible.period.dayKey, '2026-11-11');
    h.calendar.dispose();
  });

  test(
    'concurrent reloads coalesce and stale timer/focus writes wait then get rejected',
    () async {
      final h = _Harness();
      addTearDown(h.calendar.dispose);
      await h.open();
      await h.repo.incrementDailyCompleted('2026-11-10', delta: 3);
      await h.repo.setStreakCount(4);
      await h.repo.addXp(11);
      final oldDay = h.visible.period.dayKey;
      h.now = DateTime(2026, 11, 11, 0, 1);
      h.repo.hold = Completer<void>();
      final checks = List.generate(4, (_) => h.calendar.check());
      var writes = 0;
      Future<void> staleWrite(DateTime _) async {
        writes++;
        await h.repo.incrementDailyCompleted('2026-11-11');
        await h.repo.addXp(50);
        await h.repo.setStreakCount(5);
      }

      final timer = h.calendar.runForDay(oldDay, staleWrite);
      final focus = h.calendar.runForDay(oldDay, staleWrite);
      await Future<void>.delayed(Duration.zero);
      expect(h.repo.loads, 2);
      expect(writes, 0);
      expect(h.visible.period.dayKey, oldDay);
      h.repo.hold!.complete();
      await Future.wait(checks);
      expect(await timer, isFalse);
      expect(await focus, isFalse);
      expect(h.repo.loads, 2);
      expect(h.applies, 1);
      expect(writes, 0);
      expect(await h.repo.getDailyCompleted('2026-11-11'), 0);
      expect((await h.repo.getXpProgress()).totalXp, 11);
      expect(await h.repo.getStreakCount(), 4);
      expect((await h.repo.getDailyHistory(days: 0))['2026-11-10'], 3);
      expect(await h.calendar.runForDay(null, staleWrite), isFalse);
    },
  );

  test(
    'a day change while loading discards the stale view before publishing',
    () async {
      final h = _Harness();
      addTearDown(h.calendar.dispose);
      await h.open();
      h.now = DateTime(2026, 11, 11, 23, 59);
      h.repo.hold = Completer<void>();
      final sync = h.calendar.check();
      await Future<void>.delayed(Duration.zero);
      h.now = DateTime(2026, 11, 12, 0, 1);
      h.repo.hold!.complete();
      await sync;
      expect(h.repo.loads, 3);
      expect(h.applies, 1);
      expect(h.visible.period.dayKey, '2026-11-12');
      expect(await h.repo.getSelectedDate(), '2026-11-12');
    },
  );

  test('clock rollback on resume uses the actual local day and week', () async {
    final h = _Harness()..now = DateTime(2026, 11, 16, 1);
    addTearDown(h.calendar.dispose);
    await h.open();
    h.now = DateTime(2026, 11, 15, 23);
    h.calendar.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await h.calendar.check();
    expect(h.visible.period.dayKey, '2026-11-15');
    expect(h.visible.period.weekKey, '2026-11-09');
    expect(h.repo.loads, 2);
  });

  test(
    'a failed reload blocks completion and a later retry recovers',
    () async {
      final h = _Harness();
      addTearDown(h.calendar.dispose);
      await h.open();
      h.now = DateTime(2026, 11, 11);
      h.repo.fail = true;
      await h.calendar.check();
      expect(h.errors, 1);
      expect(h.calendar.isCurrent, isFalse);
      var writes = 0;
      await expectLater(
        h.calendar.runForDay('2026-11-11', (_) async {
          writes++;
        }),
        throwsStateError,
      );
      expect(writes, 0);
      h.repo.fail = false;
      await h.calendar.check();
      expect(h.calendar.isCurrent, isTrue);
      expect(h.visible.period.dayKey, '2026-11-11');
    },
  );

  test(
    'a write accepted before midnight finishes before the new view loads',
    () async {
      final h = _Harness()..now = DateTime(2026, 11, 10, 23, 59, 59);
      addTearDown(h.calendar.dispose);
      await h.open();
      final accepted = await h.calendar.runForDay('2026-11-10', (
        startedAt,
      ) async {
        expect(LocalCalendarPeriod(startedAt).dayKey, '2026-11-10');
        h.now = DateTime(2026, 11, 11, 0, 0, 1);
        await h.repo.incrementDailyCompleted(
          LocalCalendarPeriod(startedAt).dayKey,
        );
      });
      expect(accepted, isTrue);
      expect(h.visible.period.dayKey, '2026-11-11');
      expect(h.visible.todayCompleted, 0);
      expect((await h.repo.getDailyHistory(days: 0))['2026-11-10'], 1);
      expect((await h.repo.getDailyHistory(days: 0))['2026-11-11'], isNull);
    },
  );

  test('a new week without a plan cannot inherit previous targets', () async {
    final h = _Harness()..now = DateTime(2026, 11, 15, 23, 59);
    addTearDown(h.calendar.dispose);
    await h.repo.saveWeeklyPlan(
      const WeeklyPlan(weekKey: '2026-11-09', targets: {'mind': 6}),
    );
    await h.open();
    h.now = DateTime(2026, 11, 16);
    await h.calendar.check();
    expect(h.visible.weeklyTargets, isEmpty);
    expect(h.visible.weeklyDone, isEmpty);
  });

  test(
    'returning to an earlier local day preserves that day history count',
    () async {
      final h = _Harness()..now = DateTime(2026, 11, 11, 1);
      addTearDown(h.calendar.dispose);
      await h.repo.incrementDailyCompleted('2026-11-10', delta: 3);
      await h.repo.incrementDailyCompleted('2026-11-11', delta: 2);
      await h.open();
      h.now = DateTime(2026, 11, 10, 23);
      await h.calendar.check();
      expect(h.visible.todayCompleted, 3);
      final previousHistory = await h.repo.getDailyHistory(days: 0);
      expect(previousHistory, {'2026-11-10': 3, '2026-11-11': 2});
      expect(await h.repo.incrementDailyCompleted('2026-11-10'), 4);
      expect(await h.repo.getDailyHistory(days: 0), {
        '2026-11-10': 4,
        '2026-11-11': 2,
      });
    },
  );
}
