import 'package:personaltasklogger/service/PreferenceService.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

import 'PersonalTaskLoggerApp.dart';

bool isDarkMode(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

Color getActionIconColor(BuildContext context) {
  if (isDarkMode(context)) {
    return Colors.white70;
  }
  else {
    return Colors.black87;
  }
}

String truncate(String text, { required int length, omission: '...' }) {
  if (length >= text.length) {
    return text;
  }
  return text.replaceRange(length, text.length, omission);
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