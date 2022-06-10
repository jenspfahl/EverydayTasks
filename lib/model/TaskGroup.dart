import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/utils.dart';

import '../util/i18n.dart';

class TaskGroup implements Comparable {
  int? id;
  String name;
  String? description;
  Color? colorRGB;
  IconData? iconData;

  TaskGroup({this.id, required String i18nName, this.description, this.colorRGB, this.iconData}) 
  : this.name = wrapToI18nKey('task_groups.${i18nName}.name');

  String get translatedName => translateI18nKey(name);

  @override
  int compareTo(other) {
    return other.tId??0.compareTo(id??0);
  }
  
  Widget getTaskGroupRepresentation({
    bool useBackgroundColor = false,
    bool useIconColor = false,
    TextStyle? textStyle}) {
    final text = useBackgroundColor
        ? Text(" " + translatedName, style: textStyle ?? TextStyle(backgroundColor: backgroundColor))
        : Text(" " + translatedName, style: textStyle,);

    if (iconData != null) {
      var icon = getIcon(useIconColor);
      return Row(children: [icon, text]);
    } else {
      return text;
    }
  }

  Color get backgroundColor => getShadedColor(colorRGB, true);

  Icon getIcon(bool useIconColor) {
    final icon = useIconColor
      ? Icon(iconData, color: getSharpedColor(colorRGB))
      : Icon(iconData);
    return icon;
  }

  @override
  String toString() {
    return translatedName;
  }

  getKey() => runtimeType.toString() +":"+ id.toString();

}

List<TaskGroup> predefinedTaskGroups = [
  TaskGroup(id: -1, i18nName: 'cleaning_n_tidy_up', colorRGB: Color.fromARGB(100, 3, 138, 128), iconData: Icons.cleaning_services_outlined),
  TaskGroup(id: -2, i18nName: "Laundry", colorRGB: Color.fromARGB(100, 223, 185, 0), iconData: Icons.local_laundry_service_outlined),
  TaskGroup(id: -3, i18nName: "Cooking", colorRGB: Color.fromARGB(100, 222, 123, 8), iconData: Icons.lunch_dining_outlined),
  TaskGroup(id: -4, i18nName: "Dishes", colorRGB: Color.fromARGB(100, 2, 23, 228), iconData: Icons.local_cafe_outlined),
  TaskGroup(id: -5, i18nName: "Errands",colorRGB: Color.fromARGB(100, 183, 123, 8), iconData: Icons.shopping_basket_outlined),
  TaskGroup(id: -6, i18nName: "Kids", colorRGB: Color.fromARGB(100, 223, 3, 128), iconData: Icons.child_friendly_outlined),
  TaskGroup(id: -7, i18nName: "Indoor plants", colorRGB: Color.fromARGB(100, 3, 208, 23), iconData: Icons.local_florist_outlined),
  TaskGroup(id: -8, i18nName: "Garden", colorRGB: Color.fromARGB(100, 3, 155, 7), iconData: Icons.park_outlined),
  TaskGroup(id: -9, i18nName: "Maintenance", colorRGB: Color.fromARGB(100, 183, 3, 23), iconData: Icons.build_outlined),
  TaskGroup(id: -10, i18nName: "Organization",colorRGB: Color.fromARGB(100, 183, 100, 128), iconData: Icons.phone_in_talk_outlined),
  TaskGroup(id: -11, i18nName: "Car",colorRGB: Color.fromARGB(100, 123, 123, 228), iconData: Icons.directions_car_outlined),
  TaskGroup(id: -12, i18nName: "Pets",colorRGB: Color.fromARGB(100, 228, 123, 203), iconData: Icons.pets_outlined),
  TaskGroup(id: -13, i18nName: "Finance",colorRGB: Color.fromARGB(100, 123, 228, 189), iconData: Icons.money_outlined),
  TaskGroup(id: -14, i18nName: "Health",colorRGB: Color.fromARGB(100, 200, 240, 3), iconData: Icons.healing_outlined),
  TaskGroup(id: -15, i18nName: "Sport",colorRGB: Color.fromARGB(100, 240, 122, 3), iconData: Icons.sports_tennis_outlined),
  TaskGroup(id: -16, i18nName: "Work",colorRGB: Color.fromARGB(100, 240, 3, 3), iconData: Icons.work_outline),

  //last one
  TaskGroup(id: 0, i18nName: "Others", colorRGB: Color.fromARGB(100, 128, 128, 128), iconData: Icons.lightbulb_outline),
];


TaskGroup findPredefinedTaskGroupById(int id) => predefinedTaskGroups.firstWhere((element) => element.id == id);




