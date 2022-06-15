import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/TaskEventRepository.dart';
import 'package:personaltasklogger/db/repository/TemplateRepository.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/model/TemplateId.dart';
import 'package:personaltasklogger/model/When.dart';
import 'package:personaltasklogger/service/LocalNotificationService.dart';
import 'package:personaltasklogger/service/PreferenceService.dart';
import 'package:personaltasklogger/ui/SeverityPicker.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/pages/TaskEventList.dart';
import 'package:personaltasklogger/ui/utils.dart';
import 'package:personaltasklogger/util/dates.dart';

import '../ToggleActionIcon.dart';

final trackIconKey = new GlobalKey<ToggleActionIconState>();
final TRACKING_NOTIFICATION_ID = -12345678;
String getPrefKeyFromTrackingId() => "payload_of_notification:$TRACKING_NOTIFICATION_ID";

class TaskEventForm extends StatefulWidget {
  final String formTitle;
  final TaskEvent? taskEvent;
  final TaskGroup? taskGroup;
  final Template? template;
  final String? title;
  final Map<String, dynamic>? stateAsJson;

  TaskEventForm({required this.formTitle, this.taskEvent, 
    this.taskGroup, this.template, this.title, this.stateAsJson});

  @override
  State<StatefulWidget> createState() {
    return _TaskEventFormState(taskEvent, taskGroup, template, title);
  }
}

