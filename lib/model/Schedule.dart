import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:jiffy/jiffy.dart';
import 'package:personaltasklogger/util/dates.dart';
import 'package:personaltasklogger/util/extensions.dart';

import '../util/units.dart';
import 'When.dart';

enum RepetitionStep {DAILY, EVERY_OTHER_DAY, WEEKLY, EVERY_OTHER_WEEK, MONTHLY, EVERY_OTHER_MONTH, QUARTERLY, HALF_YEARLY, YEARLY, CUSTOM}
enum RepetitionUnit {DAYS, WEEKS, MONTHS, YEARS, MINUTES, HOURS}
enum RepetitionMode {DYNAMIC, FIXED}

class CustomRepetition {
  int repetitionValue;
  RepetitionUnit repetitionUnit;

  CustomRepetition(this.repetitionValue, this.repetitionUnit);

  DateTime getNextRepetitionFrom(DateTime from) {
    var jiffy = Jiffy(from);
    switch(repetitionUnit) {
      case RepetitionUnit.MINUTES: return jiffy.add(minutes: repetitionValue).dateTime;
      case RepetitionUnit.HOURS: return jiffy.add(hours: repetitionValue).dateTime;
      case RepetitionUnit.DAYS: return jiffy.add(days: repetitionValue).dateTime;
      case RepetitionUnit.WEEKS: return jiffy.add(weeks: repetitionValue).dateTime;
      case RepetitionUnit.MONTHS: return jiffy.add(months: repetitionValue).dateTime;
      case RepetitionUnit.YEARS: return jiffy.add(years: repetitionValue).dateTime;
    }
  }

  DateTime getPreviousRepetitionFrom(DateTime from) {
    var jiffy = Jiffy(from);
    switch(repetitionUnit) {
      case RepetitionUnit.MINUTES: return jiffy.subtract(minutes: repetitionValue).dateTime;
      case RepetitionUnit.HOURS: return jiffy.subtract(hours: repetitionValue).dateTime;
      case RepetitionUnit.DAYS: return jiffy.subtract(days: repetitionValue).dateTime;
      case RepetitionUnit.WEEKS: return jiffy.subtract(weeks: repetitionValue).dateTime;
      case RepetitionUnit.MONTHS: return jiffy.subtract(months: repetitionValue).dateTime;
      case RepetitionUnit.YEARS: return jiffy.subtract(years: repetitionValue).dateTime;
    }
  }

  @override
  String toString() {
    return 'CustomRepetition{repetitionValue: $repetitionValue, repetitionUnit: $repetitionUnit}';
  }

  Duration toDuration() {
    switch(repetitionUnit) {
      case RepetitionUnit.MINUTES: return Duration(minutes: repetitionValue);
      case RepetitionUnit.HOURS: return Duration(hours: repetitionValue);
      case RepetitionUnit.DAYS: return Duration(days: repetitionValue);
      case RepetitionUnit.WEEKS: return Duration(days: repetitionValue * 7);
      case RepetitionUnit.MONTHS: return Duration(days: repetitionValue * 30);
      case RepetitionUnit.YEARS: return Duration(days: repetitionValue * 365);
    }
  }
}

class Schedule {
  AroundWhenAtDay aroundStartAt;
  TimeOfDay? startAtExactly;
  RepetitionStep repetitionStep;
  CustomRepetition? customRepetition;
  RepetitionMode repetitionMode;

  Schedule({
    required this.aroundStartAt,
    this.startAtExactly,
    required this.repetitionStep,
    this.customRepetition,
    required this.repetitionMode,
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
      return addRepetitionStepToDateTime(from, repetitionStep);
    }
    throw new Exception("unknown repetition step");
  }
  
  DateTime getPreviousRepetitionFrom(DateTime from) {
    from = adjustScheduleFrom(from);
    if (customRepetition != null) {
      return customRepetition!.getPreviousRepetitionFrom(from);
    }
    else if (repetitionStep != RepetitionStep.CUSTOM) {
      return subtractRepetitionStepToDateTime(from, repetitionStep);
    }
    throw new Exception("unknown repetition step");
  }

  String toStartAtAsString() {
    return (aroundStartAt == AroundWhenAtDay.CUSTOM)
        && startAtExactly != null
        ? translate('common.words.at_for_times') + " " + formatTimeOfDay(startAtExactly!)
        : When.fromWhenAtDayToString(aroundStartAt);
  }

