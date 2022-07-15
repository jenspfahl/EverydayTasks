import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/util/dates.dart';
import 'package:personaltasklogger/util/extensions.dart';
import 'package:personaltasklogger/util/units.dart';

import '../service/PreferenceService.dart';

enum AroundWhenAtDay {NOW, MORNING, FORENOON, NOON, AFTERNOON, EVENING, NIGHT, CUSTOM}
enum AroundDurationHours {QUARTER, HALF, ONE, TWO, THREE, FOUR, CUSTOM, FIVE_MINUTES, TEN_MINUTES}

enum WhenOnDate {TODAY, YESTERDAY, BEFORE_YESTERDAY, CUSTOM}


class When {
  AroundWhenAtDay? startAt;
  TimeOfDay? startAtExactly;
  AroundDurationHours? durationHours;
  Duration? durationExactly;

  When({this.startAt, this.startAtExactly, this.durationHours, this.durationExactly});

  When.aroundAt(this.startAt);

  When.aroundDuration(this.durationHours);

  When.durationExactly(this.startAt, this.durationExactly) {
    durationHours = AroundDurationHours.CUSTOM;
  }

  When.startAtExactly(this.startAtExactly, this.durationHours) {
    startAt = AroundWhenAtDay.CUSTOM;
  }

  When.exactly(this.startAtExactly, this.durationExactly) {
    durationHours = AroundDurationHours.CUSTOM;
    startAt = AroundWhenAtDay.CUSTOM;
  }

  When.of(int? startAt, int? startAtExactly, int? durationHours, int? durationExactlyMinutes) {
    if (startAt != null) {
      this.startAt = AroundWhenAtDay.values.elementAt(startAt);
    }
    if (startAtExactly != null) {
      this.startAtExactly = TimeOfDay(
          hour: startAtExactly ~/ 100,
          minute: (startAtExactly % 100));
      this.startAt = AroundWhenAtDay.CUSTOM;
    }

    if (durationHours != null) {
      this.durationHours = AroundDurationHours.values.elementAt(durationHours);
    }
    if (durationExactlyMinutes != null) {
      this.durationExactly = Duration(minutes: durationExactlyMinutes);
      this.durationHours = AroundDurationHours.CUSTOM;
    }
  }

  int? fromStartAt() {
    return startAt?.index;
  }

  int? fromWhenExactly() {
    final _startAtExactly = startAtExactly;
    if (_startAtExactly == null) {
      return null;
    }
    return _startAtExactly.hour * 100 + _startAtExactly.minute;
  }

  int? fromDurationHours() {
    return durationHours?.index;
  }

  int? fromDurationExactly() {
    final _durationExactly = durationExactly;
    if (_durationExactly == null) {
      return null;
    }
    return _durationExactly.inMinutes;
  }

  static Duration fromDurationHoursToDuration(AroundDurationHours durationHours, Duration? customDuration) {
    switch(durationHours) {
      case AroundDurationHours.FIVE_MINUTES: return Duration(minutes: 5);
      case AroundDurationHours.TEN_MINUTES: return Duration(minutes: 10);
      case AroundDurationHours.QUARTER: return Duration(minutes: 15);
      case AroundDurationHours.HALF: return Duration(minutes: 30);
      case AroundDurationHours.ONE: return Duration(hours: 1);
      case AroundDurationHours.TWO: return Duration(hours: 2);
      case AroundDurationHours.THREE: return Duration(hours: 3);
      case AroundDurationHours.FOUR: return Duration(hours: 4);
      case AroundDurationHours.CUSTOM: return customDuration!;
    }
  }
  static String fromDurationHoursToString(AroundDurationHours durationHours) {
    switch(durationHours) {
      case AroundDurationHours.FIVE_MINUTES: return _translateAround(Minutes(5).toString());
      case AroundDurationHours.TEN_MINUTES: return _translateAround(Minutes(10).toString());
      case AroundDurationHours.QUARTER: return _translateAround(Minutes(15).toString());
      case AroundDurationHours.HALF: return _translateAround(translate('common.durations.half_an_hour'));
      case AroundDurationHours.ONE: return _translateAround(translate('common.durations.an_hour'));
      case AroundDurationHours.TWO: return _translateAround(Hours(2).toString());
      case AroundDurationHours.THREE: return _translateAround(Hours(3).toString());
      case AroundDurationHours.FOUR: return _translateAround(Hours(4).toString());
      case AroundDurationHours.CUSTOM: return translate('common.words.custom').capitalize() + "...";
    }
  }

