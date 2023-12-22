import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:permission_handler/permission_handler.dart';
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
import 'package:personaltasklogger/service/PreferenceService.dart';
import 'package:personaltasklogger/ui/components/TaskEventFilter.dart';
import 'package:personaltasklogger/ui/components/ToggleActionIcon.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';
import 'package:personaltasklogger/ui/pages/PageScaffoldState.dart';
import 'package:personaltasklogger/ui/utils.dart';
import 'package:personaltasklogger/util/dates.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../service/DueScheduleCountService.dart';
import '../../service/LocalNotificationService.dart';
import '../../util/units.dart';
import '../PersonalTaskLoggerScaffold.dart';
import '../components/TaskEventWidget.dart';
import '../forms/TaskEventForm.dart';
import 'TaskEventStats.dart';

final expandIconKey = new GlobalKey<ToggleActionIconState>();
final taskEventFilterKey = new GlobalKey<TaskEventFilterState>();
final TASK_EVENT_LIST_ROUTING_KEY = "TaskEvents";

@immutable
class TaskEventList extends PageScaffold<TaskEventListState> {

  final PagesHolder _pagesHolder;

  TaskEventList(this._pagesHolder);

  @override
  State<StatefulWidget> createState() => TaskEventListState();

  @override
  Widget getTitle() {
    return Text(translate('pages.journal.title'));
  }

  @override
  Icon getIcon() {
    return Icon(Icons.event_available);
  }

  @override
  bool withSearchBar() {
    return true;
  }
  
  @override
  String getRoutingKey() {
    return TASK_EVENT_LIST_ROUTING_KEY;
  }

}

class TaskEventListState extends PageScaffoldState<TaskEventList> with AutomaticKeepAliveClientMixin<TaskEventList> {
  List<TaskEvent> _taskEvents = [];
  List<TaskEvent>? _filteredTaskEvents;
  int _selectedTile = -1;
  Set<DateTime> _hiddenTiles = Set();

  TaskFilterSettings taskFilterSettings = TaskFilterSettings();

  String? _searchQuery;
  late Timer _timer;

