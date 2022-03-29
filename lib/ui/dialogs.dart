import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/Schedule.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/ui/DurationPicker.dart';
import 'package:personaltasklogger/ui/SeverityPicker.dart';
import 'package:personaltasklogger/ui/pages/TaskTemplateList.dart';

import 'RepetitionPicker.dart';

void showConfirmationDialog(BuildContext context, String title, String message,
    {Function()? okPressed, Function()? cancelPressed}) {
  Widget cancelButton = TextButton(
    child: Text("Cancel"),
    onPressed:  cancelPressed,
  );
  Widget okButton = TextButton(
    child: Text("Ok"),
    onPressed:  okPressed,
  );

  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      cancelButton,
      okButton,
    ],
  );  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

Future<bool?> showDurationPickerDialog({
  required BuildContext context,
  Duration? initialDuration,
  required ValueChanged<Duration> onChanged,
}) {

  final durationPicker = DurationPicker(
      initialDuration: initialDuration,
      onChanged: onChanged,
  );

  Dialog dialog = Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), //this right here
    child: Container(
      height: 300.0,
      width: 300.0,

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          durationPicker,
          SizedBox(height: 20.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
            TextButton(
              child: Text("Cancel"),
              onPressed:  () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text("Ok"),
              onPressed:  () => Navigator.of(context).pop(true),
            )
            ],)
        ],
      ),
    ),
  );

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return dialog;
    },
  );
}

Future<bool?> showRepetitionPickerDialog({
  required BuildContext context,
  CustomRepetition? initialRepetition,
  required ValueChanged<CustomRepetition> onChanged,
}) {

  final repetitionPicker = RepetitionPicker(
    initialRepetition: initialRepetition,
    onChanged: onChanged,
  );

  Dialog dialog = Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), //this right here
    child: Container(
      height: 300.0,
      width: 300.0,

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          repetitionPicker,
          SizedBox(height: 20.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
            TextButton(
              child: Text("Cancel"),
              onPressed:  () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text("Ok"),
              onPressed:  () => Navigator.of(context).pop(true),
            )
            ],)
        ],
      ),
    ),
  );

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return dialog;
    },
  );
}

Future<bool?> showTemplateDialog(BuildContext context, String title,
    {
      Function()? okPressed,
      Function()? cancelPressed,
      required Function(Object) selectedItem,
      bool? onlyHidden,
      bool? hideEmptyNodes,
      bool? expandAll,
    }) {
  Widget cancelButton = TextButton(
    child: Text("Cancel"),
    onPressed:  cancelPressed,
  );
  Widget okButton = TextButton(
    child: Text("Ok"),
    onPressed:  okPressed,
  );

  AlertDialog alert = AlertDialog(
    title: Text(title), //TODO Row (Test,  ButtonBar (Search,Expand))
    content: TaskTemplateList.withSelectionCallback(
        selectedItem,
        onlyHidden: onlyHidden,
        hideEmptyNodes: hideEmptyNodes,
        expandAll: expandAll,
    ),
    actions: [
      cancelButton,
      okButton,
    ],
  );  // show the dialog
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

Future<bool?> showSeverityPicker(BuildContext context, Severity? initialSeverity,
    bool showText, ValueChanged<Severity?> onChanged) {

  Widget clearButton = TextButton(
    child: Text("Clear"),
    onPressed: () {
      onChanged(null);
    },
  );
  AlertDialog alert = AlertDialog(
    content: SeverityPicker(
      showText: showText,
      singleButtonWidth: 75,
      initialSeverity: initialSeverity,
      onChanged: onChanged,
    ),
    actions: [clearButton],
  );
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

Future<dynamic> showPopUpMenuAtTapDown(BuildContext context, TapDownDetails tapDown, List<PopupMenuEntry> items) {
  return showMenu(
    context: context,
    position: RelativeRect.fromLTRB(
      tapDown.globalPosition.dx,
      tapDown.globalPosition.dy,
      tapDown.globalPosition.dx,
      tapDown.globalPosition.dy,
    ),
    items: items,
    elevation: 8.0,
  );
}