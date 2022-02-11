import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/ChronologicalPaging.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskRepository.dart';
import 'package:personaltasklogger/db/repository/TaskEventRepository.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/ui/ToggleActionIcon.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';
import 'package:personaltasklogger/ui/pages/ScheduledTaskList.dart';
import 'package:personaltasklogger/ui/utils.dart';
import 'package:personaltasklogger/util/dates.dart';

import '../PersonalTaskLoggerScaffold.dart';
import '../forms/TaskEventForm.dart';

final expandIconKey = new GlobalKey<_TaskEventListState>();

class TaskEventList extends StatefulWidget implements PageScaffold {

  _TaskEventListState? _state;
  ScheduledTaskList _scheduledTaskList;

  TaskEventList(this._scheduledTaskList);

  @override
  State<StatefulWidget> createState() {
    _state = _TaskEventListState(_scheduledTaskList);
    return _state!;
  }

  @override
  Widget getTitle() {
    return const Text('Personal Task Logger');
  }

  @override
  Icon getIcon() {
    return Icon(Icons.event_available);
  }

  @override
  List<Widget>? getActions(BuildContext context) {
    final expandIcon = ToggleActionIcon(Icons.unfold_less, Icons.unfold_more, _state?.isAllExpanded()??true, expandIconKey);
    final filterIcon = ToggleActionIcon(Icons.filter_alt, Icons.filter_alt_outlined, _state?.isFilterActive()??false);
    return [
      GestureDetector(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 6.0),
        child: filterIcon),
        onTapDown: (details) {
          showPopUpMenuAtTapDown(
            context,
            details,
              [
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          Icon(
                            _state?._filterByDateRange != null ? Icons.calendar_today : Icons.calendar_today_outlined,
                            color: _state?._filterByDateRange != null ? Colors.blueAccent : null,
                          ),
                          const Spacer(),
                          Text(_state?._filterByDateRange != null
                              ?  "${formatToDateOrWord(_state!._filterByDateRange!.start)} to ${formatToDateOrWord(_state!._filterByDateRange!.end).toLowerCase()}"
                              : "Filter by date range"),
                        ]
                    ),
                    value: '1'),
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          Icon(
                              _state?._filterByFavorites??false ? Icons.favorite : Icons.favorite_border,
                              color: _state?._filterByFavorites??false ? Colors.blueAccent : null,
                          ),
                          const Spacer(),
                          const Text("Filter favorites"),
                        ]
                    ),
                    value: '2'),
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          _state?._filterByTaskOrTemplate != null
                              ? _state!._filterByTaskOrTemplate is TaskGroup
                                ? (_state!._filterByTaskOrTemplate as TaskGroup).getIcon(true)
                                : (_state!._filterByTaskOrTemplate as Template).getIcon(true)
                              : const Icon(Icons.task_alt),
                          const Spacer(),
                          Text(_state?._filterByTaskOrTemplate != null
                              ? _state!._filterByTaskOrTemplate.toString()
                              : "Filter by task"),
                        ]
                    ),
                    value: '3'),
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          Icon(
                            _state?.isFilterActive()??false ? Icons.clear : Icons.clear_outlined,
                            color: _state?.isFilterActive()??false ? Colors.blueAccent : null,
                          ),
                          const Spacer(),
                          const Text("Clear filters"),
                        ]
                    ),
                    value: '4'),
              ]
          ).then((selected) {
            switch (selected) {
              case '1' : {
                if (_state?._filterByDateRange == null) {
                  showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(Duration(days: 365)),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                    currentDate: DateTime.now(),
                  ).then((dateRange) {
                    if (dateRange != null) {
                      _state?._filterByDateRange = dateRange;
                      _state?._doFilter();
                      filterIcon.refresh(_state?.isFilterActive()??false);
                    }
                  });
                }
                else {
                  _state?._filterByDateRange = null;
                  _state?._doFilter();
                  filterIcon.refresh(_state?.isFilterActive()??false);
                }
                break;
              }

              case '2' : {
                _state?._filterByFavorites = !_state!._filterByFavorites;
                _state?._doFilter();
                filterIcon.refresh(_state?.isFilterActive()??false);
                break;
              }

              case '3' : {
                if (_state?._filterByTaskOrTemplate == null) {
                  Object? selectedItem = null;
                  showTemplateDialog(context, "Select a task to filter by",
                    selectedItem: (item) {
                      selectedItem = item;
                    },
                    okPressed: () {
                      Navigator.pop(context);
                      _state?._filterByTaskOrTemplate = selectedItem;
                      _state?._doFilter();
                      filterIcon.refresh(_state?.isFilterActive()??false);
                    },
                    cancelPressed: () =>
                        Navigator.pop(context), // dis
                  );
                }
                else {
                  _state?._filterByTaskOrTemplate = null;
                  _state?._doFilter();
                  filterIcon.refresh(_state?.isFilterActive()??false);
                }
                break;
              }
              case '4' : {
                _state?.clearFilters();
                _state?._doFilter();
                filterIcon.refresh(_state?.isFilterActive()??false);
                break;
              }
            }
          });
        },
      ),
      IconButton(
        icon: expandIcon,
        onPressed: () {
          if (_state?.isAllExpanded()??false) {
            _state?.collapseAll();
            expandIcon.refresh(false);
          }
          else {
            _state?.expandAll();
            expandIcon.refresh(true);
          }
        },
      ),
    ];
  }

  @override
  void handleFABPressed(BuildContext context) {
    _state?._onFABPressed();
  }

  void addTaskEvent(TaskEvent newTaskEvent) {
    _state?._addTaskEvent(newTaskEvent);
  }

  @override
  bool withSearchBar() {
    return true;
  }

  @override
  void searchQueryUpdated(String? searchQuery) {
    _state?._updateSearchQuery(searchQuery);
    _state?._doFilter();
  }

  @override
  String getKey() {
    return "TaskEvents";
  }
}

