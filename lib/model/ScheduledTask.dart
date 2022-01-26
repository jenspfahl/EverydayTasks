import 'dart:ui';

import 'package:personaltasklogger/model/TaskTemplate.dart';

import 'Schedule.dart';
import 'TaskTemplateVariant.dart';
import 'TemplateId.dart';

class ScheduledTask {
  int? id;
  TemplateId templateId;

  String title;
  String? description;
  DateTime? createdAt = DateTime.now();
  Schedule schedule;
  bool? active = true;

  ScheduledTask({
    this.id,
    required this.templateId,
    required this.title,
    this.description,
    this.createdAt,
    required this.schedule,
    this.active,
  });

  ScheduledTask.forTaskTemplate(
      TaskTemplate taskTemplate,
      Schedule schedule,
      ) :
        templateId = taskTemplate.tId!,
        title = taskTemplate.title,
        description = taskTemplate.description,
        schedule = schedule;

  ScheduledTask.forTaskTemplateVariant(
      TaskTemplateVariant taskTemplateVariant,
      Schedule schedule,
      ) :
        templateId = taskTemplateVariant.tId!,
        title = taskTemplateVariant.title,
        description = taskTemplateVariant.description,
        schedule = schedule;

}