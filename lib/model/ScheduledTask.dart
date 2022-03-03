import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/util/dates.dart';

import 'Schedule.dart';
import 'Template.dart';
import 'TemplateId.dart';

class ScheduledTask implements Comparable {
  int? id;
  int taskGroupId;
  TemplateId? templateId;

  String title;
  String? description;
  DateTime createdAt = DateTime.now();
  Schedule schedule;
  DateTime? lastScheduledEventOn;
  bool active = true;

  ScheduledTask({
    this.id,
    required this.taskGroupId,
    this.templateId,
    required this.title,
    this.description,
    required this.createdAt,
    required this.schedule,
    this.lastScheduledEventOn,
    required this.active,
  });

  ScheduledTask.forTemplate(
      Template template,
      Schedule schedule,
      ) :
        taskGroupId = template.taskGroupId,
        templateId = template.tId!,
        title = template.title,
        description = template.description,
        schedule = schedule;

  DateTime? getNextSchedule() {
    if (lastScheduledEventOn != null) {
      return schedule.getNextRepetitionFrom(lastScheduledEventOn!);
    }
  }

  Duration? getScheduledDuration() {
    if (lastScheduledEventOn != null) {
      var nextRepetition = schedule.getNextRepetitionFrom(lastScheduledEventOn!);
      return nextRepetition.difference(lastScheduledEventOn!);
    }
  }

  Duration? getMissingDuration() {
    if (lastScheduledEventOn != null) {
      var nextRepetition = schedule.getNextRepetitionFrom(lastScheduledEventOn!);
      return nextRepetition.difference(truncToSeconds(DateTime.now()));
    }
  }

  bool isNextScheduleReached() {
    var duration = getMissingDuration();
    if (duration != null) {
      return _getRoundedDurationValue(duration) == 0;
    }
    return false;
  }

  bool isNextScheduleOverdue(bool roundedDuration) {
    var duration = getMissingDuration();
    if (duration != null) {
      if (roundedDuration) {
        return _getRoundedDurationValue(duration).isNegative;
      }
      else {
        return duration.isNegative;
      }
    }
    return false;
  }

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
      if (missingDuration.isNegative) {
        return 1; //
      }
      return 1 - (missingDuration.inMinutes / (scheduledDuration.inMinutes != 0 ? scheduledDuration.inMinutes : 1));
    }
  }

  executeSchedule(TaskEvent? taskEvent) {
    if (taskEvent != null && templateId != null && taskEvent.originTemplateId == templateId) {
      lastScheduledEventOn = taskEvent.startedAt;
    }
    else {
      lastScheduledEventOn = DateTime.now();
    }
  }

  @override
  int compareTo(other) {
    var o = other.active ? other.getNextRepetitionIndicatorValue() : -100 * other.id!.toDouble();
    var c = active ? getNextRepetitionIndicatorValue() : -100 * id!.toDouble();
    return o.compareTo(c);
  }

}