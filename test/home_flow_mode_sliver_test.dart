import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparkio/app_strings.dart';
import 'package:sparkio/models/task.dart';
import 'package:sparkio/widgets/home_flow_mode_sliver.dart';

void main() {
  testWidgets(
    'shows completion CTA instead of begin now when restored timer is finished',
    (tester) async {
      const task = Task(
        id: 'task_1',
        title: 'Breathing break',
        category: 'mind',
        difficulty: 'easy',
        durationMinutes: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                HomeFlowModeSliver(
                  task: task,
                  completedTodayCount: 0,
                  dailyGoalCount: 3,
                  latestWinTitle: null,
                  weeklyDoneCount: 0,
                  weeklyTargetCount: 3,
                  timerRunning: false,
                  timerPaused: false,
                  timerFinished: true,
                  timerRemaining: Duration.zero,
                  showMomentumPrompt: false,
                  onPrimaryAction: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Mark complete'), findsOneWidget);
      expect(find.text('Begin now'), findsNothing);
      expect(find.text('Ready to finish'), findsOneWidget);
    },
  );
}