class _TaskEventListState extends State<TaskEventList> with AutomaticKeepAliveClientMixin<TaskEventList> {
  List<TaskEvent> _taskEvents = [];
  List<TaskEvent>? _filteredTaskEvents;
  int _selectedTile = -1;
  Set<DateTime> _hiddenTiles = Set();

  Object? _selectedTemplateItem;
  ScheduledTaskList _scheduledTaskList;

  DateTimeRange? _filterByDateRange = null;
  bool _filterByFavorites = false;
  Object? _filterByTaskOrTemplate;

  String? _searchQuery;

  _TaskEventListState(this._scheduledTaskList);


  @override
  void initState() {
    super.initState();

    final paging = ChronologicalPaging(ChronologicalPaging.maxDateTime, ChronologicalPaging.maxId, 500);
    TaskEventRepository.getAllPaged(paging).then((taskEvents) {
      setState(() {
        _taskEvents = taskEvents;
      });
    });
  }

  void _updateSearchQuery(String? searchQuery) {
    _searchQuery = searchQuery;
  }

  void _doFilter() {
    setState(() {

      if (isFilterActive() || _searchQuery != null) {
        _filteredTaskEvents = List.of(_taskEvents);

        _filteredTaskEvents?..removeWhere((taskEvent) {
          if (_searchQuery != null &&
              !(taskEvent.title.toLowerCase().contains(_searchQuery!.toLowerCase())
                  || (taskEvent.description != null && taskEvent.description!.toLowerCase().contains(_searchQuery!.toLowerCase())))) {
            return true; // remove events not containing search string
          }
          if (_filterByDateRange != null && taskEvent.startedAt.isBefore(_filterByDateRange!.start)) {
            return true; // remove events before dateFrom
          }
          if (_filterByDateRange != null && taskEvent.startedAt.isAfter(_filterByDateRange!.end)) {
            return true; // remove events after dateTo
          }
          if (_filterByFavorites && !taskEvent.favorite) {
            return true; // remove non favorites
          }
          if (_filterByTaskOrTemplate is TaskGroup) {
            final _taskGroup = _filterByTaskOrTemplate as TaskGroup;
            if (taskEvent.taskGroupId != _taskGroup.id) {
              return true; // remove remove not in group items
            }
          }
          if (_filterByTaskOrTemplate is Template) {
            final _template = _filterByTaskOrTemplate as Template;
            if (taskEvent.originTemplateId != _template.tId) {
              return true; // remove not associated with template items
            }
          }
          return false; // fallback filter nothing
        });
      }
      else {
        _filteredTaskEvents = null;
      }
    });
  }

