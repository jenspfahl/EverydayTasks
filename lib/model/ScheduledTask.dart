import 'dart:ui';

import 'package:personaltasklogger/model/When.dart';

import 'Schedule.dart';
import 'Severity.dart';

class ScheduledTask {
  int? id;
  int? taskTemplateId; //taskTemplate or taskTemplateVariant
  int? taskTemplateVariantId; //taskTemplate or taskTemplateVariant

  String title;
  String? description;
  DateTime createdAt = DateTime.now();
  Schedule schedule;
  bool favorite = false;

  ScheduledTask(this.id, this.taskTemplateId, this.taskTemplateVariantId,
      this.title, this.description, this.createdAt,
      this.schedule, this.favorite);

}