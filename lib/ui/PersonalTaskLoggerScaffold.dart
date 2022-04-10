
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personaltasklogger/service/LocalNotificationService.dart';
import 'package:personaltasklogger/service/PreferenceService.dart';
import 'package:personaltasklogger/ui/pages/QuickAddTaskEventPage.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';
import 'package:personaltasklogger/ui/pages/ScheduledTaskList.dart';
import 'package:personaltasklogger/ui/pages/TaskTemplateList.dart';

import '../main.dart';
import 'dialogs.dart';
import 'forms/TaskEventForm.dart';
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

final DEFAULT_SELECTED_NAVIGATION_PAGE_INDEX = 1;

class PersonalTaskLoggerScaffoldState extends State<PersonalTaskLoggerScaffold> {
  int _selectedNavigationIndex = DEFAULT_SELECTED_NAVIGATION_PAGE_INDEX;
  PageController _pageController = PageController(initialPage: DEFAULT_SELECTED_NAVIGATION_PAGE_INDEX);

  TextEditingController _searchQueryController = TextEditingController();
  String? _searchString;

  late List<PageScaffold> _pages;
  final _notificationService = LocalNotificationService();
  final _preferenceService = PreferenceService();

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
    _notificationService.addNotificationClickedHandler(sendEventFromClicked);
    _notificationService.addActiveNotificationHandler(sendEventFromActiveNotification);
    _notificationService.handleAppLaunchNotification();

    //this is a hack since this is QuickAdd related code here
    _preferenceService.getBool(PREF_PIN_QUICK_ADD).then((pinQuickAddPage) {
      if (pinQuickAddPage == true && _selectedNavigationIndex != 3) { // only if current is not the Schdule Page
        setState(() {
          _selectedNavigationIndex = 0;
          _pageController.jumpToPage(_selectedNavigationIndex);
        });
      }
    });
  }



  PageScaffold getSelectedPage() {
    return _pages.elementAt(_selectedNavigationIndex);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
               color: Colors.green[50],
              ),
              child: Text(APP_NAME,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Website'),
              onTap: () {
                Navigator.pop(context);
                _launchUrl("https://everydaytasks.jepfa.de");
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () async {
                Navigator.pop(context);
                final packageInfo = await PackageInfo.fromPlatform();
                final version = packageInfo.version;
                final build = packageInfo.buildNumber;

                showConfirmationDialog(
                    context,
                    "About Everyday Tasks",
                    "Everyday Tasks is an app to log, track and schedule daily tasks."
                        "\n\n© Jens Pfahl 2022"
                        "\n\nVersion $version:$build",

                    okPressed: () =>  Navigator.pop(context),
                );
              },
            ),
          ],
        ),
      ),
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
    _notificationService.removeNotificationClickedHandler(sendEventFromClicked);
    _notificationService.removeActiveNotificationHandler(sendEventFromActiveNotification);
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
      Timer.periodic(Duration(milliseconds: 100), (timer) {
          var selectedPageState = getSelectedPage().getGlobalKey().currentState;
          if (selectedPageState != null) {
            timer.cancel();
            debugPrint("refresh ui state $selectedPageState");
            setState(() {
              // refresh
            });
          }
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

  sendEventFromActiveNotification(int id, String? channelId) {
    debugPrint("sendEventFromActiveNotification $id $channelId");

    //this is a hack. The tracking specific code should not live here but it works for now.
    if (id == TRACKING_NOTIFICATION_ID) {
      _preferenceService.getString(getPrefKeyFromTrackingId()).then((payload) {
        if (payload != null) {
          // simulate click on notification
          sendEventFromClicked(TASK_EVENT_LIST_ROUTING_KEY, true, payload);
        }
      });
    }
  }

  sendEventFromClicked(String receiverKey, bool isAppLaunch, String payload) {
    debugPrint("sendEventFromClicked $receiverKey $payload");

    var onlyWhenAppLaunchIndicator = "";
    if (payload.startsWith("onlyWhenAppLaunch")) {
      final index = payload.indexOf("-");
      if (index != -1) {
        onlyWhenAppLaunchIndicator = payload.substring(0, index);
        payload = payload.substring(index + 1);
      }
    }

    final onlyWhenAppLaunch = onlyWhenAppLaunchIndicator == "onlyWhenAppLaunch:true" ? isAppLaunch : true;
    final index = _pages.indexWhere((page) => page.getRoutingKey() == receiverKey);
    if (onlyWhenAppLaunch && index != -1) {
      _pageController.jumpToPage(index);
      setState(() {
        _selectedNavigationIndex = index;
        _clearOrCloseSearchBar(context, true);

        final selectedPageState = getSelectedPage().getGlobalKey().currentState;
        if (selectedPageState != null) {
          debugPrint("explicit call notification handler on $selectedPageState");
          selectedPageState.handleNotificationClickRouted(isAppLaunch, payload);
        }
        else {
          // If the destination page state is not initialized yet we need to call the handler callback later manually
          Timer.periodic(Duration(milliseconds: 100), (timer) {
            final selectedPageState = getSelectedPage().getGlobalKey().currentState;
            if (selectedPageState != null) {
              timer.cancel();
              debugPrint("delayed call notification handler on $selectedPageState");
              selectedPageState.handleNotificationClickRouted(isAppLaunch, payload);
            }
          });
        }
      });
    }
  }

  void _launchUrl(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
    else {
      debugPrint("Could not launch $url");
    }
  }
}
