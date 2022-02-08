import 'package:flutter/cupertino.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';

import 'Severity.dart';
import 'TemplateId.dart';
import 'When.dart';

abstract class Template extends Comparable {
  TemplateId? tId;
  int taskGroupId;

  String title;
  String? description;
  When? when;
  Severity? severity;
  bool? favorite = false;

  Template({this.tId, required this.taskGroupId,
      required this.title, this.description, this.when, this.severity, this.favorite});

  @override
  int compareTo(other) {
    final result = taskGroupId.compareTo(other.taskGroupId);
    if (result != 0) {
      return result;
    }
    return title.compareTo(other.title);
  }


  @override
  String toString() {
    return title;
  }

  Icon getIcon(bool useColor) {
    final taskGroup = findPredefinedTaskGroupById(taskGroupId);
    return taskGroup.getIcon(useColor);
  }
}