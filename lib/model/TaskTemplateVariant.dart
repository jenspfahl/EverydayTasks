import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/Template.dart';

import 'Severity.dart';
import 'TemplateId.dart';
import 'When.dart';

class TaskTemplateVariant extends Template {
  int taskTemplateId;

  TaskTemplateVariant({
    int? id,
    required int taskGroupId,
    required this.taskTemplateId,
    required String title,
    String? description,
    When? when,
    Severity? severity,
    bool? favorite,
  }) : super(
    tId: id != null ? new TemplateId.forTaskTemplateVariant(id) : null,
    taskGroupId: taskGroupId,
    title: title,
    description: description,
    when: when,
    severity: severity,
    favorite: favorite,
  );

  TaskTemplateVariant.data({
    required int subId,
    required int taskGroupId,
    required int subTaskTemplateId,
    required String title,
    String? description,
    When? when,
    Severity? severity,
  }) :
      this.taskTemplateId = taskGroupId * 1000 + subTaskTemplateId,
      super(
        tId: new TemplateId.forTaskTemplateVariant(taskGroupId * 1000000 + subTaskTemplateId * 1000 + subId),
        taskGroupId: taskGroupId,
        title: title,
        description: description,
        when: when,
        severity: severity,
      );

 }


List<TaskTemplateVariant> predefinedTaskTemplateVariants = [

  // Tidy up
  TaskTemplateVariant.data(subId: -1, title: "Tidy up kitchen", subTaskTemplateId: -1, taskGroupId: -1,
      when: When.durationExactly(AroundWhenAtDay.MORNING, Duration(minutes: 20))),
  TaskTemplateVariant.data(subId: -2, title: "Tidy up living room", subTaskTemplateId: -1, taskGroupId: -1,
      severity: Severity.EASY),


  // Cleaning
  TaskTemplateVariant.data(subId: -1, title: "Cleaning toilet", subTaskTemplateId: -2, taskGroupId: -1,
      when: When.aroundDuration(AroundDurationHours.QUARTER)),
  TaskTemplateVariant.data(subId: -2, title: "Cleaning sink", subTaskTemplateId: -2, taskGroupId: -1,
      when: When.aroundDuration(AroundDurationHours.QUARTER)),
  TaskTemplateVariant.data(subId: -3, title: "Cleaning shower / bathtub", subTaskTemplateId: -2, taskGroupId: -1,
      when: When.aroundDuration(AroundDurationHours.QUARTER)),
  TaskTemplateVariant.data(subId: -4, title: "Cleaning windows", subTaskTemplateId: -2, taskGroupId: -1),
  TaskTemplateVariant.data(subId: -5, title: "Cleaning fridge", subTaskTemplateId: -2, taskGroupId: -1,
      when: When.aroundDuration(AroundDurationHours.ONE)),

  // Dishes / Wash up
  TaskTemplateVariant.data(subId: -1, title: "Wash up after dinner", subTaskTemplateId: -1, taskGroupId: -4,
      severity: Severity.HARD,
      when: When.aroundAt(AroundWhenAtDay.EVENING)),
  TaskTemplateVariant.data(subId: -2, title: "Wash up after lunch", subTaskTemplateId: -1, taskGroupId: -4,
        when: When.startAtExactly(TimeOfDay(hour: 12, minute: 30), AroundDurationHours.QUARTER)),

];
