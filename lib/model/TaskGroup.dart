import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/utils.dart';

class TaskGroup {
  int? id;
  String name;
  String? description;
  Color? colorRGB;
  int? taskGroupId;

  TaskGroup({this.id, required this.name, this.description, this.colorRGB, this.taskGroupId});

}


// mockup methods
List<TaskGroup> testGroups = [
  TaskGroup(id: -1, name: "Household", colorRGB: Color.fromARGB(100, 3, 138, 128)),
  TaskGroup(id: -3, name: "Cooking", taskGroupId: -1, colorRGB: Color.fromARGB(100, 123, 155, 0)),
  TaskGroup(id: -4, name: "Cleaning", taskGroupId: -1, colorRGB: Color.fromARGB(100, 223, 3, 128)),
  TaskGroup(id: -5, name: "Hovering", taskGroupId: -4, colorRGB: Color.fromARGB(100, 183, 3, 248)),
  TaskGroup(id: -2, name: "Kid"),
];

const _pathSeparator = " / ";

String getTaskGroupPathAsString(int taskGroupId) {
  StringBuffer sb = StringBuffer();
  _buildTaskGroupPathAsString(taskGroupId, sb);
  final s = sb.toString();
  return s.substring(0, s.length - _pathSeparator.length);
}

_buildTaskGroupPathAsString(int taskGroupId, StringBuffer sb) {
  final group = findTaskGroupById(taskGroupId);
  if (group.taskGroupId != null) {
    _buildTaskGroupPathAsString(group.taskGroupId!, sb);
  }
  sb..write(group.name)..write(_pathSeparator);
}

TaskGroup findTaskGroupById(int id) => testGroups.firstWhere((element) => element.id == id);




