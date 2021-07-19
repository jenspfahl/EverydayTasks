import 'package:flutter/material.dart';

enum WhenAtDay {MORNING, FORENOON, NOON, AFTERNOON, EVENING, NIGHT, CUSTOM}
enum WhenOnDate {TODAY, YESTERDAY, CUSTOM}

enum DurationHours {QUARTER, HALF, ONE, TWO, CUSTOM}

class When {
  WhenAtDay startAt = WhenAtDay.CUSTOM;
  TimeOfDay? startAtExactly;
  DurationHours durationHours = DurationHours.CUSTOM;
  Duration? durationExactly;

  When(WhenAtDay startAt, DurationHours duration);

  When.durationExactly(WhenAtDay startAt, Duration durationExactly) {
    this.durationHours = DurationHours.CUSTOM;
  }

  When.startAtExactly(TimeOfDay startAtExactly, DurationHours duration) {
    this.startAt = WhenAtDay.CUSTOM;
  }

  When.exactly(TimeOfDay startAtExactly, Duration durationExactly) {
    this.durationHours = DurationHours.CUSTOM;
    this.startAt = WhenAtDay.CUSTOM;
  }

  When.of(int? startAt, int? startAtExactly, int? durationHours, int? durationExactlyMinutes) {
    if (startAt != null) {
      this.startAt = WhenAtDay.values.elementAt(startAt);
    }
    if (startAtExactly != null) {
      this.startAtExactly = TimeOfDay(
          hour: startAtExactly ~/ 100,
          minute: (startAtExactly % 100));
    }

    if (durationHours != null) {
      this.durationHours = DurationHours.values.elementAt(durationHours);
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

  static Duration fromDurationHoursToDuration(DurationHours durationHours, Duration? customDuration) {
    switch(durationHours) {
      case DurationHours.QUARTER: return Duration(minutes: 15);
      case DurationHours.HALF: return Duration(minutes: 30);
      case DurationHours.ONE: return Duration(hours: 1);
      case DurationHours.TWO: return Duration(hours: 2);
      case DurationHours.CUSTOM: return customDuration!;
    }
  }
  static String fromDurationHoursString(DurationHours durationHours) {
    switch(durationHours) {
      case DurationHours.QUARTER: return "Quarter of an hour";
      case DurationHours.HALF: return "Half an hour";
      case DurationHours.ONE: return "An hour";
      case DurationHours.TWO: return "Two hours";
      case DurationHours.CUSTOM: return "Custom...";
    }
  }

}
