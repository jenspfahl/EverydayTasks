import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/model/Schedule.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/ui/DurationPicker.dart';
import 'package:personaltasklogger/ui/SeverityPicker.dart';
import 'package:personaltasklogger/ui/pages/TaskTemplateList.dart';
import 'package:personaltasklogger/util/extensions.dart';

import 'ChoiceWidget.dart';
import 'PersonalTaskLoggerApp.dart';
import 'RepetitionPicker.dart';
import 'ToggleActionIcon.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';

import 'taskGroupIcons.dart';


final int MAX_DAYS = 7300; // around 20 years

Future<IconData?> showIconPicker(BuildContext context, String title) {

  return FlutterIconPicker.showIconPicker(context,
      //iconColor: ,
      iconSize: 32.0,
      title: Text(title),
 //     iconColor: Colors.blue,
      searchHintText: "${translate('common.search')} ...",
 //     noResultsText: "Not found",
      closeChild: TextButton(
        child: Text(translate("common.ok")),
        onPressed:  () => Navigator.of(context).pop(true),
      ),
      showTooltips: true,
      customIconPack: getAllTaskGroupIcons(),
      iconPackModes: [IconPack.custom],
  );
}

Future<bool?> showColorPicker(BuildContext context, {required String title, required Color initialColor, required Function(Color) onColorChanged, required Function() onOkClicked}) {
  final dialog = AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: initialColor.withOpacity(1.0),
          enableAlpha: false,
          onColorChanged: onColorChanged,
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(translate("common.ok")),
          onPressed: () {
            onOkClicked();
            Navigator.of(context).pop();
          },
        ),
      ],
    );

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return dialog;
    },
  );
}

Future<DateTime?> showTweakedDatePicker(BuildContext context, {DateTime? initialDate}) {
  return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: MAX_DAYS)),
      lastDate: DateTime.now().add(Duration(days: MAX_DAYS)),
      builder: (BuildContext context, Widget? child) {
        return _pickerTheme(context, child);
      }
  );
}

Future<DateTimeRange?> showTweakedDateRangePicker(BuildContext context, {DateTimeRange? initialDateRange}) {
  return showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      currentDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: MAX_DAYS)),
      lastDate: DateTime.now().add(Duration(days: MAX_DAYS)),
      builder: (BuildContext context, Widget? child) {
        return _pickerTheme(context, child);
      }
  );
}

Theme _pickerTheme(BuildContext context, Widget? child) {
  return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
              primary: BUTTON_COLOR,
              onPrimary: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              primary: BUTTON_COLOR,
            ),
          ),
        ),
        child: child!,
      );
}

