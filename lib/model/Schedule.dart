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
enum FixedScheduleType {WEEK_BASED, MONTH_BASED, YEAR_BASED}

class AllYearDate implements Comparable {
  int day;
  MonthOfYear month;

  AllYearDate(this.day, this.month);

  AllYearDate.fromValue(int v) : this(v % 100, MonthOfYear.values[v ~/ 100]);

  int get value => (month.index * 100) + day;

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

  @override
  int compareTo(other) {
    int cmp = month.index.compareTo(other.month.index);
    if (cmp != 0) return cmp;
    return day.compareTo(other.day);
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
  AroundWhenAtDay aroundStartAt = AroundWhenAtDay.NOW;
  TimeOfDay? startAtExactly;
  RepetitionStep repetitionStep;
  CustomRepetition? customRepetition;
  RepetitionMode repetitionMode;

  
  Set<DayOfWeek> weekBasedSchedules = {};
  Set<int> monthBasedSchedules = {}; // day of month
  Set<AllYearDate> yearBasedSchedules = {}; // date of all years

  Schedule({
    AroundWhenAtDay? aroundStartAt,
    this.startAtExactly,
    required this.repetitionStep,
    this.customRepetition,
    required this.repetitionMode,
    Set<DayOfWeek>? weekBasedSchedules,
    Set<int>? monthBasedSchedules,
    Set<AllYearDate>? yearBasedSchedules,
  }) {
    this.aroundStartAt = aroundStartAt ?? AroundWhenAtDay.NOW;
    if (weekBasedSchedules != null) this.weekBasedSchedules = weekBasedSchedules;
    if (monthBasedSchedules != null) this.monthBasedSchedules = monthBasedSchedules;
    if (yearBasedSchedules != null) this.yearBasedSchedules = yearBasedSchedules;
  }


  DateTime adjustScheduleFromToStartAt(DateTime fromDate) {
    var startAt = When.fromWhenAtDayToTimeOfDay(aroundStartAt, startAtExactly);
    return DateTime(fromDate.year, fromDate.month, fromDate.day, startAt.hour, startAt.minute);
  }


  // TODO this seems to be used to get the next schedule
  DateTime getNextRepetitionFrom(DateTime from) {
    from = adjustScheduleFromToStartAt(from);
    final nextDueOnDate = _getScheduleAfter(from);

    if (repetitionMode == RepetitionMode.FIXED) {
      return correctForDefinedSchedules(from, nextDueOnDate, moveForward: true);
    }
    else {
      return nextDueOnDate;
    }
  }
  
  DateTime getPreviousRepetitionFrom(DateTime from) {
    from = adjustScheduleFromToStartAt(from);
    final nextDueOnDate = _getScheduleBefore(from);


    if (repetitionMode == RepetitionMode.FIXED) {
      return correctForDefinedSchedules(from, nextDueOnDate, moveForward: false); 
    }
    else {
      return nextDueOnDate;
    }
  }

  DateTime _getScheduleAfter(DateTime from) {
    if (customRepetition != null) {
      return customRepetition!.getNextRepetitionFrom(from);
    }
    else if (repetitionStep != RepetitionStep.CUSTOM) {
      return addRepetitionStepToDateTime(from, repetitionStep);
    }
    return from;
  }

  DateTime _getScheduleBefore(DateTime from) {
    if (customRepetition != null) {
      return customRepetition!.getPreviousRepetitionFrom(from);
    }
    else if (repetitionStep != RepetitionStep.CUSTOM) {
      return subtractRepetitionStepToDateTime(from, repetitionStep);
    }
    return from;
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

  DateTime correctForDefinedSchedules(DateTime from, DateTime nextRegularDueDate, {required bool moveForward}) {

    if (isWeekBased() && weekBasedSchedules.isNotEmpty) {
      return findClosestDayOfWeek(from, nextRegularDueDate, moveForward: moveForward) ?? nextRegularDueDate;
    }
    if (isMonthBased() && monthBasedSchedules.isNotEmpty) {
      return findClosestDayOfMonth(nextRegularDueDate) ?? nextRegularDueDate;
    }
    if (isYearBased() && yearBasedSchedules.isNotEmpty) {
      return findClosestAllYearData(nextRegularDueDate) ?? nextRegularDueDate;
    }
    // bypass
    return nextRegularDueDate;
  }

  bool isWeekBased() {
    switch(repetitionStep) {
      case RepetitionStep.WEEKLY: 
      case RepetitionStep.EVERY_OTHER_WEEK: 
        return true;
      case RepetitionStep.CUSTOM: {
        return customRepetition != null && customRepetition!.repetitionUnit == RepetitionUnit.WEEKS;
      }
      default: return false;
    }
  }
  
  bool isMonthBased() {
    switch(repetitionStep) {
      case RepetitionStep.MONTHLY: 
      case RepetitionStep.EVERY_OTHER_MONTH:
      case RepetitionStep.QUARTERLY: // equals to 3 months
      case RepetitionStep.HALF_YEARLY: // equals to 6 months
        return true;
      case RepetitionStep.CUSTOM: {
        return customRepetition != null && customRepetition!.repetitionUnit == RepetitionUnit.MONTHS;
      }
      default: return false;
    }
  }
  
  bool isYearBased() {
    switch(repetitionStep) {
      case RepetitionStep.YEARLY: 
        return true;
      case RepetitionStep.CUSTOM: {
        return customRepetition != null && customRepetition!.repetitionUnit == RepetitionUnit.YEARS;
      }
      default: return false;
    }
  }

  DateTime? findClosestDayOfWeek(DateTime from, DateTime nextRegularDueDate, {required bool moveForward}) {

    debugPrint("from=$from nextRegularDueDate=$nextRegularDueDate");

    var sorted = weekBasedSchedules.toList();
    sorted.sort((e1, e2) => e1.index - e2.index);
    
    if (moveForward) {
      // first check from current period
      final next = _findForwardsFromCurrentDate(from, sorted);
      debugPrint("next = $next");
      if (next != null) {
        return next;
      }
      
      // second check from next period
      final firstNextPeriod = _findForwardsFromBeginOfPeriod(nextRegularDueDate, sorted);
      debugPrint("firstNextPeriod = $firstNextPeriod");
      return firstNextPeriod;
      
    }
    else {
      // first check from current period (which is after next period here)
      final last = _findBackwardsFromCurrentDate(from, sorted);
      debugPrint("last = $last");
      if (last != null) {
        //TODO if last the max element in sorted, minus one week
        if (!sorted.any((element) => element.index + 1 > last.weekday)) {
          return last.subtract(Duration(days: 7));
        }
        return last;
      }

      // second check from previous period
      final lastPreviousPeriod = _findBackwardsFromEndOfPeriod(nextRegularDueDate, sorted);
      debugPrint("lastPreviousPeriod = $lastPreviousPeriod");
      return lastPreviousPeriod;

    }
    
  }
  
  DateTime? _findForwardsFromCurrentDate(DateTime from, List<DayOfWeek> days) {
    final dayOfWeekFrom = DayOfWeek.values[from.weekday - 1];
    final nextDayOfWeek = days.where((element) => element.index > dayOfWeekFrom.index).firstOrNull;
    debugPrint("nextDayOfWeek: $nextDayOfWeek");

    if (nextDayOfWeek != null) {
      final next = from.add(Duration(days: nextDayOfWeek.index + 1 - from.weekday));
      debugPrint("found next in period $next after from");
      return next;
    }
    
    return null;
  }

  DateTime? _findForwardsFromBeginOfPeriod(DateTime from, List<DayOfWeek> days) {
    final dayBeforeMondayOfFrom = from.subtract(Duration(days: from.weekday));
    debugPrint("dayBeforeMondayOfFrom = $dayBeforeMondayOfFrom");

    var it = days.iterator;
    while (it.moveNext()) {
      final dayOfWeekCandidate = it.current;
      final testDate = dayBeforeMondayOfFrom.add(Duration(days: dayOfWeekCandidate.index + 1));
      debugPrint("found first schedule in period: $testDate");
      return testDate;
      /*debugPrint("compare testDate $testDate > from $from");
      if (testDate.isAfter(from)) {
        debugPrint("found $testDate after from");
        return testDate;
      }*/
    }
    return null;
  }
  
  DateTime? _findBackwardsFromCurrentDate(DateTime from, List<DayOfWeek> days) {
    final dayOfWeekFrom = DayOfWeek.values[from.weekday - 1];
    debugPrint("dayOfWeekFrom: $dayOfWeekFrom");

    final lastDayOfWeek = days.where((element) => element.index < dayOfWeekFrom.index).lastOrNull;
    debugPrint("lastDayOfWeek: $lastDayOfWeek");

    if (lastDayOfWeek != null) {
      final next = from.add(Duration(days: lastDayOfWeek.index + 1 - from.weekday));
      debugPrint("found last in period $next after from");
      return next;
    }

    return null;
  }


  DateTime? _findBackwardsFromEndOfPeriod(DateTime from, List<DayOfWeek> days) {

    final sundayOfFromWeek = from.add(Duration(days: DayOfWeek.values.length - from.weekday));
    debugPrint("sundayOfFromWeek = $sundayOfFromWeek");

    var it = days.reversed.iterator;
    while (it.moveNext()) {
      final dayOfWeekCandidate = it.current;
      final testDate = from.add(Duration(days: dayOfWeekCandidate.index));
      debugPrint("found last schedule in period: $testDate");
      return testDate;
      /*debugPrint("compare testDate $testDate => from $from");
      if (testDate.isBefore(from)) {
        debugPrint("found $testDate before from");
        return testDate;
      }*/
    }
    return null;
    
  }

  DateTime _findInNextDays(DateTime from, Set<DayOfWeek> checkDays) {
    for (int day = 0; day < DayOfWeek.values.length; day++) {
      final checkDate = from.add(Duration(days: day));
      final checkDayOfWeek = DayOfWeek.values[checkDate.weekday - 1];
      debugPrint("check set contains checkdate $checkDayOfWeek");
      if (checkDays.contains(checkDayOfWeek)) {
        debugPrint("found checkdate = $checkDate");

        return checkDate;
      }
    }
    return from;
  }
  
  DateTime? findClosestDayOfMonth(DateTime nextRegularDueDate) {
    final firstDayOfTargetMonth = DateTime(nextRegularDueDate.year, nextRegularDueDate.month, 1);
    var sorted = monthBasedSchedules.toList();
    sorted.sort((e1, e2) => e1 - e2);
    var it = sorted.iterator;
    while (it.moveNext()) {
      final dayOfMonthCandidate = it.current;
      final testDate = firstDayOfTargetMonth.add(Duration(days: dayOfMonthCandidate - 1));
      if (testDate == nextRegularDueDate || testDate.isAfter(nextRegularDueDate)) {
        return testDate;
      }
    }
    return nextRegularDueDate;
  } 
  
  DateTime? findClosestAllYearData(DateTime nextRegularDueDate) {
    var sorted = yearBasedSchedules.toList();
    sorted.sort();
    var it = sorted.reversed.iterator;
    while (it.moveNext()) {
      final allYearDateCandidate = it.current;
      final testDate = DateTime(nextRegularDueDate.year, allYearDateCandidate.month.index + 1, allYearDateCandidate.day);
      if (testDate == nextRegularDueDate || testDate.isAfter(nextRegularDueDate)) {
        return testDate;
      }
    }
    return nextRegularDueDate;
  }

  bool _hasFixedSchedulesInPeriodAfter(DateTime from) {
    final dayOfWeekToCheck = DayOfWeek.values[from.weekday - 1];
    return weekBasedSchedules.any((element) => element.index >= dayOfWeekToCheck.index);
  }

}
