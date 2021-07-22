import 'package:flutter/material.dart';
import 'package:personaltasklogger/util/dates.dart';

enum AroundWhenAtDay {NOW, MORNING, FORENOON, NOON, AFTERNOON, EVENING, NIGHT, CUSTOM}
enum AroundDurationHours {QUARTER, HALF, ONE, TWO, THREE, FOUR, CUSTOM}

enum WhenOnDate {TODAY, YESTERDAY, BEFORE_YESTERDAY, CUSTOM}


class When {
  AroundWhenAtDay startAt = AroundWhenAtDay.CUSTOM;
  TimeOfDay? startAtExactly;
  AroundDurationHours durationHours = AroundDurationHours.CUSTOM;
  Duration? durationExactly;

  When(AroundWhenAtDay startAt, AroundDurationHours duration);

  When.durationExactly(AroundWhenAtDay startAt, Duration durationExactly) {
    this.durationHours = AroundDurationHours.CUSTOM;
  }

  When.startAtExactly(TimeOfDay startAtExactly, AroundDurationHours duration) {
    this.startAt = AroundWhenAtDay.CUSTOM;
  }

  When.exactly(TimeOfDay startAtExactly, Duration durationExactly) {
    this.durationHours = AroundDurationHours.CUSTOM;
    this.startAt = AroundWhenAtDay.CUSTOM;
  }

  When.of(int? startAt, int? startAtExactly, int? durationHours, int? durationExactlyMinutes) {
    if (startAt != null) {
      this.startAt = AroundWhenAtDay.values.elementAt(startAt);
    }
    if (startAtExactly != null) {
      this.startAtExactly = TimeOfDay(
          hour: startAtExactly ~/ 100,
          minute: (startAtExactly % 100));
    }

    if (durationHours != null) {
      this.durationHours = AroundDurationHours.values.elementAt(durationHours);
    }
    if (durationExactlyMinutes != null) {
      this.durationExactly = Duration(minutes: durationExactlyMinutes);
    }
  }

  int fromStartAt() {
    return startAt.index;
  }

  int? fromWhenExactly() {
    final _startAtExactly = startAtExactly;
    if (_startAtExactly == null) {
      return null;
    }
    return _startAtExactly.hour * 100 + _startAtExactly.minute;
  }

  int fromDurationHours() {
    return durationHours.index;
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
      case AroundDurationHours.QUARTER: return "Around a quarter of an hour";
      case AroundDurationHours.HALF: return "Around half an hour";
      case AroundDurationHours.ONE: return "Around an hour";
      case AroundDurationHours.TWO: return "Around two hours";
      case AroundDurationHours.THREE: return "Around three hours";
      case AroundDurationHours.FOUR: return "Around four hours";
      case AroundDurationHours.CUSTOM: return "Custom...";
    }
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
  static String fromWhenAtDayToString(AroundWhenAtDay whenAtDay) {
    switch(whenAtDay) {
      case AroundWhenAtDay.NOW: return "Now";
      case AroundWhenAtDay.MORNING: return "In the morning";
      case AroundWhenAtDay.FORENOON: return "At forenoon";
      case AroundWhenAtDay.NOON: return "At noon";
      case AroundWhenAtDay.AFTERNOON: return "At afternoon";
      case AroundWhenAtDay.EVENING: return "In the evening";
      case AroundWhenAtDay.NIGHT: return "At night";
      case AroundWhenAtDay.CUSTOM: return "Custom...";
    }
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
      case WhenOnDate.TODAY: return "Today";
      case WhenOnDate.YESTERDAY: return "Yesterday";
      case WhenOnDate.BEFORE_YESTERDAY: return "Before yesterday";
      case WhenOnDate.CUSTOM: return "Custom...";
    }
  }


}
