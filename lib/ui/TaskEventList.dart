import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/ChronologicalPaging.dart';
import 'package:personaltasklogger/db/repository/TaskEventRepository.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/ui/utils.dart';
import 'package:personaltasklogger/util/dates.dart';
import 'package:personaltasklogger/ui/dialogs.dart';

import 'TaskEventForm.dart';

class TaskEventList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TaskEventListState();
  }
}

class _TaskEventListState extends State<TaskEventList> {
  List<TaskEvent> _taskEvents = [];
  int _selected = -1;

  _TaskEventListState() {
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
      _selected = _taskEvents.indexOf(taskEvent);
    });
  }

  void _removeTaskEvent(TaskEvent taskEvent) {
    setState(() {
      _taskEvents.remove(taskEvent);
      _selected = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Task Logger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {}, //_pushFavorite,
            tooltip: 'Saved Favorites',
          ),
        ],
      ),
      body: _buildList(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
                        const Text(
                            'From what do you want to create a new task event?'),
                        OutlinedButton(
                          child: const Text('From scratch'),
                          onPressed: () async {
                            Navigator.pop(context);
                            TaskEvent? newTaskEvent = await Navigator.push(
                                context, MaterialPageRoute(builder: (context) {
                              return TaskEventForm("Create new TaskEvent ");
                            }));

                            if (newTaskEvent != null) {
                              TaskEventRepository.insert(newTaskEvent)
                                  .then((newTaskEvent) {
                                ScaffoldMessenger.of(super.context).showSnackBar(SnackBar(
                                    content: Text(
                                        'New task event with name \'${newTaskEvent.title}\' created')));
                                _addTaskEvent(newTaskEvent);
                              });
                            }
                          },
                        ),
                        ElevatedButton(
                          child: const Text('From task template'),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),
                );
              });
        },
        child: Icon(Icons.event_available),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
        selectedItemColor: Colors.lime[800],
        unselectedItemColor: Colors.grey.shade600,
        currentIndex: 1,
        // onTap: _onItemTapped,
      ),
    );
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
          return _buildRow(index, dateHeadings);
        });

  }

  Widget _buildRow(int index, List<DateTime?> dateHeadings) {
    final taskEvent = _taskEvents[index];
    final dateHeading = dateHeadings[index];

    final expansionWidgets = _createExpansionWidgets(taskEvent);
    final listTile = ListTile(
      dense: true,
      title: dateHeading != null
          ? Text(
              formatToDateOrWord(dateHeading),
              style: TextStyle(color: Colors.grey, fontSize: 10.0),
            )
          : null,
      subtitle: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: GlobalKey(), // this makes updating all tiles if state changed
          title: Text(kReleaseMode ? taskEvent.title : "${taskEvent.title} (id=${taskEvent.id})"),
          subtitle: taskEvent.taskGroupId != null ? Text(getTaskGroupPathAsString(taskEvent.taskGroupId!)) : null,
          children: expansionWidgets,
          collapsedBackgroundColor: Colors.lime.shade50,
          backgroundColor: Colors.lime.shade100,
          initiallyExpanded: index == _selected,
          onExpansionChanged: ((expanded) {
            setState(() {
              _selected = expanded ? index : -1;
            });
          }),
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
        child: Text(
          formatToDateTimeRange(
              taskEvent.aroundStartedAt, taskEvent.startedAt,
              taskEvent.aroundDuration, taskEvent.duration,
              true)),
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
                child: Icon(taskEvent.favorite
                    ? Icons.favorite
                    : Icons.favorite_border),
              ),
            ],
          ),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // Perform some action
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
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Task event \'${taskEvent.title}\' deleted')));
                          _removeTaskEvent(taskEvent);
                        },
                      );
                      Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow
                    },
                    cancelPressed: () => Navigator.pop(context), // dismiss dialog, should be moved in Dialogs.dart somehow
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

}
