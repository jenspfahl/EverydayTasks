import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

import 'When.dart';

enum RepetitionStep {DAILY, EVERY_OTHER_DAY, WEEKLY, EVERY_OTHER_WEEK, MONTHLY, EVERY_OTHER_MONTH, QUARTERLY, HALF_YEARLY, YEARLY, CUSTOM}


class Schedule {
  AroundWhenAtDay? startAt;
  TimeOfDay? startAtExactly;
  RepetitionStep? repetitionStep = RepetitionStep.CUSTOM;
  int? customRepetitionDays;

  Schedule({
    this.startAt,
    this.startAtExactly,
    this.repetitionStep,
    this.customRepetitionDays,
  });

  DateTime? getNextRepetitionFrom(DateTime from) {
    if (customRepetitionDays != null) {
      return from.add(Duration(days: customRepetitionDays!));
    }
    if (repetitionStep != null && repetitionStep != RepetitionStep.CUSTOM) {
      return fromRepetitionStepToDuration(from, repetitionStep!);
    }
    throw new Exception("unknown repetition step");
  }

  static DateTime fromRepetitionStepToDuration(DateTime from, RepetitionStep repetitionStep) {
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
      case RepetitionStep.EVERY_OTHER_WEEK: return "Every other week";
      case RepetitionStep.MONTHLY: return "Monthly";
      case RepetitionStep.EVERY_OTHER_MONTH: return "Every other month";
      case RepetitionStep.QUARTERLY: return "Quarterly";
      case RepetitionStep.HALF_YEARLY: return "Half yearly";
      case RepetitionStep.YEARLY: return "Yarly";
      case RepetitionStep.CUSTOM: return "Custom...";
    }
  }

}
