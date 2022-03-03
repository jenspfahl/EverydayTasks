import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/model/When.dart';
import 'package:personaltasklogger/ui/SeverityPicker.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/util/dates.dart';

class TaskEventForm extends StatefulWidget {
  final String formTitle;
  final TaskEvent? taskEvent;
  final TaskGroup? taskGroup;
  final Template? template;
  final String? title;

  TaskEventForm({required this.formTitle, this.taskEvent, 
    this.taskGroup, this.template, this.title});

  @override
  State<StatefulWidget> createState() {
    return _TaskEventFormState(taskEvent, taskGroup, template, title);
  }
}

class _TaskEventFormState extends State<TaskEventForm> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  final TaskEvent? _taskEvent;
  final TaskGroup? _taskGroup;
  final Template? _template;
  final String? _title;

  TaskGroup? _selectedTaskGroup;

  Severity _severity = Severity.MEDIUM;

  AroundDurationHours? _selectedDurationHours;
  Duration? _customDuration;
  Duration? _tempSelectedDuration;

  AroundWhenAtDay? _selectedWhenAtDay;
  TimeOfDay? _customWhenAt;

  WhenOnDate? _selectedWhenOnDate;
  DateTime? _customWhenOn;

  _TaskEventFormState([this._taskEvent, this._taskGroup, this._template, this._title]) {

    int? selectedTaskGroupId;

    AroundDurationHours? aroundDuration;
    Duration? duration;

    AroundWhenAtDay? aroundStartedAt;
    TimeOfDay? startedAt;

    DateTime ? startedOn;

    if (_taskEvent != null) {
      selectedTaskGroupId = _taskEvent!.taskGroupId;

      _severity = _taskEvent!.severity;

      titleController.text = _taskEvent!.title;
      descriptionController.text = _taskEvent!.description ?? "";

      aroundDuration = _taskEvent!.aroundDuration;
      duration = _taskEvent!.duration;

      aroundStartedAt = _taskEvent!.aroundStartedAt;
      startedAt = TimeOfDay.fromDateTime(_taskEvent!.startedAt);

      startedOn = truncToDate(_taskEvent!.startedAt);
    }
    else if (_taskGroup != null) {
      selectedTaskGroupId = _taskGroup?.id;
      aroundStartedAt = AroundWhenAtDay.NOW;
      startedOn = DateTime.now();
    }
    else if (_template != null) {
      selectedTaskGroupId = _template?.taskGroupId;

      if (_template!.severity != null) {
        _severity = _template!.severity!;
      }

      titleController.text = _template!.title;
      descriptionController.text = _template!.description ?? "";

      aroundDuration = _template!.when?.durationHours;
      duration = _template!.when?.durationExactly;

      aroundStartedAt = _template!.when?.startAt ?? AroundWhenAtDay.NOW;
      startedAt = _template!.when?.startAtExactly;

      startedOn = DateTime.now();
    }

    if (_title != null) {
      titleController.text = _title!;
    }


    if (selectedTaskGroupId != null) {
      _selectedTaskGroup = findPredefinedTaskGroupById(selectedTaskGroupId);
    }

    _selectedDurationHours = aroundDuration;
    if (_selectedDurationHours == AroundDurationHours.CUSTOM) {
      _customDuration = duration;
    }

    _selectedWhenAtDay = aroundStartedAt;
    if (startedAt != null &&
        (_selectedWhenAtDay == AroundWhenAtDay.NOW || _selectedWhenAtDay == AroundWhenAtDay.CUSTOM)) {
      _selectedWhenAtDay = AroundWhenAtDay.CUSTOM; // Former NOW is now CUSTOM
      _customWhenAt = startedAt;
    }

    if (startedOn != null) {
      _selectedWhenOnDate = fromDateTimeToWhenOnDate(startedOn);
      if (_selectedWhenOnDate == WhenOnDate.CUSTOM) {
        _customWhenOn = startedOn;
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
          title: Text(widget.formTitle),
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
                          hintText: "Enter a title",
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
                        child: SeverityPicker(_severity, (selected) {
                            setState(() {
                              _severity = selected;
                            });
                          },
                          showText: true,
                          singleButtonWidth: 100,
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
                          }).toList()..sort((d1, d2) {
                            final duration1 = When.fromDurationHoursToDuration(d1.value!, Duration(days: 10000));
                            final duration2 = When.fromDurationHoursToDuration(d2.value!, Duration(days: 10000));
                            return duration1.compareTo(duration2);
                          }),
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
                                    return "Please select when the task starts";
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
                                    return "Please select which day the task starts";
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
                                  _template?.tId,
                                  titleController.text,
                                  descriptionController.text,
                                  _taskEvent?.createdAt ?? DateTime.now(),
                                  startedAt,
                                  _selectedWhenAtDay!,
                                  duration,
                                  _selectedDurationHours!,
                                  _severity,
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
