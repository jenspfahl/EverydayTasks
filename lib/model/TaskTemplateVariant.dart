import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';

import '../util/i18n.dart';
import 'Severity.dart';
import 'TaskTemplate.dart';
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
    bool? hidden,
  }) : super(
    tId: id != null ? new TemplateId.forTaskTemplateVariant(id) : null,
    taskGroupId: taskGroupId,
    title: title,
    description: description,
    when: when,
    severity: severity,
    favorite: favorite,
    hidden: hidden,
  );

  TaskTemplateVariant.data({
    required int subId,
    required int taskGroupId,
    required int subTaskTemplateId,
    required String i18nTitle,
    String? description,
    When? when,
    Severity? severity,
  }) :
      this.taskTemplateId = _createTaskTemplateId(taskGroupId, subTaskTemplateId),
      super(
        tId: new TemplateId.forTaskTemplateVariant(taskGroupId * 1000000 + subTaskTemplateId * 1000 + subId),
        taskGroupId: taskGroupId,
        title: _createI18nKey(_createTaskTemplateId(taskGroupId, subTaskTemplateId) , i18nTitle),
        description: description,
        when: when,
        severity: severity,
      );

  static int _createTaskTemplateId(int taskGroupId, int subTaskTemplateId) => taskGroupId * 1000 + subTaskTemplateId;

  static String _createI18nKey(int taskTemplateId, String i18nTitle) {
    final taskTemplate = predefinedTaskTemplates.firstWhere((template) => template.tId!.id == taskTemplateId);
    final taskTemplateTitle = taskTemplate.title;
    if (isI18nKey(taskTemplateTitle)) {
      final key = extractI18nKey(taskTemplateTitle);
      final newKey = key.substring(0,key.indexOf(".title")) + ".variants." + i18nTitle + ".title";
      return wrapToI18nKey(newKey);

    }
    else {
      return i18nTitle;
    }
  }

 }


List<TaskTemplateVariant> predefinedTaskTemplateVariants = [

  // Tidy up
  TaskTemplateVariant.data(subId: -1, i18nTitle: 'tidy_up_kitchen', subTaskTemplateId: -1, taskGroupId: -1,
      when: When.durationExactly(AroundWhenAtDay.MORNING, Duration(minutes: 20))),
  TaskTemplateVariant.data(subId: -2, i18nTitle: "Tidy up living room", subTaskTemplateId: -1, taskGroupId: -1,
      severity: Severity.EASY),


  // Cleaning
  TaskTemplateVariant.data(subId: -1, i18nTitle: "Cleaning toilet", subTaskTemplateId: -2, taskGroupId: -1,
      when: When.aroundDuration(AroundDurationHours.QUARTER)),
  TaskTemplateVariant.data(subId: -2, i18nTitle: "Cleaning sink", subTaskTemplateId: -2, taskGroupId: -1,
      when: When.aroundDuration(AroundDurationHours.QUARTER)),
  TaskTemplateVariant.data(subId: -3, i18nTitle: "Cleaning shower / bathtub", subTaskTemplateId: -2, taskGroupId: -1,
      when: When.aroundDuration(AroundDurationHours.QUARTER)),
  TaskTemplateVariant.data(subId: -4, i18nTitle: "Cleaning windows", subTaskTemplateId: -2, taskGroupId: -1),
  TaskTemplateVariant.data(subId: -5, i18nTitle: "Cleaning fridge", subTaskTemplateId: -2, taskGroupId: -1,
      when: When.aroundDuration(AroundDurationHours.ONE)),

  // Dishes / Wash up
  TaskTemplateVariant.data(subId: -1, i18nTitle: "Wash up after dinner", subTaskTemplateId: -1, taskGroupId: -4,
      severity: Severity.HARD,
      when: When.aroundAt(AroundWhenAtDay.EVENING)),
  TaskTemplateVariant.data(subId: -2, i18nTitle: "Wash up after lunch", subTaskTemplateId: -1, taskGroupId: -4,
        when: When.startAtExactly(TimeOfDay(hour: 12, minute: 30), AroundDurationHours.QUARTER)),

];
