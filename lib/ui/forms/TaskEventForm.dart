import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
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

import '../../db/repository/TaskGroupRepository.dart';
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
  final String? description;
  final Map<String, dynamic>? stateAsJson;

  TaskEventForm({required this.formTitle, this.taskEvent, 
    this.taskGroup, this.template, this.title, this.description, this.stateAsJson});

  @override
  State<StatefulWidget> createState() {
    return _TaskEventFormState(taskEvent, taskGroup, template, title, description);
  }
}

class _TaskEventFormState extends State<TaskEventForm> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final String? _title;
  final String? _description;

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

  WhenOnDatePast? _selectedWhenOnDate;
  DateTime? _customWhenOn;

  DateTime? _trackingStart;
  DateTime? _trackingPaused;
  Duration? _trackingPauses;

  Timer? _timer;
  final _notificationService = LocalNotificationService();
  final _preferenceService = PreferenceService();

  _TaskEventFormState([this._taskEvent, this._taskGroup, this._template, this._title, this._description]);

  @override
  initState() {
    super.initState();
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
    if (_description != null) {
      _descriptionController.text = _description!;
    }

    if (selectedTaskGroupId != null) {
      if (_isTaskGroupDeleted(selectedTaskGroupId)) {
        _selectedTaskGroup = null;
      }
      else {
        _selectedTaskGroup =
            TaskGroupRepository.findByIdFromCache(selectedTaskGroupId);
      }
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
      _selectedWhenOnDate = fromDateTimeToWhenOnDatePast(startedOn);
      if (_selectedWhenOnDate == WhenOnDatePast.CUSTOM) {
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
    final trackIcon = ToggleActionIcon(Icons.pause_circle_outline, Icons.not_started_outlined, _isTrackingRunning(), trackIconKey);

    return WillPopScope(
      onWillPop: () async {
        if (_isTrackingRunning()) {
          toastError(context, translate('forms.task_event.tracking.stop_tracking_first'));
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
                            hintText: translate('forms.task_event.title_hint'),
                            icon: Icon(Icons.event_available),
                          ),
                          maxLength: 50,
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translate('forms.common.title_emphasis');
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            hintText: translate('forms.common.description_hint'),
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
                          hint: Text(translate('forms.task_event.category_hint')),
                          isExpanded: true,
                          onChanged: (value) {
                            setState(() {
                              _selectedTaskGroup = value;
                            });
                          },
                          items: TaskGroupRepository.getAllCached(inclHidden: false).map((TaskGroup group) {
                            return DropdownMenuItem(
                              value: group,
                              child: group.getTaskGroupRepresentation(useIconColor: true),
                            );
                          }).toList(),
                          validator: (TaskGroup? value) {
                            if (value == null) {
                              return translate('forms.task_event.category_emphasis');
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
                            hint: Text(translate('forms.task_event.duration_hint')),
                            icon: Icon(Icons.timer_outlined),
                            iconDisabledColor: _isTrackingRunning() ? Colors.redAccent : null,
                            isExpanded: true,
                            onChanged:  _isTrackingRunning() ? null : (value) {
                              _resetTracking();
                              if (value == AroundDurationHours.CUSTOM) {
                                final initialDuration = _customDuration ?? (_selectedDurationHours != null ? When.fromDurationHoursToDuration(_selectedDurationHours!, _customDuration) : Duration(minutes: 1));
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
                                return translate('forms.task_event.duration_emphasis');
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
                                  hint: Text(translate('forms.task_event.when_at_hint')),
                                  icon: Icon(Icons.watch_later_outlined),
                                  iconDisabledColor: _isTrackingRunning() ? Colors.redAccent : null,
                                  isExpanded: true,
                                  onChanged:  _isTrackingRunning() ? null : (value) {
                                    if (value == AroundWhenAtDay.CUSTOM) {
                                      final initialWhenAt = _customWhenAt ?? (
                                          _selectedWhenAtDay != null && _selectedWhenAtDay != AroundWhenAtDay.CUSTOM
                                              ? When.fromWhenAtDayToTimeOfDay(_selectedWhenAtDay!, _customWhenAt)
                                              : TimeOfDay.now());
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
                                      return translate('forms.task_event.when_at_emphasis');
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
                                child: DropdownButtonFormField<WhenOnDatePast?>(
                                  onTap: () => FocusScope.of(context).unfocus(),
                                  value: _selectedWhenOnDate,
                                  hint: Text(translate('forms.task_event.when_on_hint')),
                                  icon: Icon(Icons.date_range),
                                  iconDisabledColor: _isTrackingRunning() ? Colors.redAccent : null,
                                  isExpanded: true,
                                  onChanged: _isTrackingRunning() ? null : (value) {
                                    if (value == WhenOnDatePast.CUSTOM) {
                                      final initialWhenOn = _customWhenOn ?? truncToDate(DateTime.now());
                                      showTweakedDatePicker(context,
                                        initialDate: initialWhenOn,
                                      ).then((selectedDate) {
                                        if (selectedDate != null) {
                                          setState(() {
                                            if (isToday(selectedDate)) {
                                              _selectedWhenOnDate = WhenOnDatePast.TODAY;
                                              _customWhenOn = null;
                                            } else
                                            if (isYesterday(selectedDate)) {
                                              _selectedWhenOnDate = WhenOnDatePast.YESTERDAY;
                                              _customWhenOn = null;
                                            } else
                                            if (isBeforeYesterday(selectedDate)) {
                                              _selectedWhenOnDate = WhenOnDatePast.BEFORE_YESTERDAY;
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
                                  validator: (WhenOnDatePast? value) {
                                    if (value == null || (value == WhenOnDatePast.CUSTOM && _customWhenOn == null)) {
                                      return translate('forms.task_event.when_on_emphasis');
                                    } else {
                                      return null;
                                    }
                                  },
                                  items: WhenOnDatePast.values.map((WhenOnDatePast whenOnDate) {
                                    return DropdownMenuItem(
                                      value: whenOnDate,
                                      child: Text(
                                        whenOnDate == WhenOnDatePast.CUSTOM && _customWhenOn != null
                                            ? formatToDateOrWord(_customWhenOn!, context)
                                            : When.fromWhenOnDatePastToString(whenOnDate),
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
                              child: GestureDetector(
                                onLongPress: () {
                                  if (_isTrackingRunning() || _isTrackingPaused()) {
                                    setState(() {
                                      _stopTracking(stop: true);
                                      trackIconKey.currentState?.refresh(false);
                                      toastInfo(context, translate('forms.task_event.tracking.tracking_stopped'));
                                    });
                                  }
                                },
                                child: FloatingActionButton(
                                    child: trackIcon,
                                    backgroundColor: _isTrackingRunning() ? Colors.redAccent : null,
                                    onPressed: () {
                                      setState(() {
                                        if (_isTrackingPaused() || _isTrackingStopped()) {
                                          if ((_customDuration != null || _customWhenAt != null || _customWhenOn != null)
                                                && _isTrackingStopped()) {
                                            showConfirmationDialog(
                                                context,
                                                translate('forms.task_event.tracking.start_tracking_title'),
                                                translate('forms.task_event.tracking.start_tracking_message'),
                                                icon: const Icon(Icons.warning_amber_outlined),
                                                okPressed: () {
                                                  setState(() {
                                                    final isResume = _isTrackingPaused();
                                                    _startTracking();
                                                    _showPermanentNotification(isResume);
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
                                              final isResume = _isTrackingPaused();
                                              _startTracking();
                                              _showPermanentNotification(isResume);
                                              trackIconKey.currentState?.refresh(true);
                                            });
                                          }
                                        }
                                        else if (_isTrackingRunning()) {
                                          _stopTracking(stop: false);
                                          trackIconKey.currentState?.refresh(false);
                                        }
                                      });
                                    }),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize:
                                Size(double.infinity, 40), // double.infinity is the width and 30 is the height
                              ),
                              onPressed: () {
                                if (_isTrackingRunning()) {
                                  toastError(context, translate('forms.task_event.tracking.stop_tracking_first'));
                                  return;
                                }
                                if (_formKey.currentState!.validate()) {

                                  final duration = When.fromDurationHoursToDuration(_selectedDurationHours!, _customDuration);

                                  final startedAtTimeOfDay =
                                    When.fromWhenAtDayToTimeOfDay(_selectedWhenAtDay!, _customWhenAt);
                                  final date = When.fromWhenOnDatePastToDate(_selectedWhenOnDate!, _customWhenOn);
                                  var startedAt = DateTime(date.year, date.month, date.day, startedAtTimeOfDay.hour,
                                      startedAtTimeOfDay.minute, _trackingStart?.second ?? 0);
                                  if (_selectedWhenAtDay == AroundWhenAtDay.NOW && _trackingStart == null) {
                                    startedAt = startedAt.subtract(duration);
                                  }

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
                                    _isTrackingPaused() ? _trackingPaused : null,
                                    _severity,
                                    _taskEvent?.favorite ?? false,
                                  );
                                  Navigator.pop(context, taskEvent);
                                }
                              },
                              child: Text(translate('forms.common.button_save')),
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
    if ((_isTrackingRunning() || _isTrackingPaused()) && _timer != null) {
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

  void _showPermanentNotification(bool isResume) {
    final currentTitle = _titleController.text;

    final stateAsJson = jsonEncode(this);
    final payload = "onlyWhenAppLaunch:true-TaskEventForm-$stateAsJson";
    
    _notificationService.showNotification(
        TASK_EVENT_LIST_ROUTING_KEY, //we route to task events and there it will be rerouted to here
        TRACKING_NOTIFICATION_ID,
        isResume
            ? translate('forms.task_event.tracking.tracking_resumed')
            : translate('forms.task_event.tracking.tracking_started'),
        currentTitle.isNotEmpty
            ? translate('forms.task_event.tracking.task_started_at',
                args: {"title": currentTitle ,"when": formatToTime(_trackingStart!)})
            : translate('forms.task_event.tracking.tracking_started_at',
                args: {"when": formatToTime(_trackingStart!)}),
        CHANNEL_ID_TRACKING,
        true,
        payload);

    _preferenceService.setString(getPrefKeyFromTrackingId(), payload);
  }

  @override
  void deactivate() {
    _timer?.cancel();
    if (_isTrackingRunning()) {
      _notificationService.cancelNotification(TRACKING_NOTIFICATION_ID);
      _preferenceService.remove(getPrefKeyFromTrackingId());
    }
    super.deactivate();
  }

  bool _isTrackingStopped() => _trackingStart == null && _trackingPaused == null;
  bool _isTrackingRunning() => _trackingStart != null && _trackingPaused == null;
  bool _isTrackingPaused() => _trackingStart != null && _trackingPaused != null;

  void _startTracking({DateTime? trackingStart}) {

    if (trackingStart != null || _isTrackingStopped()) {
      _trackingStart = trackingStart ?? DateTime.now();
    }
    else if (_isTrackingPaused()) {
      // resume pause
      final pauseDuration = _trackingPaused?.difference(DateTime.now()).abs();
      final totalPauseSeconds = (_trackingPauses?.inSeconds??0) + (pauseDuration?.inSeconds??0);
      _trackingPauses = Duration(seconds: totalPauseSeconds);

      _trackingPaused = null;
    }

    _selectedWhenAtDay = AroundWhenAtDay.CUSTOM;
    _customWhenAt = TimeOfDay.fromDateTime(_trackingStart!);

    _selectedWhenOnDate = WhenOnDatePast.CUSTOM;
    _customWhenOn = truncToDate(_trackingStart!);

    _updateTracking();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _updateTracking();
      });
    });

  }

  void _updateTracking() {
    _selectedDurationHours = AroundDurationHours.CUSTOM;
    final now = DateTime.now();
    final runningSeconds = now.difference(_trackingStart!).inSeconds + 1;
    final pauseSeconds = _trackingPauses?.inSeconds ?? 0;
    _customDuration = Duration(seconds: runningSeconds - pauseSeconds);
  }


  void _stopTracking({required bool stop}) {
    _notificationService.cancelNotification(TRACKING_NOTIFICATION_ID);
    _preferenceService.remove(getPrefKeyFromTrackingId());
    _timer?.cancel();
    if (stop) {
      _resetTracking();
    }
    else {
      _trackingPaused = DateTime.now();
    }
  }

  void _resetTracking() {
    _trackingStart = null;
    _trackingPauses = null;
    _trackingPaused = null;
  }

  Map<String, dynamic> toJson() => {
    'trackingStart' : _trackingStart?.millisecondsSinceEpoch,
    'trackingPaused' : _trackingPaused?.millisecondsSinceEpoch,
    'trackingPauses' : _trackingPauses?.inSeconds,
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

    final trackingPausedJson = jsonMap['trackingPaused'];
    if (trackingPausedJson != null) {
      _trackingPaused = DateTime.fromMillisecondsSinceEpoch(trackingPausedJson);
    }

    final trackingPausesJson = jsonMap['trackingPauses'];
    if (trackingPausesJson != null) {
      _trackingPauses = Duration(seconds: trackingPausesJson);
    }

    _titleController.text = jsonMap['title'];
    _descriptionController.text = jsonMap['description'];
    _severity = Severity.values.elementAt(jsonMap['severity']);

    int? taskGroupId = jsonMap['taskGroupId'];
    if (taskGroupId != null && taskGroupId != deletedDefaultTaskGroupId) {
      _selectedTaskGroup = TaskGroupRepository.findByIdFromCache(taskGroupId);
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

  @override
  bool get wantKeepAlive => true;

  bool _isTaskGroupDeleted(int taskGroupId) {
    final taskGroup = TaskGroupRepository.findByIdFromCache(taskGroupId);
    return taskGroup.id == deletedDefaultTaskGroupId;
  }

}
