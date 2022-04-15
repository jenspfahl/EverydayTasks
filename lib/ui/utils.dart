import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
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

String truncate(String text, { required int length, omission: '...' }) {
  if (length >= text.length) {
    return text;
  }
  return text.replaceRange(length, text.length, omission);
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

toastInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          duration: Duration(milliseconds: message.length * 80),
          content: Text(message)));
}

toastError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          content: Text(message)));
}

void launchUrl(url) async {
  if (await canLaunch(url)) {
    await launch(url);
  }
  else {
    debugPrint("Could not launch $url");
  }
}

Text boldedText(String text) => Text(text, style: TextStyle(fontWeight: FontWeight.bold));

Text wrappedText(String text) => Text(text, softWrap: true);