import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:jiffy/jiffy.dart';
import 'package:personaltasklogger/util/dates.dart';
import 'package:personaltasklogger/util/extensions.dart';

import 'package:personaltasklogger/util/units.dart';
import 'When.dart';

enum RepetitionStep {DAILY, EVERY_OTHER_DAY, WEEKLY, EVERY_OTHER_WEEK, MONTHLY, EVERY_OTHER_MONTH, QUARTERLY, HALF_YEARLY, YEARLY, CUSTOM}
enum RepetitionUnit {DAYS, WEEKS, MONTHS, YEARS, MINUTES, HOURS}
enum RepetitionMode {DYNAMIC, FIXED, ONE_TIME}
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
    return _addOrSubtractFrom(from, true);
  }

  DateTime getPreviousRepetitionFrom(DateTime from) {
    return _addOrSubtractFrom(from, false);
  }

  DateTime _addOrSubtractFrom(DateTime from, bool addElseSubtract) {
    var jiffy = Jiffy.parseFromDateTime(from);

    final duration = this.toDuration();

    DateTime result;
    if (addElseSubtract) {
      result = jiffy.addDuration(duration).dateTime;
    }
    else {
      result = jiffy.subtractDuration(duration).dateTime;
    }
    final possibleDaylightSavingHourDelta = from.hour - result.hour;
    if (possibleDaylightSavingHourDelta != 0) {
      var savingAdjustmentHours = Duration(hours: possibleDaylightSavingHourDelta.abs());
      if (possibleDaylightSavingHourDelta < 1) {
        // From non-Daylight Saving to Daylight Saving (mostly in March)
        if (addElseSubtract) {
          return result.subtract(savingAdjustmentHours);
        }
        else {
          return result.add(savingAdjustmentHours);
        }
      }
      else if (possibleDaylightSavingHourDelta > 1) {
        // From Daylight Saving to non-Daylight Saving (mostly in October)
        if (addElseSubtract) {
          return result.add(savingAdjustmentHours);
        }
        else {
          return result.subtract(savingAdjustmentHours);
        }
      }
    }
    return result;
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

  DateTime? oneTimeDueOn;

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
    this.oneTimeDueOn,
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


  DateTime getNextRepetitionFrom(DateTime from) {
    if (repetitionMode == RepetitionMode.ONE_TIME && oneTimeDueOn != null) {
      return adjustScheduleFromToStartAt(oneTimeDueOn!);
    }
    from = adjustScheduleFromToStartAt(from);
    final nextDueOnDate = _getScheduleAfter(from);

    if (repetitionMode == RepetitionMode.FIXED) {
      return _correctForDefinedSchedules(from, nextDueOnDate, moveForward: true);
    }
    else {
      return nextDueOnDate;
    }
  }
  
  DateTime getPreviousRepetitionFrom(DateTime from) {
    if (repetitionMode == RepetitionMode.ONE_TIME && oneTimeDueOn != null) {
      return from; // no calc back here
    }
    from = adjustScheduleFromToStartAt(from);
    final nextDueOnDate = _getScheduleBefore(from);


    if (repetitionMode == RepetitionMode.FIXED) {
      return _correctForDefinedSchedules(from, nextDueOnDate, moveForward: false); 
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
    if (repetitionStep == RepetitionStep.CUSTOM) {
      throw new Exception("custom repetition step not allowed here");
    }

    var customRepetition = fromRepetitionStepToCustomRepetition(repetitionStep, null);
    return customRepetition.getNextRepetitionFrom(from);
  }

  static DateTime subtractRepetitionStepToDateTime(DateTime from, RepetitionStep repetitionStep) {
    if (repetitionStep == RepetitionStep.CUSTOM) {
      throw new Exception("custom repetition step not allowed here");
    }

    var customRepetition = fromRepetitionStepToCustomRepetition(repetitionStep, null);
    return customRepetition.getPreviousRepetitionFrom(from);
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
      case RepetitionStep.CUSTOM: return translate('common.words.custom').capitalize() + ELLIPSIS;
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
      case RepetitionMode.ONE_TIME: return translate('model.repetition_mode.one_time');
    }
  }

  static String fromCustomRepetitionToString(CustomRepetition? customRepetition) {
    if (customRepetition == null) {
      return translate('common.words.custom').capitalize() + ELLIPSIS;
    }
    final unit = fromCustomRepetitionToUnit(customRepetition);
    return "${translate('model.repetition_step.every')} $unit";
  }

  static GeneralUnit fromCustomRepetitionToUnit(CustomRepetition customRepetition, [Clause? clause]) {
    switch(customRepetition.repetitionUnit) {
      case RepetitionUnit.MINUTES: return Minutes(customRepetition.repetitionValue, clause);
      case RepetitionUnit.HOURS: return Hours(customRepetition.repetitionValue, clause);
      case RepetitionUnit.DAYS: return Days(customRepetition.repetitionValue, clause);
      case RepetitionUnit.WEEKS: return Weeks(customRepetition.repetitionValue, clause);
      case RepetitionUnit.MONTHS: return Months(customRepetition.repetitionValue, clause);
      case RepetitionUnit.YEARS: return Years(customRepetition.repetitionValue, clause);
    }
  }

  DateTime _correctForDefinedSchedules(DateTime from, DateTime nextRegularDueDate, {required bool moveForward}) {

    if (isWeekBased() && weekBasedSchedules.isNotEmpty) {
      return findClosestDayOfPeriod<DayOfWeek>(from, nextRegularDueDate, weekBasedSchedules, moveForward,
          extractType: (dateTime) {
            return DayOfWeek.values[from.weekday - 1];
          },
          extractValue: (dayOfWeek) {
            return dayOfWeek.index + 1;
          },
      ) ?? nextRegularDueDate;
    }

    if (isMonthBased() && monthBasedSchedules.isNotEmpty) {
      return findClosestDayOfPeriod<int>(from, nextRegularDueDate, monthBasedSchedules, moveForward,
        extractType: (dateTime) {
          return dateTime.day;
        },
        extractValue: (dayOfMonth) {
          return dayOfMonth;
        }
      ) ?? nextRegularDueDate;
    }

    if (isYearBased() && yearBasedSchedules.isNotEmpty) {
      return findClosestDayOfPeriod<AllYearDate>(from, nextRegularDueDate, yearBasedSchedules, moveForward,
        extractType: (dateTime) {
          return AllYearDate(dateTime.day, MonthOfYear.values[dateTime.month - 1]);
        },
        extractValue: (dayOfMonth) {
          return dayOfMonth.value;
        }
      ) ?? nextRegularDueDate;
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

  DateTime? findClosestDayOfPeriod<T>(
    DateTime from,
    DateTime nextRegularDueDate,
    Set<T> days,
    bool moveForward, {
    required T Function (DateTime from) extractType,
    required int Function (T) extractValue,
  }) {

    //debugPrint("from=$from nextRegularDueDate=$nextRegularDueDate");

    if (moveForward) {
      final sortedAscending = days.toList();
      sortedAscending.sort((e1, e2) => extractValue(e1) - extractValue(e2));

      // first try to find next in current period
      final next = _findForwardsFromCurrentDate(from, sortedAscending, extractType, extractValue);

      //debugPrint("next = $next");
      if (next != null) {
        return next;
      }
      
      // second try to find first in next period
      final firstNextPeriod = _findForwardsFromBeginOfPeriodIn(nextRegularDueDate, sortedAscending, extractType, extractValue);

      //debugPrint("firstNextPeriod = $firstNextPeriod");
      return firstNextPeriod;
      
    }
    else {
      final sortedDescending = days.toList();
      sortedDescending.sort((e1, e2) => extractValue(e2) - extractValue(e1));

      // first try to find last in current period 
      final last = _findBackwardsFromCurrentDate(from, sortedDescending, extractType, extractValue);

      //debugPrint("last = $last");
      if (last != null) {
        return last;
      }

      // second check from previous period
      final lastPreviousPeriod = _findBackwardsFromEndOfPeriodIn(nextRegularDueDate, sortedDescending, extractType, extractValue);

      //debugPrint("lastPreviousPeriod = $lastPreviousPeriod");
      return lastPreviousPeriod;

    }
    
  }


  DateTime? _findForwardsFromCurrentDate<T>(DateTime from, List<T> daysAscending, T Function (DateTime) extractType, int Function (T) extractValue) {

    final dayFrom = extractType(from);
    final dayFromValue = extractValue(dayFrom);
    final nextDay = daysAscending.where((day) => extractValue(day) > dayFromValue).firstOrNull;
    //debugPrint("nextDay: $nextDay");

    if (nextDay is DayOfWeek) {
      final next = from.add(Duration(days: extractValue(nextDay) - dayFromValue));
      //debugPrint("found next in period $next after from");
      return next;
    }
    else {
      return _mapFixedNonWeekScheduleDay(from, nextDay);
    }
  }


  DateTime? _findForwardsFromBeginOfPeriodIn<T>(DateTime nextDueDate, List<T> daysAscending, T Function (DateTime) extractType, int Function (T) extractValue) {
    final firstDay = daysAscending.firstOrNull;
    if (firstDay is DayOfWeek) {
      // get the day before Monday of the target period
      final dayBeforeWeekStart = nextDueDate.subtract(Duration(days: extractValue(extractType(nextDueDate))));
      debugPrint("dayBeforeWeekStart = $dayBeforeWeekStart");

      // add the number of the first week day (Monday = 1, etc)
      final date = dayBeforeWeekStart.add(Duration(days: extractValue(firstDay)));
      //debugPrint("found first schedule in period: $date");
      return date;
    }
    else {
      return _mapFixedNonWeekScheduleDay(nextDueDate, firstDay);
    }
  }


  DateTime? _findBackwardsFromCurrentDate<T>(DateTime from, List<T> daysDescending, T Function (DateTime) extractType, int Function (T) extractValue) {
    final dayFrom = extractType(from);
    final dayFromValue = extractValue(dayFrom);
    //debugPrint("dayFrom: $dayFrom");

    final lastDay = daysDescending.where((day) => extractValue(day) < dayFromValue).firstOrNull;
    //debugPrint("lastDay: $lastDay");

    if (lastDay is DayOfWeek) {
      final last = from.subtract(Duration(days: dayFromValue - extractValue(lastDay)));
      //debugPrint("found last in period $last after from");
      return last;
    }
    else {
      return _mapFixedNonWeekScheduleDay(from, lastDay);
    }
  }


  DateTime? _findBackwardsFromEndOfPeriodIn<T>(DateTime previousDueDate, List<T> daysDescending, T Function (DateTime) extractType, int Function (T) extractValue) {
    final lastDay = daysDescending.firstOrNull;
    if (lastDay is DayOfWeek) {

      // get the day after Sunday of the target period
      final dayAfterWeekEnd = previousDueDate.add(Duration(days: 7 + 1 - extractValue(extractType(previousDueDate))));
      debugPrint("dayAfterWeekEnd = $dayAfterWeekEnd");

      // subtract the backwarded number of the last week day (Monday = 1 --> 7 - 1 = 6)
      final date = dayAfterWeekEnd.subtract(Duration(days: 7 + 1 - extractValue(lastDay)));
      //debugPrint("found first schedule in period: $date");
      return date;
    }
    else {
      return _mapFixedNonWeekScheduleDay(previousDueDate, lastDay);
    }
  }


  DateTime? _mapFixedNonWeekScheduleDay<T>(DateTime from, T day) {
    if (day is int) {
      final date = adjustScheduleFromToStartAt(DateTime(from.year, from.month, day));
      return _correctToLastDayOfMonthIfInvalid(date, day, from);
    }
    else if (day is AllYearDate) {
      final date = adjustScheduleFromToStartAt(DateTime(from.year, day.month.index + 1, day.day));
      return _correctToLastDayOfMonthIfInvalid(date, day, from);
    }
    else {
      return null;
    }
  }

  DateTime? _correctToLastDayOfMonthIfInvalid(DateTime date, day, DateTime from) {
    if (!_isValidDay(date, day)) {
      // the target date was not a valid date, we need to adjust. E.g. 31 Feb is not valid and lands on 2nd March --> adjust to last date in Feb
      //return null; // jump over invalid date if preferred
      final corrected = date.subtract(Duration(days: date.day)); // adjust invalid date
      if (corrected == from) {
        // I was already here
        return null;
      }
      return corrected;
    }
    return date;
  }


  bool _isValidDay<T>(DateTime date, T day) {
    if (day is int && date.day < day) {
      return false;
    }
    else if (day is AllYearDate && date.day < day.day) {
      return false;
    }

    return true;
  }

  bool appliesToFixedSchedule(DateTime dateTime) {
    if (repetitionMode == RepetitionMode.FIXED) {
      if (isWeekBased() && weekBasedSchedules.isNotEmpty) {
        return weekBasedSchedules.contains(DayOfWeek.values[dateTime.weekday - 1]);
      }
      if (isMonthBased() && monthBasedSchedules.isNotEmpty) {
        final nextDay = dateTime.add(Duration(days: 1));
        if (!_isValidDay(nextDay, dateTime.day)) {
          // next is invalid, consider selecting this if we have a schedule for the next 4 days (e.g. 28, 29, 30, 31 of month where only 28 or maybe 29 is valid for February)
          return monthBasedSchedules.contains(dateTime.day + 0)
              || monthBasedSchedules.contains(dateTime.day + 1)
              || monthBasedSchedules.contains(dateTime.day + 2)
              || monthBasedSchedules.contains(dateTime.day + 3);
        }
        return monthBasedSchedules.contains(dateTime.day);
      }
      if (isYearBased() && yearBasedSchedules.isNotEmpty) {
        final nextDay = dateTime.add(Duration(days: 1));
        var monthOfYear = MonthOfYear.values[dateTime.month - 1];
        if (!_isValidDay(nextDay, dateTime.day)) {
          // next is invalid, consider selecting this if we have a schedule for the next 4 days (e.g. 28, 29, 30, 31 of month where only 28 or maybe 29 is valid for February)
          return yearBasedSchedules.contains(AllYearDate(dateTime.day + 0, monthOfYear))
              || yearBasedSchedules.contains(AllYearDate(dateTime.day + 1, monthOfYear))
              || yearBasedSchedules.contains(AllYearDate(dateTime.day + 2, monthOfYear))
              || yearBasedSchedules.contains(AllYearDate(dateTime.day + 3, monthOfYear));
        }
        return yearBasedSchedules.contains(AllYearDate(dateTime.day, monthOfYear));
      }
    }
    return true;
  }


  static String? getStringFromWeeklyBasedSchedules(Set<DayOfWeek> weekBasedSchedules, BuildContext context) {
    if (weekBasedSchedules.isEmpty) {
      return null;
    }

    final list = weekBasedSchedules.toList();
    list.sort((a, b) => a.index - b.index);

    return list.map((e) => getShortWeekdayOf(e.index, context)).join(", ");
  }

  static String? getStringFromMonthlyBasedSchedules(Set<int> monthBasedSchedules, BuildContext context) {
    if (monthBasedSchedules.isEmpty) {
      return null;
    }

    final list = monthBasedSchedules.toList();
    list.sort();

    return list.map((day) => getDayOfMonth(day, context)).join(", ");
  }

  static String? getStringFromYearlyBasedSchedules(Set<AllYearDate> yearBasedSchedules, BuildContext context) {
    if (yearBasedSchedules.isEmpty) {
      return null;
    }

    final list = yearBasedSchedules.toList();
    list.sort();

    return list.map((allYearDate) => formatAllYearDate(allYearDate, context)).join(", ");
  }



}
