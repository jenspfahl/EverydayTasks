
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:personaltasklogger/service/LocalNotificationService.dart';
import 'package:personaltasklogger/ui/pages/QuickAddTaskEventPage.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';
import 'package:personaltasklogger/ui/pages/ScheduledTaskList.dart';
import 'package:personaltasklogger/ui/pages/TaskTemplateList.dart';

import 'pages/TaskEventList.dart';


class PagesHolder {
  QuickAddTaskEventPage? quickAddTaskEventPage;
  TaskEventList? taskEventList;
  TaskTemplateList? taskTemplateList;
  ScheduledTaskList? scheduledTaskList;

  void init (
      QuickAddTaskEventPage quickAddTaskEventPage,
      TaskEventList taskEventList,
      TaskTemplateList taskTemplateList,
      ScheduledTaskList scheduledTaskList) {
    this.quickAddTaskEventPage = quickAddTaskEventPage;
    this.taskEventList = taskEventList;
    this.taskTemplateList = taskTemplateList;
    this.scheduledTaskList = scheduledTaskList;
  }
}

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

    final pagesHolder = PagesHolder();
    final quickAddTaskEventPage = QuickAddTaskEventPage(pagesHolder);
    final taskEventList = TaskEventList(pagesHolder);
    final taskTemplateList = TaskTemplateList(pagesHolder);
    final scheduledTaskList = ScheduledTaskList(pagesHolder);
    pagesHolder.init(quickAddTaskEventPage, taskEventList, taskTemplateList, scheduledTaskList);

    _pages = <PageScaffold>[quickAddTaskEventPage, taskEventList, taskTemplateList, scheduledTaskList];
  }

  @override
  void initState() {
    super.initState();
    _notificationService.addHandler(sendEvent);
    _notificationService.handleAppLaunchNotification();
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
        onPressed: () => getSelectedPage().getGlobalKey().currentState?.handleFABPressed(context),
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
            label: 'Journal',
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
    _notificationService.removeHandler(sendEvent);
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
    var selectedPageState = getSelectedPage().getGlobalKey().currentState;
    if (selectedPageState == null) {
      // page state not yet initialized, trigger it for later
      Timer(Duration(seconds: 1), () {
        setState(() {
          debugPrint("refresh ui state ${getSelectedPage().key}");
          // refresh
        });
      });
      return null;
    }
    final definedActions = selectedPageState.getActions(context);

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
      getSelectedPage().getGlobalKey().currentState?.searchQueryUpdated(null);
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
      getSelectedPage().getGlobalKey().currentState?.searchQueryUpdated(newQuery);
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

  sendEvent(String receiverKey, String payload) {
    final index = _pages.indexWhere((page) => page.getRoutingKey() == receiverKey);
    if (index != -1 && index != _selectedNavigationIndex) {
      _pageController.jumpToPage(index);
      setState(() {
        _selectedNavigationIndex = index;
        _clearOrCloseSearchBar(context, true);

        if (getSelectedPage().getGlobalKey().currentState == null) {
          // If the destination page state is not initialized yet we need to call the handler callback later manually
          Timer(Duration(seconds: 1), () {
            final selectedPageState = getSelectedPage().getGlobalKey().currentState;
            if (selectedPageState != null) {
              debugPrint("explicit call notification handler on $selectedPageState");
              selectedPageState.handleNotificationClicked(receiverKey, payload);
            }
          });
        }
      });
    }
  }
}
