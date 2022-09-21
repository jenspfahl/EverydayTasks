import 'dart:ui';

import 'package:flutter/material.dart';

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

  Color get backgroundColor => _getShadedColor(colorRGB, true);
  Color get softColor => _getShadedColor(colorRGB, false);
  Color get accentColor => _getSharpedColor(colorRGB, 1.2);
  Color get foregroundColor => _getSharpedColor(colorRGB);

  Icon getIcon(bool useIconColor) {
    final icon = useIconColor
      ? Icon(iconData, color: _getSharpedColor(colorRGB))
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
  TaskGroup(id: -2, i18nName: "laundry", colorRGB: Color.fromARGB(100, 223, 185, 0), iconData: Icons.local_laundry_service_outlined),
  TaskGroup(id: -3, i18nName: "cooking", colorRGB: Color.fromARGB(100, 222, 123, 8), iconData: Icons.lunch_dining_outlined),
  TaskGroup(id: -4, i18nName: "dishes", colorRGB: Color.fromARGB(100, 2, 23, 228), iconData: Icons.local_cafe_outlined),
  TaskGroup(id: -5, i18nName: "errands",colorRGB: Color.fromARGB(100, 183, 123, 8), iconData: Icons.shopping_basket_outlined),
  TaskGroup(id: -6, i18nName: "kids", colorRGB: Color.fromARGB(100, 223, 3, 128), iconData: Icons.child_friendly_outlined),
  TaskGroup(id: -7, i18nName: "indoor_plants", colorRGB: Color.fromARGB(100, 3, 208, 23), iconData: Icons.local_florist_outlined),
  TaskGroup(id: -8, i18nName: "garden", colorRGB: Color.fromARGB(100, 3, 155, 7), iconData: Icons.park_outlined),
  TaskGroup(id: -9, i18nName: "maintenance", colorRGB: Color.fromARGB(100, 183, 3, 23), iconData: Icons.build_outlined),
  TaskGroup(id: -10, i18nName: "organization",colorRGB: Color.fromARGB(100, 183, 100, 128), iconData: Icons.phone_in_talk_outlined),
  TaskGroup(id: -11, i18nName: "car",colorRGB: Color.fromARGB(100, 123, 123, 228), iconData: Icons.directions_car_outlined),
  TaskGroup(id: -12, i18nName: "pets",colorRGB: Color.fromARGB(100, 228, 123, 203), iconData: Icons.pets_outlined),
  TaskGroup(id: -13, i18nName: "finance",colorRGB: Color.fromARGB(100, 123, 228, 189), iconData: Icons.money_outlined),
  TaskGroup(id: -14, i18nName: "health",colorRGB: Color.fromARGB(100, 200, 240, 3), iconData: Icons.healing_outlined),
  TaskGroup(id: -15, i18nName: "sport",colorRGB: Color.fromARGB(100, 240, 122, 3), iconData: Icons.sports_tennis_outlined),
  TaskGroup(id: -16, i18nName: "work",colorRGB: Color.fromARGB(100, 240, 3, 3), iconData: Icons.work_outline),

  //last one
  TaskGroup(id: 0, i18nName: "others", colorRGB: Color.fromARGB(100, 128, 128, 128), iconData: Icons.lightbulb_outline),
];


TaskGroup findPredefinedTaskGroupById(int id) => predefinedTaskGroups.firstWhere((element) => element.id == id);



Color _getSharpedColor(Color? colorRGB, [double factor = 2.5]) {
  var color = colorRGB ?? Colors.lime.shade100;
  return _blend(color.withAlpha((color.alpha * factor).toInt()));
}

Color _getShadedColor(Color? colorRGB, bool lessShaded) {
  var color = colorRGB ?? Colors.lime.shade100;
  return _blend(_shadeColor(lessShaded, color));
}

Color _shadeColor(bool lessShaded, Color color) {
  if (lessShaded) {
    return color.withAlpha(color.alpha~/2.5);
  }
  else {
    return color.withAlpha(color.alpha~/1.5);
  }
}

Color _blend(Color color) {
  return color.withAlpha((color.alpha * 1).toInt());
  return Color.alphaBlend(color, Colors.grey);
}




