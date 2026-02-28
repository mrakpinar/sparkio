import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  LocaleService._();

  static final LocaleService instance = LocaleService._();

  static const String _prefsKey = 'app_locale_code';
  static const Set<String> _supportedCodes = {'en', 'tr', 'es', 'de'};

  final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    locale.value = _localeFromCode(prefs.getString(_prefsKey));
  }

  Future<void> setLocale(Locale? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_prefsKey);
      locale.value = null;
      return;
    }

    final normalized = value.languageCode.toLowerCase();
    if (!_supportedCodes.contains(normalized)) return;
    await prefs.setString(_prefsKey, normalized);
    locale.value = Locale(normalized);
  }

  String get effectiveLanguageCode {
    return (locale.value?.languageCode ?? ui.PlatformDispatcher.instance.locale.languageCode)
        .toLowerCase();
  }

  Locale? _localeFromCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final normalized = code.toLowerCase();
    if (!_supportedCodes.contains(normalized)) return null;
    return Locale(normalized);
  }
}