  void _addTaskEvent(TaskEvent taskEvent) {
    if (taskEvent.originTemplateId != null) {
      ScheduledTaskRepository.getByTemplateId(taskEvent.originTemplateId!)
          .then((scheduledTasks) {
            scheduledTasks.forEach((scheduledTask) {
              scheduledTask.executeSchedule(taskEvent);
              debugPrint("schedule ${scheduledTask.id} executed");
              ScheduledTaskRepository.update(scheduledTask).then((
                  changedScheduledTask) {
                debugPrint("schedule ${changedScheduledTask.id} notified");
                PersonalTaskLoggerScaffoldState? root = context.findAncestorStateOfType();
                debugPrint("found root $root target: $_scheduledTaskList");
                _scheduledTaskList.updateScheduledTask(changedScheduledTask.id!);
              });
            });
      });
    }

    setState(() {
      _taskEvents.add(taskEvent);
      _taskEvents..sort();
      _selectedTile = _taskEvents.indexOf(taskEvent);
      _hiddenTiles.remove(truncToDate(taskEvent.startedAt));
    });
  }

  void _updateTaskEvent(TaskEvent origin, TaskEvent updated) {
    setState(() {
      final index = _taskEvents.indexOf(origin);
      if (index != -1) {
        _taskEvents.removeAt(index);
        _taskEvents.insert(index, updated);
      }
      _taskEvents..sort();
      _selectedTile = _taskEvents.indexOf(updated);
    });
  }