  static String _translateAround(String addition) {
    return translate('common.words.around').capitalize() + " " + addition;
  }

  static TimeOfDay fromWhenAtDayToTimeOfDay(AroundWhenAtDay whenAtDay, TimeOfDay? customWhenAt) {
    switch(whenAtDay) {
      case AroundWhenAtDay.NOW: return TimeOfDay.now();
      case AroundWhenAtDay.MORNING: return TimeOfDay(hour: 8, minute: 0);
      case AroundWhenAtDay.FORENOON: return TimeOfDay(hour: 10, minute: 0);
      case AroundWhenAtDay.NOON: return TimeOfDay(hour: 12, minute: 0);
      case AroundWhenAtDay.AFTERNOON: return TimeOfDay(hour: 15, minute: 0);
      case AroundWhenAtDay.EVENING: return TimeOfDay(hour: 18, minute: 0);
      case AroundWhenAtDay.NIGHT: return TimeOfDay(hour: 23, minute: 0);
      case AroundWhenAtDay.CUSTOM: return customWhenAt!;
    }
  }
  static String _fromWhenAtDayToString(AroundWhenAtDay whenAtDay) {
    switch(whenAtDay) {
      case AroundWhenAtDay.NOW: return translate('common.times.now');
      case AroundWhenAtDay.MORNING: return translate('common.times.in_the_morning');
      case AroundWhenAtDay.FORENOON: return translate('common.times.at_forenoon');
      case AroundWhenAtDay.NOON: return translate('common.times.at_noon');
      case AroundWhenAtDay.AFTERNOON: return translate('common.times.at_afternoon');
      case AroundWhenAtDay.EVENING: return translate('common.times.in_the_evening');
      case AroundWhenAtDay.NIGHT: return translate('common.times.at_night');
      case AroundWhenAtDay.CUSTOM: return translate('common.words.custom').capitalize() + "...";
    }
  }

  static String fromWhenAtDayToString(AroundWhenAtDay whenAtDay) {
    final preferenceService = PreferenceService();
    final showTimeOfDayAsText = preferenceService.showTimeOfDayAsText;
    
    final asString = _fromWhenAtDayToString(whenAtDay);
    if (showTimeOfDayAsText || whenAtDay == AroundWhenAtDay.NOW || whenAtDay == AroundWhenAtDay.CUSTOM) {
      return asString;
    }
    final timeOfDay = fromWhenAtDayToTimeOfDay(whenAtDay, null);
    return "${translate('common.words.around').capitalize()} ${formatTimeOfDay(timeOfDay)}";
  }

    static DateTime fromWhenOnDateToDate(WhenOnDate whenOnDate, DateTime? customDate) {
    switch(whenOnDate) {
      case WhenOnDate.TODAY: return truncToDate(DateTime.now());
      case WhenOnDate.YESTERDAY: return truncToDate(DateTime.now().subtract(Duration(days: 1)));
      case WhenOnDate.BEFORE_YESTERDAY: return truncToDate(DateTime.now().subtract(Duration(days: 2)));
      case WhenOnDate.CUSTOM: return customDate!;
    }
  }
  static String fromWhenOnDateToString(WhenOnDate whenOnDate) {
    switch(whenOnDate) {
      case WhenOnDate.TODAY: return translate('common.dates.today');
      case WhenOnDate.YESTERDAY: return translate('common.dates.yesterday');
      case WhenOnDate.BEFORE_YESTERDAY: return translate('common.dates.before_yesterday');
      case WhenOnDate.CUSTOM: return translate('common.words.custom').capitalize() + "...";
    }
  }

}
