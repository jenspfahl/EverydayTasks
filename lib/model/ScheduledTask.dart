import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/util/dates.dart';

import '../ui/utils.dart';
import 'Schedule.dart';
import 'Template.dart';
import 'TemplateId.dart';
import 'TitleAndDescription.dart';

class ScheduledTask extends TitleAndDescription implements Comparable {
  int? id;
  int taskGroupId;
  TemplateId? templateId;
  bool important = false;

  DateTime createdAt = DateTime.now();
  Schedule schedule;
  DateTime? lastScheduledEventOn;

  DateTime? oneTimeCompletedOn;

  bool active = true;
  DateTime? pausedAt;
  bool? reminderNotificationEnabled = true;
  CustomRepetition? reminderNotificationRepetition;

  bool? preNotificationEnabled = false;
  CustomRepetition? preNotification;

  ScheduledTask({
    this.id,
    required this.taskGroupId,
    this.templateId,
    required String title,
    String? description,
    required this.createdAt,
    required this.schedule,
    this.lastScheduledEventOn,
    this.oneTimeCompletedOn,
    required this.active,
    this.important = false,
    this.pausedAt,
    this.reminderNotificationEnabled,
    this.reminderNotificationRepetition,
    this.preNotificationEnabled,
    this.preNotification,
  })
  : super(title, description);

  ScheduledTask.forTemplate(
      Template template,
      Schedule schedule,
      ) :
        taskGroupId = template.taskGroupId,
        templateId = template.tId!,
        schedule = schedule,
        super(template.title, template.description);

  bool get isPaused => pausedAt != null;

  bool get isOneTimeCompleted => schedule.repetitionMode == RepetitionMode.ONE_TIME && oneTimeCompletedOn != null;

  DateTime? getNextSchedule() => getNextScheduleAfter(lastScheduledEventOn);

  DateTime? getNextScheduleAfter(DateTime? after) {
    if (after != null) {
      return schedule.getNextRepetitionFrom(after);
    }
    return null;
  }

  DateTime? getPreviousScheduleBefore(DateTime? before) {
    if (before != null) {
      return schedule.getPreviousRepetitionFrom(before);
    }
    return null;
  }

  Duration? getScheduledDuration() {
    if (lastScheduledEventOn != null) {
      var nextRepetition = schedule.getNextRepetitionFrom(lastScheduledEventOn!);
      return nextRepetition.difference(lastScheduledEventOn!);
    }
    return null;
  }

  Duration? getMissingDuration() {
    if (lastScheduledEventOn != null) {
      return getMissingDurationAfter(lastScheduledEventOn!);
    }
    return null;
  }
  
  Duration getMissingDurationAfter(DateTime afterDate) {
    final nextRepetition = schedule.getNextRepetitionFrom(afterDate);
    final now = pausedAt != null ? pausedAt! : DateTime.now();
    return nextRepetition.difference(truncToMinutes(now));
  }

  Duration? getPassedDuration() {
    if (schedule.repetitionMode == RepetitionMode.ONE_TIME) {
      return DateTime.now().difference(lastScheduledEventOn!);
    }
    if (lastScheduledEventOn != null) {
      final now = pausedAt != null ? pausedAt! : DateTime.now(); //passed duration is not displayed when paused, so no need to consider it here
      // if last scheduled before actual creation date, cast it to creation date
      return now.difference(truncToMinutes(lastScheduledEventOn!.isBefore(createdAt) ? createdAt : lastScheduledEventOn!));
    }
    return null;
  }

  bool isDue() => !isOneTimeCompleted && (isDueNow() || isNextScheduleOverdue(false));

  bool isNextScheduleAlmostReached() {
    return (getNextRepetitionIndicatorValue()??0.0) > 0.9;

  }

  bool isDueNow() => getNextSchedule() != null && truncToMinutes(getNextSchedule()!) == truncToMinutes(DateTime.now());

  bool isNextScheduleOverdue(bool withBuffer) {
    var duration = getMissingDuration();
    if (duration != null) {
      if (withBuffer) {
        return _getRoundedDurationValue(duration).isNegative;
      }
      else {
        return duration.isNegative;
      }
    }
    return false;
  }

  /*
   * Returns the duration in the next bigger unit then the repetition steps are defined.
   */
  int _getRoundedDurationValue(Duration duration) {
    if (schedule.repetitionMode == RepetitionMode.ONE_TIME) {
      return duration.inHours;
    }
    if (schedule.repetitionStep == RepetitionStep.DAILY
        || schedule.repetitionStep == RepetitionStep.EVERY_OTHER_DAY
        || (schedule.repetitionStep == RepetitionStep.CUSTOM
              && schedule.customRepetition?.repetitionUnit == RepetitionUnit.DAYS)
      ) {
      return duration.inHours;
    } else if (schedule.repetitionStep == RepetitionStep.WEEKLY
          || schedule.repetitionStep == RepetitionStep.EVERY_OTHER_WEEK
          || schedule.repetitionStep == RepetitionStep.MONTHLY
          || schedule.repetitionStep == RepetitionStep.EVERY_OTHER_MONTH
          || (schedule.repetitionStep == RepetitionStep.CUSTOM
              && schedule.customRepetition?.repetitionUnit == RepetitionUnit.WEEKS)
          || (schedule.repetitionStep == RepetitionStep.CUSTOM
              && schedule.customRepetition?.repetitionUnit == RepetitionUnit.MONTHS)
      ) {
        return duration.inDays;
      }
      else if (schedule.repetitionStep == RepetitionStep.QUARTERLY
          || schedule.repetitionStep == RepetitionStep.HALF_YEARLY
          || schedule.repetitionStep == RepetitionStep.YEARLY
          || (schedule.repetitionStep == RepetitionStep.CUSTOM
              && schedule.customRepetition?.repetitionUnit == RepetitionUnit.YEARS)
      ) {
        return duration.inDays ~/ 7;
      } else {
        // default if we miss something
        return duration.inMinutes;

      }
  }

