import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/ChronologicalPaging.dart';
import 'package:personaltasklogger/db/repository/TaskEventRepository.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';
import 'package:personaltasklogger/ui/utils.dart';
import 'package:personaltasklogger/util/dates.dart';
import 'package:personaltasklogger/ui/dialogs.dart';

import '../forms/TaskEventForm.dart';

class TaskEventList extends StatefulWidget implements PageScaffold {
  _TaskEventListState? _state;

  @override
  State<StatefulWidget> createState() {
    _state = _TaskEventListState();
    return _state!;
  }

  @override
  String getTitle() {
    return 'Personal Task Logger';
  }

  @override
  Icon getIcon() {
    return Icon(Icons.event_available);
  }

  @override
  List<Widget>? getActions() {
    return [
      IconButton(
        icon: const Icon(Icons.list),
        onPressed: () {}, //_pushFavorite,
        tooltip: 'Saved Favorites',
      ),
    ];
  }

  @override
  Function() handleActionPressed(int index) {
    // TODO: implement handleActionPressed
    throw UnimplementedError();
  }

  @override
  void handleFABPressed(BuildContext context) {
    _state?._onFABPressed();
  }
}

class _TaskEventListState extends State<TaskEventList> {
  List<TaskEvent> _taskEvents = [];
  int _selectedTile = -1;
  Set<DateTime> _hiddenTiles = Set();
  Object? _selectedTemplateItem;

  @override
  void initState() {
    super.initState();

    final paging = ChronologicalPaging(ChronologicalPaging.maxDateTime, ChronologicalPaging.maxId, 100);
    TaskEventRepository.getAllPaged(paging).then((taskEvents) {
      setState(() {
        _taskEvents = taskEvents;
      });
    });
  }

  void _addTaskEvent(TaskEvent taskEvent) {
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
    for (var i = 0; i < _taskEvents.length; i++) {
      var taskEvent = _taskEvents[i];
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
        itemCount: _taskEvents.length,
        itemBuilder: (context, index) {
          var taskEvent = _taskEvents[index];
          var taskEventDate = truncToDate(taskEvent.startedAt);
          return Visibility(
            visible: dateHeadings[index] != null || !_hiddenTiles.contains(taskEventDate),
            child: _buildRow(index, dateHeadings),
          );
        });
  }

  Widget _buildRow(int index, List<DateTime?> dateHeadings) {
    final taskEvent = _taskEvents[index];
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
      final taskGroup = findTaskGroupById(taskEvent.taskGroupId!);
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
                onPressed: () {},
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
                child: const Text("Change"),
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
                    child: const Text('From task template'),
                    onPressed: () {
                      Navigator.pop(context);
                      showTemplateDialog(context, "Select a task template",
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
                                  formTitle: "Create new event from task group",
                                  taskGroup: _selectedTemplateItem as TaskGroup,);
                              }
                              else if (_selectedTemplateItem is Template) {
                                return TaskEventForm(
                                  formTitle: "Create new event from task template",
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
}
