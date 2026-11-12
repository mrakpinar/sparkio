import 'package:intl/intl.dart';

import '../models/challenge_mode.dart';
import '../models/task.dart';
import '../models/weekly_plan.dart';
import 'streak_service.dart';
import 'task_repository.dart';

enum TaskCompletionStatus { committed, alreadyCompleted, rejected, failed }

enum TaskCompletionFailureKind { returnedFalse, exception }

enum TaskCompletionRejection { unavailable, differentDay, taskNotInDay }

enum TaskCompletionStep {
  calendar,
  validation,
  completedMap,
  inlineTimer,
  completedTotals,
  xp,
  dailyProgress,
  challengeProgress,
  lastCompletedTask,
  taskBadges,
  weeklyProgress,
  categoryStreakRead,
  categoryStreak,
  categoryStreakDate,
  dailyStreakRead,
  dailyStreak,
  dailyStreakDate,
  bestStreak,
  streakBadges,
}

/// A snapshot captured under HomeCalendarController.runForDay's existing lock.
/// Carries the selected assignment identity; it is not a durable receipt.
class TaskCompletionRequest {
  TaskCompletionRequest({
    required this.task,
    required this.dateKey,
    required this.startedAt,
    required Iterable<String> todayTaskIds,
    required Iterable<String> todayAssignmentIds,
    required Map<String, bool> completed,
    required this.xpReward,
    required this.categoryWeeklyTarget,
    required this.currentStreak,
    required this.allDoneAlreadyHandled,
    required this.clearInlineTimer,
  }) : todayTaskIds = List.unmodifiable(todayTaskIds),
       todayAssignmentIds = List.unmodifiable(todayAssignmentIds),
       completed = Map.unmodifiable(completed);

  final Task task;
  final String dateKey;
  final DateTime startedAt;
  final List<String> todayTaskIds;
  final List<String> todayAssignmentIds;
  final Map<String, bool> completed;
  final int xpReward;
  final int categoryWeeklyTarget;
  final int currentStreak;
  final bool allDoneAlreadyHandled;
  final bool clearInlineTimer;
}

/// Values already read/written by the completion chain, for presentation only.
class TaskCompletionCommit {
  const TaskCompletionCommit({
    required this.dateKey,
    required this.weekKey,
    required this.xp,
    required this.dailyCompleted,
    required this.totalCompleted,
    required this.challenge,
    required this.badges,
    required this.weeklyProgress,
    required this.categoryStreak,
    required this.allDoneHandled,
    required this.streak,
    required this.streakBadges,
  });

  final String dateKey;
  final String weekKey;
  final XpProgress xp;
  final int dailyCompleted;
  final int totalCompleted;
  final ChallengeProgressUpdate? challenge;
  final List<String> badges;
  final WeeklyProgress? weeklyProgress;
  // Null means the existing streak rule did not require an update.
  final int? categoryStreak;
  final bool allDoneHandled;
  final int? streak;
  final List<String> streakBadges;
}

class TaskCompletionResult {
  const TaskCompletionResult._(
    this.status, {
    this.commit,
    this.rejection,
    this.failedStep,
    this.failureKind,
    this.error,
    this.stackTrace,
    this.inlineTimerCleared = false,
    this.allDoneHandled = false,
  });

  const TaskCompletionResult.alreadyCompleted()
    : this._(TaskCompletionStatus.alreadyCompleted);

  const TaskCompletionResult.rejected(TaskCompletionRejection reason)
    : this._(TaskCompletionStatus.rejected, rejection: reason);

  TaskCompletionResult.committed(
    TaskCompletionCommit data, {
    required bool inlineTimerCleared,
  }) : this._(
         TaskCompletionStatus.committed,
         commit: data,
         inlineTimerCleared: inlineTimerCleared,
         allDoneHandled: data.allDoneHandled,
       );

  TaskCompletionResult.failed({
    required TaskCompletionStep step,
    required Object error,
    required StackTrace stackTrace,
    bool inlineTimerCleared = false,
    bool allDoneHandled = false,
  }) : this._(
         TaskCompletionStatus.failed,
         failedStep: step,
         failureKind: error is CompletionWriteRejected
             ? TaskCompletionFailureKind.returnedFalse
             : TaskCompletionFailureKind.exception,
         error: error,
         stackTrace: stackTrace,
         inlineTimerCleared: inlineTimerCleared,
         allDoneHandled: allDoneHandled,
       );

  final TaskCompletionStatus status;
  final TaskCompletionCommit? commit;
  final TaskCompletionRejection? rejection;
  final TaskCompletionStep? failedStep;
  final TaskCompletionFailureKind? failureKind;
  final Object? error;
  final StackTrace? stackTrace;
  final bool inlineTimerCleared;
  final bool allDoneHandled;

  bool get isCommitted => status == TaskCompletionStatus.committed;
}

/// Owns only the existing completion write sequence. Call under the calendar
/// lock; there is deliberately no retry, rollback, transaction or UI callback.
/// "Committed" means every required call succeeded, not atomic crash recovery.
/// "Already completed" is the existing flag, not proof all rewards were saved.
class TaskCompletionWriter {
  TaskCompletionWriter(this._repo);

  final TaskRepository _repo;

