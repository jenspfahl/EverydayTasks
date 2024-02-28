import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/ui/utils.dart';

import '../../db/repository/ScheduledTaskEventRepository.dart';
import '../../db/repository/ScheduledTaskRepository.dart';
import '../../db/repository/TaskEventRepository.dart';
import '../../db/repository/TaskGroupRepository.dart';
import '../../db/repository/TemplateRepository.dart';
import '../../model/ScheduledTask.dart';
import '../../model/Severity.dart';
import '../../model/TaskEvent.dart';
import '../../model/Template.dart';
import '../../model/When.dart';
import '../../util/dates.dart';
import '../PersonalTaskLoggerApp.dart';
import '../PersonalTaskLoggerScaffold.dart';
import '../dialogs.dart';
import '../forms/TaskEventForm.dart';

class TaskEventWidget extends StatefulWidget {

  final TaskEvent taskEvent;
  final bool isInitiallyExpanded;
  final bool Function()? shouldExpand;
  final ValueChanged<bool>? onExpansionChanged;
  final ValueChanged<TaskEvent>? onTaskEventChanged;
  final ValueChanged<TaskEvent>? onTaskEventDeleted;
  final PagesHolder pagesHolder;
  final bool selectInListWhenChanged;

  TaskEventWidget(this.taskEvent, {
    Key? key,
    this.shouldExpand,
    this.onExpansionChanged,
    this.onTaskEventChanged,
    this.onTaskEventDeleted,
    required this.isInitiallyExpanded,
    required this.pagesHolder,
    required this.selectInListWhenChanged,
  }) : super(key: key);
  
  @override
  TaskEventWidgetState createState() => TaskEventWidgetState();

  static Widget? taskGroupPresentation(BuildContext context, TaskEvent taskEvent) {
    if (taskEvent.taskGroupId != null) {
      final taskGroup = TaskGroupRepository.findByIdFromCache(taskEvent.taskGroupId!);
      return taskGroup.getTaskGroupRepresentation(context, useIconColor: true);
    }
    return null;
  }


  static Text buildWhenText(TaskEvent taskEvent, {bool small = false}) {
    if (small) {
      var text = formatToTime(taskEvent.startedAt);
      if (taskEvent.aroundStartedAt != AroundWhenAtDay.CUSTOM && taskEvent.isAroundStartAtTheSameAsActualTime()) {
        text = When.fromWhenAtDayToString(taskEvent.aroundStartedAt);
      }
      return Text(text, style: TextStyle(fontSize: 10));
    }
    else {
      var text = formatToDateTimeRange(
          taskEvent.aroundStartedAt, taskEvent.startedAt,
          taskEvent.aroundDuration, taskEvent.duration,
          taskEvent.trackingFinishedAt,
          taskEvent.isAroundStartAtTheSameAsActualTime());
      return Text(text);
    }
  }

}

