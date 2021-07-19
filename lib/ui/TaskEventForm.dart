import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/When.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/utils.dart';
import 'package:personaltasklogger/util/dates.dart';

class TaskEventForm extends StatefulWidget {
  final String _title;
  final TaskEvent? _taskEvent;

  TaskEventForm(this._title, [this._taskEvent]);

  @override
  State<StatefulWidget> createState() {
    return _TaskEventFormState(_taskEvent);
  }
}

class _TaskEventFormState extends State<TaskEventForm> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  late TaskEvent? _taskEvent;

  late List<bool> _severitySelection;
  late int _severityIndex;

  DurationHours? _selectedDurationHours;
  Duration? _customDuration;

  _TaskEventFormState([this._taskEvent]) {
    final severity = _taskEvent?.severity != null ? _taskEvent!.severity : Severity.MEDIUM;

    this._severityIndex = severity.index;
    this._severitySelection = List.generate(Severity.values.length, (index) => index == _severityIndex);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._title),
      ),
      body: Builder(
        builder: (scaffoldContext) => Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(hintText: "Enter an event name"),
                  maxLength: 50,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(hintText: "An optional description"),
                  maxLength: 500,
                  maxLines: 3,
                ),
                Padding(
                  padding: EdgeInsets.only(top: 30.0),
                  child: ToggleButtons(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    renderBorder: true,
                    borderWidth: 1.5,
                    borderColor: Colors.grey,
                    color: Colors.grey.shade600,
                    selectedBorderColor: Colors.blue,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            severityToIcon(Severity.EASY),
                            Text('Easy going'),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            severityToIcon(Severity.MEDIUM),
                            Text('As always ok'),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            severityToIcon(Severity.HARD),
                            Text('Exhausting'),
                          ],
                        ),
                      ),
                    ],
                    isSelected: _severitySelection,
                    onPressed: (int index) {
                      setState(() {
                        _severitySelection[_severityIndex] = false;
                        _severitySelection[index] = true;
                        _severityIndex = index;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 30.0),
                  child: DropdownButtonFormField<DurationHours?>(
                    value: _selectedDurationHours,
                    hint: Text(
                      'Choose a duration',
                    ),
                    isExpanded: true,
                    onChanged: (value) {
                      if (value == DurationHours.CUSTOM) {
                        showDurationPickerDialog(context, _customDuration ?? Duration(minutes: 1)).then((duration) {
                          if (duration != null) {
                            setState(() => _customDuration = duration);
                          }
                        });
                      }
                      setState(() {
                        _selectedDurationHours = value;
                      });
                    },
                    validator: (DurationHours? value) {
                      if (value == null || (value == DurationHours.CUSTOM && _customDuration == null)) {
                        return "Please select a duration";
                      } else {
                        return null;
                      }
                    },
                    items: DurationHours.values.map((DurationHours durationHour) {
                      return DropdownMenuItem(
                        value: durationHour,
                        child: Text(
                          durationHour == DurationHours.CUSTOM && _customDuration != null
                              ? formatDuration(_customDuration!)
                              : When.fromDurationHoursString(durationHour),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        var taskEvent = TaskEvent.newInstance(
                          nameController.text,
                          descriptionController.text,
                          null,
                          null,
                          DateTime.now(),
                          DateTime.now()
                              .add(When.fromDurationHoursToDuration(_selectedDurationHours!, _customDuration!)),
                          Severity.values.elementAt(_severityIndex),
                        );
                        Navigator.pop(context, taskEvent);
                      }
                    },
                    child: Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