  Future<TaskCompletionResult> write(TaskCompletionRequest request) async {
    var step = TaskCompletionStep.validation;
    var inlineTimerCleared = false;
    var allDoneHandled = false;
    try {
      if (request.dateKey != DateFormat('yyyy-MM-dd').format(request.startedAt)) {
        return const TaskCompletionResult.rejected(
          TaskCompletionRejection.differentDay,
        );
      }
      final task = request.task;
      final assignmentMatches = request.todayAssignmentIds
          .where((id) => id == task.assignmentId).length;
      if (!request.todayTaskIds.contains(task.id) ||
          task.assignmentId == null ||
          assignmentMatches != 1) {
        return const TaskCompletionResult.rejected(
          TaskCompletionRejection.taskNotInDay,
        );
      }
      if (request.completed[task.id] == true) {
        return const TaskCompletionResult.alreadyCompleted();
      }

      final completed = {...request.completed, task.id: true};
      final weekKey = _repo.currentWeekKey(request.startedAt);
      step = TaskCompletionStep.completedMap;
      await _repo.saveCompletedMap(completed);

      if (request.clearInlineTimer) {
        step = TaskCompletionStep.inlineTimer;
        await _repo.clearActiveTaskTimer();
        inlineTimerCleared = true;
      }
      step = TaskCompletionStep.completedTotals;
      await _repo.incrementCompleted(
        task.category,
        task: task,
        completedAt: request.startedAt,
      );
      step = TaskCompletionStep.xp;
      final xp = await _repo.addXp(request.xpReward);
      step = TaskCompletionStep.dailyProgress;
      final daily = await _repo.incrementDailyCompleted(request.dateKey);
      step = TaskCompletionStep.challengeProgress;
      final challenge = await _repo.markActiveChallengeProgress(
        dateKey: request.dateKey,
        completedToday: daily,
      );
      step = TaskCompletionStep.lastCompletedTask;
      await _repo.setLastCompletedTask(
        title: task.title,
        category: task.category,
        dateKey: request.dateKey,
      );
      step = TaskCompletionStep.taskBadges;
      final total = await _repo.getTotalCompleted();
      final best = await _repo.getBestStreak();
      final counts = await _repo.getCategoryCounts();
      final badges = await _repo.awardBadges(
        totalCompleted: total,
        bestStreak: best,
        categoryCounts: counts,
      );
      WeeklyProgress? weeklyProgress;
      if (request.categoryWeeklyTarget > 0) {
        step = TaskCompletionStep.weeklyProgress;
        weeklyProgress = await _repo.incrementWeeklyProgress(
          weekKey: weekKey,
          category: task.category,
        );
      }

      step = TaskCompletionStep.categoryStreakRead;
      final lastCategoryDate = _parseDate(
        await _repo.getCategoryLastCompletedDate(task.category),
      );
      final currentCategoryStreak = await _repo.getCategoryStreak(task.category);
      final categoryResolution = StreakService.resolveNextStreak(
        currentStreak: currentCategoryStreak,
        today: request.startedAt,
        lastCompletedDate: lastCategoryDate,
      );
      int? categoryStreak;
      if (categoryResolution.shouldUpdate) {
        categoryStreak = categoryResolution.nextStreak;
        step = TaskCompletionStep.categoryStreak;
        await _repo.setCategoryStreak(task.category, categoryStreak);
        step = TaskCompletionStep.categoryStreakDate;
        await _repo.setCategoryLastCompletedDate(task.category, request.dateKey);
      }

      int? streak;
      var streakBadges = <String>[];
      final allDone =
          request.todayTaskIds.isNotEmpty &&
          request.todayTaskIds.every((id) => completed[id] == true);
      if (allDone && !request.allDoneAlreadyHandled) {
        // Preserve the existing in-memory all-done guard, including on failure.
        allDoneHandled = true;
        step = TaskCompletionStep.dailyStreakRead;
        final lastDate = _parseDate(await _repo.getLastCompletedDate());
        final resolution = StreakService.resolveNextStreak(
          currentStreak: request.currentStreak,
          today: request.startedAt,
          lastCompletedDate: lastDate,
        );
        if (resolution.shouldUpdate) {
          streak = resolution.nextStreak;
          step = TaskCompletionStep.dailyStreak;
          await _repo.setStreakCount(streak);
          step = TaskCompletionStep.dailyStreakDate;
          await _repo.setLastCompletedDate(request.dateKey);
          step = TaskCompletionStep.bestStreak;
          await _repo.setBestStreakIfHigher(streak);
          step = TaskCompletionStep.streakBadges;
          final streakTotal = await _repo.getTotalCompleted();
          final streakCounts = await _repo.getCategoryCounts();
          streakBadges = await _repo.awardBadges(
            totalCompleted: streakTotal,
            bestStreak: streak,
            categoryCounts: streakCounts,
          );
        }
      }

      return TaskCompletionResult.committed(
        TaskCompletionCommit(
          dateKey: request.dateKey,
          weekKey: weekKey,
          xp: xp,
          dailyCompleted: daily,
          totalCompleted: total,
          challenge: challenge,
          badges: List.unmodifiable(badges),
          weeklyProgress: weeklyProgress,
          categoryStreak: categoryStreak,
          allDoneHandled: allDoneHandled,
          streak: streak,
          streakBadges: List.unmodifiable(streakBadges),
        ),
        inlineTimerCleared: inlineTimerCleared,
      );
    } catch (error, stackTrace) {
      // The failing method may itself contain several writes. Earlier writes
      // are intentionally retained; no later step runs after this catch.
      return TaskCompletionResult.failed(
        step: step,
        error: error,
        stackTrace: stackTrace,
        inlineTimerCleared: inlineTimerCleared,
        allDoneHandled: allDoneHandled,
      );
    }
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateFormat('yyyy-MM-dd').parse(value);
    } catch (_) {
      return null;
    }
  }
}
