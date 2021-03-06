import 'package:personaltasklogger/service/PreferenceService.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';

import 'PersonalTaskLoggerApp.dart';

Color getTaskGroupColor(int? taskGroupId, bool lessShaded) {
  final taskGroupColor = taskGroupId != null ? findPredefinedTaskGroupById(taskGroupId).colorRGB : null;
  return getShadedColor(taskGroupColor, lessShaded);
}

Color getColorWithOpacity(Color? colorRGB, double opacity) {
  var color = colorRGB ?? Colors.lime.shade100;
  return color.withOpacity(opacity);
}

Color getSharpedColor(Color? colorRGB, [double factor = 2.5]) {
  var color = colorRGB ?? Colors.lime.shade100;
  return color.withAlpha((color.alpha * factor).toInt());
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
    return color.withAlpha(color.alpha~/1.5);
  }
}

Widget createCheckIcon(bool checked) {
  if (!checked) {
    return Text("");
  }
  return Icon(
    Icons.check,
    color: BUTTON_COLOR,
  );
}

toastInfo(BuildContext context, String message, {bool? forceShow}) {
  PreferenceService().getBool(PreferenceService.PREF_SHOW_ACTION_NOTIFICATIONS)
      .then((show) {
        if (show != false || forceShow == true) {
          _calcMessageDuration(message, false).then((duration) {
            var messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
                SnackBar(
                    duration: duration,
                    content: Text(message)));
          });
        }
  });

}

toastError(BuildContext context, String message) {
  _calcMessageDuration(message, true).then((duration) {
    var messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.clearSnackBars();
    messenger.showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            duration: duration,
            content: Text(message)));
  });
}

Future<Duration> _calcMessageDuration(String message, bool isError) async {
  final showActionNotificationDurationSelection = await PreferenceService().getInt(PreferenceService.PREF_SHOW_ACTION_NOTIFICATION_DURATION_SELECTION)??1;
  double factor = 1;
  switch (showActionNotificationDurationSelection) {
    case 0 : { // slow
      factor = 2;
      break;
    }
    case 2 : { // fast
      factor = 0.5;
      break;
    }
    case 3 : { // fast
      factor = 0.3;
      break;
    }
  }
  return Duration(milliseconds: (message.length * (isError ? 100 : 80) * factor).toInt());
}

void launchUrl(url) async {
  launch(url);
}

Text boldedText(String text) => Text(text, style: TextStyle(fontWeight: FontWeight.bold));

Text wrappedText(String text) => Text(text, softWrap: true);