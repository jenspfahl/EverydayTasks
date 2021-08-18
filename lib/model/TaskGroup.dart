import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:personaltasklogger/ui/utils.dart';

class TaskGroup implements Comparable {
  int? id;
  String name;
  String? description;
  Color? colorRGB;
  IconData? iconData;

  TaskGroup({this.id, required this.name, this.description, this.colorRGB, this.iconData});

  @override
  int compareTo(other) {
    return other.id??0.compareTo(id??0);
  }
  
  Widget getTaskGroupRepresentation({bool useBackgroundColor = false, bool useIconColor = false}) {
    final text = useBackgroundColor
        ? Text(" " + name, style: TextStyle(backgroundColor: getShadedColor(colorRGB, true)))
        : Text(" " + name);

    if (iconData != null) {
      final icon = useIconColor
        ? Icon(iconData, color: getSharpedColor(colorRGB))
        : Icon(iconData);
      return Row(children: [icon, text]);
    } else {
      return text;
    }
  }

}


List<TaskGroup> predefinedTaskGroups = [
  TaskGroup(id: 0, name: "Others"),
  TaskGroup(id: -1, name: "Cleaning & Tidy up", colorRGB: Color.fromARGB(100, 3, 138, 128), iconData: Icons.cleaning_services_outlined),
  TaskGroup(id: -2, name: "Laundry", colorRGB: Color.fromARGB(100, 223, 185, 0), iconData: Icons.local_laundry_service_outlined),
  TaskGroup(id: -3, name: "Cooking", colorRGB: Color.fromARGB(100, 222, 123, 8), iconData: Icons.lunch_dining_outlined),
  TaskGroup(id: -4, name: "Dishes", colorRGB: Color.fromARGB(100, 2, 23, 228), iconData: Icons.local_cafe_outlined),
  TaskGroup(id: -5, name: "Errands",colorRGB: Color.fromARGB(100, 183, 123, 8), iconData: Icons.shopping_basket_outlined),
  TaskGroup(id: -6, name: "Kids", colorRGB: Color.fromARGB(100, 223, 3, 128), iconData: Icons.child_friendly_outlined),
  TaskGroup(id: -7, name: "Indoor plants", colorRGB: Color.fromARGB(100, 3, 228, 7), iconData: Icons.local_florist_outlined),
  TaskGroup(id: -8, name: "Garden", colorRGB: Color.fromARGB(100, 3, 155, 7), iconData: Icons.park_outlined),
  TaskGroup(id: -9, name: "Maintenance", colorRGB: Color.fromARGB(100, 183, 3, 7), iconData: Icons.build_outlined),
  TaskGroup(id: -10, name: "Organization",colorRGB: Color.fromARGB(100, 183, 123, 128), iconData: Icons.phone_in_talk_outlined),
  TaskGroup(id: -11, name: "Car",colorRGB: Color.fromARGB(100, 83, 123, 228), iconData: Icons.directions_car_outlined),
];


TaskGroup findTaskGroupById(int id) => predefinedTaskGroups.firstWhere((element) => element.id == id);




