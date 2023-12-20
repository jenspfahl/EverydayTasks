import 'dart:ui';

import 'package:flutter/material.dart';

import '../ui/utils.dart';
import '../util/i18n.dart';

const baseAlpha = 100;
const darkThemeBaseAlpha = 150;

class TaskGroup implements Comparable {
  int? id;
  String name;
  Color? colorRGB;
  IconData? iconData;
  bool? hidden;

  TaskGroup({this.id, required this.name, this.colorRGB, this.iconData, this.hidden});

  TaskGroup.data({this.id, required String i18nName, this.colorRGB, this.iconData, this.hidden})
  : this.name = wrapToI18nKey('task_groups.${i18nName}.name');

  String get translatedName => translateI18nKey(name);

  @override
  int compareTo(other) {
    return other.id??0.compareTo(id??0);
  }
  
  Widget getTaskGroupRepresentation(BuildContext context, {
    bool useBackgroundColor = false,
    bool useIconColor = false,
    TextStyle? textStyle}) {
    final text = useBackgroundColor
        ? Text(" " + translatedName, style: textStyle ?? TextStyle(backgroundColor: backgroundColor(context)))
        : Text(" " + translatedName, style: textStyle,);

    if (iconData != null) {
      var icon = getIcon(useIconColor);
      return Row(children: [icon, text]);
    } else {
      return text;
    }
  }

  bool isPredefined() => id != null && isIdPredefined(id!);

  static bool isIdPredefined(int id) => id <= 0;

  Color? _getThemedColor(BuildContext context) => colorRGB?.withAlpha(isDarkMode(context) ? darkThemeBaseAlpha : baseAlpha);

  Color backgroundColor(BuildContext context) => _getShadedColor(_getThemedColor(context), true);
  Color softColor(BuildContext context) => _getShadedColor(_getThemedColor(context), false);
  Color accentColor(BuildContext context) => _getSharpedColor(_getThemedColor(context), 1.2);
  Color foregroundColor(BuildContext context) => _getSharpedColor(colorRGB);

  Icon getIcon(bool useIconColor, {Color? color}) {
    final icon = useIconColor
      ? Icon(iconData, color: color ?? _getSharpedColor(colorRGB))
      : Icon(iconData);
    return icon;
  }


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskGroup && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return translatedName;
  }

  getKey() => runtimeType.toString() +":"+ id.toString();

}

List<TaskGroup> predefinedTaskGroups = [
  TaskGroup.data(id: -1, i18nName: 'cleaning_n_tidy_up', colorRGB: Color.fromARGB(baseAlpha, 3, 138, 128), iconData: Icons.cleaning_services_outlined),
  TaskGroup.data(id: -2, i18nName: "laundry", colorRGB: Color.fromARGB(baseAlpha, 223, 185, 0), iconData: Icons.local_laundry_service_outlined),
  TaskGroup.data(id: -3, i18nName: "cooking", colorRGB: Color.fromARGB(baseAlpha, 222, 123, 8), iconData: Icons.lunch_dining_outlined),
  TaskGroup.data(id: -4, i18nName: "dishes", colorRGB: Color.fromARGB(baseAlpha, 2, 123, 255), iconData: Icons.local_cafe_outlined),
  TaskGroup.data(id: -5, i18nName: "errands",colorRGB: Color.fromARGB(baseAlpha, 183, 123, 8), iconData: Icons.shopping_basket_outlined),
  TaskGroup.data(id: -6, i18nName: "kids", colorRGB: Color.fromARGB(baseAlpha, 223, 3, 128), iconData: Icons.child_friendly_outlined),
  TaskGroup.data(id: -7, i18nName: "indoor_plants", colorRGB: Color.fromARGB(baseAlpha, 3, 208, 23), iconData: Icons.local_florist_outlined),
  TaskGroup.data(id: -8, i18nName: "garden", colorRGB: Color.fromARGB(baseAlpha, 3, 155, 7), iconData: Icons.park_outlined),
  TaskGroup.data(id: -9, i18nName: "maintenance", colorRGB: Color.fromARGB(baseAlpha, 183, 3, 23), iconData: Icons.build_outlined),
  TaskGroup.data(id: -10, i18nName: "organization",colorRGB: Color.fromARGB(baseAlpha, 183, 100, 128), iconData: Icons.phone_in_talk_outlined),
  TaskGroup.data(id: -11, i18nName: "car",colorRGB: Color.fromARGB(baseAlpha, 123, 123, 228), iconData: Icons.directions_car_outlined),
  TaskGroup.data(id: -12, i18nName: "pets",colorRGB: Color.fromARGB(baseAlpha, 228, 123, 203), iconData: Icons.pets_outlined),
  TaskGroup.data(id: -13, i18nName: "finance",colorRGB: Color.fromARGB(baseAlpha, 123, 228, 189), iconData: Icons.money_outlined),
  TaskGroup.data(id: -14, i18nName: "health",colorRGB: Color.fromARGB(baseAlpha, 200, 240, 3), iconData: Icons.healing_outlined),
  TaskGroup.data(id: -15, i18nName: "sport",colorRGB: Color.fromARGB(baseAlpha, 240, 122, 3), iconData: Icons.sports_tennis_outlined),
  TaskGroup.data(id: -16, i18nName: "work",colorRGB: Color.fromARGB(baseAlpha, 240, 3, 3), iconData: Icons.work_outline),
  TaskGroup.data(id: -17, i18nName: "private",colorRGB: Color.fromARGB(baseAlpha, 200, 30, 123), iconData: Icons.groups),
  TaskGroup.data(id: -18, i18nName: "hygiene",colorRGB: Color.fromARGB(baseAlpha, 3, 200, 205), iconData: Icons.bathtub_outlined),
  TaskGroup.data(id: -19, i18nName: "voluntary",colorRGB: Color.fromARGB(baseAlpha, 190, 140, 90), iconData: Icons.bloodtype_outlined),

  //last one
  TaskGroup.data(id: 0, i18nName: "others", colorRGB: Color.fromARGB(baseAlpha, 128, 128, 128), iconData: Icons.lightbulb_outline),
];

int deletedDefaultTaskGroupId = -1000000;
TaskGroup deletedDefaultTaskGroup = TaskGroup.data(id: deletedDefaultTaskGroupId, i18nName: "deleted", colorRGB: Color.fromARGB(
    100, 185, 185, 185), iconData: Icons.question_mark_outlined);


Color _getSharpedColor(Color? colorRGB, [double factor = 2.5]) {
  var color = colorRGB ?? Colors.lime.shade100;
  return tweakAlpha(color, factor)!;
}

Color _getShadedColor(Color? colorRGB, bool lessShaded) {
  var color = colorRGB ?? Colors.lime.shade100;
  return _shadeColor(lessShaded, color);
}

Color _shadeColor(bool lessShaded, Color color) {
  if (lessShaded) {
    return color.withAlpha(color.alpha~/2.5);
  }
  else {
    return color.withAlpha(color.alpha~/1.5);
  }
}





