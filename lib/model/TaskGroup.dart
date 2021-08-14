import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';

class TaskGroup implements Comparable {
  int? id;
  String name;
  String? description;
  Color? colorRGB;

  TaskGroup({this.id, required this.name, this.description, this.colorRGB});

  @override
  int compareTo(other) {
    return other.id??0.compareTo(id??0);
  }

}


List<TaskGroup> predefinedTaskGroups = [
  TaskGroup(id: 0, name: "Others"),
  TaskGroup(id: -1, name: "Cleaning & Tidy up", colorRGB: Color.fromARGB(100, 3, 138, 128)), 
  TaskGroup(id: -2, name: "Laundry", colorRGB: Color.fromARGB(100, 223, 185, 0)),
  TaskGroup(id: -3, name: "Cooking", colorRGB: Color.fromARGB(100, 2, 123, 8)),
  TaskGroup(id: -4, name: "Dishes", colorRGB: Color.fromARGB(100, 2, 23, 228)),
  TaskGroup(id: -5, name: "Errands",colorRGB: Color.fromARGB(100, 183, 123, 8)),
  TaskGroup(id: -6, name: "Kids", colorRGB: Color.fromARGB(100, 223, 3, 128)),
  TaskGroup(id: -7, name: "Maintenance", colorRGB: Color.fromARGB(100, 183, 3, 7)),
  TaskGroup(id: -8, name: "Organization",colorRGB: Color.fromARGB(100, 183, 123, 128)),
];


TaskGroup findTaskGroupById(int id) => predefinedTaskGroups.firstWhere((element) => element.id == id);




