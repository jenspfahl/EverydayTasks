import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
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
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  late TaskEvent? _taskEvent;

  TaskGroup? _selectedTaskGroup;

  late List<bool> _severitySelection;
  late int _severityIndex;

  AroundDurationHours? _selectedDurationHours;
  Duration? _customDuration;
  Duration? _tempSelectedDuration;

  AroundWhenAtDay? _selectedWhenAtDay;
  TimeOfDay? _customWhenAt;

  WhenOnDate? _selectedWhenOnDate;
  DateTime? _customWhenOn;

  _TaskEventFormState([this._taskEvent]) {
    final severity = _taskEvent?.severity != null ? _taskEvent!.severity : Severity.MEDIUM;
    this._severityIndex = severity.index;
    this._severitySelection = List.generate(Severity.values.length, (index) => index == _severityIndex);

    if (_taskEvent != null) {
      titleController.text = _taskEvent!.title;
      descriptionController.text = _taskEvent!.description ?? "";
      if (_taskEvent?.taskGroupId != null) {
        _selectedTaskGroup = findTaskGroupById(_taskEvent!.taskGroupId!);
      }

      _selectedDurationHours = _taskEvent?.aroundDuration;
      if (_selectedDurationHours == AroundDurationHours.CUSTOM) {
        _customDuration = _taskEvent?.duration;
      }

      _selectedWhenAtDay = _taskEvent?.aroundStartedAt;
      if (_selectedWhenAtDay == AroundWhenAtDay.NOW || _selectedWhenAtDay == AroundWhenAtDay.CUSTOM) {
        _selectedWhenAtDay = AroundWhenAtDay.CUSTOM; // Former NOW is now CUSTOM
        _customWhenAt = TimeOfDay.fromDateTime(_taskEvent!.startedAt);
      }

      final startedAt = truncToDate(_taskEvent!.startedAt);
      if (isToday(startedAt)) {
        _selectedWhenOnDate = WhenOnDate.TODAY;
      } else if (isYesterday(startedAt)) {
        _selectedWhenOnDate = WhenOnDate.YESTERDAY;
      } else if (isBeforeYesterday(startedAt)) {
        _selectedWhenOnDate = WhenOnDate.BEFORE_YESTERDAY;
      } else {
        _selectedWhenOnDate = WhenOnDate.CUSTOM;
        _customWhenOn = startedAt;
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget._title),
        ),
        body: SingleChildScrollView(
          child: Container(
            child: Builder(
              builder: (scaffoldContext) => Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: "Enter an event title",
                          icon: Icon(Icons.event_available),
                        ),
                        maxLength: 50,
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          hintText: "An optional description",
                          icon: Icon(Icons.info_outline),
                        ),
                        maxLength: 500,
                        keyboardType: TextInputType.text,
                        maxLines: 1,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 16.0),
                        child: DropdownButtonFormField<TaskGroup?>(
                          onTap: () => FocusScope.of(context).unfocus(),
                          value: _selectedTaskGroup,
                          hint: Text(
                            'Belongs to a group',
                          ),
                          isExpanded: true,
                          onChanged: (value) {
                            setState(() {
                              _selectedTaskGroup = value;
                            });
                          },
                          items: predefinedTaskGroups.map((TaskGroup group) {
                            return DropdownMenuItem(
                              value: group,
                              child: group.getTaskGroupRepresentation(useIconColor: true),
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20.0),
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
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _severitySelection[_severityIndex] = false;
                              _severitySelection[index] = true;
                              _severityIndex = index;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: DropdownButtonFormField<AroundDurationHours?>(
                          onTap: () => FocusScope.of(context).unfocus(),
                          value: _selectedDurationHours,
                          hint: Text(
                            'Choose a duration',
                          ),
                          icon: Icon(Icons.timer),
                          isExpanded: true,
                          onChanged: (value) {
                            if (value == AroundDurationHours.CUSTOM) {
                              final initialDuration = _customDuration ?? Duration(minutes: 1);
                              showDurationPickerDialog(
                                      context,
                                      (selectedDuration) => setState(() => _tempSelectedDuration = selectedDuration),
                                      initialDuration)
                                  .then((okPressed) {
                                if (okPressed ?? false) {
                                  setState(() => _customDuration = _tempSelectedDuration ?? initialDuration);
                                }
                              });
                            }
                            setState(() {
                              _selectedDurationHours = value;
                            });
                          },
                          validator: (AroundDurationHours? value) {
                            if (value == null || (value == AroundDurationHours.CUSTOM && _customDuration == null)) {
                              return "Please select a duration";
                            } else {
                              return null;
                            }
                          },
                          items: AroundDurationHours.values.map((AroundDurationHours durationHour) {
                            return DropdownMenuItem(
                              value: durationHour,
                              child: Text(
                                durationHour == AroundDurationHours.CUSTOM && _customDuration != null
                                    ? formatDuration(_customDuration!)
                                    : When.fromDurationHoursToString(durationHour),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 64.0,
                              width: (MediaQuery.of(context).size.width / 2) - 30,
                              child: DropdownButtonFormField<AroundWhenAtDay?>(
                                onTap: () => FocusScope.of(context).unfocus(),
                                value: _selectedWhenAtDay,
                                hint: Text(
                                  'Choose when at',
                                ),
                                icon: Icon(Icons.watch_later_outlined),
                                isExpanded: true,
                                onChanged: (value) {
                                  if (value == AroundWhenAtDay.CUSTOM) {
                                    final initialWhenAt = _customWhenAt ?? TimeOfDay.now();
                                    showTimePicker(
                                      initialTime: initialWhenAt,
                                      context: context,
                                    ).then((selectedTimeOfDay) {
                                      setState(() => _customWhenAt = selectedTimeOfDay ?? initialWhenAt);
                                    });
                                  }
                                  setState(() {
                                    _selectedWhenAtDay = value;
                                  });
                                },
                                validator: (AroundWhenAtDay? value) {
                                  if (value == null || (value == AroundWhenAtDay.CUSTOM && _customWhenAt == null)) {
                                    return "Please select when the event starts";
                                  } else {
                                    return null;
                                  }
                                },
                                items: AroundWhenAtDay.values.map((AroundWhenAtDay whenAtDay) {
                                  return DropdownMenuItem(
                                    value: whenAtDay,
                                    child: Text(
                                      whenAtDay == AroundWhenAtDay.CUSTOM && _customWhenAt != null
                                          ? formatTimeOfDay(_customWhenAt!)
                                          : When.fromWhenAtDayToString(whenAtDay),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            Container(
                              height: 64.0,
                              width: (MediaQuery.of(context).size.width / 2) - 30,
                              child: DropdownButtonFormField<WhenOnDate?>(
                                onTap: () => FocusScope.of(context).unfocus(),
                                value: _selectedWhenOnDate,
                                hint: Text(
                                  'Choose when on',
                                ),
                                icon: Icon(Icons.date_range),
                                isExpanded: true,
                                onChanged: (value) {
                                  if (value == WhenOnDate.CUSTOM) {
                                    final initialWhenOn = _customWhenOn ?? truncToDate(DateTime.now());
                                    showDatePicker(
                                      context: context,
                                      initialDate: initialWhenOn,
                                      firstDate: DateTime.now().subtract(Duration(days: 600)),
                                      lastDate: DateTime.now(),
                                    ).then((selectedDate) => setState(() {
                                          if (isToday(selectedDate)) {
                                            _selectedWhenOnDate = WhenOnDate.TODAY;
                                            _customWhenOn = null;
                                          } else if (isYesterday(selectedDate)) {
                                            _selectedWhenOnDate = WhenOnDate.YESTERDAY;
                                            _customWhenOn = null;
                                          } else if (isBeforeYesterday(selectedDate)) {
                                            _selectedWhenOnDate = WhenOnDate.BEFORE_YESTERDAY;
                                            _customWhenOn = null;
                                          } else {
                                            _customWhenOn = selectedDate ?? initialWhenOn;
                                          }
                                        }));
                                  }
                                  setState(() {
                                    _selectedWhenOnDate = value;
                                  });
                                },
                                validator: (WhenOnDate? value) {
                                  if (value == null || (value == WhenOnDate.CUSTOM && _customWhenOn == null)) {
                                    return "Please select which day the event starts";
                                  } else {
                                    return null;
                                  }
                                },
                                items: WhenOnDate.values.map((WhenOnDate whenOnDate) {
                                  return DropdownMenuItem(
                                    value: whenOnDate,
                                    child: Text(
                                      whenOnDate == WhenOnDate.CUSTOM && _customWhenOn != null
                                          ? formatToDateOrWord(_customWhenOn!)
                                          : When.fromWhenOnDateToString(whenOnDate),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 26.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize:
                                  Size(double.infinity, 40), // double.infinity is the width and 30 is the height
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                final startedAtTimeOfDay =
                                    When.fromWhenAtDayToTimeOfDay(_selectedWhenAtDay!, _customWhenAt);
                                final date = When.fromWhenOnDateToDate(_selectedWhenOnDate!, _customWhenOn);
                                final startedAt = DateTime(date.year, date.month, date.day, startedAtTimeOfDay.hour,
                                    startedAtTimeOfDay.minute);
                                final duration =
                                    When.fromDurationHoursToDuration(_selectedDurationHours!, _customDuration);
                                var taskEvent = TaskEvent(
                                  _taskEvent?.id,
                                  _selectedTaskGroup?.id,
                                  titleController.text,
                                  descriptionController.text,
                                  _taskEvent?.createdAt ?? DateTime.now(),
                                  startedAt,
                                  _selectedWhenAtDay!,
                                  duration,
                                  _selectedDurationHours!,
                                  Severity.values.elementAt(_severityIndex),
                                  _taskEvent?.favorite ?? false,
                                );
                                Navigator.pop(context, taskEvent);
                              }
                            },
                            child: Text('Save'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
