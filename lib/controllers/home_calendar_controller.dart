import 'dart:async';

import 'package:flutter/widgets.dart';

class LocalCalendarPeriod {
  LocalCalendarPeriod(DateTime date)
    : dayKey = _key(date),
      weekKey = _key(
        DateTime(date.year, date.month, date.day - (date.weekday - 1)),
      );

  final String dayKey;
  final String weekKey;

  static String _key(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  bool matches(LocalCalendarPeriod other) =>
      dayKey == other.dayKey && weekKey == other.weekKey;
}

/// Serializes calendar reloads and task writes. Opening ads and rewards do not
/// belong in [load]. A result from an earlier day must never enter [runForDay].
class HomeCalendarController<T> with WidgetsBindingObserver {
  HomeCalendarController({
    required this.load,
    required this.apply,
    required this.onError,
    this.onLoading,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final Future<T> Function(LocalCalendarPeriod period) load;
  final void Function(T value) apply;
  final void Function(Object error) onError;
  final void Function(bool loading)? onLoading;
  final DateTime Function() now;
  LocalCalendarPeriod? loadedPeriod;
  Future<void> _tail = Future<void>.value();
  Timer? _midnight;
  bool _started = false;
  bool _disposed = false;

  bool get isCurrent =>
      loadedPeriod?.matches(LocalCalendarPeriod(now())) ?? false;

  void start(LocalCalendarPeriod initialPeriod) {
    loadedPeriod = initialPeriod;
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addObserver(this);
    }
    unawaited(check());
    _scheduleMidnight();
  }

  Future<R> serialize<R>(Future<R> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _synchronize() async {
    if (_disposed) return;
    var loading = false;
    try {
      while (!_disposed && !isCurrent) {
        if (!loading) {
          loading = true;
          onLoading?.call(true);
        }
        final period = LocalCalendarPeriod(now());
        final value = await load(period);
        if (_disposed) return;
        // Loading may itself straddle midnight or a device clock change.
        if (!period.matches(LocalCalendarPeriod(now()))) continue;
        apply(value);
        loadedPeriod = period;
      }
    } finally {
      if (loading && !_disposed) onLoading?.call(false);
    }
  }

  Future<void> check({bool force = false}) async {
    try {
      await serialize(() async {
        if (force) loadedPeriod = null;
        await _synchronize();
      });
    } catch (error) {
      if (!_disposed) onError(error);
    }
  }

  Future<bool> runForDay(
    String? dayKey,
    Future<void> Function(DateTime startedAt) action,
  ) => serialize(() async {
    if (_disposed) return false;
    await _synchronize();
    final startedAt = now();
    if (_disposed ||
        !isCurrent ||
        dayKey == null ||
        dayKey != LocalCalendarPeriod(startedAt).dayKey) {
      return false;
    }
    await action(startedAt);
    await _synchronize();
    return true;
  });

  void _scheduleMidnight() {
    _midnight?.cancel();
    if (_disposed || !_started) return;
    final current = now();
    final next = DateTime(current.year, current.month, current.day + 1);
    _midnight = Timer(next.difference(current), () {
      unawaited(check());
      _scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(check());
      _scheduleMidnight();
    } else {
      _midnight?.cancel();
    }
  }

  void dispose() {
    _disposed = true;
    _midnight?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
  }
}
