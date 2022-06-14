import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:personaltasklogger/model/Schedule.dart';
import 'package:personaltasklogger/model/ScheduledTask.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/model/When.dart';
import 'package:personaltasklogger/ui/RepetitionPicker.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/util/dates.dart';

class ScheduledTaskForm extends StatefulWidget {
  final String formTitle;
  final ScheduledTask? scheduledTask;
  final TaskGroup taskGroup;
  final Template? template;

  ScheduledTaskForm({
    required this.formTitle, 
    this.scheduledTask, 
    required this.taskGroup, 
    this.template
  });

  @override
  State<StatefulWidget> createState() {
    return _ScheduledTaskFormState(scheduledTask, taskGroup, template);
  }
}

class _ScheduledTaskFormState extends State<ScheduledTaskForm> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  final ScheduledTask? _scheduledTask;
  final TaskGroup _taskGroup;
  final Template? _template;

  RepetitionStep? _selectedRepetitionStep;
  CustomRepetition? _customRepetition;

  AroundWhenAtDay? _selectedStartAt;
  TimeOfDay? _customStartAt;

  WhenOnDate? _selectedScheduleFrom;
  DateTime? _customScheduleFrom;

  late bool _isActive;
  RepetitionMode _repetitionMode = RepetitionMode.DYNAMIC;


  _ScheduledTaskFormState(this._scheduledTask, this._taskGroup, this._template);

  @override
  void initState() {
    super.initState();

    if (_scheduledTask != null) {
      titleController.text = _scheduledTask!.translatedTitle;
      descriptionController.text = _scheduledTask!.translatedDescription ?? "";

      _selectedRepetitionStep = _scheduledTask!.schedule.repetitionStep;
      _customRepetition = _scheduledTask!.schedule.customRepetition;

      _selectedStartAt = _scheduledTask!.schedule.aroundStartAt;
      _customStartAt = _scheduledTask!.schedule.startAtExactly;

      if (_scheduledTask?.lastScheduledEventOn != null) {
        _selectedScheduleFrom = fromDateTimeToWhenOnDate(_scheduledTask!.lastScheduledEventOn!);
        debugPrint("_selectedScheduleFrom=$_selectedScheduleFrom");
      }
      debugPrint("_customScheduleFrom=$_customScheduleFrom");
      _customScheduleFrom = _scheduledTask!.lastScheduledEventOn;

      _isActive = _scheduledTask!.active;
      _repetitionMode = _scheduledTask!.schedule.repetitionMode;
    }
    else if (_template != null) {
      titleController.text = _template!.translatedTitle;
      descriptionController.text = _template?.translatedDescription ?? "";

      _selectedStartAt = _template?.when?.startAt;
      _customStartAt = _template?.when?.startAtExactly;
      _isActive = true;
    }
    else {
      // is taskGroup
      titleController.text = "";
      descriptionController.text = "";

      _isActive = true;
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
                          icon: _taskGroup.getIcon(true),
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
                        padding: EdgeInsets.only(top: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 64.0,
                              width: (MediaQuery.of(context).size.width / 2) - 25,
                              child: DropdownButtonFormField<RepetitionStep?>(
                                onTap: () => FocusScope.of(context).unfocus(),
                                value: _selectedRepetitionStep,
                                hint: Text(
                                  'Repetition steps',
                                ),
                                isExpanded: true,
                                icon: Icon(Icons.next_plan_outlined),
                                onChanged: (value) {
                                  if (value == RepetitionStep.CUSTOM) {
                                    var tempSelectedRepetition = _customRepetition ?? RepetitionPicker.DEFAULT_INIT_REPETITION;
                                    showRepetitionPickerDialog(
                                      context: context,
                                      initialRepetition: _customRepetition,
                                      onChanged: (repetition) => tempSelectedRepetition = repetition,
                                    ).then((okPressed) {
                                      if (okPressed ?? false) {
                                        setState(() {
                                          _selectedRepetitionStep = RepetitionStep.CUSTOM;
                                          _customRepetition = tempSelectedRepetition;
                                        });
                                      }
                                    });
                                  }
                                  else {
                                    setState(() {
                                      _selectedRepetitionStep = value;
                                      _customRepetition = null;
                                    });
                                  }
                                },
                                items: RepetitionStep.values.map((RepetitionStep repetitionStep) {
                                  return DropdownMenuItem(
                                    value: repetitionStep,
                                    child: Text(repetitionStep != RepetitionStep.CUSTOM 
                                        ? Schedule.fromRepetitionStepToString(repetitionStep)
                                        : Schedule.fromCustomRepetitionToString(_customRepetition))
                                  );
                                }).toList(),
                                validator: (RepetitionStep? value) {
                                  if (value == null || (value == RepetitionStep.CUSTOM && _customRepetition == null)) {
                                    return "Please select a repetition";
                                  } else {
                                    return null;
                                  }
                                },
                              ),
                            ),
                            Container(
                              height: 64.0,
                              width: (MediaQuery.of(context).size.width / 2) - 25,
                              child: DropdownButtonFormField<AroundWhenAtDay?>(
                                onTap: () => FocusScope.of(context).unfocus(),
                                value: _selectedStartAt,
                                hint: Text(
                                  'Scheduled at',
                                ),
                                icon: Icon(Icons.watch_later_outlined),
                                isExpanded: true,
                                onChanged: (value) {
                                  if (value == AroundWhenAtDay.CUSTOM) {
                                    final initialWhenAt = _customStartAt ?? TimeOfDay.now();
                                    showTimePicker(
                                      initialTime: initialWhenAt,
                                      context: context,
                                    ).then((selectedTimeOfDay) {
                                      if (selectedTimeOfDay != null) {
                                        setState(() =>
                                        _customStartAt = selectedTimeOfDay);
                                      }
                                    });
                                  }
                                  setState(() {
                                    _selectedStartAt = value;
                                  });
                                },
                                validator: (AroundWhenAtDay? value) {
                                  if (value == null || (value == AroundWhenAtDay.CUSTOM && _customStartAt == null)) {
                                    return "Please select when the schedule starts";
                                  } else {
                                    return null;
                                  }
                                },
                                items: AroundWhenAtDay.values.map((AroundWhenAtDay whenAtDay) {
                                  return DropdownMenuItem(
                                    value: whenAtDay,
                                    child: Text(
                                      whenAtDay == AroundWhenAtDay.CUSTOM && _customStartAt != null
                                          ? formatTimeOfDay(_customStartAt!)
                                          : When.fromWhenAtDayToString(whenAtDay),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 64.0,
                              width: (MediaQuery.of(context).size.width / 2) - 25,
                              child: CheckboxListTile(
                                title: Text("Activate schedule"),
                                value: _isActive,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value != null) _isActive = value;
                                  });
                                },
                              )
                            ),
                            Container(
                              height: 64.0,
                              width: (MediaQuery.of(context).size.width / 2) - 25,
                              child: DropdownButtonFormField<WhenOnDate?>(
                                onTap: () => FocusScope.of(context).unfocus(),
                                value: _selectedScheduleFrom,
                                hint: Text(
                                  'Scheduled from',
                                ),
                                icon: Icon(MdiIcons.arrowExpandRight),
                                isExpanded: true,
                                onChanged: (value) {
                                  if (value == WhenOnDate.CUSTOM) {
                                    final initialScheduleFrom = _customScheduleFrom ?? truncToDate(DateTime.now());
                                    showDatePicker(
                                      context: context,
                                      initialDate: initialScheduleFrom,
                                      firstDate: DateTime.now().subtract(Duration(days: 600)),
                                      lastDate: DateTime.now().add(Duration(days: 600)),
                                    ).then((selectedDate) {
                                      if (selectedDate != null) {
                                        setState(() {
                                          if (isToday(selectedDate)) {
                                            _selectedScheduleFrom =
                                                WhenOnDate.TODAY;
                                            _customScheduleFrom = null;
                                          } else
                                          if (isYesterday(selectedDate)) {
                                            _selectedScheduleFrom =
                                                WhenOnDate.YESTERDAY;
                                            _customScheduleFrom = null;
                                          } else
                                          if (isBeforeYesterday(selectedDate)) {
                                            _selectedScheduleFrom =
                                                WhenOnDate.BEFORE_YESTERDAY;
                                            _customScheduleFrom = null;
                                          } else {
                                            _customScheduleFrom = selectedDate;
                                          }
                                        });
                                      }
                                    });
                                  }
                                  setState(() {
                                    _selectedScheduleFrom = value;
                                  });
                                },
                                validator: (WhenOnDate? value) {
                                  if (value == null || (value == WhenOnDate.CUSTOM && _customScheduleFrom == null)) {
                                    return "Please select which day the schedule starts";
                                  } else {
                                    return null;
                                  }
                                },
                                items: WhenOnDate.values.map((WhenOnDate whenOnDate) {
                                  return DropdownMenuItem(
                                    value: whenOnDate,
                                    child: Text(
                                     whenOnDate == WhenOnDate.CUSTOM && _customScheduleFrom != null && _isNotAWord(_customScheduleFrom!)
                                          ? formatToDateOrWord(_customScheduleFrom!, context)
                                          : When.fromWhenOnDateToString(whenOnDate),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text("Dynamic repetition behavior: ${_repetitionMode == RepetitionMode.DYNAMIC ? "On" : "Off"}"),
                          subtitle: Text(_repetitionMode == RepetitionMode.DYNAMIC
                              ? "Next schedule is due based on the repetition steps and when the current one is done."
                              : "Next schedule is due based on the exact repetition steps."),
                          value: _repetitionMode == RepetitionMode.DYNAMIC,
                          onChanged: (bool value) {
                            setState(() {
                              _repetitionMode = _repetitionMode == RepetitionMode.DYNAMIC
                                  ? RepetitionMode.FIXED
                                  : RepetitionMode.DYNAMIC;
                            });
                          },)
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

                                var scheduleFrom = When.fromWhenOnDateToDate(_selectedScheduleFrom!, _customScheduleFrom);
                                if (_selectedStartAt == AroundWhenAtDay.NOW) {
                                  _selectedStartAt = AroundWhenAtDay.CUSTOM;
                                  _customStartAt = TimeOfDay.now();
                                }
                                var schedule = Schedule(
                                  aroundStartAt: _selectedStartAt!,
                                  startAtExactly: _customStartAt,
                                  repetitionStep: _selectedRepetitionStep!,
                                  customRepetition: _customRepetition,
                                  repetitionMode: _repetitionMode,
                                );
                                var scheduledTask = ScheduledTask(
                                  id: _scheduledTask?.id,
                                  taskGroupId: _taskGroup.id!,
                                  templateId: _scheduledTask?.templateId ?? _template?.tId,
                                  title: titleController.text,
                                  description: descriptionController.text,
                                  createdAt: _scheduledTask?.createdAt ?? DateTime.now(),
                                  schedule: schedule,
                                  lastScheduledEventOn: scheduleFrom,
                                  active: _isActive,
                                );
                                Navigator.pop(context, scheduledTask);
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

  bool _isNotAWord(DateTime dateTime) {
    final whenOn = fromDateTimeToWhenOnDate(dateTime);
    return whenOn == WhenOnDate.CUSTOM;
  }
}
