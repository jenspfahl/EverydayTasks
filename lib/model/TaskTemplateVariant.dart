import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/Template.dart';

import 'Severity.dart';
import 'When.dart';

class TaskTemplateVariant extends Template {
  int taskTemplateId;

  TaskTemplateVariant({int? id, required int taskGroupId, required this.taskTemplateId,
    required String title, String? description, When? when, Severity? severity, bool? favorite})
      : super(id: id, taskGroupId: taskGroupId, title: title, description: description, when: when, severity: severity, favorite: favorite);
}


List<TaskTemplateVariant> predefinedTaskTemplateVariants = [

  // Tidy up
  TaskTemplateVariant(id: -1001001, title: "Tidy up kitchen", taskTemplateId: -1001, taskGroupId: -1,
      when: When.durationExactly(AroundWhenAtDay.MORNING, Duration(hours: 2, minutes: 15))),
  TaskTemplateVariant(id: -1001002, title: "Tidy up living room", taskTemplateId: -1001, taskGroupId: -1,
      description: "was easy",
      severity: Severity.EASY,
      when: When.aroundDuration(AroundDurationHours.HALF)),

  // Dishes / Wash up
  TaskTemplateVariant(id: -4001001, title: "Wash up after dinner", taskTemplateId: -4001, taskGroupId: -4,
      description: "was much",
      severity: Severity.HARD,
      when: When.aroundAt(AroundWhenAtDay.EVENING)),
  TaskTemplateVariant(id: -4001002, title: "Wash up after lunch", taskTemplateId: -4001, taskGroupId: -4,
        when: When.startAtExactly(TimeOfDay(hour: 7, minute: 30), AroundDurationHours.QUARTER)),

];

TaskTemplateVariant findTaskTemplateVariantById(int id) =>
    predefinedTaskTemplateVariants.firstWhere((element) => element.id == id);

List<TaskTemplateVariant >findTaskTemplateVariantsByTaskTemplateId(int taskTemplateId) =>
    predefinedTaskTemplateVariants.where((element) => element.taskTemplateId == taskTemplateId).toList();
