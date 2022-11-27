import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/util/dates.dart';

import 'Schedule.dart';
import 'Template.dart';
import 'TemplateId.dart';
import 'TitleAndDescription.dart';

class ScheduledTask extends TitleAndDescription implements Comparable {
  int? id;
  int taskGroupId;
  TemplateId? templateId;

  DateTime createdAt = DateTime.now();
  Schedule schedule;
  DateTime? lastScheduledEventOn;
  bool active = true;
  DateTime? pausedAt;
  bool? reminderNotificationEnabled = true;
  CustomRepetition? reminderNotificationRepetition;

  ScheduledTask({
    this.id,
    required this.taskGroupId,
    this.templateId,
    required String title,
    String? description,
    required this.createdAt,
    required this.schedule,
    this.lastScheduledEventOn,
    required this.active,
    this.pausedAt,
    this.reminderNotificationEnabled,
    this.reminderNotificationRepetition,
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

  DateTime? getNextSchedule() => getNextScheduleAfter(lastScheduledEventOn);

  DateTime? getNextScheduleAfter(DateTime? after) {
    if (after != null) {
      return schedule.getNextRepetitionFrom(after);
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
    if (lastScheduledEventOn != null) {
      final now = pausedAt != null ? pausedAt! : DateTime.now();
      return now.difference(truncToMinutes(lastScheduledEventOn!));
    }
    return null;
  }

  bool isNextScheduleReached() {
    var duration = getMissingDuration();
    if (duration != null) {
      return _getRoundedDurationValue(duration) == 0;
    }
    return false;
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
   * Returns the duration in the next bigger unit then the repitition steps are defined.
   */
  int _getRoundedDurationValue(Duration duration) {
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
      return 1 - (missingDuration.inMinutes / (scheduledDuration.inMinutes != 0 ? scheduledDuration.inMinutes : 1));
    }
    return null;
  }

  executeSchedule(TaskEvent? taskEvent) {
    lastScheduledEventOn = _calcLastScheduledEventOn(taskEvent);
  }

  DateTime? simulateExecuteSchedule(TaskEvent? taskEvent) {
    final calculatedLastScheduledEventOn = _calcLastScheduledEventOn(taskEvent);
    return getNextScheduleAfter(calculatedLastScheduledEventOn);
  }

  DateTime? _calcLastScheduledEventOn(TaskEvent? taskEvent) {
    if (schedule.repetitionMode == RepetitionMode.DYNAMIC) {
      if (taskEvent != null && templateId != null &&
          taskEvent.originTemplateId == templateId) {
        return taskEvent.startedAt;
      }
      else {
        return DateTime.now();
      }
    }
    else if (schedule.repetitionMode == RepetitionMode.FIXED) {
      return getNextSchedule();
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
      if (lastScheduledEventOn != null) {
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

}