  final _listScrollController = AutoScrollController(suggestedRowHeight: 40);


  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      setState(() {
        // update all
        debugPrint(".. ET timer refresh #${_timer.tick} ..");
      });
    });

    _loadTaskEvents();

    Permission.notification.request().then((status) {
      debugPrint("notification permission = $status");
      if (status == PermissionStatus.denied) {
        toastInfo(context, translate("system.notifications.denied_permission_message"));
      }
    });
  }

  void _loadTaskEvents() {
    final paging = ChronologicalPaging(ChronologicalPaging.maxDateTime, ChronologicalPaging.maxId, 1000000);
    TaskEventRepository.getAllPaged(paging).then((taskEvents) {
      setState(() {
        _taskEvents = taskEvents;
      });
    });
  }


  @override
  reload() {
    _loadTaskEvents();
  }

  @override
  List<Widget>? getActions(BuildContext context) {
    final expandIcon = ToggleActionIcon(Icons.unfold_less, Icons.unfold_more, isAllExpanded(), expandIconKey);
    return [
      TaskEventFilter(
        initialTaskFilterSettings: taskFilterSettings,
        doFilter: (newFilterSettings, _) {
          setState(() {
            taskFilterSettings = newFilterSettings;
            doFilter();
          });
        },
        key: taskEventFilterKey,
      ),
      IconButton(
        icon: Icon(Icons.donut_large_outlined),
        onPressed: () {
          Navigator.push(super.context, MaterialPageRoute(builder: (context) => TaskEventStats(this)))
              .then((_) {
            taskEventFilterKey.currentState?.refresh(taskFilterSettings);
          });
        }
      ),
      IconButton(
        icon: expandIcon,
        onPressed: () {
          if (isAllExpanded()) {
            collapseAll();
            expandIconKey.currentState?.refresh(false);
          }
          else {
            expandAll();
            expandIconKey.currentState?.refresh(true);
          }
        },
      ),
    ];
  }

  @override
  void handleFABPressed(BuildContext context) {
    _onFABPressed();
  }

  @override
  void searchQueryUpdated(String? searchQuery) {
    _updateSearchQuery(searchQuery);
    doFilter();
  }


  void _updateSearchQuery(String? searchQuery) {
    _searchQuery = searchQuery;
  }

  void doFilter() {
    setState(() {

      if (isFilterActive() || _searchQuery != null) {
        _filteredTaskEvents = List.of(_taskEvents);

        _filteredTaskEvents?..removeWhere((taskEvent) {
          if (_searchQuery != null &&
              !(taskEvent.translatedTitle.toLowerCase().contains(_searchQuery!.toLowerCase())
                  || (taskEvent.translatedDescription != null && taskEvent.translatedDescription!.toLowerCase().contains(_searchQuery!.toLowerCase())))) {
            return true; // remove events not containing search string
          }
          if (taskFilterSettings.filterByTaskEventIds != null && !taskFilterSettings.filterByTaskEventIds!.contains(taskEvent.id!)) {
            return true;  // remove not explicitly requested events
          }
          if (taskFilterSettings.filterByDateRange != null && taskEvent.startedAt.isBefore(truncToDate(taskFilterSettings.filterByDateRange!.start))) {
            return true; // remove events before dateFrom
          }
          if (taskFilterSettings.filterByDateRange != null && taskEvent.startedAt.isAfter(truncToDate(taskFilterSettings.filterByDateRange!.end))) {
            return true; // remove events after dateTo
          }
          if (taskFilterSettings.filterBySeverity != null && taskEvent.severity != taskFilterSettings.filterBySeverity) {
            return true; // remove events don't match given severity
          }
          if (taskFilterSettings.filterByFavorites == true && !taskEvent.favorite) {
            return true; // remove non favorites
          }
          if (taskFilterSettings.filterByTaskOrTemplate is TaskGroup) {
            final _taskGroup = taskFilterSettings.filterByTaskOrTemplate as TaskGroup;
            if (taskEvent.taskGroupId != _taskGroup.id) {
              return true; // remove not in group items
            }
          }
          if (taskFilterSettings.filterByTaskOrTemplate is Template) {
            final filterTemplate = taskFilterSettings.filterByTaskOrTemplate as Template;
            final eventTemplate = taskEvent.originTemplateId;
            if (eventTemplate == null) {
              return true; // remove events with no template at all
            }
            if (filterTemplate.isVariant()) {
              if (eventTemplate != filterTemplate.tId) {
                return true; // remove not associated with this variant
              }
            }
            else {
              final eventTaskTemplateId = TemplateRepository.getParentId(eventTemplate.id); // returns a taskTemplate or null, never a variant
              if (eventTaskTemplateId != filterTemplate.tId!.id && eventTemplate != filterTemplate.tId) {
                return true; // remove not associated parent with template variant item
              }
            }
          }
          return false; // fallback filter nothing
        });
      }
      else {
        _filteredTaskEvents = null;
      }
    });
    taskEventFilterKey.currentState?.refresh(taskFilterSettings);
  }

  void addTaskEvent(TaskEvent taskEvent, {bool justSetState = false}) {
    if (!justSetState && taskEvent.originTemplateId != null) {
      ScheduledTaskRepository.getByTemplateId(taskEvent.originTemplateId!)
          .then((scheduledTasks) {
            final schedulesToConsider = scheduledTasks
                .where((scheduledTask) => scheduledTask.active)
                .toList();
            PreferenceService().getBool(PreferenceService.PREF_EXECUTE_SCHEDULES_ON_TASK_EVENT).then((value) {
              if (value != false) {
                _executeAllSchedules(schedulesToConsider, taskEvent);
              }
            });
      });
    }

    setState(() {
      _taskEvents.add(taskEvent);
      _taskEvents..sort();
      _updateSelectedTile(_taskEvents.indexOf(taskEvent));
      _hiddenTiles.remove(truncToDate(taskEvent.startedAt));

      if (_filteredTaskEvents != null) {
        _filteredTaskEvents?.add(taskEvent);
        _filteredTaskEvents?..sort();
        _updateSelectedTile(_filteredTaskEvents?.indexOf(taskEvent) ?? -1);
      }
    });
  }

  void _executeAllSchedules(List<ScheduledTask> scheduledTasks, TaskEvent taskEvent) {
    scheduledTasks.forEach((scheduledTask) {
      scheduledTask.executeSchedule(taskEvent);
      _cancelSnoozedNotification(scheduledTask);
    
      debugPrint("schedule ${scheduledTask.id} executed: ${scheduledTask.lastScheduledEventOn}");
      ScheduledTaskRepository.update(scheduledTask).then((
          changedScheduledTask) {
        debugPrint("schedule ${changedScheduledTask.id} notified: ${changedScheduledTask.lastScheduledEventOn}");
        widget._pagesHolder.scheduledTaskList?.getGlobalKey().currentState?.updateScheduledTaskFromEvent(changedScheduledTask);
    
        final scheduledTaskEvent = ScheduledTaskEvent.fromEvent(taskEvent, changedScheduledTask);
        ScheduledTaskEventRepository.insert(scheduledTaskEvent).then((value) => debugPrint(value.toString()));

        DueScheduleCountService().dec();
      });
    });
  }

  void _cancelSnoozedNotification(ScheduledTask scheduledTask) {
    LocalNotificationService().cancelNotification(scheduledTask.id! + LocalNotificationService.RESCHEDULED_IDS_RANGE);
  }

  void updateTaskEvent(TaskEvent origin, TaskEvent updated, {required bool selectItem }) {
    setState(() {
      //origin.apply(updated); doesnt work
      final index = _taskEvents.indexOf(origin);
      if (index != -1) {
        _taskEvents.removeAt(index);
        _taskEvents.insert(index, updated);
      }
      _taskEvents..sort();
      if (selectItem) {
        _updateSelectedTile(_taskEvents.indexOf(updated));
      }

      if (_filteredTaskEvents != null) {
        final index = _filteredTaskEvents?.indexOf(origin)??-1;
        if (index != -1) {
          _filteredTaskEvents?.removeAt(index);
          _filteredTaskEvents?.insert(index, updated);
        }
        _filteredTaskEvents?..sort();
        if (selectItem) {
          _updateSelectedTile(_filteredTaskEvents?.indexOf(updated) ?? -1);
        }
      }
    });
  }

  void removeTaskEvent(TaskEvent taskEvent) {
    setState(() {
      bool success = _taskEvents.remove(taskEvent);
      debugPrint("remove ${taskEvent.id} success=$success");

      _selectedTile = -1;
      _filteredTaskEvents?.remove(taskEvent);
    });
  }

  void filterByTaskEventIds(ScheduledTask scheduledTask, Iterable<int> taskEventIds) {
    clearFilters();
    taskFilterSettings.filterByTaskEventIds = taskEventIds.toList();
    taskFilterSettings.filterByScheduledTask = scheduledTask;
    debugPrint("filter by ${taskFilterSettings.filterByTaskEventIds}");
    doFilter();
    expandAll();
  }

  @override
  void deactivate() {
    _timer.cancel();
    super.deactivate();
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildList();
  }

  Widget _buildList() {
    DateTime? dateHeading;
    List<DateTime?> dateHeadings = [];
    Map<DateTime, int> dateCounts = HashMap();
    Map<DateTime, Duration> dateDurations = HashMap();
    var list = getVisibleTaskEvents();

    for (var i = 0; i < list.length; i++) {
      var taskEvent = list[i];
      var taskEventDate = truncToDate(taskEvent.startedAt);
      DateTime? usedDateHeading;

      if (dateHeading == null) {
        dateHeading = truncToDate(taskEvent.startedAt);
        usedDateHeading = dateHeading;
      } else if (taskEventDate.isBefore(dateHeading)) {
        usedDateHeading = taskEventDate;
      }
      dateHeading = taskEventDate;
      dateHeadings.add(usedDateHeading);

      final dateCount = dateCounts[dateHeading];
      dateCounts[dateHeading] = dateCount != null ? dateCount + 1 : 1;

      final dateDuration = dateDurations[dateHeading];
      dateDurations[dateHeading] = dateDuration != null
          ? dateDuration + taskEvent.duration
          : taskEvent.duration;

    }
    return ListView.builder(
        itemCount: list.length,
        controller: _listScrollController,
        itemBuilder: (context, index) {
          var taskEvent = list[index];
          var taskEventDate = truncToDate(taskEvent.startedAt);
          return AutoScrollTag(
            key: ValueKey(index),
            controller: _listScrollController,
            index: index,
            child: Visibility(
              visible: dateHeadings[index] != null || !_hiddenTiles.contains(taskEventDate),
              child: _buildRow(list, index, dateHeadings, dateCounts, dateDurations),
            ),
          );
        });
  }

  List<TaskEvent> getVisibleTaskEvents() => _filteredTaskEvents != null ? _filteredTaskEvents! : _taskEvents;

  Widget _buildRow(List<TaskEvent> list, int index, List<DateTime?> dateHeadings, 
      Map<DateTime, int> dateCounts, Map<DateTime, Duration> dateDurations) {
    final taskEvent = list[index];
    final dateHeading = dateHeadings[index];
    final dateCount = dateCounts[dateHeading];
    final items = Items(dateCount??0);
    final dateDuration = dateDurations[dateHeading];
    var taskEventDate = truncToDate(taskEvent.startedAt);

    final isExpanded = index == _selectedTile;

    final listTile = ListTile(
      dense: true,
      visualDensity: VisualDensity(horizontal: 0, vertical: -4),
      minVerticalPadding: 2.0,
      title: dateHeading != null
          ? TextButton(
              style: ButtonStyle(
                alignment: Alignment.centerLeft,
                visualDensity: VisualDensity.compact,
                padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.zero),
              ),
              child: Row(
                children: [
                  Text(
                    "${formatToDateOrWord(dateHeading, context)} ($items, ${dateDuration != null ? formatDuration(dateDuration) : ""})",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10.0,
                    ),
                  ),
                  Icon(
                    _hiddenTiles.contains(taskEventDate) ? Icons.arrow_drop_down_sharp : Icons.arrow_drop_up_sharp,
                    color: Colors.grey,
                  ),
                ],
              ),
              onPressed: () {
                setState(() {
                  if (_hiddenTiles.contains(taskEventDate)) {
                    _hiddenTiles.remove(taskEventDate);
                  } else {
                    _hiddenTiles.add(taskEventDate);
                  }
                  expandIconKey.currentState?.refresh(isAllExpanded());
                });
              },
            )
          : null,
      subtitle: Visibility(
        visible: !_hiddenTiles.contains(taskEventDate),
        child: TaskEventWidget(taskEvent,
          isInitiallyExpanded: isExpanded,
          shouldExpand: () => index == _selectedTile,
          onExpansionChanged: ((expanded) {
            setState(() {
              _selectedTile = expanded ? index : -1;
            });
          }),
          pagesHolder: widget._pagesHolder,
          selectInListWhenChanged: true,
        ),
      ),
    );

    if (dateHeading != null && index > 0) {
      return Column(
        children: [const Divider(), listTile],
      );
    } else {
      return listTile;
    }
  }

  void _onFABPressed() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(translate('pages.journal.action.description')),
                  ),
                  OutlinedButton(
                    child: Text(translate('pages.journal.action.from_scratch.title')),
                    onPressed: () async {
                      Navigator.pop(context);
                      TaskEvent? newTaskEvent = await Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return TaskEventForm(formTitle: translate('forms.task_event.create.title'));
                      }));

                      if (newTaskEvent != null) {
                        TaskEventRepository.insert(newTaskEvent).then((newTaskEvent) {

                          toastInfo(super.context, translate('forms.task_event.create.success',
                              args: {"title" : newTaskEvent.translatedTitle}));

                          addTaskEvent(newTaskEvent);
                        });
                      }
                    },
                  ),
                  ElevatedButton(
                    child: Text(translate('pages.journal.action.from_task.title')),
                    onPressed: () {
                      Navigator.pop(context);
                      Object? _selectedTemplateItem;
                      showTemplateDialog(context,
                          translate('forms.task_event.create.title'),
                          translate('pages.journal.action.from_task.description'),
                          selectedItem: (selectedItem) {
                            setState(() {
                              _selectedTemplateItem = selectedItem;
                            });
                          },
                          okPressed: () async {
                            Navigator.pop(super.context);
                            TaskEvent? newTaskEvent = await Navigator.push(super.context, MaterialPageRoute(builder: (context) {
                              if (_selectedTemplateItem is TaskGroup) {
                                return TaskEventForm(
                                  formTitle: translate('forms.task_event.create.title'),
                                  taskGroup: _selectedTemplateItem as TaskGroup,);
                              }
                              else if (_selectedTemplateItem is Template) {
                                return TaskEventForm(
                                  formTitle: translate('forms.task_event.create.title'),
                                  template: _selectedTemplateItem as Template,);
                              }
                              else {
                                return TaskEventForm(formTitle: translate('forms.task_event.create.title'));
                              }
                            }));

                            if (newTaskEvent != null) {
                              TaskEventRepository.insert(newTaskEvent).then((newTaskEvent) {
                                toastInfo(super.context, translate('forms.task_event.create.success',
                                    args: {"title" : newTaskEvent.translatedTitle}));
                                addTaskEvent(newTaskEvent);
                              });
                            }
                          },
                          cancelPressed: () {
                            Navigator.pop(super.context);
                          });
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  @override
  bool get wantKeepAlive => true;

  bool isFilterActive() => taskFilterSettings.isFilterActive();

  void clearFilters() => taskFilterSettings.clearFilters();

  bool isAllExpanded() => _hiddenTiles.isEmpty;

  void expandAll() {
    setState(() {
      _hiddenTiles.clear();
    });
  }

  void collapseAll() {
    setState(() {
      final allDates = _taskEvents.map((e) => truncToDate(e.startedAt));
      _hiddenTiles.addAll(allDates);
    });
  }

  @override
  handleNotificationClickRouted(bool isAppLaunch, String payload, String? actionId) async {
    debugPrint("_handle TaskEventList: payload=$payload $isAppLaunch");
    if (payload == "noop") {
      debugPrint("nothing to do");
      return;
    }
    final index = payload.indexOf("-");
    if (index == -1) {
      debugPrint("payload is an id?: $payload");
      final taskEventId = int.tryParse(payload);
      if (taskEventId != null) {
        final foundIndex = _taskEvents.indexWhere((taskEvent) => taskEvent.id == taskEventId);
        debugPrint("foundIndex= $foundIndex");
        if (foundIndex != -1) {
          setState(() {
            _updateSelectedTile(foundIndex);
          });
        }
      }
      return;
    }

    final subRoutingKey = payload.substring(0, index);
    final stateAsJsonString = payload.substring(index + 1);

    if (subRoutingKey == "TaskEventForm" && stateAsJsonString.isNotEmpty) {
      //open new form with payload content
      debugPrint("json to decode: $stateAsJsonString");

      Map<String, dynamic> stateAsJson = jsonDecode(stateAsJsonString);
      final isCreation = stateAsJson['taskEventId'] == null;
      final title = stateAsJson['title'];
      TaskEvent? taskEvent = await Navigator.push(context, MaterialPageRoute(builder: (context) {
        return TaskEventForm(
            formTitle: isCreation
                ? translate('forms.task_event.create.title')
                : translate('forms.task_event.change.title',
                args: {"title" : title}),
            stateAsJson: stateAsJson,
        );
      }));

      if (taskEvent != null) {
        if (isCreation) {
          TaskEventRepository.insert(taskEvent).then((newTaskEvent) {
            toastInfo(context, translate('forms.task_event.create.success',
                args: {"title" : newTaskEvent.translatedTitle}));
            addTaskEvent(newTaskEvent);
          });
        }
        else {
          TaskEventRepository.update(taskEvent).then((changedTaskEvent) {

            toastInfo(context, translate('forms.task_event.change.success',
                args: {"title" : changedTaskEvent.translatedTitle}));

            updateTaskEvent(taskEvent, changedTaskEvent, selectItem: true);
          });
        }
      }
    }
  }

  _updateSelectedTile(int index) {
    _selectedTile = index;
    if (index != -1) {
      _listScrollController.scrollToIndex(index, duration: Duration(milliseconds: 1));
    }
  }

}
