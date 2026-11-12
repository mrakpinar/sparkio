import 'dart:ui' show SemanticsAction, SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkio/app_strings.dart';
import 'package:sparkio/models/task.dart';
import 'package:sparkio/widgets/home_flow_mode_sliver.dart';

const _labels = <String, ({String pause, String resume, String stop})>{
  'tr': (pause: 'Duraklat', resume: 'Devam et', stop: 'Sayacı durdur'),
  'en': (pause: 'Pause timer', resume: 'Resume timer', stop: 'Stop timer'),
  'es': (
    pause: 'Pausar temporizador',
    resume: 'Reanudar temporizador',
    stop: 'Detener temporizador',
  ),
  'de': (
    pause: 'Timer pausieren',
    resume: 'Timer fortsetzen',
    stop: 'Timer stoppen',
  ),
};

const _task = Task(
  id: 'timer_accessibility',
  title: 'Breathing break',
  category: 'mind',
  durationMinutes: 1,
);

Widget _timerApp({
  required String language,
  required bool paused,
  required VoidCallback onPause,
  required VoidCallback onStop,
  double textScale = 1,
}) {
  return MaterialApp(
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(useMaterial3: true),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: CustomScrollView(
        slivers: [
          HomeFlowModeSliver(
            task: _task,
            completedTodayCount: 0,
            dailyGoalCount: 3,
            latestWinTitle: null,
            weeklyDoneCount: 0,
            weeklyTargetCount: 3,
            timerRunning: !paused,
            timerPaused: paused,
            timerFinished: false,
            timerRemaining: const Duration(seconds: 42),
            showMomentumPrompt: false,
            onPrimaryAction: () {},
            onPauseAction: onPause,
            onEndAction: onStop,
          ),
        ],
      ),
    ),
  );
}

void _setViewport(WidgetTester tester, double width) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _controlBarApp({
  required String language,
  required Widget controlBar,
  required double horizontalInset,
  double textScale = 1,
}) {
  return MaterialApp(
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalInset / 2),
            child: controlBar,
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpControlBar(
  WidgetTester tester, {
  required String language,
  required bool paused,
  required VoidCallback onPause,
  required VoidCallback onStop,
  double width = 360,
  double textScale = 1,
}) async {
  _setViewport(tester, 360);
  // Obtain the real private control bar from the public widget. Isolating it
  // keeps unrelated task metadata layout outside these accessibility tests.
  final barFinder = find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_ActiveTimerControlBar',
  );
  await tester.pumpWidget(
    _timerApp(
      language: language,
      paused: false,
      onPause: onPause,
      onStop: onStop,
    ),
  );
  await tester.pump();
  final runningBar = tester.widget<Widget>(barFinder);
  final horizontalInset = 360 - tester.getSize(barFinder).width;
  Widget targetBar = runningBar;
  if (paused) {
    await tester.pumpWidget(
      _timerApp(
        language: language,
        paused: true,
        onPause: onPause,
        onStop: onStop,
      ),
    );
    await tester.pump();
    targetBar = tester.widget<Widget>(barFinder);
  }

  tester.view.physicalSize = Size(width, 900);
  // Exercise running -> paused with the existing decorative animation already
  // mounted; initially-paused animation disposal is a separate existing issue.
  await tester.pumpWidget(
    _controlBarApp(
      language: language,
      controlBar: runningBar,
      horizontalInset: horizontalInset,
      textScale: textScale,
    ),
  );
  await tester.pump();
  if (paused) {
    await tester.pumpWidget(
      _controlBarApp(
        language: language,
        controlBar: targetBar,
        horizontalInset: horizontalInset,
        textScale: textScale,
      ),
    );
    await tester.pump();
  }
}

void _expectAccessibleButton(WidgetTester tester, Finder finder, String label) {
  final data = tester.getSemantics(finder).getSemanticsData();
  // IconButton exposes its accessible description as a semantic tooltip.
  expect(data.tooltip, label);
  expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
  expect(data.hasFlag(SemanticsFlag.isEnabled), isTrue);
  expect(data.hasAction(SemanticsAction.tap), isTrue);
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
}