  double? getNextRepetitionIndicatorValue() {
    var scheduledDuration = getScheduledDuration();
    var missingDuration = getMissingDuration();
    if (scheduledDuration != null && missingDuration != null) {
      final value = 1 - (missingDuration.inMinutes / (scheduledDuration.inMinutes != 0 ? scheduledDuration.inMinutes : 1));
      if (value.isNegative && schedule.repetitionMode == RepetitionMode.ONE_TIME) {
        // It can be negative if the schedule was reused after stopped or done and due date was set to a past date (which is an unusual use case).
        // With having this, we cannot really compare by progress since the start value is random by the users reactivation date
        final missingDays = missingDuration.inHours / 24;
        return 1 + (missingDays.abs() * 0.5);
      }
      else {
        return value;
      }
    }
    return null;
  }

  executeSchedule(TaskEvent? taskEvent) {
    if (schedule.repetitionMode == RepetitionMode.ONE_TIME && oneTimeCompletedOn == null) {
      oneTimeCompletedOn = _calcLastScheduledEventOn(taskEvent);
    }
    else {
      lastScheduledEventOn = _calcLastScheduledEventOn(taskEvent);
    }
  }

  setNextSchedule(DateTime nextDueDate) {
    final customRepetition = Schedule.fromRepetitionStepToCustomRepetition(schedule.repetitionStep, schedule.customRepetition);
    final newLastScheduledEventOn = nextDueDate.subtract(customRepetition.toDuration());

    if (schedule.repetitionMode == RepetitionMode.FIXED) {
      lastScheduledEventOn = schedule.getPreviousRepetitionFrom(nextDueDate);
    }
    else if (schedule.repetitionMode == RepetitionMode.DYNAMIC) {
      lastScheduledEventOn = newLastScheduledEventOn;
    }
  }

  DateTime? simulateExecuteSchedule(TaskEvent? taskEvent) {
    final calculatedLastScheduledEventOn = _calcLastScheduledEventOn(taskEvent);
    return getNextScheduleAfter(calculatedLastScheduledEventOn);
  }

  DateTime? _calcLastScheduledEventOn(TaskEvent? taskEvent) {

    final startedAtFromTask =
      (taskEvent != null)
          ? taskEvent.startedAt
          : null;


    if (schedule.repetitionMode == RepetitionMode.DYNAMIC) {
      return startedAtFromTask ?? DateTime.now();
    }
    else if (schedule.repetitionMode == RepetitionMode.FIXED) {
      if (isDue())  {
        // only complete this schedule if due
        return getNextSchedule();
      }
      else {
        // keep current state
        return lastScheduledEventOn;
      }
    }
    else if (schedule.repetitionMode == RepetitionMode.ONE_TIME) {
      // for one-time we can only set it to done (like dynamic)
      return startedAtFromTask ?? DateTime.now();
    }
    return null;
  }

  void pause() {
    if (active) {
      pausedAt = DateTime.now();
    }
  }

  void resume() {
    if (active && pausedAt != null) {
      final delta = DateTime.now().difference(pausedAt!);
      pausedAt = null;
      if (lastScheduledEventOn != null && schedule.repetitionMode == RepetitionMode.DYNAMIC) {
        lastScheduledEventOn = lastScheduledEventOn!.add(delta);
      }
    }
  }

  @override
  int compareTo(other) {
    var o = other.active ? other.getNextRepetitionIndicatorValue() : -100 * other.id!.toDouble();
    var c = active ? getNextRepetitionIndicatorValue() : -100 * id!.toDouble();
    return o.compareTo(c);
  }

  Color getDueColor(BuildContext context, {required bool lighter}) =>
      (isDarkMode(context)
          ? (lighter ? Color(0xFFC74C0C) : Color(0xFF972C0C))
          : Color(0xFF770C0C));

  Color? getDueBackgroundColor(BuildContext context) => isNextScheduleOverdue(true)
    ? ((getNextRepetitionIndicatorValue()??0.0) > 1.3333
    ? isDarkMode(context) ? Colors.red[900] : Colors.red[200]
        : isDarkMode(context) ? Colors.red[800] : Colors.red[300])
        : null;


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledTask &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  void apply(ScheduledTask other) {
    assert (id == other.id);
    title = other.title;
    description = other.description;
    taskGroupId = other.taskGroupId;
    templateId = other.templateId;
    active = other.active;
    important = other.important;
    pausedAt = other.pausedAt;
    schedule = other.schedule;
    oneTimeCompletedOn = other.oneTimeCompletedOn;
    lastScheduledEventOn = other.lastScheduledEventOn;
    reminderNotificationEnabled = other.reminderNotificationEnabled;
    reminderNotificationRepetition = other.reminderNotificationRepetition;
    preNotificationEnabled = other.preNotificationEnabled;
    preNotification = other.preNotification;
  }

}