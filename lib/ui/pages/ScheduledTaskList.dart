import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/ChronologicalPaging.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskEventRepository.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskRepository.dart';
import 'package:personaltasklogger/db/repository/TaskEventRepository.dart';
import 'package:personaltasklogger/db/repository/TemplateRepository.dart';
import 'package:personaltasklogger/model/ScheduledTask.dart';
import 'package:personaltasklogger/model/ScheduledTaskEvent.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/service/LocalNotificationService.dart';
import 'package:personaltasklogger/service/PreferenceService.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/forms/ScheduledTaskForm.dart';
import 'package:personaltasklogger/ui/forms/TaskEventForm.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';
import 'package:personaltasklogger/util/dates.dart';

import '../ToggleActionIcon.dart';
import '../utils.dart';
import 'PageScaffoldState.dart';


final String PREF_DISABLE_NOTIFICATIONS = "scheduledTasks/disableNotifications";
final String PREF_SORT_BY = "scheduledTasks/sortedBy";

final disableNotificationIconKey = new GlobalKey<ToggleActionIconState>();

@immutable
class ScheduledTaskList extends PageScaffold<ScheduledTaskListState> {

  final PagesHolder _pagesHolder;

  ScheduledTaskList(this._pagesHolder);

  @override
  State<StatefulWidget> createState() => ScheduledTaskListState();

  @override
  Widget getTitle() {
    return Text('Schedules');
  }

  @override
  Icon getIcon() {
    return Icon(Icons.next_plan_outlined);
  }

  @override
  bool withSearchBar() {
    return false;
  }

  @override
  String getRoutingKey() {
    return "ScheduledTasks";
  }
}

enum SortBy {PROGRESS, REMAINING_TIME, GROUP, TITLE,}

class ScheduledTaskListState extends PageScaffoldState<ScheduledTaskList> with AutomaticKeepAliveClientMixin<ScheduledTaskList> {
  List<ScheduledTask> _scheduledTasks = [];
  bool _initialLoaded = false;
  int _selectedTile = -1;
  bool _disableNotification = false;
  SortBy _sortBy = SortBy.PROGRESS;

  final _notificationService = LocalNotificationService();
  final _preferenceService = PreferenceService();

  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _preferenceService.getInt(PREF_SORT_BY).then((value) {
      if (value != null) {
        setState(() {
          _sortBy = SortBy.values.elementAt(value);
        });
      }
    });

    _timer = Timer.periodic(Duration(seconds: 20), (timer) {
      setState(() {
        // update all
        _sortList();
        debugPrint(".. ST timer refresh #${_timer.tick} ..");
      });
    });