Future<void> _tapOuterEdges(WidgetTester tester, Finder finder) async {
  final rect = tester.getRect(finder);
  for (final point in [
    Offset(rect.left + 1, rect.center.dy),
    Offset(rect.right - 1, rect.center.dy),
    Offset(rect.center.dx, rect.top + 1),
    Offset(rect.center.dx, rect.bottom - 1),
  ]) {
    await tester.tapAt(point);
    await tester.pump();
  }
}

void main() {
  for (final entry in _labels.entries) {
    for (final paused in [false, true]) {
      final actionLabel = paused ? entry.value.resume : entry.value.pause;

      testWidgets(
        '${entry.key}: $actionLabel has a labeled, tappable 48 dp target',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            var pauseCalls = 0;
            var stopCalls = 0;
            await _pumpControlBar(
              tester,
              language: entry.key,
              paused: paused,
              onPause: () => pauseCalls++,
              onStop: () => stopCalls++,
            );

            final pauseButton = find.byTooltip(actionLabel);
            final stopButton = find.byTooltip(entry.value.stop);
            expect(pauseButton, findsOneWidget);
            expect(stopButton, findsOneWidget);
            _expectAccessibleButton(tester, pauseButton, actionLabel);
            _expectAccessibleButton(tester, stopButton, entry.value.stop);
            final actionIcon = paused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded;
            expect(tester.widget<Icon>(find.byIcon(actionIcon)).size, 17);
            expect(
              tester.widget<Icon>(find.byIcon(Icons.stop_rounded)).size,
              17,
            );

            await _tapOuterEdges(tester, pauseButton);
            expect(pauseCalls, 4);
            expect(stopCalls, 0);
            await _tapOuterEdges(tester, stopButton);
            expect(pauseCalls, 4);
            expect(stopCalls, 4);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );

      for (final layout in [
        (width: 280.0, textScale: 1.0),
        (width: 320.0, textScale: 1.0),
        (width: 320.0, textScale: 2.0),
      ]) {
        testWidgets(
          '${entry.key}: $actionLabel fits ${layout.width} dp at ${layout.textScale}x text',
          (tester) async {
            await _pumpControlBar(
              tester,
              language: entry.key,
              paused: paused,
              width: layout.width,
              textScale: layout.textScale,
              onPause: () {},
              onStop: () {},
            );

            for (final label in [actionLabel, entry.value.stop]) {
              final button = find.byTooltip(label);
              final rect = tester.getRect(button);
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(layout.width));
              expect(rect.width, greaterThanOrEqualTo(48));
              expect(rect.height, greaterThanOrEqualTo(48));
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('pause, resume and stop forward the existing timer callbacks', (
    tester,
  ) async {
    _setViewport(tester, 320);
    final paused = ValueNotifier(false);
    addTearDown(paused.dispose);
    final calls = <String>[];
    await tester.pumpWidget(
      ValueListenableBuilder<bool>(
        valueListenable: paused,
        builder: (context, isPaused, _) => _timerApp(
          language: 'tr',
          paused: isPaused,
          onPause: () {
            calls.add(isPaused ? 'resume' : 'pause');
            paused.value = !isPaused;
          },
          onStop: () => calls.add('stop'),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Duraklat'));
    await tester.pump();
    expect(find.byTooltip('Devam et'), findsOneWidget);
    expect(find.byTooltip('Duraklat'), findsNothing);
    await tester.tap(find.byTooltip('Devam et'));
    await tester.pump();
    expect(find.byTooltip('Duraklat'), findsOneWidget);
    await tester.tap(find.byTooltip('Sayacı durdur'));
    await tester.pump();
    expect(calls, ['pause', 'resume', 'stop']);
    expect(tester.takeException(), isNull);
  });
}
