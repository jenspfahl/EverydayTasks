import 'package:flutter/material.dart';
import 'package:personaltasklogger/util/dates.dart';

import 'When.dart';

enum DayOfWeek {MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY}
enum RepetitionStep {DAILY, EVERY_OTHER_DAY, WEEKLY, EVERY_OTHER_WEEK, MONTHLY, EVERY_OTHER_MONTH, QUARTERLY, HALF_YEARLY, YEARLY, CUSTOM}



class Schedule {
  DateTime? startAt = DateTime.now();
  DateTime? endAt;
  List<DayOfWeek>? daysOfWeek;
  RepetitionStep? repetitionStep = RepetitionStep.CUSTOM;
  int? customRepetitionDays;


  Schedule({this.startAt, this.endAt, this.daysOfWeek, this.repetitionStep, this.customRepetitionDays});

  Schedule.withDaysOfWeekAndRepetition(List<DayOfWeek>? daysOfWeek, RepetitionStep repetitionStep) {
    this.daysOfWeek = daysOfWeek;
    this.repetitionStep = repetitionStep;
  }

  Schedule.withCustomerRepetition(int customRepetitionDays) {
    this.daysOfWeek = daysOfWeek;
    this.customRepetitionDays = customRepetitionDays;
  }

  DateTime? getNextRepetitionFrom(DateTime from) {
    final now = DateTime.now();
    if (endAt != null && now.isAfter(endAt!)) {
      return null;
    }
    var nextDate = startAt??DateTime.now();

    //TODO calc next repetition here

    return nextDate;
  }

  static String fromRepetitionStepToString(RepetitionStep repetitionStep) {
    switch(repetitionStep) {
      case RepetitionStep.DAILY: return "Daily";
      case RepetitionStep.EVERY_OTHER_DAY: return "Every other day";
      case RepetitionStep.WEEKLY: return "Weekly";
      case RepetitionStep.EVERY_OTHER_WEEK: return "Every other week";
      case RepetitionStep.MONTHLY: return "Monthly";
      case RepetitionStep.EVERY_OTHER_MONTH: return "Every other month";
      case RepetitionStep.QUARTERLY: return "Quarterly";
      case RepetitionStep.HALF_YEARLY: return "Half yearly";
      case RepetitionStep.YEARLY: return "Yarly";
      case RepetitionStep.CUSTOM: return "Custom...";
    }
  }

  static String fromDayOfWeekToString(DayOfWeek dayOfWeek) {
    switch(dayOfWeek) {
      case DayOfWeek.MONDAY: return "Monday";
      case DayOfWeek.TUESDAY: return "Tuesday";
      case DayOfWeek.WEDNESDAY: return "Wednesday";
      case DayOfWeek.THURSDAY: return "Thursday";
      case DayOfWeek.FRIDAY: return "Friday";
      case DayOfWeek.SATURDAY: return "Saturday";
      case DayOfWeek.SUNDAY: return "Sunday";
    }
  }

}
