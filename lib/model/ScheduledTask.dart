import 'package:jiffy/jiffy.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskTemplate.dart';
import 'package:personaltasklogger/util/dates.dart';

import 'Schedule.dart';
import 'TaskTemplateVariant.dart';
import 'Template.dart';
import 'TemplateId.dart';

class ScheduledTask {
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
      return nextRepetition.difference(DateTime.now());
    }
  }

  bool isNextScheduleReached() {
    var duration = getMissingDuration();
    if (duration != null) {
      return duration.isNegative;
    }
    return false;
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

  executeSchedule(TaskEvent taskEvent) {
    if (taskEvent.originTemplateId == templateId) {
      lastScheduledEventOn = taskEvent.startedAt;
    }
  }

  resetSchedule() {
    lastScheduledEventOn = DateTime.now();
  }

}