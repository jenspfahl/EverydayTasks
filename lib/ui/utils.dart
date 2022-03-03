import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';

Color getTaskGroupColor(int? taskGroupId, bool lessShaded) {
  final taskGroupColor = taskGroupId != null ? findPredefinedTaskGroupById(taskGroupId).colorRGB : null;
  return getShadedColor(taskGroupColor, lessShaded);
}

Color getColorWithOpacity(Color? colorRGB, double opacity) {
  var color = colorRGB ?? Colors.lime.shade100;
  return color.withOpacity(opacity);
}

Color getSharpedColor(Color? colorRGB) {
  var color = colorRGB ?? Colors.lime.shade100;
  return color.withAlpha((color.alpha * 2.5).toInt());
}

Color getShadedColor(Color? colorRGB, bool lessShaded) {
  var color = colorRGB ?? Colors.lime.shade100;
  return shadeColor(lessShaded, color);
}

Color shadeColor(bool lessShaded, Color color) {
  if (lessShaded) {
    return color.withAlpha((color.alpha/2.5).toInt());
  }
  else {
    return color.withAlpha((color.alpha/1.5).toInt());
  }
}

Icon createCheckIcon(bool checked) {
  return Icon(
    checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
    color: checked ? Colors.blueAccent : null,
  );
}