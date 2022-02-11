
import 'package:flutter/material.dart';
import 'package:personaltasklogger/service/LocalNotificationService.dart';
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
  PageController _pageController = PageController(initialPage: 1);

  TextEditingController _searchQueryController = TextEditingController();
  String? _searchString;

  late List<PageScaffold> _pages;
  final _notificationService = LocalNotificationService();

  PersonalTaskLoggerScaffoldState() {

    // Pages are dependent on each other. Tried to notify instead without that but failed.
    var scheduledTaskList = ScheduledTaskList();
    var taskEventList = TaskEventList(scheduledTaskList);
    var quickAddTaskEventPage = QuickAddTaskEventPage(taskEventList);

    _pages = <PageScaffold>[quickAddTaskEventPage, taskEventList, TaskTemplateList(), scheduledTaskList];
  }

  @override
  void initState() {
    super.initState();
    _notificationService.addHandler(handleNotificationClicked);
  }

  PageScaffold getSelectedPage() {
    return _pages.elementAt(_selectedNavigationIndex);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: _searchString != null ? _buildSearchField() : getSelectedPage().getTitle(),
        actions: _buildActions(context),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (newIndex) {
          setState(() {
            _selectedNavigationIndex = newIndex;
            _clearOrCloseSearchBar(context, true);
          });
        },
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
            label: 'QuickAdd',
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
        onTap: (index) {
          _pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.ease);
        },
      ),
    );
  }

  @override
  void deactivate() {
    _notificationService.removeHandler(handleNotificationClicked);
    super.deactivate();
  }

  void dispatch(Notification notification) {
    debugPrint("dispatch to context $context");
    notification..dispatch(context);
  }


  Widget _buildSearchField() {
    return TextField(
      controller: _searchQueryController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: "Search ...",
        border: InputBorder.none,
      ),
      style: TextStyle(fontSize: 16.0),
      onChanged: (query) => updateSearchQuery(query),
    );
  }


  List<Widget>? _buildActions(BuildContext context) {
    final definedActions = getSelectedPage().getActions(context);

    if (getSelectedPage().withSearchBar() == false && definedActions == null) {
      return null;
    }
    List<Widget> actions = [];

    if (_searchString != null) {
      //actions.add(
       return [IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _clearOrCloseSearchBar(context, false);
          },
        )];
    //  );
    }
    else if (getSelectedPage().withSearchBar()) {
      actions.add(IconButton(
        icon: const Icon(Icons.search),
        onPressed: _startSearch,
      ));
    }
    if (definedActions != null) {
      actions.addAll(definedActions);
    }

    return actions;
  }

  void _clearOrCloseSearchBar(BuildContext context, bool immediately) {
    if (immediately || _searchQueryController.text.isEmpty) {
      _searchString = null;
      getSelectedPage().searchQueryUpdated(null);
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
    else {
      _clearSearchQuery();
    }
  }

  void _startSearch() {
    ModalRoute.of(context)!
        .addLocalHistoryEntry(LocalHistoryEntry(onRemove: _stopSearching));

    setState(() {
      _searchString = "";
    });
  }

  void updateSearchQuery(String? newQuery) {
    setState(() {
      _searchString = newQuery;
      getSelectedPage().searchQueryUpdated(newQuery);
    });
  }

  void _stopSearching() {
    _clearSearchQuery();

    setState(() {
      _searchString = null;
    });
  }

  void _clearSearchQuery() {
    setState(() {
      _searchQueryController.clear();
      updateSearchQuery("");
    });
  }

  handleNotificationClicked(String receiverKey, String id) {
    final index = _pages.indexWhere((page) => page.getKey() == receiverKey);
    if (index != -1 && index != _selectedNavigationIndex) {
      _pageController.jumpToPage(index);
      setState(() {
        _selectedNavigationIndex = index;
        _clearOrCloseSearchBar(context, true);
      });
    }
  }
}
