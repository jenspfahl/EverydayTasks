import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService implements ITranslatePreferences {

  static final PREF_LANGUAGE_SELECTION = "common/languageSelection";

  static final PREF_SHOW_TIME_OF_DAY_AS_TEXT = "common/showTimeOfDayAsText";
  
  static final PREF_SHOW_WEEKDAYS = "common/showWeekdays";
  static final PREF_DATE_FORMAT_SELECTION = "common/dateFormatSelection";
  
  static final PREF_SHOW_ACTION_NOTIFICATIONS = "common/showActionNotifications";
  static final PREF_SHOW_ACTION_NOTIFICATION_DURATION_SELECTION = "common/showActionNotificationDurationSelection";

  static final PreferenceService _service = PreferenceService._internal();

  factory PreferenceService() {
    return _service;
  }

  PreferenceService._internal() {
    getBool(PreferenceService.PREF_SHOW_TIME_OF_DAY_AS_TEXT)
        .then((value) {
          if (value != null) {
            showTimeOfDayAsText = value;
          }
    }); 
    getBool(PreferenceService.PREF_SHOW_WEEKDAYS)
        .then((value) {
          if (value != null) {
            showWeekdays = value;
          }
    });
    getInt(PreferenceService.PREF_DATE_FORMAT_SELECTION)
        .then((value) {
      if (value != null) {
        dateFormatSelection = value;
      }
    });
  }

  bool showTimeOfDayAsText = true;
  bool showWeekdays = true;
  int dateFormatSelection = 1;
  int languageSelection = 0;

  Future<String?> getString(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString(key);
  }

  Future<int?> getInt(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getInt(key);
  }

  Future<bool?> getBool(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool(key);
  }

  Future<bool> setString(String key, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setString(key, value);
  }

  Future<bool> setInt(String key, int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setInt(key, value);
  }

  Future<bool> setBool(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setBool(key, value);
  }

  Future<bool> remove(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.remove(key);
  }

  @override
  Future<Locale?> getPreferredLocale() async {
    final languageSelection = await getInt(PREF_LANGUAGE_SELECTION);

    this.languageSelection = languageSelection??0;

    if (languageSelection != null) {
      final locale = _getLocaleFromSelection(languageSelection);

      if (locale != null) {
        return Future.value(locale);
      }
    }
    return Future.value(null);
  }

  @override
  Future savePreferredLocale(Locale locale) async {
    // not needed, saved by SettingsScreen.dart
  }

  Locale? _getLocaleFromSelection(int languageSelection) {
    switch (languageSelection) {
      case 1: return Locale('en');
      case 2: return Locale('de');
    }
    return null;
  }

}

