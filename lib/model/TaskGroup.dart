import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';

class TaskGroup implements Comparable {
  int? id;
  String name;
  String? description;
  Color? colorRGB;
  Icon? icon;

  TaskGroup({this.id, required this.name, this.description, this.colorRGB, this.icon});

  @override
  int compareTo(other) {
    return other.id??0.compareTo(id??0);
  }

}


List<TaskGroup> predefinedTaskGroups = [
  TaskGroup(id: 0, name: "Others"),
  TaskGroup(id: -1, name: "Cleaning & Tidy up", colorRGB: Color.fromARGB(100, 3, 138, 128), icon: Icon(Icons.cleaning_services_outlined)),
  TaskGroup(id: -2, name: "Laundry", colorRGB: Color.fromARGB(100, 223, 185, 0), icon: Icon(Icons.local_laundry_service_outlined)),
  TaskGroup(id: -3, name: "Cooking", colorRGB: Color.fromARGB(100, 222, 123, 8), icon: Icon(Icons.lunch_dining_outlined)),
  TaskGroup(id: -4, name: "Dishes", colorRGB: Color.fromARGB(100, 2, 23, 228), icon: Icon(Icons.restaurant_outlined)),
  TaskGroup(id: -5, name: "Errands",colorRGB: Color.fromARGB(100, 183, 123, 8), icon: Icon(Icons.shopping_basket_outlined)),
  TaskGroup(id: -6, name: "Kids", colorRGB: Color.fromARGB(100, 223, 3, 128), icon: Icon(Icons.child_friendly_outlined)),
  TaskGroup(id: -7, name: "Indoor plants", colorRGB: Color.fromARGB(100, 3, 255, 7), icon: Icon(Icons.local_florist_outlined)),
  TaskGroup(id: -8, name: "Garden", colorRGB: Color.fromARGB(100, 3, 155, 7), icon: Icon(Icons.park_outlined)),
  TaskGroup(id: -9, name: "Maintenance", colorRGB: Color.fromARGB(100, 183, 3, 7), icon: Icon(Icons.build_outlined)),
  TaskGroup(id: -10, name: "Organization",colorRGB: Color.fromARGB(100, 183, 123, 128), icon: Icon(Icons.phone_in_talk_outlined)),
  TaskGroup(id: -11, name: "Car",colorRGB: Color.fromARGB(100, 83, 123, 228), icon: Icon(Icons.directions_car_outlined)),
];


TaskGroup findTaskGroupById(int id) => predefinedTaskGroups.firstWhere((element) => element.id == id);




