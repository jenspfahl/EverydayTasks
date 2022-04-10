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
  bool? hidden = false;

  Template({this.tId, required this.taskGroupId,
      required this.title, this.description, this.when, this.severity, this.favorite, this.hidden});

  bool isVariant() => tId != null && tId!.isVariant;

  bool isPredefined() => tId != null && tId!.isPredefined();

  @override
  int compareTo(other) {
    final result = taskGroupId.compareTo(other.taskGroupId);
    if (result != 0) {
      return result;
    }
    return tId!.compareTo(other.tId);
  }


  @override
  String toString() {
    return 'Template{tId: $tId, taskGroupId: $taskGroupId, title: $title, description: $description, when: $when, severity: $severity, favorite: $favorite, hidden: $hidden}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Template && runtimeType == other.runtimeType && tId == other.tId;

  @override
  int get hashCode => tId.hashCode;

  getKey() => tId.toString();

  Icon getIcon(bool useColor) {
    final taskGroup = findPredefinedTaskGroupById(taskGroupId);
    return taskGroup.getIcon(useColor);
  }
}