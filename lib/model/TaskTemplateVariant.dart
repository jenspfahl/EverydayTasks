import 'package:personaltasklogger/model/Template.dart';

import 'Severity.dart';
import 'When.dart';

class TaskTemplateVariant extends Template {
  int taskTemplateId;

  TaskTemplateVariant({int? id, required this.taskTemplateId,
    required String title, String? description, When? when, Severity? severity, bool? favorite})
      : super(id: id, title: title, description: description, when: when, severity: severity, favorite: favorite);
}