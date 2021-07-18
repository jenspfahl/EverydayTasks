import 'package:flutter/material.dart';

enum WhenAtDay {MORNING, FORENOON, NOON, AFTERNOON, EVENING, NIGHT}

enum DurationHours {QUARTER, HALF, ONE, TWO}

class When {
  WhenAtDay? startAt;
  TimeOfDay? startAtExactly;
  DurationHours? durationHours;
  Duration? durationExactly;

  When(WhenAtDay startAt, DurationHours duration);
  When.durationExactly(WhenAtDay startAt, Duration durationExactly);
  When.startAtExactly(TimeOfDay startAtExactly, DurationHours duration);
  When.exactly(TimeOfDay startAtExactly, Duration durationExactly);

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

}
