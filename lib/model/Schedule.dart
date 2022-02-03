import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:personaltasklogger/util/dates.dart';

import 'When.dart';

enum RepetitionStep {DAILY, EVERY_OTHER_DAY, WEEKLY, EVERY_OTHER_WEEK, MONTHLY, EVERY_OTHER_MONTH, QUARTERLY, HALF_YEARLY, YEARLY, CUSTOM}
enum RepetitionUnit {HOURS, DAYS, WEEKS, MONTHS, YEARS}

class CustomRepetition {
  int repetitionValue;
  RepetitionUnit repetitionUnit;

  CustomRepetition(this.repetitionValue, this.repetitionUnit);

  DateTime getNextRepetitionFrom(DateTime from) {
    var jiffy = Jiffy(from);
    switch(repetitionUnit) {
      case RepetitionUnit.HOURS: return jiffy.add(hours: repetitionValue).dateTime;
      case RepetitionUnit.DAYS: return jiffy.add(days: repetitionValue).dateTime;
      case RepetitionUnit.WEEKS: return jiffy.add(weeks: repetitionValue).dateTime;
      case RepetitionUnit.MONTHS: return jiffy.add(months: repetitionValue).dateTime;
      case RepetitionUnit.YEARS: return jiffy.add(years: repetitionValue).dateTime;
    }
  }

  @override
  String toString() {
    return 'CustomRepetition{repetitionValue: $repetitionValue, repetitionUnit: $repetitionUnit}';
  }
}

class Schedule {
  AroundWhenAtDay aroundStartAt;
  TimeOfDay? startAtExactly;
  RepetitionStep repetitionStep;
  CustomRepetition? customRepetition;

  Schedule({
    required this.aroundStartAt,
    this.startAtExactly,
    required this.repetitionStep,
    this.customRepetition,
  });

  DateTime adjustScheduleFrom(DateTime fromDate) {
    var startAt = When.fromWhenAtDayToTimeOfDay(aroundStartAt, startAtExactly);
    return DateTime(fromDate.year, fromDate.month, fromDate.day, startAt.hour, startAt.minute);
  }


  DateTime getNextRepetitionFrom(DateTime from) {
    from = adjustScheduleFrom(from);
    if (customRepetition != null) {
      return customRepetition!.getNextRepetitionFrom(from);
    }
    else if (repetitionStep != RepetitionStep.CUSTOM) {
      return fromRepetitionStepToDateTime(from, repetitionStep);
    }
    throw new Exception("unknown repetition step");
  }

  String toStartAtAsString() {
    return (aroundStartAt == AroundWhenAtDay.CUSTOM)
        && startAtExactly != null
        ? "at " + formatTimeOfDay(startAtExactly!)
        : When.fromWhenAtDayToString(aroundStartAt);
  }

  static DateTime fromRepetitionStepToDateTime(DateTime from, RepetitionStep repetitionStep) {
    switch(repetitionStep) {
      case RepetitionStep.DAILY: return from.add(Duration(days: 1));
      case RepetitionStep.EVERY_OTHER_DAY: return from.add(Duration(days: 2));
      case RepetitionStep.WEEKLY: return from.add(Duration(days: 7));
      case RepetitionStep.EVERY_OTHER_WEEK: return from.add(Duration(days: 14));
      case RepetitionStep.MONTHLY: return Jiffy(from).add(months: 1).dateTime;
      case RepetitionStep.EVERY_OTHER_MONTH: return Jiffy(from).add(months: 2).dateTime;
      case RepetitionStep.QUARTERLY: return Jiffy(from).add(months: 3).dateTime;
      case RepetitionStep.HALF_YEARLY: return Jiffy(from).add(months: 6).dateTime;
      case RepetitionStep.YEARLY: return Jiffy(from).add(years: 1).dateTime;
      case RepetitionStep.CUSTOM: throw new Exception("custom repetition step not allowed here");
    }
  }

  static String fromRepetitionStepToString(RepetitionStep repetitionStep) {
    switch(repetitionStep) {
      case RepetitionStep.DAILY: return "Daily";
      case RepetitionStep.EVERY_OTHER_DAY: return "Every other day";
      case RepetitionStep.WEEKLY: return "Weekly";
      case RepetitionStep.EVERY_OTHER_WEEK: return "Biweekly";
      case RepetitionStep.MONTHLY: return "Monthly";
      case RepetitionStep.EVERY_OTHER_MONTH: return "Bimonthly";
      case RepetitionStep.QUARTERLY: return "Quarterly";
      case RepetitionStep.HALF_YEARLY: return "Half yearly";
      case RepetitionStep.YEARLY: return "Yearly";
      case RepetitionStep.CUSTOM: return "Custom...";
    }
  }

  static String fromRepetitionUnitToString(RepetitionUnit repetitionUnit) {
    switch(repetitionUnit) {
      case RepetitionUnit.HOURS: return "Hours";
      case RepetitionUnit.DAYS: return "Days";
      case RepetitionUnit.WEEKS: return "Weeks";
      case RepetitionUnit.MONTHS: return "Months";
      case RepetitionUnit.YEARS: return "Years";
    }
  }

  static String fromCustomRepetitionToString(CustomRepetition? customRepetition) {
    if (customRepetition == null) {
      return "Custom...";
    }
    return customRepetition.repetitionValue.toString() + " " + fromRepetitionUnitToString(customRepetition.repetitionUnit);
  }

}
