import 'package:flutter/cupertino.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';

import '../db/repository/TaskGroupRepository.dart';
import 'TitleAndDescription.dart';
import 'Severity.dart';
import 'TemplateId.dart';
import 'When.dart';

abstract class Template extends TitleAndDescription implements Comparable {
  TemplateId? tId;
  int taskGroupId;
  TaskGroup? taskGroup;

  When? when;
  Severity? severity;
  bool? favorite = false;
  bool? hidden = false;

  Template({this.tId, required this.taskGroupId,
      required String title, String? description, this.when, this.severity, this.favorite, this.hidden})
  : super(title, description);

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

  Widget getTemplateRepresentation() {
    final text = Text(" " + translatedTitle);
    var icon = getIcon(true);
    return Row(children: [icon, text]);

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

  Icon getIcon(bool useColor, {Color? color}) {
    final taskGroup = TaskGroupRepository.findByIdFromCache(taskGroupId);
    return taskGroup.getIcon(useColor, color: color);
  }
}