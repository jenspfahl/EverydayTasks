
import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/pages/AddTaskEventPage.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';
import 'package:personaltasklogger/ui/pages/ScheduledTaskList.dart';
import 'package:personaltasklogger/ui/pages/TaskTemplateList.dart';

import 'pages/TaskEventList.dart';

class PersonalTaskLoggerScaffold extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PersonalTaskLoggerScaffoldState();
  }
}

class PersonalTaskLoggerScaffoldState extends State<PersonalTaskLoggerScaffold> {
  int _selectedNavigationIndex = 1;

  late List<PageScaffold> _pages;

  PersonalTaskLoggerScaffoldState() {

    // ScheduledTaskList is dependent from TaskEventList. Tried to notify instead without that but failed.
    var scheduledTaskList = ScheduledTaskList();
    var taskEventList = TaskEventList(scheduledTaskList);

    _pages = <PageScaffold>[QuickAddTaskEventPage(), taskEventList, TaskTemplateList(), scheduledTaskList];
  }

  PageScaffold getSelectedPage() {
    return _pages.elementAt(_selectedNavigationIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getSelectedPage().getTitle()),
        actions: getSelectedPage().getActions(),
      ),
      body: IndexedStack(
        index: _selectedNavigationIndex,
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => getSelectedPage().handleFABPressed(context),
        child: getSelectedPage().getIcon(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_outlined),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available_rounded),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.next_plan_outlined),
            label: 'Schedules',
          ),
        ],
        selectedItemColor: Colors.lime[800],
        unselectedItemColor: Colors.grey.shade600,
        currentIndex: _selectedNavigationIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  void dispatch(Notification notification) {
    debugPrint("dispatch to context $context");
    notification..dispatch(context);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedNavigationIndex = index;
    });
  }

}