class _TaskEventFormState extends State<TaskEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final String? _title;

  TaskEvent? _taskEvent;
  TaskGroup? _taskGroup;
  Template? _template;

  TaskGroup? _selectedTaskGroup;

  Severity _severity = Severity.MEDIUM;

  AroundDurationHours? _selectedDurationHours;
  Duration? _customDuration;
  Duration? _tempSelectedDuration;

  AroundWhenAtDay? _selectedWhenAtDay;
  TimeOfDay? _customWhenAt;

  WhenOnDate? _selectedWhenOnDate;
  DateTime? _customWhenOn;

  DateTime? _trackingStart;

  Timer? _timer;
  final _notificationService = LocalNotificationService();
  final _preferenceService = PreferenceService();

  _TaskEventFormState([this._taskEvent, this._taskGroup, this._template, this._title]);

  @override
  initState() {
    int? selectedTaskGroupId;

    AroundDurationHours? aroundDuration;
    Duration? duration;

    AroundWhenAtDay? aroundStartedAt;
    TimeOfDay? startedAt;

    DateTime ? startedOn;

    if (_taskEvent != null) {
      selectedTaskGroupId = _taskEvent!.taskGroupId;

      _severity = _taskEvent!.severity;

      _titleController.text = _taskEvent!.translatedTitle;
      _descriptionController.text = _taskEvent!.translatedDescription ?? "";

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

      _titleController.text = _template!.translatedTitle;
      _descriptionController.text = _template!.translatedDescription ?? "";

      aroundDuration = _template!.when?.durationHours;
      duration = _template!.when?.durationExactly;

      aroundStartedAt = _template!.when?.startAt ?? AroundWhenAtDay.NOW;
      startedAt = _template!.when?.startAtExactly;

      startedOn = DateTime.now();
    }

    if (_title != null) {
      _titleController.text = _title!;
    }

    if (selectedTaskGroupId != null) {
      _selectedTaskGroup = findPredefinedTaskGroupById(selectedTaskGroupId);
    }

    _selectedDurationHours = aroundDuration;
    if (_selectedDurationHours == AroundDurationHours.CUSTOM) {
      _customDuration = duration;
    }

    _selectedWhenAtDay = aroundStartedAt;
    if (startedAt != null && _selectedWhenAtDay == AroundWhenAtDay.CUSTOM) {
      _selectedWhenAtDay = AroundWhenAtDay.CUSTOM; // Former NOW is now CUSTOM
      _customWhenAt = startedAt;
    }

    if (startedOn != null) {
      _selectedWhenOnDate = fromDateTimeToWhenOnDate(startedOn);
      if (_selectedWhenOnDate == WhenOnDate.CUSTOM) {
        _customWhenOn = startedOn;
      }
    }

    if (widget.stateAsJson != null) {
      _setStateFromJson(widget.stateAsJson!);
      _startTracking(trackingStart: _trackingStart);
    }

  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackIcon = ToggleActionIcon(Icons.stop_circle_outlined, Icons.not_started_outlined, _trackingStart != null, trackIconKey);

    return WillPopScope(
      onWillPop: () async {
        if (_trackingStart != null) {
          toastError(context, "Please stop tracking first!");
          return false;
        }
        return true;
      },
      child: GestureDetector(
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
                          controller: _titleController,
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
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            hintText: "An optional description",
                            icon: Icon(Icons.info_outline),
                          ),
                          maxLength: 500,
                          keyboardType: TextInputType.text,
                          maxLines: 1,
                        ),
                        DropdownButtonFormField<TaskGroup?>(
                          onTap: () => FocusScope.of(context).unfocus(),
                          value: _selectedTaskGroup,
                          icon: const Icon(Icons.category_outlined),
                          hint: Text(
                            'Belongs to a category',
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
                          validator: (TaskGroup? value) {
                            if (value == null) {
                              return "Please select a category";
                            } else {
                              return null;
                            }
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 20.0),
                          child: SeverityPicker(
                            showText: true,
                            singleButtonWidth: 100,
                            initialSeverity: _severity,
                            onChanged: (severity) =>_severity = severity,
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
                            icon: Icon(Icons.timer_outlined),
                            iconDisabledColor: _trackingStart != null ? Colors.redAccent : null,
                            isExpanded: true,
                            onChanged:  _trackingStart != null ? null : (value) {
                              if (value == AroundDurationHours.CUSTOM) {
                                final initialDuration = _customDuration ?? Duration(minutes: 1);
                                showDurationPickerDialog(
                                  context: context,
                                  initialDuration: initialDuration,
                                  onChanged: (duration) => _tempSelectedDuration = duration,
                                ).then((okPressed) {
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
                                      ? _formatDuration()
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
                                  iconDisabledColor: _trackingStart != null ? Colors.redAccent : null,
                                  isExpanded: true,
                                  onChanged:  _trackingStart != null ? null : (value) {
                                    if (value == AroundWhenAtDay.CUSTOM) {
                                      final initialWhenAt = _customWhenAt ?? (_selectedWhenAtDay != null ? When.fromWhenAtDayToTimeOfDay(_selectedWhenAtDay!, _customWhenAt) : TimeOfDay.now());
                                      showTimePicker(
                                        initialTime: initialWhenAt,
                                        context: context,
                                      ).then((selectedTimeOfDay) {
                                        if (selectedTimeOfDay != null) {
                                          setState(() => _customWhenAt = selectedTimeOfDay);
                                        }
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
                                  iconDisabledColor: _trackingStart != null ? Colors.redAccent : null,
                                  isExpanded: true,
                                  onChanged: _trackingStart != null ? null : (value) {
                                    if (value == WhenOnDate.CUSTOM) {
                                      final initialWhenOn = _customWhenOn ?? truncToDate(DateTime.now());
                                      showDatePicker(
                                        context: context,
                                        initialDate: initialWhenOn,
                                        firstDate: DateTime.now().subtract(Duration(days: 600)),
                                        lastDate: DateTime.now(),
                                      ).then((selectedDate) {
                                        if (selectedDate != null) {
                                          setState(() {
                                            if (isToday(selectedDate)) {
                                              _selectedWhenOnDate = WhenOnDate.TODAY;
                                              _customWhenOn = null;
                                            } else
                                            if (isYesterday(selectedDate)) {
                                              _selectedWhenOnDate = WhenOnDate.YESTERDAY;
                                              _customWhenOn = null;
                                            } else
                                            if (isBeforeYesterday(selectedDate)) {
                                              _selectedWhenOnDate = WhenOnDate.BEFORE_YESTERDAY;
                                              _customWhenOn = null;
                                            } else {
                                              _customWhenOn = selectedDate;
                                            }
                                          });
                                        }
                                      });
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
                                            ? formatToDateOrWord(_customWhenOn!, context)
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
                          child: Column(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: FloatingActionButton(
                                  child: trackIcon,
                                  backgroundColor: _trackingStart != null ? Colors.redAccent : null,
                                  onPressed: () {
                                    setState(() {
                                      if (_trackingStart == null) {
                                        if (_customDuration != null || _customWhenAt != null || _customWhenOn != null) {
                                          showConfirmationDialog(
                                              context,
                                              "Start tracking",
                                              "There are some values which will be overwritten when starting the tracking. Continue?",
                                              icon: const Icon(Icons.warning_amber_outlined),
                                              okPressed: () {
                                                setState(() {
                                                  _startTracking();
                                                  _showPermanentNotification();
                                                  trackIconKey.currentState?.refresh(true);
                                                });

                                                Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow
                                              },
                                              cancelPressed: () {
                                                Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow
                                              },
                                          );
                                        }
                                        else {
                                          setState(() {
                                            _startTracking();
                                            _showPermanentNotification();
                                            trackIconKey.currentState?.refresh(true);
                                          });
                                        }
                                      }
                                      else {
                                        _stopTracking();
                                        trackIconKey.currentState?.refresh(false);
                                      }
                                    });
                                  }),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize:
                                Size(double.infinity, 40), // double.infinity is the width and 30 is the height
                              ),
                              onPressed: () {
                                if (_trackingStart != null) {
                                  toastError(context, "Please stop tracking first!");
                                  return;
                                }
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
                                    _template?.tId ?? _taskEvent?.originTemplateId,
                                    _titleController.text,
                                    _descriptionController.text,
                                    _taskEvent?.createdAt ?? DateTime.now(),
                                    startedAt,
                                    _selectedWhenAtDay == AroundWhenAtDay.NOW ? AroundWhenAtDay.CUSTOM : _selectedWhenAtDay!,
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
                          ],),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration() {
    if (_trackingStart != null && _timer != null) {
      final clock = ['|','/', '--', '\\', ];
      final ticker = _timer!.tick % clock.length;
      final exact = formatTrackingDuration(_customDuration!);
      final step = clock[ticker];
      return "$step   $exact   $step";
    }
    else {
      return formatDuration(_customDuration!);
    }
  }

  void _startTracking({DateTime? trackingStart}) {

    _trackingStart = trackingStart ?? DateTime.now();

    _selectedWhenAtDay = AroundWhenAtDay.CUSTOM;
    _customWhenAt = TimeOfDay.fromDateTime(_trackingStart!);

    _selectedWhenOnDate = WhenOnDate.CUSTOM;
    _customWhenOn = truncToDate(_trackingStart!);

    _updateTracking();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _updateTracking();
      });
    });

  }

  void _showPermanentNotification() {
    final currentTitle = _titleController.text;

    final stateAsJson = jsonEncode(this);
    final payload = "onlyWhenAppLaunch:true-TaskEventForm-$stateAsJson";
    
    _notificationService.showNotification(
        TASK_EVENT_LIST_ROUTING_KEY, //we route to task events and there it will be rerouted to here
        TRACKING_NOTIFICATION_ID,
        "Tracking started",
        currentTitle.isNotEmpty
            ? "'$currentTitle' started at ${formatToTime(_trackingStart!)}"
            : "Tracking started at ${formatToTime(_trackingStart!)}",
        CHANNEL_ID_TRACKING,
        true,
        payload);

    _preferenceService.setString(getPrefKeyFromTrackingId(), payload);
  }

  @override
  void deactivate() {
    _timer?.cancel();
    if (_trackingStart != null) {
      _notificationService.cancelNotification(TRACKING_NOTIFICATION_ID);
      _preferenceService.remove(getPrefKeyFromTrackingId());
    }
    super.deactivate();
  }


  void _updateTracking() {
    _selectedDurationHours = AroundDurationHours.CUSTOM;
    final now = DateTime.now();
    _customDuration = now.difference(_trackingStart!);
  }


  void _stopTracking() {
    if (_trackingStart != null) {
      _notificationService.cancelNotification(TRACKING_NOTIFICATION_ID);
      _preferenceService.remove(getPrefKeyFromTrackingId());
    }
    _trackingStart = null;
    _timer?.cancel();
  }

  Map<String, dynamic> toJson() => {
    'trackingStart' : _trackingStart?.millisecondsSinceEpoch,
    'title': _titleController.text,
    'description': _descriptionController.text,
    'severity': _severity.index,
    'taskGroupId': _selectedTaskGroup?.id ?? _template?.taskGroupId,
    'templateId': _template?.tId?.id,
    'isVariant': _template?.isVariant(),
    'taskEventId' : _taskEvent?.id,
  };

  void _setStateFromJson(Map<String, dynamic> jsonMap) {
    _trackingStart = DateTime.fromMillisecondsSinceEpoch(jsonMap['trackingStart']);
    _titleController.text = jsonMap['title'];
    _descriptionController.text = jsonMap['description'];
    _severity = Severity.values.elementAt(jsonMap['severity']);

    int? taskGroupId = jsonMap['taskGroupId'];
    if (taskGroupId != null) {
      _selectedTaskGroup = findPredefinedTaskGroupById(taskGroupId);
    }

    int? templateId = jsonMap['templateId'];
    bool? isVariant = jsonMap['isVariant'];
    if (templateId != null && isVariant != null) {
      TemplateRepository.findById(TemplateId(templateId, isVariant))
          .then((foundTemplate) {
            _template = foundTemplate;
      });
    }

    int? taskEventId = jsonMap['taskEventId'];
    if (taskEventId != null) {
      TaskEventRepository.getById(taskEventId)
          .then((foundTaskEvent) {
            _taskEvent = foundTaskEvent;
      });
    }
  }

}
