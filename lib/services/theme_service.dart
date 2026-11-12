import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level_unlocks.dart';

class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const _kThemeMode = 'theme_mode_v1';

  final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  Future<void> load({required int level}) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kThemeMode);
    final saved = _fromString(raw);
    if (saved == ThemeMode.dark && !LevelUnlocks.canUseThemeSwitcher(level)) {
      mode.value = ThemeMode.light;
      await sp.setString(_kThemeMode, 'light');
    } else {
      mode.value = saved;
    }
  }

  Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kThemeMode, _toString(value));
  }

  Future<void> toggle() async {
    final next =
        mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }

  ThemeMode _fromString(String? raw) {
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.light;
    }
  }

  String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'light';
    }
  }
}
