import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskTemplate.dart';

import 'Schedule.dart';
import 'TaskTemplateVariant.dart';
import 'TemplateId.dart';

class ScheduledTask {
  int? id;
  int taskGroupId;
  TemplateId templateId;

  String title;
  String? description;
  DateTime createdAt = DateTime.now();
  Schedule schedule;
  DateTime? lastScheduledEventAt;
  bool active = true;

  ScheduledTask({
    this.id,
    required this.taskGroupId,
    required this.templateId,
    required this.title,
    this.description,
    required this.createdAt,
    required this.schedule,
    this.lastScheduledEventAt,
    required this.active,
  });

  ScheduledTask.forTaskTemplate(
      TaskTemplate taskTemplate,
      Schedule schedule,
      ) :
        taskGroupId = taskTemplate.taskGroupId,
        templateId = taskTemplate.tId!,
        title = taskTemplate.title,
        description = taskTemplate.description,
        schedule = schedule;

  ScheduledTask.forTaskTemplateVariant(
      TaskTemplateVariant taskTemplateVariant,
      Schedule schedule,
      ) :
        taskGroupId = taskTemplateVariant.taskGroupId,
        templateId = taskTemplateVariant.tId!,
        title = taskTemplateVariant.title,
        description = taskTemplateVariant.description,
        schedule = schedule;

  DateTime? getNextSchedule() {
    if (lastScheduledEventAt != null) {
      return schedule.getNextRepetitionFrom(lastScheduledEventAt!);
    }
  }

  Duration? getMissingDuration() {
    if (lastScheduledEventAt != null) {
      return schedule.getNextRepetitionFrom(lastScheduledEventAt!)?.difference(DateTime.now());
    }
  }

  bool isNextScheduleReached() {
    var duration = getMissingDuration();
    if (duration != null) {
      return duration.isNegative;
    }
    return false;
  }

  executeSchedule(TaskEvent taskEvent) {
    if (taskEvent.originTemplateId == templateId) {
      lastScheduledEventAt = taskEvent.startedAt;
    }
  }

  resetSchedule() {
    lastScheduledEventAt = DateTime.now();
  }
}