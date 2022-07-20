import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/db/repository/TemplateRepository.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/TaskTemplate.dart';
import 'package:personaltasklogger/model/TaskTemplateVariant.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/model/When.dart';
import 'package:personaltasklogger/ui/SeverityPicker.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/util/dates.dart';
import 'package:personaltasklogger/util/extensions.dart';

class TaskTemplateForm extends StatefulWidget {
  final TaskGroup _taskGroup;
  final Template? template;
  final bool createNew;
  final String formTitle;
  final String? title;

  TaskTemplateForm(this._taskGroup, {this.template, required this.createNew, this.title, required this.formTitle});

  @override
  State<StatefulWidget> createState() {
    return _TaskTemplateFormState(template);
  }
}

class _TaskTemplateFormState extends State<TaskTemplateForm> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  Template? template;
  
  Severity _severity = Severity.MEDIUM;

  AroundDurationHours? _selectedDurationHours;
  Duration? _customDuration;
  Duration? _tempSelectedDuration;

  AroundWhenAtDay? _selectedWhenAtDay;
  TimeOfDay? _customWhenAt;

  _TaskTemplateFormState(Template? template) {
    this.template = template;
  }

  initState() {
    super.initState();

    _initState();

  }

  void _initState() {
    
    AroundDurationHours? aroundDuration;
    Duration? duration;
    
    AroundWhenAtDay? aroundStartedAt;
    TimeOfDay? startedAt;

    if (template != null) {
    
      if (template!.severity != null) {
        _severity = template!.severity!;
      }
      else {
        _severity = Severity.MEDIUM;
      }
    
      titleController.text = template!.translatedTitle;
      descriptionController.text = template!.translatedDescription ?? "";
    
      aroundDuration = template!.when?.durationHours;
      duration = template!.when?.durationExactly;
    
      aroundStartedAt = template!.when?.startAt;
      startedAt = template!.when?.startAtExactly;
    
    }
    
    if (widget.title != null) {
      titleController.text = widget.title!;
    }
    
    _selectedDurationHours = aroundDuration;
    if (_selectedDurationHours == AroundDurationHours.CUSTOM) {
      _customDuration = duration;
    }
    
    _selectedWhenAtDay = aroundStartedAt;
    if (startedAt != null && _selectedWhenAtDay == AroundWhenAtDay.CUSTOM) {
      _customWhenAt = startedAt;
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
          actions: [
            Visibility(
              visible: !widget.createNew && template!.isPredefined(),
              child: IconButton(
                icon: const Icon(Icons.undo),
                onPressed: () {
                  showConfirmationDialog(
                    context,
                    translate('forms.task.reset.title'),
                    template!.isVariant()
                      ? translate('forms.task.reset.message_variant', args: {"title": template!.translatedTitle})
                      : translate('forms.task.reset.message_task', args: {"title": template!.translatedTitle}),
                    icon: const Icon(Icons.undo),
                    okPressed: () {
                      Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow

                      final originFav = template?.favorite ?? false;
                      template = TemplateRepository.findPredefinedTemplate(template!.tId!);
                      template!.favorite = originFav;
                      template = template;
                      setState(() {
                        _initState();
                      });
                    },
                    cancelPressed: () =>
                        Navigator.pop(context), // dismiss dialog, should be moved in Dialogs.dart somehow
                  );
                },
              ),
            ),
          ],
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
                          hintText: translate('forms.task.title_hint'),
                          icon: widget._taskGroup.getIcon(true),
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
                      Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: SeverityPicker(
                          showText: true,
                          singleButtonWidth: 100,
                          initialSeverity: _severity,
                          onChanged: (severity) => _severity = severity,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child:
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<AroundDurationHours?>(
                                onTap: () => FocusScope.of(context).unfocus(),
                                value: _selectedDurationHours,
                                hint: Text(translate('forms.task.duration_hint')),
                                icon: Icon(Icons.timer_outlined),
                                isExpanded: true,
                                onChanged: (value) {
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
                            Visibility(
                              visible: _selectedDurationHours != null,
                              child: IconButton(
                                icon: Icon(Icons.clear_outlined),
                                onPressed: () {
                                  setState(() {
                                    _selectedDurationHours = null;
                                  });
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child:
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<AroundWhenAtDay?>(
                                onTap: () => FocusScope.of(context).unfocus(),
                                value: _selectedWhenAtDay,
                                hint: Text(translate('forms.task.when_at_hint')),
                                icon: Icon(Icons.watch_later_outlined),
                                isExpanded: true,
                                onChanged: (value) {
                                  if (value == AroundWhenAtDay.CUSTOM) {
                                    final initialWhenAt = _customWhenAt ?? TimeOfDay.now();
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
                            Visibility(
                              visible: _selectedWhenAtDay != null,
                              child: IconButton(
                                icon: Icon(Icons.clear_outlined),
                                onPressed: () {
                                  setState(() {
                                    _selectedWhenAtDay = null;
                                  });
                                },
                              ),
                            )
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
                                TimeOfDay? startedAtTimeOfDay;
                                if (_selectedWhenAtDay != null) {
                                  startedAtTimeOfDay =
                                      When.fromWhenAtDayToTimeOfDay(
                                          _selectedWhenAtDay!,
                                          _customWhenAt);
                                }
                                Duration? duration;

                                if (_selectedDurationHours != null) {
                                  duration =
                                      When.fromDurationHoursToDuration(
                                          _selectedDurationHours!,
                                          _customDuration);
                                }

                                if (widget.createNew) {
                                  if (template == null) {
                                    // create new task template under given taskGroup
                                    final taskTemplate = _createTaskTemplate(
                                        null, startedAtTimeOfDay, duration, null);
                                    Navigator.pop(context, taskTemplate);
                                  }
                                  else if (template!.isVariant() == false) {
                                    // create new variant under given template
                                    final taskTemplateVariant = _createTaskTemplateVariant(
                                        null, template!.tId!.id, startedAtTimeOfDay, duration, null);
                                    Navigator.pop(context, taskTemplateVariant);
                                  }
                                  else if (template!.isVariant() == true) {
                                    // clone existing variant to a new one
                                    final variant = template! as TaskTemplateVariant;
                                    final taskTemplateVariant = _createTaskTemplateVariant(
                                        null, variant.taskTemplateId, startedAtTimeOfDay, duration, null);
                                    Navigator.pop(context, taskTemplateVariant);
                                  }
                                }
                                else {
                                  if (template == null) {
                                    // update taskGroup, not supported
                                  }
                                  else if (template!.isVariant() == false) {
                                    // update task template
                                    final taskTemplate = _createTaskTemplate(
                                        template!.tId!.id, startedAtTimeOfDay, duration, template!.favorite);
                                    Navigator.pop(context, taskTemplate);
                                  }
                                  else if (template!.isVariant() == true) {
                                    // update variant
                                    final variant = template! as TaskTemplateVariant;
                                    final taskTemplateVariant = _createTaskTemplateVariant(
                                        variant.tId!.id, variant.taskTemplateId, startedAtTimeOfDay, duration, template!.favorite);
                                    Navigator.pop(context, taskTemplateVariant);
                                  }
                                }
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

  TaskTemplate _createTaskTemplate(int? id, TimeOfDay? startedAtTimeOfDay, Duration? duration, bool? isFavorite) {
    final when = _createWhen(startedAtTimeOfDay, duration);

    final taskTemplate = TaskTemplate(
      id: id,
      taskGroupId: widget._taskGroup.id!,
      title: titleController.text,
      description: descriptionController.text,
      when: when,
      severity: _severity,
      favorite: isFavorite
    );
    return taskTemplate;
  }

  TaskTemplateVariant _createTaskTemplateVariant(int? id, int taskTemplateId,
      TimeOfDay? startedAtTimeOfDay, Duration? duration, bool? isFavorite) {
    final when = _createWhen(startedAtTimeOfDay, duration);

    final taskTemplateVariant = TaskTemplateVariant(
      id: id,
      taskGroupId: widget._taskGroup.id!,
      taskTemplateId: taskTemplateId,
      title: titleController.text,
      description: descriptionController.text,
      when: when,
      severity: _severity,
      favorite: isFavorite,
    );
    return taskTemplateVariant;
  }

  When _createWhen(TimeOfDay? startedAtTimeOfDay, Duration? duration) {
    final when = When(
        startAtExactly: startedAtTimeOfDay,
        startAt: _selectedWhenAtDay,
        durationExactly: duration,
        durationHours: _selectedDurationHours);
    return when;
  }

}
