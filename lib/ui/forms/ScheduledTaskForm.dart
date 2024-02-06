import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/db/repository/TemplateRepository.dart';
import 'package:personaltasklogger/model/Schedule.dart';
import 'package:personaltasklogger/model/ScheduledTask.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/model/When.dart';
import 'package:personaltasklogger/ui/components/RepetitionPicker.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/util/dates.dart';
import 'package:personaltasklogger/util/extensions.dart';

import '../../db/repository/TaskGroupRepository.dart';
import '../../util/units.dart';
import '../PersonalTaskLoggerApp.dart';
import '../utils.dart';

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
  final _monthBasedScheduleController = TextEditingController();
  final _yearBasedScheduleController = TextEditingController();


  final ScheduledTask? _scheduledTask;
  TaskGroup _taskGroup;
  Template? _template;

  RepetitionStep? _selectedRepetitionStep;
  CustomRepetition? _customRepetition;

  AroundWhenAtDay? _selectedStartAt;
  TimeOfDay? _customStartAt;
  RepetitionMode _repetitionMode = RepetitionMode.DYNAMIC;

  Set<DayOfWeek> weekBasedSchedules = {};
  Set<int> monthBasedSchedules = {}; // day of month
  Set<AllYearDate> yearBasedSchedules = {}; // date of all years



  bool _isRemindersEnabled = true;
  CustomRepetition _reminderRepetition = CustomRepetition(1, RepetitionUnit.HOURS);


  WhenOnDateFuture? _selectedNextDueOn;
  DateTime? _customNextDueOn;

  late bool _isActive;

  static int _repetitionModeHintShownForDynamic = 0;
  static int _repetitionModeHintShownForFixed = 0;
  
  final _daysOfMonthSelectorKey = GlobalKey();
  final _daysOfYearSelectorKey = GlobalKey();

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
        // adjust forth
        final nextDueDate = _scheduledTask!.schedule.getNextRepetitionFrom(_scheduledTask!.lastScheduledEventOn!);
        _selectedNextDueOn = fromDateTimeToWhenOnDateFuture(nextDueDate);
        _customNextDueOn = nextDueDate;
      }

      _isActive = _scheduledTask!.active;
      _repetitionMode = _scheduledTask!.schedule.repetitionMode;

      if (_scheduledTask!.reminderNotificationEnabled != null) {
        _isRemindersEnabled = _scheduledTask!.reminderNotificationEnabled!;
      }
      if (_scheduledTask!.reminderNotificationRepetition != null) {
        _reminderRepetition = _scheduledTask!.reminderNotificationRepetition!;
      }

      weekBasedSchedules = _scheduledTask!.schedule.weekBasedSchedules.toSet();
      monthBasedSchedules = _scheduledTask!.schedule.monthBasedSchedules.toSet();
      yearBasedSchedules = _scheduledTask!.schedule.yearBasedSchedules.toSet();

      var nextDueOn = When.fromWhenOnDateFutureToDate(_selectedNextDueOn!, _customNextDueOn);

      if (_repetitionMode == RepetitionMode.FIXED) {
        if (_scheduledTask!.schedule.isMonthBased()) {
          // remove the standard repetition day
          monthBasedSchedules.remove(nextDueOn.day);
        }
        if (_scheduledTask!.schedule.isYearBased()) {
          // remove the standard repetition day
          yearBasedSchedules.remove(AllYearDate(nextDueOn.day, MonthOfYear.values[nextDueOn.month - 1]));
        }
      }
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

    if (_selectedNextDueOn != null) {
      _updateFixedWeekSchedule(When.fromWhenOnDateFutureToDate(_selectedNextDueOn!, _customNextDueOn));
    }
    _updateMonthBasedText();
    _updateYearBasedText();

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
                  builder: (scaffoldContext) {
                    final dueOnFixedScheduleWidget = buildDueOnWidget(context);
                    Widget dueOnWidget;
                    if (dueOnFixedScheduleWidget != null) {
                      dueOnWidget = Column(
                        children: [
                          Container(
                            height: 64.0,
                            width: (MediaQuery
                                .of(context)
                                .size
                                .width / 1) - 35,
                            child: _buildDueOnDayDropDown(context),
                          ),
                          Container(
                            height: 64.0,
                            width: (MediaQuery
                                .of(context)
                                .size
                                .width / 1) - 35,
                            child: dueOnFixedScheduleWidget,
                          ),
                        ],
                      );
                    }
                    else {
                      dueOnWidget = Container(
                        height: 64.0,
                        width: (MediaQuery
                            .of(context)
                            .size
                            .width / 1) - 35,
                        child: _buildDueOnDayDropDown(context),
                      );
                    }

                    return Form(
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
                                          _taskGroup = TaskGroupRepository.findByIdFromCache(selectedTemplate.taskGroupId);
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
                                    child: _taskGroup.getTaskGroupRepresentation(context, useIconColor: true))
                                  ]
                                : [
                                  DropdownMenuItem(
                                      value: currentTemplate,
                                      child: currentTemplate.getTemplateRepresentation()),
                                  ],

                          ),

                          Padding(
                              padding: EdgeInsets.only(top: 30.0),
                              child: Container(
                                height: 64.0,
                                child: ToggleButtons(
                                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                  renderBorder: true,
                                  borderWidth: 1.5,
                                  borderColor: Colors.grey,
                                  color: Colors.grey.shade600,
                                  selectedBorderColor: BUTTON_COLOR,
                                  children: [
                                    SizedBox(
                                        width: 80,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _buildDynamicScheduleIcon(context),
                                            Text(Schedule.fromRepetitionModeToString(RepetitionMode.DYNAMIC), textAlign: TextAlign.center,
                                                style: TextStyle(color: isDarkMode(context) ? (_repetitionMode == RepetitionMode.DYNAMIC ? PRIMARY_COLOR : null) : null)),
                                          ],
                                        )
                                    ),
                                    SizedBox(
                                        width: 80,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _buildFixedScheduleIcon(context, _repetitionMode == RepetitionMode.FIXED),
                                            Text(Schedule.fromRepetitionModeToString(RepetitionMode.FIXED), textAlign: TextAlign.center,
                                                style: TextStyle(color: isDarkMode(context) ? (_repetitionMode == RepetitionMode.FIXED ? PRIMARY_COLOR : null) : null)),
                                          ],
                                        )
                                    ),
                                  ],
                                  isSelected: [_repetitionMode == RepetitionMode.DYNAMIC, _repetitionMode == RepetitionMode.FIXED],
                                  onPressed: (int index) {
                                    setState(() {
                                      _repetitionMode = RepetitionMode.values[index];
                                      if (_selectedNextDueOn != null) {
                                        _updateFixedWeekSchedule(
                                            When.fromWhenOnDateFutureToDate(
                                                _selectedNextDueOn!,
                                                _customNextDueOn));
                                      }
                                    });

                                    //TODO store a total seen counter
                                    if (_repetitionModeHintShownForDynamic < 2 && _repetitionMode == RepetitionMode.DYNAMIC) {
                                      toastInfo(context, translate('forms.schedule.repetition_mode_dynamic'));
                                      _repetitionModeHintShownForDynamic++;
                                    }
                                    else if (_repetitionModeHintShownForFixed < 2 && _repetitionMode == RepetitionMode.FIXED) {
                                      toastInfo(context, translate('forms.schedule.repetition_mode_fixed'));
                                      _repetitionModeHintShownForFixed++;
                                    }
                                  },
                                ),
                              ),
                          ),

                          Padding(
                            padding: EdgeInsets.only(top: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  height: 64.0,
                                  width: (MediaQuery.of(context).size.width / 2) - 20,
                                  //width: (MediaQuery.of(context).size.width / 2) + 10,
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

                                              final interimSchedule = Schedule(
                                                aroundStartAt: _selectedStartAt,
                                                startAtExactly: _customStartAt,
                                                repetitionStep: _selectedRepetitionStep!,
                                                customRepetition: _customRepetition,
                                                repetitionMode: _repetitionMode,
                                                weekBasedSchedules: weekBasedSchedules,
                                                monthBasedSchedules: monthBasedSchedules,
                                                yearBasedSchedules: yearBasedSchedules,
                                              );

                                              final nextDueDate = interimSchedule.getNextRepetitionFrom(DateTime.now());
                                              _updateNextDueOn(nextDueDate);
                                            });
                                          }
                                        });
                                      }
                                      else {
                                        setState(() {
                                          _selectedRepetitionStep = value;
                                          _customRepetition = null;

                                          final interimSchedule = Schedule(
                                              aroundStartAt: _selectedStartAt,
                                              startAtExactly: _customStartAt,
                                              repetitionStep: _selectedRepetitionStep!,
                                              customRepetition: _customRepetition,
                                              repetitionMode: _repetitionMode,
                                              weekBasedSchedules: weekBasedSchedules,
                                              monthBasedSchedules: monthBasedSchedules,
                                              yearBasedSchedules: yearBasedSchedules,
                                          );
                                          final nextDueDate = interimSchedule.getNextRepetitionFrom(DateTime.now());
                                          _updateNextDueOn(nextDueDate);
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
                            padding: EdgeInsets.only(top: 0.0),
                            child: dueOnWidget
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
                                      value: _isRemindersEnabled,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value != null) _isRemindersEnabled = value;
                                        });
                                      },
                                    )
                                ),
                                Container(
                                  height: 64.0,
                                  width: (MediaQuery.of(context).size.width / 2) + 10,
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
                                            args: {"when": Schedule.fromCustomRepetitionToUnit(_reminderRepetition, usedClause(context, Clause.dative))})
                                        ))
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10.0),
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
                                      weekBasedSchedules: weekBasedSchedules,
                                      monthBasedSchedules: monthBasedSchedules,
                                      yearBasedSchedules: yearBasedSchedules,
                                    );

                                    var nextDueOn = When.fromWhenOnDateFutureToDate(_selectedNextDueOn!, _customNextDueOn);

                                    if (_repetitionMode == RepetitionMode.FIXED) {
                                      // add the default schedule to the set
                                      if (schedule.isMonthBased()) {
                                        schedule.monthBasedSchedules.add(nextDueOn.day);
                                      }
                                      if (schedule.isYearBased()) {
                                        schedule.yearBasedSchedules.add(AllYearDate(nextDueOn.day, MonthOfYear.values[nextDueOn.month - 1]));
                                      }
                                    }


                                    // adjust back
                                    final scheduleFrom = schedule.getPreviousRepetitionFrom(nextDueOn);


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
                                      reminderNotificationEnabled: _isRemindersEnabled,
                                      reminderNotificationRepetition: _reminderRepetition
                                    );

                                    debugPrint("_isRemindersEnabled=$_isRemindersEnabled $_reminderRepetition");
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
                  );
                  },
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Stack _buildDynamicScheduleIcon(BuildContext context) {
    return Stack(children: [
      Icon(Icons.calendar_today, color: isDarkMode(context) ? (_repetitionMode == RepetitionMode.DYNAMIC ? PRIMARY_COLOR : null) : null,),
      Positioned.fill(top: 4, left: 5.25, child: Text("▪", style: TextStyle(color: isDarkMode(context) ? (_repetitionMode == RepetitionMode.DYNAMIC ? PRIMARY_COLOR : null) : null, fontSize: 14,))),
      Positioned.fill(top: 8, left: 12, child: Text("?", style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode(context) ? (_repetitionMode == RepetitionMode.DYNAMIC ? PRIMARY_COLOR : null) : null, fontSize: 12,))),
    ]);
  }

  Stack _buildFixedScheduleIcon(BuildContext context, bool isHighlighted) {
    return Stack(children: [
      Icon(Icons.calendar_today, color: isDarkMode(context) ? (isHighlighted ? PRIMARY_COLOR : null) : null,),
      Positioned.fill(top: 4, left: 5.25, child: Text("▪ ▪", style: TextStyle(color: isDarkMode(context) ? (isHighlighted ? PRIMARY_COLOR : null) : null, fontSize: 14,))),
    ]);
  }

  Widget? buildDueOnWidget(BuildContext context) {
    if (_selectedRepetitionStep == null) {
      return null;
    }
    final interimSchedule = Schedule(
      aroundStartAt: _selectedStartAt,
      startAtExactly: _customStartAt,
      repetitionStep: _selectedRepetitionStep!,
      customRepetition: _customRepetition,
      repetitionMode: _repetitionMode,
      weekBasedSchedules: weekBasedSchedules,
      monthBasedSchedules: monthBasedSchedules,
      yearBasedSchedules: yearBasedSchedules,
    );

    if (_repetitionMode == RepetitionMode.FIXED) {
      if (_selectedRepetitionStep != null && interimSchedule.isWeekBased()) {
        return _buildWeekDaySelector();
      }
      else if (_selectedRepetitionStep != null && interimSchedule.isMonthBased()) {
        return _buildMonthlyDaySelector();
      }
      else if (_selectedRepetitionStep != null && interimSchedule.isYearBased()) {
        return _buildYearlyDaySelector();
      }
    }
    return null;
  }

  Widget _buildDueOnDayDropDown(BuildContext context) {
    return DropdownButtonFormField<WhenOnDateFuture?>(
      onTap: () => FocusScope.of(context).unfocus(),
      value: _selectedNextDueOn,
      hint: Text(translate('forms.schedule.due_on_hint')),
      icon: Icon(Icons.event_available),
      isExpanded: true,
      onChanged: (value) {
        if (value == WhenOnDateFuture.CUSTOM) {
          final initialScheduleFrom = _customNextDueOn ??
              truncToDate(DateTime.now());
          showTweakedDatePicker(
            context,
            initialDate: initialScheduleFrom,
          ).then((selectedDate) {
            if (selectedDate != null) {
              setState(() {
                _updateNextDueOn(selectedDate);
              });
            }
          });
        }
        setState(() {
          _selectedNextDueOn = value;
          _updateFixedWeekSchedule(When.fromWhenOnDateFutureToDate(_selectedNextDueOn!, _customNextDueOn));
        });
      },
      validator: (WhenOnDateFuture? value) {
        if (value == null ||
            (value == WhenOnDateFuture.CUSTOM && _customNextDueOn == null)) {
          return translate('forms.schedule.due_at_emphasis');
        } else {
          return null;
        }
      },
      items: WhenOnDateFuture.values.map((WhenOnDateFuture whenOnDate) {
        return DropdownMenuItem(
          value: whenOnDate,
          child: Text(
            whenOnDate == WhenOnDateFuture.CUSTOM &&
                _customNextDueOn != null &&
                _dateCannotBeMappedToAWord(_customNextDueOn!)
                ? formatToDateOrWord(_customNextDueOn!, context)
                : When.fromWhenOnDateFutureString(whenOnDate),
          ),
        );
      }).toList(),
    );
  }

  Row _buildWeekDaySelector() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            child: Row(
              children: [
                Expanded(
                  child: buildDayItem(DayOfWeek.MONDAY),
                ),
                Expanded(
                  child: buildDayItem(DayOfWeek.TUESDAY),
                ),
                Expanded(
                  child: buildDayItem(DayOfWeek.WEDNESDAY),
                ),
                Expanded(
                  child: buildDayItem(DayOfWeek.THURSDAY),
                ),
                Expanded(
                  child: buildDayItem(DayOfWeek.FRIDAY),
                ),
                Expanded(
                  child: buildDayItem(DayOfWeek.SATURDAY),
                ),
                Expanded(
                  child: buildDayItem(DayOfWeek.SUNDAY),
                ),
    
              ],),
          ),
        ),
      ],
    );
  }


  Widget _buildMonthlyDaySelector() {

    return TextFormField(
      controller: _monthBasedScheduleController,
      decoration: InputDecoration(
        hintText: translate('forms.schedule.fixed_monthly_hint'),
        counter: Text(""),
      ),
      maxLength: 100,
      keyboardType: TextInputType.text,
      readOnly: true,
      maxLines: 1,
      onTap: () {
        final tempSchedules = monthBasedSchedules.toSet();
        showCustomDialog(context,
          title: translate('forms.schedule.fixed_monthly_title'),
          message: translate('forms.schedule.fixed_monthly_message'),
          body: _buildSingleDayOfMonthSelector(tempSchedules),
          titleFlex: 10,
          bodyFlex: 15,
          okPressed: () {
            Navigator.pop(context);
            monthBasedSchedules = tempSchedules;

            setState(() {
              _updateMonthBasedText();
            });
          },
          cancelPressed: () => Navigator.pop(context),

          neutralButton: TextButton(
              onPressed: () {
                _daysOfMonthSelectorKey.currentState
                    ?.setState(() {
                      tempSchedules.clear();
                    });
              },
              child: Text(translate('common.words.clear').capitalize()),
          ),
        );
      },
    );
  }


  Widget _buildYearlyDaySelector() {

    return TextFormField(
      controller: _yearBasedScheduleController,
      decoration: InputDecoration(
        hintText: translate('forms.schedule.fixed_yearly_hint'),
        counter: Text(""),
      ),
      maxLength: 100,
      keyboardType: TextInputType.text,
      readOnly: true,
      maxLines: 1,
      onTap: () {
        final tempSchedules = yearBasedSchedules.toSet();
        showCustomDialog(context,
          title: translate('forms.schedule.fixed_yearly_title'),
          message: translate('forms.schedule.fixed_yearly_message'),
          body: _buildMultipleDayOfMonthSelector(tempSchedules),
          titleFlex: 4,
          bodyFlex: 7,
          okPressed: () {
            Navigator.pop(context);
            yearBasedSchedules = tempSchedules;

            setState(() {
              _updateYearBasedText();
            });
          },
          cancelPressed: () => Navigator.pop(context),

          neutralButton: TextButton(
            onPressed: () {
              _daysOfYearSelectorKey.currentState
                  ?.setState(() {
                tempSchedules.clear();
              });
            },
            child: Text(translate('common.words.clear').capitalize()),
          ),
        );
      },
    );
  }

  void _updateMonthBasedText() {
    final daysAsString = Schedule.getStringFromMonthlyBasedSchedules(monthBasedSchedules, context);
    if (daysAsString != null) {
      _monthBasedScheduleController.text = "${translate('common.words.and')} ${translate('common.words.on_for_dates')} $daysAsString";
    }
    else {
      _monthBasedScheduleController.text = "";
    }
  }

  void _updateYearBasedText() {
    final daysAsString = Schedule.getStringFromYearlyBasedSchedules(yearBasedSchedules, context);
    if (daysAsString != null) {
      _yearBasedScheduleController.text = "${translate('common.words.and')} ${translate('common.words.on_for_dates')} $daysAsString";
    }
    else {
      _yearBasedScheduleController.text = "";
    }
  }

  Widget buildDayItem(DayOfWeek day) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (weekBasedSchedules.contains(day)) {
            if (weekBasedSchedules.length > 1) { // don't remove the last weekday
              weekBasedSchedules.remove(day);
            }
          }
          else {
            weekBasedSchedules.add(day);
          }
        });
      },
      child: CircleAvatar(
        radius: 15,
        backgroundColor: weekBasedSchedules.contains(day) ? BUTTON_COLOR : Colors.transparent,
        child: Text(
          getShortWeekdayOf(day.index, context).toUpperCase(),
          style: TextStyle(
            color: weekBasedSchedules.contains(day)
                ? Colors.white
                : isDarkMode(context) ? Colors.white60 : Colors.black54,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSingleDayOfMonthSelector(Set<int> monthBasedSchedules) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: SingleChildScrollView(
        child: SizedBox(
          height: 180,
          child: StatefulBuilder(
              key: _daysOfMonthSelectorKey,
              builder: (context, setState) {
                return _buildDayOfMonthSelector(
                    monthBasedSchedules,
                    itemCount: 31,
                    onTap: (day) {
                      setState(() {
                        if (monthBasedSchedules.contains(day)) {
                          monthBasedSchedules.remove(day);
                        }
                        else {
                          monthBasedSchedules.add(day);
                        }
                      });
                    }
                );
              }),
        ),
      ),
    );
  }
  
  Widget _buildMultipleDayOfMonthSelector(Set<AllYearDate> yearBasedSchedules) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: StatefulBuilder(
          key: _daysOfYearSelectorKey,
          builder: (context, setState) {
            final flex = 1;
            return SingleChildScrollView(
              child: SizedBox(
                height: 2500,
                child: Column(
                  children: [
                    Expanded(flex: flex, child: _buildMonthForYearSelector(setState, MonthOfYear.JANUARY, 31, yearBasedSchedules)),
                    Expanded(flex: flex, child: _buildMonthForYearSelector(setState, MonthOfYear.FEBRUARY, 29, yearBasedSchedules)),
                    Expanded(flex: flex, child: _buildMonthForYearSelector(setState, MonthOfYear.MARCH, 31, yearBasedSchedules)),
                    Expanded(flex: flex, child: _buildMonthForYearSelector(setState, MonthOfYear.APRIL, 30, yearBasedSchedules)),
                    Expanded(flex: flex, child: _buildMonthForYearSelector(setState, MonthOfYear.MAY, 31, yearBasedSchedules)),
                    Expanded(flex: flex, child: _buildMonthForYearSelector(setState, MonthOfYear.JUNE, 30, yearBasedSchedules)),
                    Expanded(flex: flex, child: _buildMonthForYearSelector(setState, MonthOfYear.JULY, 31, yearBasedSchedules)),
                    Expanded(flex: flex, child: _buildMonthForYearSelector(setState, MonthOfYear.AUGUST, 31, yearBasedSchedules)),
                    Expanded(flex: flex, child: _buildMonthForYearSelector(setState, MonthOfYear.SEPTEMBER, 30, yearBasedSchedules)),
                    Expanded(flex: flex, child: _buildMonthForYearSelector(setState, MonthOfYear.OCTOBER, 31, yearBasedSchedules)),
                    Expanded(flex: flex, child: _buildMonthForYearSelector(setState, MonthOfYear.NOVEMBER, 30, yearBasedSchedules)),
                    Expanded(flex: flex, child: _buildMonthForYearSelector(setState, MonthOfYear.DECEMBER, 31, yearBasedSchedules)),
                  ],
                ),
              ),
            );
          }),
    );
  }

  Widget _buildMonthForYearSelector(StateSetter setState, MonthOfYear monthOfYear, int maxDays, Set<AllYearDate> yearBasedSchedules) {
    final monthBasedSchedules = _transformToMonthlySchedules(yearBasedSchedules, monthOfYear);
    return Column(
      children: [
        Text(getMonthOf(monthOfYear.index, context)),
        Expanded(
            child: _buildDayOfMonthSelector(monthBasedSchedules,
                itemCount: maxDays,
                onTap: (day) {
                  final receivedAllYearDay = AllYearDate(day, monthOfYear);
                  setState(() {
                    if (yearBasedSchedules.contains(receivedAllYearDay)) {
                      yearBasedSchedules.remove(receivedAllYearDay);
                    }
                    else {
                      yearBasedSchedules.add(receivedAllYearDay);
                    }
                  });
                }
            ),
        ),

      ],
    );
  }

  Set<int> _transformToMonthlySchedules(Set<AllYearDate> yearBasedSchedules, MonthOfYear monthOfYear) {
    return yearBasedSchedules
              .where((e) => e.month == monthOfYear)
              .map((e) => e.day)
              .toSet();
  }

  Widget _buildDayOfMonthSelector(Set<int> monthBasedSchedules, {required int itemCount, required Function(int) onTap}) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: itemCount,
      shrinkWrap: false,
      itemBuilder: (context, index) {
        final day = index + 1;
        final date = DateTime(2024, 1, day);
        return GestureDetector(
          onTap: () => onTap(day),
          child: Container(
            child: FilledCell(
              date: date,
              shouldHighlight: monthBasedSchedules.contains(day),
              backgroundColor: isDarkMode(context) ? Colors.black12 : Colors.white60,
              titleColor: isDarkMode(context) ? Colors.white70 : Colors.black12,
              events: [],
            ),
          ),
        );
      },
    );
  }

  void _updateNextDueOn(DateTime selectedDate) {
    if (isToday(selectedDate)) {
      _selectedNextDueOn =
          WhenOnDateFuture.TODAY;
      _customNextDueOn = null;
    } else
    if (isTomorrow(selectedDate)) {
      _selectedNextDueOn =
          WhenOnDateFuture.TOMORROW;
      _customNextDueOn = null;
    } else
    if (isAfterTomorrow(selectedDate)) {
      _selectedNextDueOn =
          WhenOnDateFuture.AFTER_TOMORROW;
      _customNextDueOn = null;
    } else {
      _customNextDueOn = selectedDate;
      _selectedNextDueOn = WhenOnDateFuture.CUSTOM;
    }

    _updateFixedWeekSchedule(selectedDate);
  }

  void _updateFixedWeekSchedule(DateTime selectedDate) {
    if (_repetitionMode == RepetitionMode.FIXED) {
      weekBasedSchedules.add(DayOfWeek.values[selectedDate.weekday - 1]);
    }
  }

  bool _dateCannotBeMappedToAWord(DateTime dateTime) {
    final whenOn = fromDateTimeToWhenOnDateFuture(dateTime);
    return whenOn == WhenOnDateFuture.CUSTOM;
  }


}
