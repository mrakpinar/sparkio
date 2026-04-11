import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


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
      await syncPushLanguage();
      return;
    }

    final normalized = value.languageCode.toLowerCase();
    if (!_supportedCodes.contains(normalized)) return;
    await prefs.setString(_prefsKey, normalized);
    locale.value = Locale(normalized);
    await syncPushLanguage();
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

  Future<void> syncPushLanguage() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.subscribeToTopic('sparkio_v2');

    final code = effectiveLanguageCode;
    final matchedCode = _supportedCodes.contains(code) ? code : 'en';

    for (final supported in _supportedCodes) {
      final topic = 'sparkio_lang_$supported';
      if (supported == matchedCode) {
        await messaging.subscribeToTopic(topic);
      } else {
        await messaging.unsubscribeFromTopic(topic);
      }
    }
  }
}
