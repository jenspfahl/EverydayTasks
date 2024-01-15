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
enum DayOfWeek {MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY}
enum MonthOfYear {JANUARY, FEBRUARY, MARCH, APRIL, MAY, JUNE, JULY, AUGUST, SEPTEMBER, OCTOBER, NOVEMBER , DECEMBER}
// if FIXED, we cld define week days for week based intervals
// and month days for month based (but only to 28th?)
// and dates for year based (what about leap year?)
// if a fixed date cannot be resolved it is skipped OR moved to the next possible data (e.g. 29th Feb in a non-leap year would move to 1st March)
//Redesign Schedule form (!!!):
// make a new section visible when FIXED based on the interval basis

class AllYearDate {
  int day;
  MonthOfYear month;

  AllYearDate(this.day, this.month);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllYearDate &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          month == other.month;

  @override
  int get hashCode => day.hashCode ^ month.hashCode;

  @override
  String toString() {
    return 'AllYearDate{day: $day, month: $month}';
  }
}

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

  
  //TODO mockup data used
  Set<DayOfWeek> weekBasedSchedules = {DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY};
  Set<int> monthBasedSchedules = {3, 31}; // day of month
  Set<AllYearDate> yearBasedSchedules = {AllYearDate(29, MonthOfYear.FEBRUARY), AllYearDate(12, MonthOfYear.MAY)}; // date of all years

  Schedule({
    required this.aroundStartAt,
    this.startAtExactly,
    required this.repetitionStep,
    this.customRepetition,
    required this.repetitionMode,
 /*   required this.weekBasedSchedules,
    required this.monthBasedSchedules,
    required this.yearBasedSchedules*/
  });

  DateTime adjustScheduleFrom(DateTime fromDate) {
    var startAt = When.fromWhenAtDayToTimeOfDay(aroundStartAt, startAtExactly);
    return DateTime(fromDate.year, fromDate.month, fromDate.day, startAt.hour, startAt.minute);
  }


  DateTime getNextRepetitionFrom(DateTime from) {
    from = adjustScheduleFrom(from);
    if (customRepetition != null) {
      return correctForDefinedSchedules(
        customRepetition!.getNextRepetitionFrom(from),
        repetitionMode,
        repetitionStep,
        customRepetition,
        weekBasedSchedules,
        monthBasedSchedules,
        yearBasedSchedules,
      );
    }
    else if (repetitionStep != RepetitionStep.CUSTOM) {
      return correctForDefinedSchedules(
        addRepetitionStepToDateTime(from, repetitionStep),
        repetitionMode,
        repetitionStep,
        customRepetition,
        weekBasedSchedules,
        monthBasedSchedules,
        yearBasedSchedules,
      );
    }
    throw new Exception("unknown repetition step");
  }
  
  DateTime getPreviousRepetitionFrom(DateTime from) {
    from = adjustScheduleFrom(from);
    if (customRepetition != null) {
      return correctForDefinedSchedules( //TODO not sure whether we need this here
        customRepetition!.getPreviousRepetitionFrom(from),
        repetitionMode,
        repetitionStep,
        customRepetition,
        weekBasedSchedules,
        monthBasedSchedules,
        yearBasedSchedules,
      );
    }
    else if (repetitionStep != RepetitionStep.CUSTOM) {
      return correctForDefinedSchedules(  //TODO not sure whether we need this here
        subtractRepetitionStepToDateTime(from, repetitionStep),
        repetitionMode,
        repetitionStep,
        customRepetition,
        weekBasedSchedules,
        monthBasedSchedules,
        yearBasedSchedules,
      );
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

  static DateTime correctForDefinedSchedules(DateTime dateTime, RepetitionMode repetitionMode, RepetitionStep repetitionStep, CustomRepetition? customRepetition,
      Set<DayOfWeek> weekBasedSchedules, Set<int> monthBasedSchedules, Set<AllYearDate> yearBasedSchedules) {
    if (repetitionMode == RepetitionMode.FIXED) {
      if (isWeekBased(repetitionStep, customRepetition) && weekBasedSchedules.isNotEmpty) {
        return findClosestDayOfWeek(weekBasedSchedules, dateTime) ?? dateTime; 
      }
      if (isMonthBased(repetitionStep, customRepetition) && monthBasedSchedules.isNotEmpty) {
        return findClosestDayOfMonth(monthBasedSchedules, dateTime) ?? dateTime;
      }
      if (isYearBased(repetitionStep, customRepetition) && yearBasedSchedules.isNotEmpty) {
        return findClosestAllYearData(yearBasedSchedules, dateTime) ?? dateTime;
      }
    }
    // bypass 
    return dateTime;
  }

  static bool isWeekBased(RepetitionStep repetitionStep, CustomRepetition? customRepetition) {
    switch(repetitionStep) {
      case RepetitionStep.WEEKLY: 
      case RepetitionStep.EVERY_OTHER_WEEK: 
        return true;
      case RepetitionStep.CUSTOM: {
        return customRepetition != null && customRepetition.repetitionUnit == RepetitionUnit.WEEKS;
      }
      default: return false;
    }
  }
  
  static bool isMonthBased(RepetitionStep repetitionStep, CustomRepetition? customRepetition) {
    switch(repetitionStep) {
      case RepetitionStep.MONTHLY: 
      case RepetitionStep.EVERY_OTHER_MONTH:
      case RepetitionStep.QUARTERLY: // equals to 3 months
      case RepetitionStep.HALF_YEARLY: // equals to 6 months
        return true;
      case RepetitionStep.CUSTOM: {
        return customRepetition != null && customRepetition.repetitionUnit == RepetitionUnit.MONTHS;
      }
      default: return false;
    }
  }
  
  static bool isYearBased(RepetitionStep repetitionStep, CustomRepetition? customRepetition) {
    switch(repetitionStep) {
      case RepetitionStep.YEARLY: 
        return true;
      case RepetitionStep.CUSTOM: {
        return customRepetition != null && customRepetition.repetitionUnit == RepetitionUnit.YEARS;
      }
      default: return false;
    }
  }

  static DateTime? findClosestDayOfWeek(Set<DayOfWeek> weekBasedSchedules, DateTime dateTime) {
    final mondayOfTargetWeek = dateTime.subtract(Duration(days: dateTime.weekday - 1));
    var sorted = weekBasedSchedules.toList();
    sorted.sort((e1, e2) => e1.index - e2.index);
    var it = sorted.iterator;
    while (it.moveNext()) {
      final dayOfWeekCandidate = it.current;
      final testDate = mondayOfTargetWeek.add(Duration(days: dayOfWeekCandidate.index));
      if (testDate == dateTime || testDate.isAfter(dateTime)) {
        return testDate;
      }
    }
    return dateTime;
  }
  
  static DateTime? findClosestDayOfMonth(Set<int> monthBasedSchedules, DateTime dateTime) {
    final firstDayOfTargetMonth = DateTime(dateTime.year, dateTime.month, 1);
    var sorted = monthBasedSchedules.toList();
    sorted.sort((e1, e2) => e1 - e2);
    var it = sorted.iterator;
    while (it.moveNext()) {
      final dayOfMonthCandidate = it.current;
      final testDate = firstDayOfTargetMonth.add(Duration(days: dayOfMonthCandidate - 1));
      if (testDate == dateTime || testDate.isAfter(dateTime)) {
        return testDate;
      }
    }
    return dateTime;
  } 
  
  static DateTime? findClosestAllYearData(Set<AllYearDate> yearBasedSchedules, DateTime dateTime) {
    var sorted = yearBasedSchedules.toList();
    sorted.sort((e1, e2) {
      int cmp = e2.month.index.compareTo(e1.month.index);
      if (cmp != 0) return cmp;
      return e2.day.compareTo(e1.day);
    });
    var it = sorted.iterator;
    while (it.moveNext()) {
      final allYearDateCandidate = it.current;
      final testDate = DateTime(dateTime.year, allYearDateCandidate.month.index + 1, allYearDateCandidate.day);
      if (testDate == dateTime || testDate.isAfter(dateTime)) {
        return testDate;
      }
    }
    return dateTime;
  }

}