  void _removeTaskEvent(TaskEvent taskEvent) {
    setState(() {
      _taskEvents.remove(taskEvent);
      _selectedTile = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    DateTime? dateHeading;
    List<DateTime?> dateHeadings = [];
    var list = _filteredTaskEvents != null ? _filteredTaskEvents! : _taskEvents;

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
    }
    return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          var taskEvent = list[index];
          var taskEventDate = truncToDate(taskEvent.startedAt);
          return Visibility(
            visible: dateHeadings[index] != null || !_hiddenTiles.contains(taskEventDate),
            child: _buildRow(list, index, dateHeadings),
          );
        });
  }

  Widget _buildRow(List<TaskEvent> list, int index, List<DateTime?> dateHeadings) {
    final taskEvent = list[index];
    final dateHeading = dateHeadings[index];
    var taskEventDate = truncToDate(taskEvent.startedAt);

    final expansionWidgets = _createExpansionWidgets(taskEvent);
    final listTile = ListTile(
      dense: true,
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
                    formatToDateOrWord(dateHeading),
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
                  debugPrint("curr ${expandIconKey.currentWidget}");

                  if (expandIconKey.currentWidget is ToggleActionIcon) {
                    final expandIcon = expandIconKey.currentWidget as ToggleActionIcon;
                    expandIcon.refresh(isAllExpanded());
                    debugPrint("refresh expand icon with ${isAllExpanded()}");
                  }
                });
              },
            )
          : null,
      subtitle: Visibility(
        visible: !_hiddenTiles.contains(taskEventDate),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            key: GlobalKey(),
            // this makes updating all tiles if state changed
            title: Text(kReleaseMode ? taskEvent.title : "${taskEvent.title} (id=${taskEvent.id})"),
            subtitle: _taskGroupPresentation(taskEvent),
            children: expansionWidgets,
            collapsedBackgroundColor: getTaskGroupColor(taskEvent.taskGroupId, true),
            backgroundColor: getTaskGroupColor(taskEvent.taskGroupId, false),
            initiallyExpanded: index == _selectedTile,
            onExpansionChanged: ((expanded) {
              setState(() {
                _selectedTile = expanded ? index : -1;
              });
            }),
          ),
        ),
      ),
    );

    if (dateHeading != null) {
      return Column(
        children: [const Divider(), listTile],
      );
    } else {
      return listTile;
    }
  }

  Widget? _taskGroupPresentation(TaskEvent taskEvent) {
    if (taskEvent.taskGroupId != null) {
      final taskGroup = findPredefinedTaskGroupById(taskEvent.taskGroupId!);
      return taskGroup.getTaskGroupRepresentation(useIconColor: true);
    }
    return null;
  }

  List<Widget> _createExpansionWidgets(TaskEvent taskEvent) {
    var expansionWidgets = <Widget>[];

    if (taskEvent.description != null && taskEvent.description!.isNotEmpty) {
      expansionWidgets.add(Padding(
        padding: EdgeInsets.all(4.0),
        child: Text(taskEvent.description!),
      ));
    }

    expansionWidgets.addAll([
      Padding(
        padding: EdgeInsets.all(4.0),
        child: Text(formatToDateTimeRange(
            taskEvent.aroundStartedAt, taskEvent.startedAt, taskEvent.aroundDuration, taskEvent.duration, true)),
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
                  taskEvent.favorite = !taskEvent.favorite;
                  TaskEventRepository.update(taskEvent);
                  _updateTaskEvent(taskEvent, taskEvent);
                },
                child: Icon(taskEvent.favorite ? Icons.favorite : Icons.favorite_border),
              ),
            ],
          ),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  TaskEvent? changedTaskEvent = await Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return TaskEventForm(
                        formTitle: "Change TaskEvent \'${taskEvent.title}\'", 
                        taskEvent: taskEvent);
                  }));

                  if (changedTaskEvent != null) {
                    TaskEventRepository.update(changedTaskEvent).then((updatedTaskEvent) {
                      ScaffoldMessenger.of(super.context).showSnackBar(
                          SnackBar(content: Text('Task event with name \'${updatedTaskEvent.title}\' updated')));
                      _updateTaskEvent(taskEvent, updatedTaskEvent);
                    });
                  }
                },
                child: const Icon(Icons.edit),
              ),
              TextButton(
                onPressed: () {
                  showConfirmationDialog(
                    context,
                    "Delete Task Event",
                    "Are you sure to delete \'${taskEvent.title}\' ?",
                    okPressed: () {
                      TaskEventRepository.delete(taskEvent).then(
                        (_) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Task event \'${taskEvent.title}\' deleted')));
                          _removeTaskEvent(taskEvent);
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
                  const Text('From what do you want to create a new task event?'),
                  OutlinedButton(
                    child: const Text('From scratch'),
                    onPressed: () async {
                      Navigator.pop(context);
                      TaskEvent? newTaskEvent = await Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return TaskEventForm(formTitle: "Create new TaskEvent ");
                      }));

                      if (newTaskEvent != null) {
                        TaskEventRepository.insert(newTaskEvent).then((newTaskEvent) {
                          ScaffoldMessenger.of(super.context).showSnackBar(
                              SnackBar(content: Text('New task event with name \'${newTaskEvent.title}\' created')));
                          _addTaskEvent(newTaskEvent);
                        });
                      }
                    },
                  ),
                  ElevatedButton(
                    child: const Text('From task'),
                    onPressed: () {
                      Navigator.pop(context);
                      showTemplateDialog(context, "Select a task",
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
                                  formTitle: "Create new event from group",
                                  taskGroup: _selectedTemplateItem as TaskGroup,);
                              }
                              else if (_selectedTemplateItem is Template) {
                                return TaskEventForm(
                                  formTitle: "Create new event from task",
                                  template: _selectedTemplateItem as Template,);
                              }
                              else {
                                return TaskEventForm(formTitle: "Create new event from scratch");
                              }
                            }));

                            if (newTaskEvent != null) {
                              TaskEventRepository.insert(newTaskEvent).then((newTaskEvent) {
                                ScaffoldMessenger.of(super.context).showSnackBar(
                                    SnackBar(content: Text('New task event with name \'${newTaskEvent.title}\' created')));
                                _addTaskEvent(newTaskEvent);
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

  bool isFilterActive() => _filterByDateRange != null || _filterByFavorites || _filterByTaskOrTemplate != null;

  void clearFilters() {
    _filterByDateRange = null;
    _filterByFavorites = false;
    _filterByTaskOrTemplate = null;
  }

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
  
}
