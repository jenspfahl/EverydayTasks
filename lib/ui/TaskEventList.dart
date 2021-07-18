import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/TaskEventRepository.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/util/dates.dart';
import 'package:personaltasklogger/ui/Dialogs.dart';

import 'TaskEventForm.dart';

class TaskEventList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TaskEventListState();
  }
}

class _TaskEventListState extends State<TaskEventList> {
  List<TaskEvent> _taskEvents = [];

  @override
  void initState() {
    super.initState();
    TaskEventRepository.getAll().then((taskEvents) {
      _taskEvents = taskEvents;
    });
  }

  void _addTaskEvent(TaskEvent taskEvent) {
    setState(() {
      _taskEvents.add(taskEvent);
      _taskEvents..sort();
    });
  }

  void _removeTaskEvent(TaskEvent taskEvent) {
    setState(() {
      _taskEvents.remove(taskEvent);
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
      /*ListView.builder(
        itemCount: _taskEvents.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _notes[index].priority == 1? Colors.yellow: Colors.red,
              child: Icon(_notes[index].priority == 1 ? Icons.arrow_right : Icons.add),
            ),
            title: Text(_notes[index].title),
            subtitle: Text(_notes[index].date),
            trailing: Icon(Icons.delete),
            onTap: () {
              navigateToNoteForm("Edit Note", _notes[index]);
            },
          );
        }),*/
      // TaskEventsList(),
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
                            'From what do you want to create a new log entry?'),
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
                                        'New event with id = ${newTaskEvent.id} created')));
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
        showUnselectedLabels: true,
        showSelectedLabels: true,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Logs',
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
    List<Widget> rows = List.empty(growable: true);
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
      rows.add(_buildRow(taskEvent, usedDateHeading));
    }

    return ListView(
      children: rows,
    );
  }

  Widget _buildRow(TaskEvent taskEvent, DateTime? dateHeading) {
    List<Widget> expansionWidgets = _createExpansionWidgets(taskEvent);

    var listTile = ListTile(
      title: dateHeading != null
          ? Text(
              formatToDateOrWord(dateHeading),
              style: TextStyle(color: Colors.grey, fontSize: 10.0),
            )
          : null,
      subtitle: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          title: Text(taskEvent.name),
          subtitle: Text(taskEvent.originTaskGroup ?? ""),
          //          backgroundColor: Colors.lime,
          children: expansionWidgets,
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
            formatToDateTimeRange(taskEvent.startedAt, taskEvent.finishedAt)),
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
                    "Are you sure to delete ${taskEvent.name} ?",
                    okPressed: () {
                      TaskEventRepository.delete(taskEvent).then(
                        (_) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Task event with id = ${taskEvent.id} deleted')));
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

  Future<List<TaskEvent>> _loadTaskEvents() async {
    var taskEvents = [
      TaskEvent(
          1,
          "Wash up",
          "Washing all up",
          "Household/Daily",
          null,
          DateTime(2021, 5, 12, 17, 30),
          DateTime(2021, 5, 12, 17, 45),
          Severity.MEDIUM,
          false),
      TaskEvent(
          2,
          "Clean kitchen",
          "Clean all in kitchen",
          "Household/Weekly",
          null,
          DateTime(2021, 5, 12, 20, 30),
          DateTime(2021, 5, 12, 21, 00),
          Severity.MEDIUM,
          false),
      TaskEvent(
          3,
          "Bring kid to daycare",
          "",
          "Care/Daily",
          null,
          DateTime(2021, 5, 11, 08, 05),
          DateTime(2021, 5, 11, 08, 20),
          Severity.EASY,
          true),
      TaskEvent(
          4,
          "Cook lunch",
          "Pasta",
          "Cooking",
          null,
          DateTime.now().subtract(Duration(minutes: 10)),
          DateTime.now(),
          Severity.HARD,
          false),
      TaskEvent(
          6,
          "Repair closet",
          "Pasta",
          "Repair",
          null,
          DateTime.now().subtract(Duration(minutes: 10, days: 1)),
          DateTime.now().subtract(Duration(days: 1)),
          Severity.HARD,
          false),
      TaskEvent(
          7,
          "Build bathroom",
          "Assemble Ikea bathroom furniture",
          "Construct/Assembe",
          null,
          DateTime(2020, 12, 1, 09, 30),
          DateTime(2020, 12, 1, 14, 20),
          Severity.HARD,
          true),
    ];

    return taskEvents..sort();
  }

  Widget severityToIcon(Severity severity) {
    List<Icon> icons = List.generate(
        severity.index + 1, (index) => Icon(Icons.fitness_center_outlined));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: icons,
    );
  }
}