void showConfirmationDialog(BuildContext context, String title, String message,
    {Icon? icon, Function()? okPressed, Function()? cancelPressed}) {

  List<Widget> actions = [];
  if (cancelPressed != null) {
    Widget cancelButton = TextButton(
      child: Text(translate("common.cancel")),
      onPressed:  cancelPressed,
    );
    actions.add(cancelButton);
  }
  if (okPressed != null) {
    Widget okButton = TextButton(
      child: Text(translate("common.ok")),
      onPressed:  okPressed,
    );
    actions.add(okButton);
  }
  AlertDialog alert = AlertDialog(
    title: icon != null
      ? Row(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
        child: icon,
      ),
      Text(title)
    ],)
      : Text(title),
    content: Text(message),
    actions: actions,
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)), //this right here
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
              child: Text(translate("common.cancel")),
              onPressed:  () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(translate("common.ok")),
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
  required String description,
  required ValueChanged<CustomRepetition> onChanged,
  List<RepetitionUnit>? supportedUnits
}) {

  final repetitionPicker = RepetitionPicker(
    description: description,
    initialRepetition: initialRepetition,
    onChanged: onChanged,
    supportedUnits: supportedUnits ?? [RepetitionUnit.DAYS, RepetitionUnit.WEEKS, RepetitionUnit.MONTHS, RepetitionUnit.YEARS],
  );

  Dialog dialog = Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), //this right here
    child: Container(
      height: 350.0,
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
              child: Text(translate("common.cancel")),
              onPressed:  () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(translate("common.ok")),
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
      String? initialSelectedKey,
    }) {
  Widget cancelButton = TextButton(
    child: Text(translate("common.cancel")),
    onPressed:  cancelPressed,
  );
  Widget okButton = TextButton(
    child: Text(translate("common.ok")),
    onPressed:  okPressed,
  );

  final taskTemplateListStateKey = new GlobalKey<TaskTemplateListState>();
  final templateDialogDescriptionStateKey = new GlobalKey<TemplateDialogDescriptionState>();

  final dialog = AlertDialog(
    title: TemplateDialogBar(title, expandAll??false, taskTemplateListStateKey, templateDialogDescriptionStateKey),
    titlePadding: EdgeInsets.fromLTRB(16, 16, 8, 8),
    content: Container(
      child: Column(
        children: [
          TemplateDialogDescription(description, templateDialogDescriptionStateKey),
          Expanded(
            flex: 100,
            child: SizedBox(
              width: 3000,
              height: 3000,
              child: TaskTemplateList.withSelectionCallback(
                selectedItem,
                onlyHidden: onlyHidden,
                hideEmptyNodes: hideEmptyNodes,
                expandAll: expandAll,
                initialSelectedKey: initialSelectedKey,
                key: taskTemplateListStateKey,
              ),
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
      return dialog;
    },
  );
}

Future<bool?> showSeverityPicker(BuildContext context, Severity? initialSeverity,
    bool showText, ValueChanged<Severity?> onChanged) {

  Widget clearButton = TextButton(
    child: Text(translate('common.words.clear').capitalize()),
    onPressed: () {
      onChanged(null);
    },
  );
  AlertDialog alert = AlertDialog(
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
    content: SeverityPicker(
      showText: showText,
      singleButtonWidth: 85,
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

Future<void> showChoiceDialog(BuildContext context, String title, List<String> choices, {
  Function()? okPressed,
  Function()? cancelPressed,
  int? initialSelected,
  required ValueChanged<int> selectionChanged
}) {
  Widget cancelButton = TextButton(
    child: Text(translate("common.cancel")),
    onPressed:  cancelPressed,
  );
  Widget okButton = TextButton(
    child: Text(translate("common.ok")),
    onPressed:  okPressed,
  );

  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: ChoiceWidget(
            choices: choices,
            initialSelected: initialSelected,
            onChanged: selectionChanged,
          ),
          actions: [
            cancelButton,
            okButton,
          ],
        );
      }
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
  final bool initialExpandAll;

  final expandIconKey = new GlobalKey<ToggleActionIconState>();

  TemplateDialogBar(this.title, this.initialExpandAll, this.taskTemplateListStateKey, this.templateDialogDescriptionStateKey);

  @override
  State<StatefulWidget> createState() => TemplateDialogBarState();
}

class TemplateDialogBarState extends State<TemplateDialogBar> {

  TextEditingController _searchQueryController = TextEditingController();
  String? _searchString;
  bool _isAllExpanded = false;

  @override
  void initState() {
    _isAllExpanded = widget.initialExpandAll;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return _searchString != null
        ? _buildSearchField()
        : _buildBar();
  }

  Widget _buildBar() {
    final expandIcon = ToggleActionIcon(Icons.unfold_less, Icons.unfold_more, _isAllExpanded, widget.expandIconKey);

    return Row(
        children: [
          Text(widget.title),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 40,
                child: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _startSearch,
                ),
              ),
              SizedBox(
                width: 40,
                child: IconButton(
                  icon: expandIcon,
                  onPressed: () {
                    setState(() {
                      widget.taskTemplateListStateKey.currentState?.updateExpanded(_isAllExpanded);
                      _isAllExpanded = !_isAllExpanded;
                      widget.expandIconKey.currentState?.refresh(_isAllExpanded);
                    });
                  },
                ),
              ),
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
            hintText: "${translate('common.search')} ...",
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
      _searchString = "";
      widget.taskTemplateListStateKey.currentState?.searchQueryUpdated("");

    });
  }

  void _clearOrCloseSearchBar(BuildContext context) {
    if (_searchQueryController.text.isEmpty) {
      _stopSearching();
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

