import 'package:personaltasklogger/model/Template.dart';

import 'Severity.dart';
import 'When.dart';

class TaskTemplate extends Template {
  int? taskGroupId;

  TaskTemplate({int? id, this.taskGroupId,
      required String title, String? description, When? when, Severity? severity, bool? favorite})
      : super(id: id, title: title, description: description, when: when, severity: severity, favorite: favorite);
}