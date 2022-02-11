import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/util/dates.dart';

import 'Schedule.dart';
import 'Template.dart';
import 'TemplateId.dart';

class ScheduledTask implements Comparable {
  int? id;
  int taskGroupId;
  TemplateId templateId;

  String title;
  String? description;
  DateTime createdAt = DateTime.now();
  Schedule schedule;
  DateTime? lastScheduledEventOn;
  bool active = true;

  ScheduledTask({
    this.id,
    required this.taskGroupId,
    required this.templateId,
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
    if (schedule.customRepetition?.repetitionUnit == RepetitionUnit.HOURS) {
      return duration.inMinutes;
    }
    else if (schedule.repetitionStep == RepetitionStep.DAILY
        || schedule.repetitionStep == RepetitionStep.EVERY_OTHER_DAY) {
      return duration.inHours;
    } else {
      return duration.inDays;
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
    if (taskEvent?.originTemplateId == templateId && taskEvent != null) {
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