class TaskEventWidgetState extends State<TaskEventWidget> {

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final taskEvent = widget.taskEvent;
    final taskGroup = TaskGroupRepository.findByIdFromCache(taskEvent.taskGroupId!);
    final expansionWidgets = _createExpansionWidgets(taskEvent);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: GlobalKey(), // this makes updating all tiles if state changed
        title: _isExpanded
            ? Text(kReleaseMode ? taskEvent.translatedTitle : "${taskEvent.translatedTitle} (id=${taskEvent.id})")
            : Row(
          children: [
            taskGroup.getIcon(true),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
              child: Text(truncate(kReleaseMode ? taskEvent.translatedTitle : "${taskEvent.translatedTitle} (id=${taskEvent.id})", length: 30)),
            )
          ],
        ),
        subtitle: _isExpanded ? TaskEventWidget.taskGroupPresentation(context, taskEvent) : TaskEventWidget.buildWhenText(taskEvent, small: true),
        children: expansionWidgets,
        collapsedBackgroundColor: taskGroup.backgroundColor(context),
        backgroundColor: taskGroup.softColor(context),
        textColor: isDarkMode(context) ? BUTTON_COLOR.shade300 : BUTTON_COLOR,
        initiallyExpanded: widget.shouldExpand != null ? widget.shouldExpand!() : _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
            if (widget.onExpansionChanged != null) {
              widget.onExpansionChanged!(expanded);
            }
          });
        },
      ),
    );
  }


  List<Widget> _createExpansionWidgets(TaskEvent taskEvent) {
    var expansionWidgets = <Widget>[];

    if (taskEvent.translatedDescription != null && taskEvent.translatedDescription!.isNotEmpty) {
      expansionWidgets.add(Padding(
        padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 16),
        child: Text(taskEvent.translatedDescription!),
      ));
    }

    expansionWidgets.addAll([
      Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.watch_later_outlined),
            ),
            TaskEventWidget.buildWhenText(taskEvent),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.timer_outlined),
            ),
            Text(formatToDuration(taskEvent.aroundDuration, taskEvent.duration, true)),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.all(4.0),
        child: severityToIcon(taskEvent.severity),
      ),
      Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ButtonBar(
            alignment: MainAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    taskEvent.favorite = !taskEvent.favorite;
                  });
                  TaskEventRepository.update(taskEvent);
                  widget.pagesHolder
                      .taskEventList
                      ?.getGlobalKey()
                      .currentState
                      ?.updateTaskEvent(taskEvent, taskEvent, selectItem: widget.selectInListWhenChanged);
                  if (widget.onTaskEventChanged != null)
                    widget.onTaskEventChanged!(taskEvent);

                },
                child: Icon(taskEvent.favorite ? Icons.favorite : Icons.favorite_border,
                    color: isDarkMode(context) ? BUTTON_COLOR.shade300 : BUTTON_COLOR),
              ),
            ],
          ),
          ButtonBar(
              alignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () async {
                    final scheduledTaskEvents = await ScheduledTaskEventRepository.findByTaskEventId(taskEvent.id);
                    final scheduledTaskIds = scheduledTaskEvents.map((e) => e.scheduledTaskId);

                    if (taskEvent.originTemplateId != null) {
                      TemplateRepository.findById(taskEvent.originTemplateId!).then((template) {
                        _showInfoDialog(taskEvent, template, scheduledTaskIds);
                      });
                    }
                    else {
                      _showInfoDialog(taskEvent, null, scheduledTaskIds);
                    }
                  },
                  child: Icon(Icons.info_outline,
                      color: isDarkMode(context) ? BUTTON_COLOR.shade300 : BUTTON_COLOR),
                ),
              ]),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  TaskEvent? changedTaskEvent = await Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return TaskEventForm(
                        formTitle: translate('forms.task_event.change.title',
                            args: {"title" : taskEvent.translatedTitle}),
                        taskEvent: taskEvent);
                  }));

                  if (changedTaskEvent != null) {
                    TaskEventRepository.update(changedTaskEvent).then((updatedTaskEvent) {

                      setState(() {
                        taskEvent.apply(updatedTaskEvent);
                      });

                      toastInfo(context, translate('forms.task_event.change.success',
                          args: {"title" : updatedTaskEvent.translatedTitle}));

                      widget.pagesHolder
                          .taskEventList
                          ?.getGlobalKey()
                          .currentState
                          ?.updateTaskEvent(taskEvent, updatedTaskEvent, selectItem: widget.selectInListWhenChanged);


                      if (widget.onTaskEventChanged != null)
                        widget.onTaskEventChanged!(updatedTaskEvent);
                    });
                  }
                },
                child: Icon(Icons.edit,
                    color: isDarkMode(context) ? BUTTON_COLOR.shade300 : BUTTON_COLOR),
              ),
              TextButton(
                onPressed: () {
                  showConfirmationDialog(
                    context,
                    translate('pages.journal.action.deletion.title'),
                    translate('pages.journal.action.deletion.message',
                        args: {"title" : taskEvent.translatedTitle}),
                    icon: const Icon(Icons.warning_amber_outlined),
                    okPressed: () {
                      TaskEventRepository.delete(taskEvent).then(
                            (_) {
                          ScheduledTaskEventRepository
                              .findByTaskEventId(taskEvent.id!)
                              .then((scheduledTaskEvent) {
                            scheduledTaskEvent.forEach((scheduledTaskEvent) {
                                ScheduledTaskEventRepository.delete(
                                    scheduledTaskEvent);
                            });
                          });
                          toastInfo(context, translate('pages.journal.action.deletion.success',
                              args: {"title" : taskEvent.translatedTitle}));
                          widget.pagesHolder
                              .taskEventList
                              ?.getGlobalKey()
                              .currentState
                              ?.removeTaskEvent(taskEvent);

                          if (widget.onTaskEventDeleted != null)
                            widget.onTaskEventDeleted!(taskEvent);

                          Navigator.pop(context);
                       },
                      );
                    },
                    cancelPressed: () =>
                        Navigator.pop(context),
                  );
                },
                child: Icon(Icons.delete,
                    color: isDarkMode(context) ? BUTTON_COLOR.shade300 : BUTTON_COLOR),
              ),
            ],
          ),
        ],
      ),
    ]);
    return expansionWidgets;
  }


  Future<void> _showInfoDialog(TaskEvent taskEvent, Template? originTemplate, Iterable<int> scheduledTaskIds) async {
    final associatedSchedulesWidgets = <Widget>[boldedText("${translate('pages.journal.details.associated_schedule')}: ")];
    if (scheduledTaskIds.isEmpty) {
      final widget = _createScheduleInfo(null);
      associatedSchedulesWidgets.add(widget);
    }
    else {
      for (final id in scheduledTaskIds) {
        final schedule = await ScheduledTaskRepository.findById(id);

        if (schedule != null) {
          final widget = _createScheduleInfo(schedule);
          associatedSchedulesWidgets.add(widget);
        }
      }
    }

    final alert = AlertDialog(
      title: Row(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
          child: const Icon(Icons.info_outline),
        ),
        Text(translate('pages.journal.details.title'))
      ],),
      content: Wrap(
        children: [
          Wrap(
            children: [
              boldedText("${translate('pages.journal.details.attrib_title')}: "),
              wrappedText(taskEvent.translatedTitle),
            ],
          ),
          Row(
            children: [
              boldedText("${translate('pages.journal.details.attrib_category')}: "),
              TaskEventWidget.taskGroupPresentation(context, taskEvent) ?? Text("-${translate('pages.journal.details.value_uncategorized')}-"),
            ],
          ),
          Divider(),
          Row(
            children: [
              boldedText("${translate('pages.journal.details.attrib_created_at')}: "),
              Spacer(),
              Text(formatToDateTime(taskEvent.createdAt, context)),
            ],
          ),
          Row(
            children: [
              boldedText("${translate('pages.journal.details.attrib_started_at')}: "),
              Spacer(),
              Text(formatToDateTime(taskEvent.startedAt, context)),
            ],
          ),
          Row(
            children: [
              boldedText("${translate('pages.journal.details.attrib_finished_at')}: "),
              Spacer(),
              Text(formatToDateTime(taskEvent.finishedAt, context)),
            ],
          ),
          Wrap(
            children: [
              boldedText("${translate('pages.journal.details.attrib_duration')}: "),
              Text(" " + formatTrackingDuration(taskEvent.duration)),
            ],
          ),
          Divider(),
          Wrap(
            children: [
              boldedText("${translate('pages.journal.details.associated_task')}: "),
              _createOriginTemplateInfo(originTemplate),
            ],
          ),
          Divider(),
          Wrap(
            children: associatedSchedulesWidgets,
          ),
        ],
      ),
    );  // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }


  Widget _createOriginTemplateInfo(Template? originTemplate) {
    if (originTemplate == null) {
      return Text("-${translate('pages.journal.details.value_none')}-");
    }
    final originTaskGroup = TaskGroupRepository.findByIdFromCache(originTemplate.taskGroupId);
    return Column(
      children: [
        Row(
          children: [
            originTaskGroup.getTaskGroupRepresentation(context, useIconColor: true),
            const Text(" /"),
          ],
        ),
        wrappedText(originTemplate.translatedTitle)
      ],);
  }

  Widget _createScheduleInfo(ScheduledTask? scheduledTask) {
    if (scheduledTask == null) {
      return Text("-${translate('pages.journal.details.value_none')}-");
    }
    final originTaskGroup = TaskGroupRepository.findByIdFromCache(scheduledTask.taskGroupId);
    return Column(
      children: [
        Row(
          children: [
            originTaskGroup.getTaskGroupRepresentation(context, useIconColor: true),
            const Text(" /"),
          ],
        ),
        wrappedText(scheduledTask.translatedTitle)
      ],);
  }

}