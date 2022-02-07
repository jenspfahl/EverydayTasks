import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/Schedule.dart';
import 'package:personaltasklogger/ui/DurationPicker.dart';
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

/// Returns if a duration was chosen
Future<bool?> showDurationPickerDialog(BuildContext context, Function(Duration) _selectedDuration,
    [Duration? initialDuration]) {

  final durationPicker = DurationPicker(initialDuration, _selectedDuration);

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

/// Returns if a duration was chosen
Future<bool?> showRepetitionPickerDialog(BuildContext context, Function(CustomRepetition) _selectedRepetition,
    [CustomRepetition? initialRepetition]) {

  final repetitionPicker = RepetitionPicker(initialRepetition, _selectedRepetition);

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

void showTemplateDialog(BuildContext context, String title,
    {Function()? okPressed, Function()? cancelPressed, required Function(Object) selectedItem,}) {
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
    content: TaskTemplateList.withSelectionCallback(selectedItem),
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