import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:personaltasklogger/db/repository/TemplateRepository.dart';
import 'package:personaltasklogger/model/Schedule.dart';
import 'package:personaltasklogger/model/ScheduledTask.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/model/When.dart';
import 'package:personaltasklogger/ui/RepetitionPicker.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/util/dates.dart';
import 'package:personaltasklogger/util/extensions.dart';

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
  TaskGroup _taskGroup;
  Template? _template;

  RepetitionStep? _selectedRepetitionStep;
  CustomRepetition? _customRepetition;
  CustomRepetition _reminderRepetition = CustomRepetition(1, RepetitionUnit.HOURS); //TODO

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
      final startedAt = _scheduledTask!.schedule.startAtExactly;
      if (startedAt != null && _selectedStartAt == AroundWhenAtDay.CUSTOM) {
        _selectedStartAt = AroundWhenAtDay.CUSTOM; // Former NOW is now CUSTOM
        _customStartAt = startedAt;
      }

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
    Future<Template?> currentTemplateFuture = _template != null
        ? Future.value(_template)
        : (_scheduledTask?.templateId != null
          ? TemplateRepository.findById(_scheduledTask!.templateId!)
          : Future.value(null));

    return FutureBuilder<Template?>(
        future: currentTemplateFuture,
      builder: (context, snapshot) {
        Template? currentTemplate = snapshot.data;
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
                              hintText: translate('forms.schedule.title_hint'),
                              icon: const Icon(Icons.next_plan_outlined),
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
                            controller: descriptionController,
                            decoration: InputDecoration(
                              hintText: translate('forms.common.description_hint'),
                              icon: Icon(Icons.info_outline),
                            ),
                            maxLength: 500,
                            keyboardType: TextInputType.text,
                            maxLines: 1,
                          ),
                          DropdownButtonFormField<Object?>(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              Navigator.pop(context);

                              Object? selectedTemplateItem;

                              showTemplateDialog(context,
                                  translate('pages.schedules.action.addition.title'),
                                  translate('pages.schedules.action.addition.message'),
                                  initialSelectedKey: currentTemplate?.getKey() ?? _taskGroup.getKey(),
                                  selectedItem: (selectedItem) {
                                    setState(() {
                                      selectedTemplateItem = selectedItem;
                                    });
                                  },
                                  okPressed: () async {
                                    Navigator.pop(context);
                                    if (selectedTemplateItem == null) {
                                      return;
                                    }
                                    else {
                                      setState(() {
                                        if (selectedTemplateItem is TaskGroup) {
                                          var selectedTaskGroup = (selectedTemplateItem as TaskGroup);
                                          _taskGroup = selectedTaskGroup;
                                          _template = null;
                                          _scheduledTask?.taskGroupId = selectedTaskGroup.id!;
                                          _scheduledTask?.templateId = null;
                                        }
                                        else if (selectedTemplateItem is Template) {
                                          var selectedTemplate = (selectedTemplateItem as Template);
                                          _template = selectedTemplate;
                                          _taskGroup = findPredefinedTaskGroupById(selectedTemplate.taskGroupId);
                                          _scheduledTask?.taskGroupId = selectedTemplate.taskGroupId;
                                          _scheduledTask?.templateId = selectedTemplate.tId;
                                        }
                                      });
                                    }
                                  },
                                  cancelPressed: () {
                                    Navigator.pop(super.context);
                                  });

                            },
                            value: currentTemplate ?? _taskGroup,
                            icon: const Icon(Icons.task_alt),
                            isExpanded: true,
                            onChanged: (value) {},
                            items: currentTemplate == null
                                ? [
                                  DropdownMenuItem(
                                    value: _taskGroup,
                                    child: _taskGroup.getTaskGroupRepresentation(useIconColor: true))
                                  ]
                                : [
                                  DropdownMenuItem(
                                      value: currentTemplate,
                                      child: currentTemplate.getTemplateRepresentation()),
                                  ],

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
                                    hint: Text(translate('forms.schedule.repetition_steps_hint')),
                                    isExpanded: true,
                                    icon: Icon(Icons.next_plan_outlined),
                                    onChanged: (value) {
                                      if (value == RepetitionStep.CUSTOM) {
                                        final initialRepetition = _customRepetition ?? (
                                            _selectedRepetitionStep != null && _selectedRepetitionStep != RepetitionStep.CUSTOM
                                                ? Schedule.fromRepetitionStepToCustomRepetition(_selectedRepetitionStep!, _customRepetition)
                                                : null); // null fallback to 0:01
                                        var tempSelectedRepetition = initialRepetition ?? RepetitionPicker.createDefaultRepetition();

                                        showRepetitionPickerDialog(
                                          context: context,
                                          description: translate('forms.schedule.custom_repetition_steps_description'),
                                          initialRepetition: initialRepetition,
                                          onChanged: (repetition) => tempSelectedRepetition = repetition,
                                        ).then((okPressed) {
                                          if (okPressed ?? false) {
                                            setState(() {
                                              //TODO map back to predefined repetition steps if custom matches
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
                                        return translate('forms.schedule.repetition_steps_emphasis');
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
                                    hint: Text(translate('forms.schedule.due_at_hint')),
                                    icon: Icon(Icons.watch_later_outlined),
                                    isExpanded: true,
                                    onChanged: (value) {
                                      if (value == AroundWhenAtDay.CUSTOM) {
                                        final initialWhenAt = _customStartAt ?? (
                                            _selectedStartAt != null && _selectedStartAt != AroundWhenAtDay.CUSTOM
                                                ? When.fromWhenAtDayToTimeOfDay(_selectedStartAt!, _customStartAt)
                                                : TimeOfDay.now());
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
                                        return translate('forms.schedule.due_at_emphasis');
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
                                  width: (MediaQuery.of(context).size.width / 2) - 60,
                                  child: CheckboxListTile(
                                    title: Text(translate('forms.schedule.activate_schedule')),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
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
                                  width: (MediaQuery.of(context).size.width / 2) + 5,
                                  child: DropdownButtonFormField<WhenOnDate?>(
                                    onTap: () => FocusScope.of(context).unfocus(),
                                    value: _selectedScheduleFrom,
                                    hint: Text(translate('forms.schedule.scheduled_from_hint')),
                                    icon: Icon(MdiIcons.arrowExpandRight),
                                    isExpanded: true,
                                    onChanged: (value) {
                                      if (value == WhenOnDate.CUSTOM) {
                                        final initialScheduleFrom = _customScheduleFrom ?? truncToDate(DateTime.now());
                                        showTweakedDatePicker(
                                          context,
                                          initialDate: initialScheduleFrom,
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
                                        return translate('forms.schedule.scheduled_from_emphasis');
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
                            padding: EdgeInsets.only(top: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                    height: 64.0,
                                    width: (MediaQuery.of(context).size.width / 2) - 60,
                                    child: CheckboxListTile(
                                      title: Text(translate('forms.schedule.activate_reminders')),
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
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
                                  width: (MediaQuery.of(context).size.width / 2) + 5,
                                  child: DropdownButtonFormField<CustomRepetition>(
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                      Navigator.pop(context);

                                      CustomRepetition? tempSelectedRepetition = null;
                                      showRepetitionPickerDialog(
                                        context: context,
                                        description: translate('forms.schedule.remind_again_delay_description'),
                                        initialRepetition: _reminderRepetition,
                                        supportedUnits: [RepetitionUnit.MINUTES, RepetitionUnit.HOURS, RepetitionUnit.DAYS, RepetitionUnit.WEEKS],
                                        onChanged: (repetition) {
                                         tempSelectedRepetition = repetition;
                                        },
                                      ).then((okPressed) {
                                        if (okPressed ?? false) {
                                          setState(() {
                                            if (tempSelectedRepetition != null) {
                                              _reminderRepetition =
                                                  tempSelectedRepetition!;
                                            }
                                          });
                                        }
                                      });
                                    },
                                    value: _reminderRepetition,
                                    isExpanded: true,
                                    icon: Icon(Icons.notifications_paused),
                                    onChanged: (value) {},
                                    items: [DropdownMenuItem(
                                        value: _reminderRepetition,
                                        child: Text(translate('forms.schedule.remind_after',
                                            args: {"when": Schedule.fromCustomRepetitionToUnit(_reminderRepetition)})
                                        ))
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10.0),
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text("${translate('forms.schedule.repetition_mode').capitalize()}: ${_repetitionMode == RepetitionMode.DYNAMIC
                                  ? translate('common.words.on_for_enabled').capitalize()
                                  : translate('common.words.off_for_disabled').capitalize()
                              }"),
                              subtitle: Text(_repetitionMode == RepetitionMode.DYNAMIC
                                  ? translate('forms.schedule.repetition_mode_dynamic')
                                  : translate('forms.schedule.repetition_mode_fixed')),
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
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
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
                                      templateId: _template?.tId ?? _scheduledTask?.templateId,
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
                                child: Text(translate('forms.common.button_save')),
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
    );
  }

  bool _isNotAWord(DateTime dateTime) {
    final whenOn = fromDateTimeToWhenOnDate(dateTime);
    return whenOn == WhenOnDate.CUSTOM;
  }
}
