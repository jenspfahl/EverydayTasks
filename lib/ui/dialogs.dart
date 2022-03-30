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

Future<bool?> showTemplateDialog(BuildContext context, String title, String description,
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

  final taskTemplateListStateKey = new GlobalKey<TaskTemplateListState>();
  final templateDialogDescriptionStateKey = new GlobalKey<TemplateDialogDescriptionState>();

  AlertDialog alert = AlertDialog(
    title: TemplateDialogBar(title, taskTemplateListStateKey, templateDialogDescriptionStateKey),
    content: Container(
      child: Column(
        children: [
          TemplateDialogDescription(description, templateDialogDescriptionStateKey),
          Expanded(
            flex: 100,
            child: TaskTemplateList.withSelectionCallback(
              selectedItem,
              onlyHidden: onlyHidden,
              hideEmptyNodes: hideEmptyNodes,
              expandAll: expandAll,
              key: taskTemplateListStateKey,
            ),
          ),
        ],
      ),
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


@immutable
class TemplateDialogBar extends StatefulWidget {
  final String title;
  final GlobalKey<TaskTemplateListState> taskTemplateListStateKey;
  final GlobalKey<TemplateDialogDescriptionState> templateDialogDescriptionStateKey;

  TemplateDialogBar(this.title, this.taskTemplateListStateKey, this.templateDialogDescriptionStateKey);

  @override
  State<StatefulWidget> createState() => TemplateDialogBarState();
}

class TemplateDialogBarState extends State<TemplateDialogBar> {

  TextEditingController _searchQueryController = TextEditingController();
  String? _searchString;

  @override
  Widget build(BuildContext context) {

    return _searchString != null
        ? _buildSearchField()
        : _buildBar();
  }

  Widget _buildBar() {
    return Row(
        children: [
          Text(widget.title),
          Spacer(),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _startSearch,
              ),
              Icon(Icons.unfold_less),
            ],
          )]
    );
  }

  Widget _buildSearchField() {
    return Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _stopSearching();
        },
      ),
      Flexible(
        child:
        TextField(
          controller: _searchQueryController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Search ...",
            border: InputBorder.none,
          ),
          style: TextStyle(fontSize: 16.0),
          onChanged: (query) {
            widget.taskTemplateListStateKey.currentState?.searchQueryUpdated(query);
          },
        ),
      ),
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
        _clearOrCloseSearchBar(context);
        },
      )
    ],);
  }


  void _startSearch() {
    setState(() {
      _searchString = "";
      widget.templateDialogDescriptionStateKey.currentState?.update(false);
    });
  }


  void _stopSearching() {
    _clearSearchQuery();

    setState(() {
      _searchString = null;
      widget.templateDialogDescriptionStateKey.currentState?.update(true);
    });
  }

  void _clearSearchQuery() {
    setState(() {
      _searchQueryController.clear();
      widget.taskTemplateListStateKey.currentState?.searchQueryUpdated("");

    });
  }

  void _clearOrCloseSearchBar(BuildContext context) {
    if (_searchQueryController.text.isEmpty) {
      _searchString = null;
      widget.taskTemplateListStateKey.currentState?.searchQueryUpdated(null);
    }
    else {
      _clearSearchQuery();
    }
  }

}


@immutable
class TemplateDialogDescription extends StatefulWidget {
  final String description;

  TemplateDialogDescription(
      this.description,
      GlobalKey<TemplateDialogDescriptionState> templateDialogDescriptionStateKey)
      : super(key: templateDialogDescriptionStateKey);

  @override
  State<StatefulWidget> createState() => TemplateDialogDescriptionState();
}

class TemplateDialogDescriptionState extends State<TemplateDialogDescription> {

  bool _showDescription = true;

  @override
  Widget build(BuildContext context) {

    return _showDescription
        ? Flexible(
            flex: 11,
            fit: FlexFit.loose,
            child: Text(widget.description),
          )
        : Container();
  }

  update(bool showDescription) {
    setState(() {
      _showDescription = showDescription;
    });
  }

}

