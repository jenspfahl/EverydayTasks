import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:personaltasklogger/db/repository/ChronologicalPaging.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskEventRepository.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskRepository.dart';
import 'package:personaltasklogger/db/repository/TaskEventRepository.dart';
import 'package:personaltasklogger/db/repository/TemplateRepository.dart';
import 'package:personaltasklogger/model/Schedule.dart';
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

import '../../util/units.dart';
import '../ToggleActionIcon.dart';
import '../utils.dart';
import 'PageScaffoldState.dart';
import 'TaskEventList.dart';


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
    return Text(translate('pages.schedules.title'));
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
  bool _statusTileHidden = true;

  int _totalRunningSchedules = 0;
  int _totalDueSchedules = 0;
  int _totalOverdueSchedules = 0;
  int _dueBeforeTodaySchedules = 0;
  int _dueTodaySchedules = 0;
  int _dueTomorrowSchedules = 0;
  int _dueAfterTomorrowSchedules = 0;
  int _pausedSchedules = 0;
  int _inactiveSchedules = 0;

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
        _calcOverallStats();
        debugPrint(".. ST timer refresh #${_timer.tick} ..");
      });
    });

    _loadSchedules();
  }

  void _loadSchedules() {
    final paging = ChronologicalPaging(ChronologicalPaging.maxDateTime, ChronologicalPaging.maxId, 10000);
    ScheduledTaskRepository.getAllPaged(paging).then((scheduledTasks) {
      setState(() {
        _scheduledTasks = scheduledTasks;
        _initialLoaded = true;
        _sortList();
        _calcOverallStats();
    
      });
    });
  }

  @override
  reload() {
    _loadSchedules();
  }

  @override
  void searchQueryUpdated(String? searchQuery) {
  }

  @override
  List<Widget>? getActions(BuildContext context) {
    final disableNotificationIcon = ToggleActionIcon(Icons.notifications_on_outlined, Icons.notifications_off_outlined, !_disableNotification, disableNotificationIconKey);
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
            _updateDisableNotifications(!_disableNotification, withSnackMsg: true);
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
          toastInfo(context, "Schedule notifications disabled");
        }

      }
      else {
        _scheduledTasks.forEach((scheduledTask) =>
            _rescheduleNotification(scheduledTask,
                withCancel: false,
                withCancelFixedMode: scheduledTask.schedule.repetitionMode == RepetitionMode.FIXED)
        );
        if (withSnackMsg) {
          toastInfo(context, "Schedule notifications enabled");
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

    final statusTile = Column(
      children: [
        TextButton(
          style: ButtonStyle(
            alignment: Alignment.centerLeft,
            visualDensity: VisualDensity.compact,
            padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.zero),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                Text(
                  "${Schedules(_totalRunningSchedules).toStringWithAdjective("running")}, $_totalDueSchedules due, thereof $_totalOverdueSchedules overdue",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10.0,
                  ),
                ),
                Icon(
                  _statusTileHidden ? Icons.arrow_drop_down_sharp : Icons.arrow_drop_up_sharp,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          onPressed: () {
            setState(() {
              _statusTileHidden = !_statusTileHidden;
            });
          },
        ),
        Visibility(
          visible: !_statusTileHidden,
          child: GestureDetector(
            child: Column(
              children: [
                _createStatusRow(Icons.warning_amber_outlined, Colors.red, "Due before today", _dueBeforeTodaySchedules),
                _createStatusRow(Icons.warning_amber_outlined, Colors.red, "Due today", _dueTodaySchedules),
                _createStatusRow(Icons.schedule, Colors.blue, "Due tomorrow", _dueTomorrowSchedules),
                _createStatusRow(Icons.schedule, Colors.blue, "Due after tomorrow", _dueAfterTomorrowSchedules),
                _createStatusRow(Icons.pause, Colors.black87, "Paused schedules", _pausedSchedules),
                _createStatusRow(Icons.check_box_outline_blank, Colors.black87, "Inactive schedules", _inactiveSchedules),
                Divider(),
              ],
            ),
            onTapDown: (_) {
              setState(() {
                _statusTileHidden = true;
              });
            },
            onPanUpdate: (details) {
              if (details.delta.dy < 0) {
                setState(() {
                  _statusTileHidden = true;
                });
              }
            },
          ),
        ),
      ],
    );


    return Padding(
        padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          children: [
            statusTile,
            Expanded(
              child: ListView.builder(
                  itemCount: _scheduledTasks.length,
                  itemBuilder: (context, index) {
                    var scheduledTask = _scheduledTasks[index];
                    var taskGroup = findPredefinedTaskGroupById(scheduledTask.taskGroupId);
                    return _buildRow(index, scheduledTask, taskGroup);
                  }),
            ),
          ],
        ),
    );
  }

  Widget _createStatusRow(IconData iconData, Color color, String text, int data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(iconData, color: color),
          Spacer(),
          Text(text, style: TextStyle(color: color)),
          Spacer(),
          Text(data.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold)
          ),
        ],),
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
    final isExpanded = index == _selectedTile;
    return Padding(
        padding: EdgeInsets.all(4.0),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile( //better use ExpansionPanel?
            key: GlobalKey(),
            // this makes updating all tiles if state changed
            title: isExpanded
                ? Text(kReleaseMode ? scheduledTask.translatedTitle : "${scheduledTask.translatedTitle} (id=${scheduledTask.id})")
                : Row(
              children: [
                taskGroup.getIcon(true),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                  child: Text(kReleaseMode ? scheduledTask.translatedTitle : "${scheduledTask.translatedTitle} (id=${scheduledTask.id})"),
                )
              ],
            ),
            subtitle: Column(
              children: [
                isExpanded ? taskGroup.getTaskGroupRepresentation(useIconColor: true) : _buildShortProgressText(scheduledTask),
                Visibility(
                  visible: scheduledTask.active,
                  child: Opacity(
                    opacity: scheduledTask.isPaused ? 0.3 : 1,
                    child: LinearProgressIndicator(
                      value: scheduledTask.isNextScheduleOverdue(true) ? null : scheduledTask.getNextRepetitionIndicatorValue(),
                      color: scheduledTask.isNextScheduleOverdue(false)
                          ? Colors.red[500]
                          : (scheduledTask.isNextScheduleReached()
                            ? Color(0xFF770C0C)
                            : null),
                      backgroundColor: scheduledTask.isNextScheduleOverdue(true)
                          ? ((scheduledTask.getNextRepetitionIndicatorValue()??0.0) > 1.3333
                            ? Colors.red[200]
                            : Colors.red[300])
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            children: expansionWidgets,
            collapsedBackgroundColor: getTaskGroupColor(scheduledTask.taskGroupId, true),
            backgroundColor: getTaskGroupColor(scheduledTask.taskGroupId, false),
            initiallyExpanded: isExpanded,
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

    if (scheduledTask.translatedDescription != null && scheduledTask.translatedDescription!.isNotEmpty) {
      expansionWidgets.add(Padding(
        padding: EdgeInsets.all(4.0),
        child: Text(scheduledTask.translatedDescription!),
      ));
    }

    List<Widget> content = [];
    if (!scheduledTask.active || scheduledTask.lastScheduledEventOn == null) {
      content.add(const Text("- inactive -"));
    }
    else if (scheduledTask.isPaused) {
      content.add(const Text("- paused -"));
    }
    else {
      content.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: scheduledTask.isNextScheduleOverdue(false) || scheduledTask.isDueNow()
                    ? Icon(Icons.warning_amber_outlined, color: scheduledTask.isDueNow() ? Color(0xFF770C0C) : Colors.red)
                    : const Icon(Icons.watch_later_outlined),
              ),
              Text(_getDueMessage(scheduledTask), softWrap: true),
            ]
          )
      );
      content.add(const Text(""));
      content.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Icon(MdiIcons.arrowExpandRight),
              ),
              Text(_getScheduledMessage(scheduledTask)),
            ]
          )
      );
      content.add(const Text(""));
      content.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Icon(Icons.next_plan_outlined),
              ),
              Text(scheduledTask.schedule.repetitionStep != RepetitionStep.CUSTOM
                  ? Schedule.fromRepetitionStepToString(scheduledTask.schedule.repetitionStep)
                  : Schedule.fromCustomRepetitionToString(scheduledTask.schedule.customRepetition)),
            ]
          ),
      );
    }

    expansionWidgets.addAll([
      Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: content,
        ),
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
                SizedBox(
                  width: 50,
                  child: TextButton(
                    child: Icon(Icons.check),
                    onPressed: () async {
                      if (scheduledTask.isPaused) {
                        toastError(context, "Cannot execute paused schedule! Resume it first!");
                        return;
                      }
                      final templateId = scheduledTask.templateId;
                      Template? template;
                      if (templateId != null) {
                        template = await TemplateRepository.findById(templateId);
                      }

                      TaskEvent? newTaskEvent = await Navigator.push(context, MaterialPageRoute(builder: (context) {
                        String title = scheduledTask.translatedTitle;
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
                          toastInfo(context, "New journal entry with name '${newTaskEvent.translatedTitle}' created");
                          widget._pagesHolder
                              .taskEventList
                              ?.getGlobalKey()
                              .currentState
                              ?.addTaskEvent(newTaskEvent, justSetState: true);

                          scheduledTask.executeSchedule(null);
                          ScheduledTaskRepository.update(scheduledTask).then((changedScheduledTask) {
                            _updateScheduledTask(scheduledTask, changedScheduledTask);
                          });

                          final scheduledTaskEvent = ScheduledTaskEvent.fromEvent(newTaskEvent, scheduledTask);
                          ScheduledTaskEventRepository.insert(scheduledTaskEvent);

                          PersonalTaskLoggerScaffoldState? root = context.findAncestorStateOfType();
                          if (root != null) {
                            final taskEventListState = widget._pagesHolder.taskEventList?.getGlobalKey().currentState;
                            if (taskEventListState != null) {
                              taskEventListState.clearFilters();
                              root.sendEventFromClicked(TASK_EVENT_LIST_ROUTING_KEY, false, newTaskEvent.id.toString());
                            }
                          }
                        });
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: TextButton(
                    child: const Icon(Icons.replay),
                    onPressed: () {
                      if (scheduledTask.isPaused) {
                        toastError(context, "Cannot reset paused schedule! Resume it first!");
                        return;
                      }
                      final newNextDueDate = scheduledTask.simulateExecuteSchedule(null);
                      final actualNextDueDate = scheduledTask.getNextSchedule();
                      var nextDueDateAsString = formatToDateOrWord(newNextDueDate!, context,
                          withPreposition: true,
                          makeWhenOnLowerCase: true);
                      var message = (newNextDueDate != actualNextDueDate)
                          ? "Are you sure to reset the progress of '${scheduledTask.translatedTitle}' ? The schedule is then due $nextDueDateAsString at ${formatToTime(newNextDueDate)}."
                          : "Are you sure to reset the progress of '${scheduledTask.translatedTitle}' ? The schedule is still due $nextDueDateAsString at ${formatToTime(newNextDueDate)}.";
                      showConfirmationDialog(
                        context,
                        "Reset schedule",
                        message,
                        icon: const Icon(Icons.replay),
                        okPressed: () {
                          scheduledTask.executeSchedule(null);
                          ScheduledTaskRepository.update(scheduledTask).then((changedScheduledTask) {
                            toastInfo(context, "Schedule with name '${changedScheduledTask.translatedTitle}' reset to now");
                            _updateScheduledTask(scheduledTask, changedScheduledTask);
                          });
                          Navigator.pop(context);// dismiss dialog, should be moved in Dialogs.dart somehow
                        },
                        cancelPressed: () =>
                            Navigator.pop(context), // dismiss dialog, should be moved in Dialogs.dart somehow
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          ButtonBar(
            alignment: scheduledTask.active ? MainAxisAlignment.center : MainAxisAlignment.start,
            buttonPadding: EdgeInsets.symmetric(horizontal: 0.0),
            children: [
              Visibility(
                visible: scheduledTask.active,
                child: SizedBox(
                  width: 50,
                  child: TextButton(
                      child: Icon(scheduledTask.isPaused ? Icons.play_arrow : Icons.pause),
                      onPressed: () {
                        if (scheduledTask.isPaused) {
                          scheduledTask.resume();
                        }
                        else {
                          scheduledTask.pause();
                        }
                        ScheduledTaskRepository.update(scheduledTask)
                            .then((changedScheduledTask) {
                          _updateScheduledTask(scheduledTask, changedScheduledTask);

                          var msg = changedScheduledTask.isPaused
                              ? "Scheduled task '${changedScheduledTask.translatedTitle}' paused"
                              : "Scheduled task '${changedScheduledTask.translatedTitle}' resumed";
                          toastInfo(context, msg);
                        });
                      }
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: TextButton(
                  child: const Icon(Icons.checklist),
                  onPressed: () {
                    ScheduledTaskEventRepository
                        .getByScheduledTaskIdPaged(scheduledTask.id, ChronologicalPaging.start(10000))
                        .then((scheduledTaskEvents) {
                      if (scheduledTaskEvents.isNotEmpty) {
                        PersonalTaskLoggerScaffoldState? root = context.findAncestorStateOfType();
                        if (root != null) {
                          final taskEventListState = widget._pagesHolder.taskEventList?.getGlobalKey().currentState;
                          if (taskEventListState != null) {
                            taskEventListState.filterByTaskEventIds(
                                scheduledTask,
                                scheduledTaskEvents.map((e) => e.taskEventId)
                            );
                            root.sendEventFromClicked(TASK_EVENT_LIST_ROUTING_KEY, false, "noop");
                          }
                        }
                      }
                      else {
                        toastInfo(context, "No journal entries for this schedule so far");
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            buttonPadding: EdgeInsets.symmetric(horizontal: 0.0),
            children: [
              SizedBox(
                width: 50,
                child: TextButton(
                  onPressed: () async {
                    if (scheduledTask.isPaused) {
                      toastError(context, "Cannot change paused schedule! Resume it first!");
                      return;
                    }
                    ScheduledTask? changedScheduledTask = await Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return ScheduledTaskForm(
                          formTitle: "Change schedule '${scheduledTask.translatedTitle}'",
                          scheduledTask: scheduledTask,
                          taskGroup: findPredefinedTaskGroupById(scheduledTask.taskGroupId),
                      );
                    }));

                    if (changedScheduledTask != null) {
                      ScheduledTaskRepository.update(changedScheduledTask).then((changedScheduledTask) {
                        toastInfo(context, "Schedule with name '${changedScheduledTask.translatedTitle}' changed");
                        _updateScheduledTask(scheduledTask, changedScheduledTask);
                      });
                    }
                  },
                  child: const Icon(Icons.edit),
                ),
              ),
              SizedBox(
                width: 50,
                child: TextButton(
                  onPressed: () {
                    showConfirmationDialog(
                      context,
                      "Delete Schedule",
                      "Are you sure to delete '${scheduledTask.translatedTitle}' ?",
                      icon: const Icon(Icons.warning_amber_outlined),
                      okPressed: () {
                        ScheduledTaskRepository.delete(scheduledTask).then(
                              (_) {
                                ScheduledTaskEventRepository
                                    .getByScheduledTaskIdPaged(scheduledTask.id!, ChronologicalPaging.start(10000))
                                    .then((scheduledTaskEvents) {
                                  scheduledTaskEvents.forEach((scheduledTaskEvent) {
                                    ScheduledTaskEventRepository.delete(scheduledTaskEvent);
                                  });
                                });

                                toastInfo(context, "Schedule '${scheduledTask.translatedTitle}' deleted");
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
              ),
            ],
          ),
        ],
      ),
    ]);
    return expansionWidgets;
  }

  String _getDueMessage(ScheduledTask scheduledTask) {
    final nextSchedule = scheduledTask.getNextSchedule()!;

    if (scheduledTask.isNextScheduleOverdue(false)) {
      final dueString = scheduledTask.isNextScheduleOverdue(true)
          ? "Overdue"
          : "Due";
      return "$dueString for ${formatDuration(scheduledTask.getMissingDuration()!, true)} "
              "\n"
              "(${formatToDateOrWord(
              scheduledTask.getNextSchedule()!, context, withPreposition: true,
              makeWhenOnLowerCase: true)})!";

    }
    else if (scheduledTask.isDueNow()) {
      return "Due now!";
    }
    else {
      return "Due in ${formatDuration(scheduledTask.getMissingDuration()!)} "
              "\n"
              "(${formatToDateOrWord(nextSchedule, context, withPreposition: true,
              makeWhenOnLowerCase: true)} "
              "${scheduledTask.schedule.toStartAtAsString().toLowerCase()})";
    }
  }

  String _getScheduledMessage(ScheduledTask scheduledTask) {
    final passedDuration = scheduledTask.getPassedDuration();
    var passedString = "";
    if (passedDuration != null) {
      passedString = passedDuration.isNegative
          ? "in " + formatDuration(passedDuration.abs())
          : formatDuration(passedDuration.abs()) + " ago";
    }
    return "Scheduled $passedString "
        "\n"
        "(${formatToDateOrWord(scheduledTask.lastScheduledEventOn!, context, withPreposition: true, makeWhenOnLowerCase: true)})";
  }

  void _addScheduledTask(ScheduledTask scheduledTask) {
    setState(() {
      _scheduledTasks.add(scheduledTask);
      _sortList();
      _selectedTile = _scheduledTasks.indexOf(scheduledTask);
      _rescheduleNotification(scheduledTask, withCancel: false);
      _calcOverallStats();
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
      _calcOverallStats();

      _rescheduleNotification(updated,
          withCancelFixedMode: origin.schedule.repetitionMode == RepetitionMode.FIXED);

    });

  }

  void _sortList() {
    _scheduledTasks..sort((s1, s2) {
      if (_sortBy == SortBy.PROGRESS) {
        return _sortByProgress(s1, s2);
      }
      else if (_sortBy == SortBy.REMAINING_TIME) {
        final n1 = s1.active ? s1.getNextSchedule() : null;
        final n2 = s2.active ? s2.getNextSchedule() : null;
        if (n1 == null && n2 != null) {
          return 1;
        }
        else if (n1 != null && n2 == null) {
          return -1;
        }
        else if (n1 == null && n2 == null) {
          return _sortByTitleAndId(s1, s2);
        }
        else if (s1.isPaused && !s2.isPaused) {
          return 1;
        }
        else if (!s1.isPaused && s2.isPaused) {
          return -1;
        }
        final c = n1!.compareTo(n2!);
        if (c == 0) {
          return _sortByProgress(s1, s2);
        }
        return c;
      }
      else if (_sortBy == SortBy.GROUP) {
        final g1 = s1.taskGroupId;
        final g2 = s2.taskGroupId;
        final c = g2.compareTo(g1);
        if (c == 0) {
          return _sortByTitleAndId(s1, s2);
        }
        return c;
      }
      else if (_sortBy == SortBy.TITLE) {
        return _sortByTitleAndId(s1, s2);
      }
      else {
        return s1.compareTo(s2);
      }
    });
  }

  int _sortByProgress(ScheduledTask s1, ScheduledTask s2) {
    final n1 = s1.active ? s1.getNextRepetitionIndicatorValue() : null;
    final n2 = s2.active ? s2.getNextRepetitionIndicatorValue() : null;
    if (n1 == null && n2 != null) {
      return 1;
    }
    else if (n1 != null && n2 == null) {
      return -1;
    }
    else if (n1 == null && n2 == null) {
      return _sortByTitleAndId(s1, s2);
    }
    final c = n2!.compareTo(n1!); // reverse
    if (c == 0) {
      return _sortByTitleAndId(s1, s2);
    }
    return c;
  }

  void _removeScheduledTask(ScheduledTask scheduledTask) {
    setState(() {
      _scheduledTasks.remove(scheduledTask);
      _selectedTile = -1;
      _calcOverallStats();

      _cancelNotification(scheduledTask);
    });

  }


  void _onFABPressed() {
    Object? selectedTemplateItem;

    showTemplateDialog(context, "Schedule a task",  "Select a category or task to be repeatedly scheduled.",
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
                toastInfo(context, "New schedule with name '${newScheduledTask.translatedTitle}' created");
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


  void _rescheduleNotification(ScheduledTask scheduledTask,
      {bool withCancel = true, withCancelFixedMode = true}) {
    final missingDuration = scheduledTask.getMissingDuration();
    if (missingDuration != null && !missingDuration.isNegative) {
      debugPrint("reschedule ${scheduledTask.id!} with missing duration: $missingDuration");

      if (withCancel) {
        _cancelNotification(scheduledTask, alsoFixedMode: withCancelFixedMode);
      }

      if (scheduledTask.active && !scheduledTask.isPaused && _disableNotification == false) {
        final taskGroup = findPredefinedTaskGroupById(
            scheduledTask.taskGroupId);
        _scheduleNotification(scheduledTask, taskGroup, missingDuration);
      }
    }
  }

  void _scheduleNotification(ScheduledTask scheduledTask, TaskGroup taskGroup, Duration missingDuration) {
    if (scheduledTask.schedule.repetitionMode == RepetitionMode.FIXED) {
      var lastScheduled = scheduledTask.lastScheduledEventOn!;

      forFixedNotificationIds(scheduledTask.id!, (notificationId, isLast) {
        final nextMissingDuration = scheduledTask.getMissingDurationAfter(lastScheduled);
        debugPrint("schedule $notificationId, lastScheduled $lastScheduled nextMissingDuration $nextMissingDuration isLast $isLast");
        _schedule(notificationId, scheduledTask.translatedTitle, taskGroup, nextMissingDuration, true, isLast);

        lastScheduled = scheduledTask.getNextScheduleAfter(lastScheduled)!;
      });
    }
    else {
      _schedule(scheduledTask.id!, scheduledTask.translatedTitle, taskGroup, missingDuration, false, false);
    }
  }

  void _schedule(int id, String title, TaskGroup taskGroup, Duration missingDuration, bool isFixed, bool isLast) {
    final taskWord = isFixed ? "fixed task" : "task";
    _notificationService.scheduleNotification(
        widget.getRoutingKey(),
        id,
        "Due scheduled $taskWord (${taskGroup.translatedName})",
        isLast
            ? "Scheduled $taskWord '$title' is due! Please click to get future notifications!"
            : "Scheduled $taskWord '$title' is due!",
        missingDuration,
        CHANNEL_ID_SCHEDULES,
        taskGroup.backgroundColor);
  }

  void _cancelNotification(ScheduledTask scheduledTask, {alsoFixedMode = true}) {
    // cancel dynamic mode
    debugPrint("cancel dynamic ${scheduledTask.id!}");
    _notificationService.cancelNotification(scheduledTask.id!);

    // cancel fixed mode
    if (alsoFixedMode) {
      forFixedNotificationIds(scheduledTask.id!, (notificationId, _) {
        debugPrint("cancel fixed $notificationId");
        _notificationService.cancelNotification(notificationId);
      });
    }

  }

  forFixedNotificationIds(int scheduledTaskId, Function(int, bool) f) {
    const amount = 10;
    const multiplier = 1000000;
    int base = scheduledTaskId * multiplier;
    List.generate(amount, (baseId) => base + baseId + 1)
        .forEach((id) => f(id, id - base  == amount));
  }

  void _updateSortBy(SortBy sortBy) {
    _preferenceService.setInt(PREF_SORT_BY, sortBy.index);
    setState(() {
      _sortBy = sortBy;
      _sortList();
    });
  }

  int _sortByTitleAndId(ScheduledTask s1, ScheduledTask s2) {
    final d1 = s1.translatedTitle.toLowerCase();
    final d2 = s2.translatedTitle.toLowerCase();
    final c = d1.compareTo(d2);
    if (c == 0) {
      return s1.id!.compareTo(s2.id!);
    }
    return c;
  }

  void _calcOverallStats() {
    setState(() {
      _totalRunningSchedules = 0;
      _totalDueSchedules = 0;
      _totalOverdueSchedules = 0;
      _dueBeforeTodaySchedules = 0;
      _dueTodaySchedules = 0;
      _dueTomorrowSchedules = 0;
      _dueAfterTomorrowSchedules = 0;
      _pausedSchedules = 0;
      _inactiveSchedules = 0;

      final now = DateTime.now();
      _scheduledTasks
          .forEach((scheduledTask) {

        if (!scheduledTask.active) {
          _inactiveSchedules++;
        }
        else if (scheduledTask.isPaused) {
          _pausedSchedules++;
        }
        else {
          _totalRunningSchedules++;

          if (scheduledTask.isDueNow() ||
              scheduledTask.isNextScheduleOverdue(false)) {
            _totalDueSchedules++;
          }
          if (scheduledTask.isNextScheduleOverdue(true)) {
            _totalOverdueSchedules++;
          }

          final nextSchedule = scheduledTask.getNextSchedule();
          if (nextSchedule != null) {
            if (nextSchedule.isBefore(truncToDate(now))) {
              _dueBeforeTodaySchedules++;
            }
            if (isToday(nextSchedule)) {
              _dueTodaySchedules++;
            }
            if (isTomorrow(nextSchedule)) {
              _dueTomorrowSchedules++;
            }
            if (isAfterTomorrow(nextSchedule)) {
              _dueAfterTomorrowSchedules++;
            }
          }
        }
      });
    });
  }

  Widget _buildShortProgressText(ScheduledTask scheduledTask) {
    String text = "";
    if (!scheduledTask.active || scheduledTask.lastScheduledEventOn == null) {
      text = "- inactive -";
    }
    else if (scheduledTask.isPaused) {
      text = "- paused -";
    }
    else {
      if (scheduledTask.isNextScheduleOverdue(false)) {
        text = scheduledTask.isNextScheduleOverdue(true)
            ? "Overdue!"
            : "Due!";
      }
      else if (scheduledTask.isDueNow()) {
        text ="Due now!";
      }
      else {
        text = "in ${formatDuration(scheduledTask.getMissingDuration()!)}";
      }
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: TextStyle(fontSize: 10)),
    );
  }
}


