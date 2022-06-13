import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/model/TitleAndDescription.dart';

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
        title: _createI18nKeyForTitle(_createTaskTemplateId(taskGroupId, subTaskTemplateId) , i18nTitle),
        description: description,
        when: when,
        severity: severity,
      );

  static int _createTaskTemplateId(int taskGroupId, int subTaskTemplateId) => taskGroupId * 1000 + subTaskTemplateId;

  static String _createI18nKeyForTitle(int taskTemplateId, String i18nTitle) {
    final taskTemplate = predefinedTaskTemplates.firstWhere((template) => template.tId!.id == taskTemplateId);
    final taskTemplateTitle = taskTemplate.title;
    return TitleAndDescription.createPredefinedI18nKey(taskTemplateTitle, i18nTitle, "title", "variants", "title")!;
  }

 }


List<TaskTemplateVariant> predefinedTaskTemplateVariants = [

  // Tidy up
  TaskTemplateVariant.data(subId: -1, i18nTitle: 'tidy_up_kitchen', subTaskTemplateId: -1, taskGroupId: -1,
      when: When.durationExactly(AroundWhenAtDay.MORNING, Duration(minutes: 20))),
  TaskTemplateVariant.data(subId: -2, i18nTitle: "tidy_up_living_room", subTaskTemplateId: -1, taskGroupId: -1,
      severity: Severity.EASY),


  // Cleaning
  TaskTemplateVariant.data(subId: -1, i18nTitle: "cleaning_toilet", subTaskTemplateId: -2, taskGroupId: -1,
      when: When.aroundDuration(AroundDurationHours.QUARTER)),
  TaskTemplateVariant.data(subId: -2, i18nTitle: "cleaning_sink", subTaskTemplateId: -2, taskGroupId: -1,
      when: When.aroundDuration(AroundDurationHours.QUARTER)),
  TaskTemplateVariant.data(subId: -3, i18nTitle: "cleaning_shower_o_bathtub", subTaskTemplateId: -2, taskGroupId: -1,
      when: When.aroundDuration(AroundDurationHours.QUARTER)),
  TaskTemplateVariant.data(subId: -4, i18nTitle: "cleaning_windows", subTaskTemplateId: -2, taskGroupId: -1),
  TaskTemplateVariant.data(subId: -5, i18nTitle: "cleaning_fridge", subTaskTemplateId: -2, taskGroupId: -1,
      when: When.aroundDuration(AroundDurationHours.ONE)),

  // Dishes / Wash up
  TaskTemplateVariant.data(subId: -1, i18nTitle: "wash_up_after_dinner", subTaskTemplateId: -1, taskGroupId: -4,
      severity: Severity.HARD,
      when: When.aroundAt(AroundWhenAtDay.EVENING)),
  TaskTemplateVariant.data(subId: -2, i18nTitle: "wash_up_after_lunch", subTaskTemplateId: -1, taskGroupId: -4,
        when: When.startAtExactly(TimeOfDay(hour: 12, minute: 30), AroundDurationHours.QUARTER)),

];
