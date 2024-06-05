import 'dart:collection';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/db/repository/KeyValueRepository.dart';
import 'package:personaltasklogger/model/KeyValue.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/repository/mapper.dart';
import '../model/When.dart';

class PreferenceService implements ITranslatePreferences {

  static final PREF_LANGUAGE_SELECTION = "common/languageSelection";

  static final PREF_SHOW_TIME_OF_DAY_AS_TEXT = "common/showTimeOfDayAsText";
  
  static final PREF_DARK_THEME = "common/darkTheme";
  static final PREF_SHOW_WEEKDAYS = "common/showWeekdays";
  static final PREF_DATE_FORMAT_SELECTION = "common/dateFormatSelection";
  
  static final PREF_SHOW_ACTION_NOTIFICATIONS = "common/showActionNotifications";
  static final PREF_SHOW_ACTION_NOTIFICATION_DURATION_SELECTION = "common/showActionNotificationDurationSelection";
  static final PREF_EXECUTE_SCHEDULES_ON_TASK_EVENT = "common/executeSchedulesOnTaskEvent";
  static final PREF_SHOW_BADGE_FOR_DUE_SCHEDULES = "common/showBadgeForDueSchedules";


  static final DATA_SHOW_SCHEDULED_SUMMARY = "data/showScheduledSummary";
  static final DATA_SHOW_SCHEDULE_MODE_HINTS = "data/showScheduledModeHint";
  static final DATA_WALKTHROUGH_SHOWN = "data/walkThroughShown";
  static final DATA_CURRENT_CALENDAR_MODE = "data/currentCalendarMode";
  static final DATA_CURRENT_EVENT_TYPE = "data/currentEventType";
  static final DATA_CURRENT_STATS_DATA_TYPE = "data/currentStatsDataType";
  static final DATA_CURRENT_STATS_GROUP_BY = "data/currentStatsGroupBy";


  static final PreferenceService _service = PreferenceService._internal();

  factory PreferenceService() {
    return _service;
  }

  final _whenAtDayTimes = HashMap<AroundWhenAtDay, TimeOfDay>();




  PreferenceService._internal() {
    getBool(PreferenceService.PREF_SHOW_BADGE_FOR_DUE_SCHEDULES)
        .then((value) {
          if (value != null) {
            showBadgeForDueSchedules = value;
          }
    });
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
    getBool(PreferenceService.PREF_DARK_THEME)
        .then((value) {
          if (value != null) {
            darkTheme = value;
          }
    });
    getInt(PreferenceService.PREF_DATE_FORMAT_SELECTION)
        .then((value) {
      if (value != null) {
        dateFormatSelection = value;
      }
    });

  }

  TimeOfDay getWhenAtDayTimeOfDay(AroundWhenAtDay whenAtDay) => _whenAtDayTimes[whenAtDay] ?? When.fromWhenAtDayToTimeOfDay(whenAtDay, null, getDefault: true);
  setWhenAtDayTimeOfDay(AroundWhenAtDay whenAtDay, TimeOfDay time) => _whenAtDayTimes[whenAtDay] = time;
  resetWhenAtDayTimeOfDay(AroundWhenAtDay whenAtDay) => _whenAtDayTimes[whenAtDay] = When.fromWhenAtDayToTimeOfDay(whenAtDay, null, getDefault: true);

  initWhenAtDayTimes() async {
    for (AroundWhenAtDay whenAtDay in AroundWhenAtDay.values) {
      final keyValue = await KeyValueRepository.findByKey(whenAtDay.toString());
      if (keyValue != null) {
        _whenAtDayTimes[whenAtDay] = timeOfDayFromEntity(int.parse(keyValue.value));
      }
    }
  }

  bool showBadgeForDueSchedules = true;
  bool showTimeOfDayAsText = true;
  bool showWeekdays = true;
  bool darkTheme = false;
  int dateFormatSelection = 1;
  int languageSelection = 0;

  Future<String?> getString(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _getPref(key, () => prefs.getString(key), (val) => val);
  }

  Future<int?> getInt(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _getPref(key, () => prefs.getInt(key), (val) => int.parse(val));
  }

  Future<bool?> getBool(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _getPref(key, () => prefs.getBool(key), (val) => val == true.toString());  }

  Future<bool> setString(String key, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _setPref(prefs, key, value, () => prefs.setString(key, value));
  }

  Future<bool> setInt(String key, int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _setPref(prefs, key, value, () => prefs.setInt(key, value));
  }

  Future<bool> setBool(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _setPref(prefs, key, value, () => prefs.setBool(key, value));
  }

  Future<bool> remove(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await KeyValueRepository.delete(key);

    return prefs.remove(key);
  }

  Future<T> _getPref<T>(String key, T Function() loadPref, T Function(String) convertValue) async {
    var pref = loadPref();

    final keyValue = await KeyValueRepository.findByKey(key);
    if (keyValue == null && pref != null) {
      // migrate to table
      KeyValueRepository.insert(KeyValue(null, key, pref.toString()));
    }
    else if (keyValue != null) {
      return convertValue(keyValue.value);
    }
    return pref;
  }

  Future<bool> _setPref(SharedPreferences prefs, String key, dynamic value, Future<bool> Function() storePref) async {

    KeyValueRepository.findByKey(key).then((keyValue) {
      if (keyValue != null) {
        keyValue.value = value.toString();
        KeyValueRepository.update(keyValue);
      }
      else {
        KeyValueRepository.insert(KeyValue(null, key, value));
      }
    });

    return storePref();
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
    debugPrint("stored language choice: $languageSelection");

    switch (languageSelection) {
      case 1: return Locale('en');
      case 2: return Locale('de');
      case 3: return Locale('fr');
      case 4: return Locale('ru');
      case 5: return Locale('es');
    }
    return null;
  }

}