    final paging = ChronologicalPaging(ChronologicalPaging.maxDateTime, ChronologicalPaging.maxId, 100);
    ScheduledTaskRepository.getAllPaged(paging).then((scheduledTasks) {
      setState(() {
        _scheduledTasks = scheduledTasks;
        _initialLoaded = true;
        _sortList();

        // refresh scheduled notifications. Could be lost if phone was reseted.
        _scheduledTasks.forEach((scheduledTask) => _rescheduleNotification(scheduledTask));
      });
    });
  }

  @override
  void searchQueryUpdated(String? searchQuery) {
  }

  @override
  List<Widget>? getActions(BuildContext context) {
    final disableNotificationIcon = ToggleActionIcon(Icons.notifications_on_outlined, Icons.notifications_off_outlined, false, disableNotificationIconKey);
    _preferenceService.getBool(PREF_DISABLE_NOTIFICATIONS).then((value) {
      if (value != null) {
        _updateDisableNotifications(value, withSnackMsg: false);
      }
      else {
        disableNotificationIconKey.currentState?.refresh(_disableNotification);
      }
    });
    
    return [
      IconButton(
          icon: disableNotificationIcon,
          onPressed: () {
            _disableNotification = !_disableNotification;
            _updateDisableNotifications(_disableNotification, withSnackMsg: true);
          }),
      GestureDetector(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(Icons.sort_outlined)),
        onTapDown: (details) {
          showPopUpMenuAtTapDown(
              context,
              details,
              [
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          createCheckIcon(_sortBy == SortBy.PROGRESS),
                          const Spacer(),
                          Text("Sort by progress"),
                        ]
                    ),
                    value: '1'),
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          createCheckIcon(_sortBy == SortBy.REMAINING_TIME),
                          const Spacer(),
                          Text("Sort by remaining time"),
                        ]
                    ),
                    value: '2'),
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          createCheckIcon(_sortBy == SortBy.GROUP),
                          const Spacer(),
                          Text("Sort by category"),
                        ]
                    ),
                    value: '3'),
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          createCheckIcon(_sortBy == SortBy.TITLE),
                          const Spacer(),
                          Text("Sort by title"),
                        ]
                    ),
                    value: '4'),

              ]
          ).then((selected) {
            switch (selected) {
              case '1' :
                {
                  _updateSortBy(SortBy.PROGRESS);
                  break;
                }
              case '2' :
                {
                  _updateSortBy(SortBy.REMAINING_TIME);
                  break;
                }
              case '3' :
                {
                  _updateSortBy(SortBy.GROUP);
                  break;
                }
              case '4' :
                {
                  _updateSortBy(SortBy.TITLE);
                  break;
                }
            }
          });
        },
      ),
    ];
  }

  void _updateDisableNotifications(bool value, {required bool withSnackMsg}) {
    setState(() {
      _disableNotification = value;
      disableNotificationIconKey.currentState?.refresh(!_disableNotification);
      if (_disableNotification) {
        _notificationService.cancelAllNotifications();
        if (withSnackMsg) {
          ScaffoldMessenger.of(super.context).showSnackBar(SnackBar(
              content: Text('Schedule notifications disabled')));
        }

      }
      else {
        _scheduledTasks.forEach((scheduledTask) => _rescheduleNotification(scheduledTask));
        if (withSnackMsg) {
          ScaffoldMessenger.of(super.context).showSnackBar(SnackBar(
              content: Text('Schedule notifications enabled')));
        }
      }
      _preferenceService.setBool(PREF_DISABLE_NOTIFICATIONS, _disableNotification);
    });
  }

  @override
  void handleFABPressed(BuildContext context) {
    _onFABPressed();
  }

  @override
  Widget build(BuildContext context) {
    return _buildList();
  }
  
  @override
  void deactivate() {
    _timer.cancel();
    super.deactivate();
  }

  void updateScheduledTask(ScheduledTask scheduledTask) {
    debugPrint("received scheduledTaskId:" + scheduledTask.id.toString());
    setState(() {
      final found = _scheduledTasks.firstWhereOrNull((element) => element.id == scheduledTask.id);
      debugPrint("found in list: " + found.toString());
      if (found != null) {
        var index = _scheduledTasks.indexOf(found);
        debugPrint("index in list: " + index.toString());
        if (index != -1) {
          _scheduledTasks.removeAt(index);
          _scheduledTasks.insert(index, scheduledTask);
          debugPrint("exchanged: " + scheduledTask.lastScheduledEventOn.toString());
          _sortList();
        }
      }
    });
  }

  Widget _buildList() {
    return Padding(
        padding: EdgeInsets.all(8.0),
        child: ListView.builder(
            itemCount: _scheduledTasks.length,
            itemBuilder: (context, index) {
              var scheduledTask = _scheduledTasks[index];
              var taskGroup = findPredefinedTaskGroupById(scheduledTask.taskGroupId);
              return _buildRow(index, scheduledTask, taskGroup);
            }),
    );
  }

  handleNotificationClickRouted(bool isAppLaunch, String payload) {
    if (_initialLoaded) {
      setState(() {
        final clickedScheduledTask = _scheduledTasks.firstWhere((scheduledTask) => scheduledTask.id.toString() == payload);
        _selectedTile = _scheduledTasks.indexOf(clickedScheduledTask);
      });
    }
    else {
      Timer.periodic(Duration(milliseconds: 100), (timer) {
        if (_initialLoaded) {
          timer.cancel();
          debugPrint("jump to schedule after initial load");
          setState(() {
            final clickedScheduledTask = _scheduledTasks.firstWhere((
                scheduledTask) => scheduledTask.id.toString() == payload);
            _selectedTile = _scheduledTasks.indexOf(clickedScheduledTask);
          });
        }
      });
    }
  }

  Widget _buildRow(int index, ScheduledTask scheduledTask, TaskGroup taskGroup) {
    final expansionWidgets = _createExpansionWidgets(scheduledTask);
    return Padding(
        padding: EdgeInsets.all(4.0),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile( //better use ExpansionPanel?
            key: GlobalKey(),
            // this makes updating all tiles if state changed
            title: Text(kReleaseMode ? scheduledTask.title : "${scheduledTask.title} (id=${scheduledTask.id})"),
            subtitle: Column(
              children: [
                taskGroup.getTaskGroupRepresentation(useIconColor: true),
                Visibility(
                  visible: scheduledTask.active,
                  child: LinearProgressIndicator(
                    value: scheduledTask.isNextScheduleOverdue(true) ? null : scheduledTask.getNextRepetitionIndicatorValue(),
                    color: scheduledTask.isNextScheduleOverdue(false)
                        ? Colors.red[500]
                        : (scheduledTask.isNextScheduleReached()
                          ? Color(0xFF770C0C)
                          : null),
                    backgroundColor: scheduledTask.isNextScheduleOverdue(true) ? Colors.red[300] : null,
                  ),
                ),
              ],
            ),
            children: expansionWidgets,
            collapsedBackgroundColor: getTaskGroupColor(scheduledTask.taskGroupId, true),
            backgroundColor: getTaskGroupColor(scheduledTask.taskGroupId, false),
            initiallyExpanded: index == _selectedTile,
            onExpansionChanged: ((expanded) {
              setState(() {
                _selectedTile = expanded ? index : -1;
              });
            }),
          )
        ),
    );
  }

  List<Widget> _createExpansionWidgets(ScheduledTask scheduledTask) {
    var expansionWidgets = <Widget>[];

    if (scheduledTask.description != null && scheduledTask.description!.isNotEmpty) {
      expansionWidgets.add(Padding(
        padding: EdgeInsets.all(4.0),
        child: Text(scheduledTask.description!),
      ));
    }
    expansionWidgets.addAll([
      Padding(
        padding: EdgeInsets.all(4.0),
        child: Text(getDetailsMessage(scheduledTask)),
      ),
      Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Visibility(
            visible: scheduledTask.active,
            child: ButtonBar(
              alignment: MainAxisAlignment.start,
              buttonPadding: EdgeInsets.symmetric(horizontal: 0.0),
              children: [
                TextButton(
                  child: Icon(Icons.check),
                  onPressed: () async {
                    final templateId = scheduledTask.templateId;
                    Template? template;
                    if (templateId != null) {
                      template = await TemplateRepository.getById(templateId);
                    }

                    TaskEvent? newTaskEvent = await Navigator.push(context, MaterialPageRoute(builder: (context) {
                      String title = scheduledTask.title;
                      if (template != null) {
                        return TaskEventForm(
                            formTitle: "Create new journal entry from schedule",
                            template: template,
                            title: title);
                      }
                      else {
                        final taskGroup = findPredefinedTaskGroupById(
                            scheduledTask.taskGroupId);
                        return TaskEventForm(
                            formTitle: "Create new journal entry from schedule",
                            taskGroup: taskGroup,
                            title: title);
                      }
                    }));

                    if (newTaskEvent != null) {
                      TaskEventRepository.insert(newTaskEvent).then((newTaskEvent) {
                        ScaffoldMessenger.of(super.context).showSnackBar(
                            SnackBar(content: Text('New journal entry with name \'${newTaskEvent.title}\' created')));
                        widget._pagesHolder.taskEventList?.getGlobalKey().currentState?.addTaskEvent(newTaskEvent);

                        scheduledTask.executeSchedule(null);
                        ScheduledTaskRepository.update(scheduledTask).then((changedScheduledTask) {
                          _updateScheduledTask(scheduledTask, changedScheduledTask);
                        });

                        final scheduledTaskEvent = ScheduledTaskEvent.fromEvent(newTaskEvent, scheduledTask);
                        ScheduledTaskEventRepository.insert(scheduledTaskEvent);
                      });
                    }
                  },
                ),
                TextButton(
                  child: Icon(Icons.replay),
                  onPressed: () {
                    showConfirmationDialog(
                      context,
                      "Reset schedule",
                      "Are you sure to reset \'${scheduledTask.title}\' ? This will reset the progress to the beginning.",
                      okPressed: () {
                        scheduledTask.executeSchedule(null);
                        ScheduledTaskRepository.update(scheduledTask).then((changedScheduledTask) {
                          ScaffoldMessenger.of(super.context).showSnackBar(
                              SnackBar(content: Text('Schedule with name \'${changedScheduledTask.title}\' reset done')));
                          _updateScheduledTask(scheduledTask, changedScheduledTask);
                        });
                        Navigator.pop(context);// dismiss dialog, should be moved in Dialogs.dart somehow
                      },
                      cancelPressed: () =>
                          Navigator.pop(context), // dismiss dialog, should be moved in Dialogs.dart somehow
                    );
                  },
                ),
              ],
            ),
          ),
          TextButton(
            child: const Icon(Icons.checklist),
            onPressed: () {
              ScheduledTaskEventRepository
                  .getByScheduledTaskIdPaged(scheduledTask.id, ChronologicalPaging.start(100))
                  .then((scheduledTaskEvents) {
                    if (scheduledTaskEvents.isNotEmpty) {
                      final lastEvent = scheduledTaskEvents.last;
                      final receiverKey = widget._pagesHolder.taskEventList?.getRoutingKey();
                      PersonalTaskLoggerScaffoldState? root = context.findAncestorStateOfType();
                      if (receiverKey != null && root != null) {
                        final taskEventListState = widget._pagesHolder.taskEventList?.getGlobalKey().currentState;
                        if (taskEventListState != null) {
                          taskEventListState.clearFilters();
                          taskEventListState.filterByTaskEventIds(scheduledTaskEvents.map((e) => e.taskEventId));
                          root.sendEventFromClicked(receiverKey, false, lastEvent.taskEventId.toString());
                        }
                      }
                    }
                    else {
                      ScaffoldMessenger.of(super.context).showSnackBar(
                          SnackBar(content: Text('No journal entries for this schedule so far')));
                    }
              });
            },
          ),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            buttonPadding: EdgeInsets.symmetric(horizontal: 0.0),
            children: [
              TextButton(
                onPressed: () async {
                  ScheduledTask? changedScheduledTask = await Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ScheduledTaskForm(
                        formTitle: "Change schedule \'${scheduledTask.title}\'",
                        scheduledTask: scheduledTask,
                        taskGroup: findPredefinedTaskGroupById(scheduledTask.taskGroupId),
                    );
                  }));

                  if (changedScheduledTask != null) {
                    ScheduledTaskRepository.update(changedScheduledTask).then((changedScheduledTask) {
                      ScaffoldMessenger.of(super.context).showSnackBar(
                          SnackBar(content: Text('Schedule with name \'${changedScheduledTask.title}\' changed')));
                      _updateScheduledTask(scheduledTask, changedScheduledTask);
                    });
                  }
                },
                child: const Icon(Icons.edit),
              ),
              TextButton(
                onPressed: () {
                  showConfirmationDialog(
                    context,
                    "Delete Schedule",
                    "Are you sure to delete \'${scheduledTask.title}\' ?",
                    okPressed: () {
                      ScheduledTaskRepository.delete(scheduledTask).then(
                            (_) {
                              ScheduledTaskEventRepository
                                  .getByScheduledTaskIdPaged(scheduledTask.id!, ChronologicalPaging.start(100))
                                  .then((scheduledTaskEvents) {
                                scheduledTaskEvents.forEach((scheduledTaskEvent) {
                                  ScheduledTaskEventRepository.delete(scheduledTaskEvent);
                                });
                              });

                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Schedule \'${scheduledTask.title}\' deleted')));
                            _removeScheduledTask(scheduledTask);
                        },
                      );
                      Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow
                    },
                    cancelPressed: () =>
                        Navigator.pop(context), // dismiss dialog, should be moved in Dialogs.dart somehow
                  );
                },
                child: const Icon(Icons.delete),
              ),
            ],
          ),
        ],
      ),
    ]);
    return expansionWidgets;
  }


  String getDetailsMessage(ScheduledTask scheduledTask) {
    var debug = kReleaseMode ? "" : "last:${scheduledTask.lastScheduledEventOn}, next:${scheduledTask.getNextSchedule()}, ratio: ${scheduledTask.getNextRepetitionIndicatorValue()}\n";
    final nextSchedule = scheduledTask.getNextSchedule()!;

    if (scheduledTask.active && scheduledTask.lastScheduledEventOn != null) {
      var msg = "";
      if (scheduledTask.isNextScheduleOverdue(false)) {
        msg = debug +
            "Overdue ${formatToDateOrWord(
            scheduledTask.getNextSchedule()!, true).toLowerCase()} "
            "for ${formatDuration(scheduledTask.getMissingDuration()!, true)} !";
      }
      else if (truncToSeconds(nextSchedule) == truncToSeconds(DateTime.now())) {
        msg = debug +
            "Due now!";
      }
      else {
        msg = debug +
            "Due ${formatToDateOrWord(nextSchedule, true)
                .toLowerCase()} "
                "${scheduledTask.schedule.toStartAtAsString().toLowerCase()} "
                "in ${formatDuration(scheduledTask.getMissingDuration()!)}";
      }

      final passedDuration = scheduledTask.getPassedDuration();
      var passedString = "";
      if (passedDuration != null) {
        passedString = passedDuration.isNegative
            ? "in " + formatDuration(passedDuration.abs())
            : formatDuration(passedDuration.abs()) + " ago";
      }
      return "$msg"
          "\n\n"
          "Scheduled from ${formatToDateOrWord(
          scheduledTask.lastScheduledEventOn!).toLowerCase()}"
          " $passedString";
    }
    else {
      return debug +
          "- currently inactive -";
    }
  }


  void _addScheduledTask(ScheduledTask scheduledTask) {
    setState(() {
      _scheduledTasks.add(scheduledTask);
      _sortList();
      _selectedTile = _scheduledTasks.indexOf(scheduledTask);
      _rescheduleNotification(scheduledTask);

    });

  }

  void _updateScheduledTask(ScheduledTask origin, ScheduledTask updated) {
    setState(() {
      final index = _scheduledTasks.indexOf(origin);
      if (index != -1) {
        _scheduledTasks.removeAt(index);
        _scheduledTasks.insert(index, updated);
      }
      _sortList();
      _selectedTile = _scheduledTasks.indexOf(updated);
      _rescheduleNotification(updated);

    });

  }

  void _sortList() {
    _scheduledTasks..sort((t1, t2) {
      if (_sortBy == SortBy.PROGRESS) {
        final d1 = t1.active ? t1.getNextRepetitionIndicatorValue() : null;
        final d2 = t2.active ? t2.getNextRepetitionIndicatorValue() : null;
        if (d1 == null && d2 != null) {
          return 1;
        }
        else if (d1 != null && d2 == null) {
          return -1;
        }
        else if (d1 == null && d2 == null) {
          return t1.title.toLowerCase().compareTo(t2.title.toLowerCase());
        }
        return d2!.compareTo(d1!); // reverse
      }
      else if (_sortBy == SortBy.REMAINING_TIME) {
        final d1 = t1.active ? t1.getNextSchedule() : null;
        final d2 = t2.active ? t2.getNextSchedule() : null;
        if (d1 == null && d2 != null) {
          return 1;
        }
        else if (d1 != null && d2 == null) {
          return -1;
        }
        else if (d1 == null && d2 == null) {
          return t1.title.toLowerCase().compareTo(t2.title.toLowerCase());
        }
        return d1!.compareTo(d2!); // reverse
      }
      else if (_sortBy == SortBy.GROUP) {
        final d1 = t1.taskGroupId;
        final d2 = t2.taskGroupId;
        return d1.compareTo(d2);
      }
      else if (_sortBy == SortBy.TITLE) {
        final d1 = t1.title.toLowerCase();
        final d2 = t2.title.toLowerCase();
        final c = d1.compareTo(d2);
        if (c == 0) {
          return t1.title.toLowerCase().compareTo(t2.title.toLowerCase());
        }
        return c;
      }
      else {
        return t1.compareTo(t2);
      }
    });
  }

  void _removeScheduledTask(ScheduledTask scheduledTask) {
    setState(() {
      _scheduledTasks.remove(scheduledTask);
      _selectedTile = -1;
      _cancelNotification(scheduledTask);

    });

  }


  void _onFABPressed() {
    Object? selectedTemplateItem;

    showTemplateDialog(context, "Select a task to be scheduled",
        selectedItem: (selectedItem) {
          setState(() {
            selectedTemplateItem = selectedItem;
          });
        },
        okPressed: () async {
            if (selectedTemplateItem == null) {
              return;
            }
            Navigator.pop(context);
            ScheduledTask? newScheduledTask = await Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ScheduledTaskForm(
                formTitle: "Create new schedule ",
                taskGroup: selectedTemplateItem is Template
                  ? findPredefinedTaskGroupById((selectedTemplateItem as Template).taskGroupId)
                  : selectedTemplateItem as TaskGroup,
                template: selectedTemplateItem is Template
                  ? selectedTemplateItem as Template
                  : null,
              );
            }));

            if (newScheduledTask != null) {
              ScheduledTaskRepository.insert(newScheduledTask).then((newScheduledTask) {
                ScaffoldMessenger.of(super.context).showSnackBar(
                    SnackBar(content: Text('New schedule with name \'${newScheduledTask.title}\' created')));
                _addScheduledTask(newScheduledTask);
              });
            }
        },
        cancelPressed: () {
          Navigator.pop(super.context);
        });

  }

  @override
  bool get wantKeepAlive => true;


  void _rescheduleNotification(ScheduledTask scheduledTask) {
    final missingDuration = scheduledTask.getMissingDuration();
    debugPrint("missing duration: $missingDuration");
    if (missingDuration != null && !missingDuration.isNegative) {
      _cancelNotification(scheduledTask);

      if (scheduledTask.active && _disableNotification == false) {
        final taskGroup = findPredefinedTaskGroupById(
            scheduledTask.taskGroupId);
        _notificationService.scheduleNotification(
            widget.getRoutingKey(),
            scheduledTask.id!,
            "Due scheduled task (${taskGroup.name})",
            "Scheduled task '${scheduledTask.title}' is due!",
            missingDuration,
            CHANNEL_ID_SCHEDULES,
            taskGroup.backgroundColor);
      }
    }
  }

  void _cancelNotification(ScheduledTask scheduledTask) {
    _notificationService.cancelNotification(scheduledTask.id!);
  }

  void _updateSortBy(SortBy sortBy) {
    _preferenceService.setInt(PREF_SORT_BY, sortBy.index);
    setState(() {
      _sortBy = sortBy;
      _sortList();
    });
  }


}