  static DateTime addRepetitionStepToDateTime(DateTime from, RepetitionStep repetitionStep) {
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

  static DateTime subtractRepetitionStepToDateTime(DateTime from, RepetitionStep repetitionStep) {
    switch(repetitionStep) {
      case RepetitionStep.DAILY: return from.subtract(Duration(days: 1));
      case RepetitionStep.EVERY_OTHER_DAY: return from.subtract(Duration(days: 2));
      case RepetitionStep.WEEKLY: return from.subtract(Duration(days: 7));
      case RepetitionStep.EVERY_OTHER_WEEK: return from.subtract(Duration(days: 14));
      case RepetitionStep.MONTHLY: return Jiffy(from).subtract(months: 1).dateTime;
      case RepetitionStep.EVERY_OTHER_MONTH: return Jiffy(from).subtract(months: 2).dateTime;
      case RepetitionStep.QUARTERLY: return Jiffy(from).subtract(months: 3).dateTime;
      case RepetitionStep.HALF_YEARLY: return Jiffy(from).subtract(months: 6).dateTime;
      case RepetitionStep.YEARLY: return Jiffy(from).subtract(years: 1).dateTime;
      case RepetitionStep.CUSTOM: throw new Exception("custom repetition step not allowed here");
    }
  }

  static String fromRepetitionStepToString(RepetitionStep repetitionStep) {
    switch(repetitionStep) {
      case RepetitionStep.DAILY: return translate('model.repetition_step.daily');
      case RepetitionStep.EVERY_OTHER_DAY: return translate('model.repetition_step.every_other_day');
      case RepetitionStep.WEEKLY: return translate('model.repetition_step.weekly');
      case RepetitionStep.EVERY_OTHER_WEEK: return translate('model.repetition_step.every_other_week');
      case RepetitionStep.MONTHLY: return translate('model.repetition_step.monthly');
      case RepetitionStep.EVERY_OTHER_MONTH: return translate('model.repetition_step.every_other_month');
      case RepetitionStep.QUARTERLY: return translate('model.repetition_step.quarterly');
      case RepetitionStep.HALF_YEARLY: return translate('model.repetition_step.half_yearly');
      case RepetitionStep.YEARLY: return translate('model.repetition_step.yearly');
      case RepetitionStep.CUSTOM: return translate('common.words.custom').capitalize() + "...";
    }
  }

  static CustomRepetition fromRepetitionStepToCustomRepetition(RepetitionStep repetitionStep, CustomRepetition? customRepetition) {
    switch(repetitionStep) {
      case RepetitionStep.DAILY: return CustomRepetition(1, RepetitionUnit.DAYS);
      case RepetitionStep.EVERY_OTHER_DAY: return CustomRepetition(2, RepetitionUnit.DAYS);
      case RepetitionStep.WEEKLY: return CustomRepetition(1, RepetitionUnit.WEEKS);
      case RepetitionStep.EVERY_OTHER_WEEK: return CustomRepetition(2, RepetitionUnit.WEEKS);
      case RepetitionStep.MONTHLY: return CustomRepetition(1, RepetitionUnit.MONTHS);
      case RepetitionStep.EVERY_OTHER_MONTH: return CustomRepetition(2, RepetitionUnit.MONTHS);
      case RepetitionStep.QUARTERLY: return CustomRepetition(3, RepetitionUnit.MONTHS);
      case RepetitionStep.HALF_YEARLY: return CustomRepetition(6, RepetitionUnit.MONTHS);
      case RepetitionStep.YEARLY: return CustomRepetition(1, RepetitionUnit.YEARS);
      case RepetitionStep.CUSTOM: return customRepetition!;
    }
  }

  static String fromRepetitionUnitToString(RepetitionUnit repetitionUnit) {
    switch(repetitionUnit) {
      case RepetitionUnit.MINUTES: return translate('model.repetition_unit.minutes');
      case RepetitionUnit.HOURS: return translate('model.repetition_unit.hours');
      case RepetitionUnit.DAYS: return translate('model.repetition_unit.days');
      case RepetitionUnit.WEEKS: return translate('model.repetition_unit.weeks');
      case RepetitionUnit.MONTHS: return translate('model.repetition_unit.months');
      case RepetitionUnit.YEARS: return translate('model.repetition_unit.years');
    }
  }
  
  static String fromRepetitionModeToString(RepetitionMode repetitionMode) {
    switch(repetitionMode) {
      case RepetitionMode.DYNAMIC: return translate('model.repetition_mode.dynamic');
      case RepetitionMode.FIXED: return translate('model.repetition_mode.fixed');
    }
  }

  static String fromCustomRepetitionToString(CustomRepetition? customRepetition) {
    if (customRepetition == null) {
      return translate('common.words.custom').capitalize() + "...";
    }
    final unit = fromCustomRepetitionToUnit(customRepetition);
    return "${translate('model.repetition_step.every')} $unit";
  }

  static Unit fromCustomRepetitionToUnit(CustomRepetition customRepetition, [Clause? clause]) {
    switch(customRepetition.repetitionUnit) {
      case RepetitionUnit.MINUTES: return Minutes(customRepetition.repetitionValue, clause);
      case RepetitionUnit.HOURS: return Hours(customRepetition.repetitionValue, clause);
      case RepetitionUnit.DAYS: return Days(customRepetition.repetitionValue, clause);
      case RepetitionUnit.WEEKS: return Weeks(customRepetition.repetitionValue, clause);
      case RepetitionUnit.MONTHS: return Months(customRepetition.repetitionValue, clause);
      case RepetitionUnit.YEARS: return Years(customRepetition.repetitionValue, clause);
    }
  }

}
