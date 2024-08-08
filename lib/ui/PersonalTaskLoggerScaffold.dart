
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/service/BackupRestoreService.dart';
import 'package:personaltasklogger/service/CsvService.dart';
import 'package:personaltasklogger/service/LocalNotificationService.dart';
import 'package:personaltasklogger/service/PreferenceService.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerApp.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';
import 'package:personaltasklogger/ui/pages/QuickAddTaskEventPage.dart';
import 'package:personaltasklogger/ui/pages/ScheduledTaskList.dart';
import 'package:personaltasklogger/ui/pages/TaskTemplateList.dart';
import 'package:personaltasklogger/ui/utils.dart';
import 'package:showcaseview/showcaseview.dart';

import '../db/repository/TaskEventRepository.dart';
import '../db/repository/TaskGroupRepository.dart';
import '../main.dart';
import '../service/DueScheduleCountService.dart';
import 'pages/CalendarPage.dart';
import 'pages/SettingsScreen.dart';
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

GlobalKey<PersonalTaskLoggerScaffoldState> appScaffoldKey = GlobalKey();

class PersonalTaskLoggerScaffold extends StatefulWidget {

  PersonalTaskLoggerScaffold(): super(key: appScaffoldKey);

  @override
  State<StatefulWidget> createState() {
    return PersonalTaskLoggerScaffoldState();
  }
}

final NAVIGATION_IDX_QUICKADD = 0;
final NAVIGATION_IDX_TASK_EVENTS = 1;
final NAVIGATION_IDX_TASK_SCHEDULES = 2;
final NAVIGATION_IDX_TEMPLATES = 3;
final DEFAULT_SELECTED_NAVIGATION_PAGE_INDEX = NAVIGATION_IDX_TASK_EVENTS;

GlobalKey showcaseFloatingButton = GlobalKey();
GlobalKey showcaseQuickAddIcon = GlobalKey();
GlobalKey showcaseJournalIcon = GlobalKey();
GlobalKey showcaseSchedulesIcon = GlobalKey();
GlobalKey showcaseTasksIcon = GlobalKey();
GlobalKey showcaseExtensionsIcon = GlobalKey();


class PersonalTaskLoggerScaffoldState extends State<PersonalTaskLoggerScaffold> {


  int _selectedNavigationIndex = DEFAULT_SELECTED_NAVIGATION_PAGE_INDEX;
  PageController _pageController = PageController(initialPage: DEFAULT_SELECTED_NAVIGATION_PAGE_INDEX);

  TextEditingController _searchQueryController = TextEditingController();
  String? _searchString;

  late List<PageScaffold> _pages;
  final _notificationService = LocalNotificationService();
  final _preferenceService = PreferenceService();
  final _backupRestoreService = BackupRestoreService();
  late Timer _scheduleBadgeTimer;

  var _showBanner = false;
  final _calendarDragScrollController = DraggableScrollableController();

  final PagesHolder _pagesHolder = PagesHolder();


  PersonalTaskLoggerScaffoldState() {

    final quickAddTaskEventPage = QuickAddTaskEventPage(_pagesHolder);
    final taskEventList = TaskEventList(_pagesHolder);
    final taskTemplateList = TaskTemplateList(_pagesHolder);
    final scheduledTaskList = ScheduledTaskList(_pagesHolder);
    _pagesHolder.init(quickAddTaskEventPage, taskEventList, taskTemplateList, scheduledTaskList);

    // order is important here
    _pages = <PageScaffold>[quickAddTaskEventPage, taskEventList, scheduledTaskList, taskTemplateList];
  }

  @override
  void initState() {
    super.initState();
    _notificationService.addNotificationClickedHandler(sendEventFromClicked);
    _notificationService.addActiveNotificationHandler(sendEventFromActiveNotification);
    _notificationService.handleAppLaunchNotification((ids) {
      if (!ids.contains(TRACKING_NOTIFICATION_ID)) {
        // don't jump to another if tracking is active
        //this is a hack since this is QuickAdd/ScheduledTask related code here
        _preferenceService.getBool(PREF_PIN_QUICK_ADD).then((pinQuickAddPage) {
          if (pinQuickAddPage == true && _selectedNavigationIndex != NAVIGATION_IDX_TASK_SCHEDULES) { // only if current is not the Schedule Page
            setState(() {
              _selectedNavigationIndex = NAVIGATION_IDX_QUICKADD;
              _pageController.jumpToPage(_selectedNavigationIndex);
            });
          }
          else _preferenceService.getBool(PREF_PIN_SCHEDULES).then((pinSchedulesPage) {
            if (pinSchedulesPage == true && _selectedNavigationIndex != NAVIGATION_IDX_TASK_SCHEDULES) { // only if current is not the Schedule Page
              setState(() {
                _selectedNavigationIndex = NAVIGATION_IDX_TASK_SCHEDULES;
                _pageController.jumpToPage(_selectedNavigationIndex);
              });
            }
          });
        });
      }
    }); // here all handlers are invoked


    _preferenceService.getBool(PreferenceService.DATA_WALKTHROUGH_SHOWN).then((value) {
      if (value == null || value == false) {
        TaskEventRepository.count().then((count) {
          if (count == null || count == 0) {
            setState(() => _showBanner = true);
          }
        });
      }
    });

    DueScheduleCountService().gather();
    _scheduleBadgeTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      DueScheduleCountService().gather();
    });

    _notificationService.requestPermissions();
  }

  PageScaffold getSelectedPage() {
    return _pages.elementAt(_selectedNavigationIndex);
  }

  @override
  Widget build(BuildContext context) {

    return ShowCaseWidget(
      blurValue: 0.5,
      onFinish: () {
        setState(() {
          _dismissShowcaseBanner();
        });
      },
      builder: (context) {
        return Scaffold(
          drawer: _isSearching ? null : SizedBox(
            width: 250,
            child: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(
                    height: 150,
                    child: DrawerHeader(
                      decoration: BoxDecoration(
                        color: PRIMARY_COLOR,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: Column(
                          children: [
                            Text(""),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Row(
                                children: [
                                  Text(APP_NAME,
                                    style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black
                                    ),
                                  ),
                                  Icon(Icons.task_alt, color: ACCENT_COLOR),
                                ],
                              ),
                            ),
                            Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                    translate('navigation.header_subtitle'),
                                    style: TextStyle(color: Colors.grey[700]))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: Text(translate('navigation.menus.settings')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(super.context, MaterialPageRoute(
                          builder: (context) => SettingsScreen()))
                          .then((_) {
                        setState(() {
                          getSelectedPage()
                              .getGlobalKey()
                              .currentState
                              ?.setState(() {
                            // refresh current page
                            debugPrint("refresh ..");
                          });
                          _pages.forEach((page) {
                            page
                                .getGlobalKey()
                                .currentState
                                ?.reload();
                          });
                        });
                      });
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: const Icon(Icons.import_export),
                    title: Text(translate('navigation.menus.export_as_csv')),
                    onTap: () async {
                      Navigator.pop(context);

                      showConfirmationDialog(context,
                          translate('navigation.menus.export_as_csv'),
                          translate('pages.export.description'),
                          cancelPressed: () => Navigator.pop(context),
                          okPressed: () {
                            Navigator.pop(context);
                            CsvService().backup(context,
                                    (success, dstPath) {
                                  if (success) {
                                    toastInfo(context, translate(
                                        'pages.export.export_created',
                                        args: {'dst_path': dstPath}));
                                  }
                                  else {
                                    toastInfo(context, translate(
                                        'pages.export.export_aborted'));
                                  }
                                }, (errorMsg) => toastError(context, errorMsg));
                          }
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.save_alt_outlined),
                    title: Text(translate('navigation.menus.backup_as_file')),
                    onTap: () async {
                      Navigator.pop(context);

                      showConfirmationDialog(context,
                          translate('navigation.menus.backup_as_file'),
                          translate('pages.backup.description'),
                          cancelPressed: () => Navigator.pop(context),
                          okPressed: () {
                            Navigator.pop(context);

                            _backupRestoreService.backup(
                                    (success, dstPath) {
                                  if (success) {
                                    toastInfo(context, translate(
                                        'pages.backup.backup_created',
                                        args: {'dst_path': dstPath}));
                                  }
                                  else {
                                    toastInfo(context, translate(
                                        'pages.backup.backup_aborted'));
                                  }
                                }, (errorMsg) => toastError(context, errorMsg));
                          }
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: Text(
                        translate('navigation.menus.restore_from_file')),
                    onTap: () async {
                      Navigator.pop(context);
                      showConfirmationDialog(
                          context, translate('pages.restore.dialog.title'),
                          translate('pages.restore.dialog.message'),
                          icon: const Icon(Icons.warning_amber_outlined),
                          cancelPressed: () => Navigator.pop(context),
                          okPressed: () async {
                            Navigator.pop(context);
                            await _backupRestoreService.restore((
                                success) async {
                              if (success) {
                                await TaskGroupRepository.loadAll(
                                    true); // load caches

                                toastInfo(context,
                                    translate('pages.restore.backup_restored'));
                                setState(() {
                                  _pages.forEach((page) {
                                    page
                                        .getGlobalKey()
                                        .currentState
                                        ?.reload();
                                  });
                                });
                              }
                              else {
                                toastInfo(context,
                                    translate('pages.restore.restore_aborted'));
                              }
                            }, (errorMsg) => toastError(context, errorMsg));
                          });
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: const Icon(Icons.run_circle_outlined),
                    title: Text(translate('navigation.menus.start_app_walk')),
                    onTap: () {
                      Navigator.pop(context);
                      _startAppWalkThrough(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: Text(translate('navigation.menus.online_help')),
                    onTap: () {
                      Navigator.pop(context);
                      launchUrl("https://everydaytasks.jepfa.de");
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(translate('navigation.menus.about_the_app')),
                    onTap: () async {
                      Navigator.pop(context);
                      final packageInfo = await PackageInfo.fromPlatform();
                      final version = packageInfo.version;

                      showAboutDialog(
                        context: context,
                        applicationVersion: version,
                        applicationName: APP_NAME,
                        children: [
                          Text(translate('pages.about.message')),
                          Text(''),
                          InkWell(
                              child: Text.rich(
                                TextSpan(
                                  text: translate('pages.about.star_it',
                                      args: {"link": ""}),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: "github.com/jenspfahl/EverydayTasks",
                                        style: TextStyle(
                                            decoration: TextDecoration
                                                .underline)),
                                  ],
                                ),
                              ),
                              onTap: () {
                                launchUrl(
                                    "https://github.com/jenspfahl/EverydayTasks");
                              }),
                          Divider(),
                          Text('© Jens Pfahl 2022 - 2024',
                              style: TextStyle(fontSize: 12)),
                        ],
                        applicationIcon: Icon(Icons.task_alt,
                            color: ACCENT_COLOR),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: const Icon(Icons.translate),
                    title: Text(translate('navigation.menus.help_translate')),
                    onTap: () async {
                      Navigator.pop(context);
                      launchUrl(
                          "https://github.com/jenspfahl/EverydayTasks/blob/master/TRANSLATE.md");
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: Text(translate('navigation.menus.report_a_bug')),
                    onTap: () async {
                      Navigator.pop(context);
                      final packageInfo = await PackageInfo.fromPlatform();
                      final version = packageInfo.version;
                      final build = packageInfo.buildNumber;

                      final title = Uri.encodeComponent(
                          "A bug in version $version ($build)");
                      final body = Uri.encodeComponent("Please describe ..");
                      launchUrl(
                          "https://github.com/jenspfahl/EverydayTasks/issues/new?title=$title&body=$body");
                    },
                  ),
                ],
              ),
            ),
          ),
          appBar: AppBar(
            title: _isSearching ? _buildSearchField() : getSelectedPage()
                .getTitle(),
            actions: _buildActions(context),
          ),
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (newIndex) {
                  setState(() {
                    _selectedNavigationIndex = newIndex;
                    _clearOrCloseSearchBar(context, true);
                  });
                },
                children: _pages,
              ),
              Visibility(
                visible: _showBanner,
                child: SizedBox(
                  child: Container(
                    child: MaterialBanner(
                      // backgroundColor: Colors.transparent,
                        elevation: 3,
                        content: Text(translate('walk_through.banner.text')),
                        actions: [
                          TextButton(
                            onPressed: () {
                              _startAppWalkThrough(context);
                            },
                            child: Text(
                                translate('walk_through.banner.start_action')),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _dismissShowcaseBanner());
                            },
                            child: Text(translate(
                                'walk_through.banner.dismiss_action')),
                          ),
                        ]),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: MediaQuery
                        .of(context)
                        .size
                        .width / 4,
                    height: 150,
                    child: DraggableScrollableSheet(
                      controller: _calendarDragScrollController,
                      initialChildSize: 0.15,
                      minChildSize: 0.15,
                      maxChildSize: 0.5,
                      snap: true,
                      builder: (context, scrollController) {
                        return Container(
                          decoration: BoxDecoration(
                            color: PRIMARY_COLOR,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                            border: Border(
                              // left: BorderSide(), //TODO doesn't work
                              //right: BorderSide(color: Colors.black54, width: 1),
                              // top: BorderSide(color: Colors.black54, width: 1),
                            ),
                          ),
                          child: Showcase(
                            key: showcaseExtensionsIcon,
                            title: translate('walk_through.extensions.title'),
                            description: translate(
                                'walk_through.extensions.description'),
                            targetPadding: EdgeInsets.all(8),
                            overlayOpacity: showcaseOpacity,
                            child: ListView(
                              controller: scrollController,
                              children: [
                                Icon(Icons.drag_handle, color: Colors.black38),
                                Container(
                                  color: isDarkMode(context) ? null : Colors
                                      .white54,
                                  child: IconButton(
                                    icon: Icon(Icons.calendar_month_sharp,
                                      color: Colors.black54,),
                                    onPressed: () {
                                      _calendarDragScrollController.animateTo(
                                          0.15, duration: const Duration(
                                          milliseconds: 100),
                                          curve: Curves.easeOutBack);
                                      Navigator.push(super.context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  CalendarPage(_pagesHolder)))
                                          .then((_) {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation
              .centerDocked,
          floatingActionButton: Showcase(
            key: showcaseFloatingButton,
            title: translate('walk_through.action_button.title'),
            description: translate('walk_through.action_button.description'),
            targetPadding: EdgeInsets.all(8),
            overlayOpacity: showcaseOpacity,
            child: FloatingActionButton(
              onPressed: () {
                getSelectedPage()
                    .getGlobalKey()
                    .currentState
                    ?.handleFABPressed(context);
              },
              child: getSelectedPage().getIcon(),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            showSelectedLabels: true,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Showcase(
                  key: showcaseQuickAddIcon,
                  title: translate('walk_through.quick_add.title'),
                  description: translate('walk_through.quick_add.description'),
                  targetPadding: EdgeInsets.all(16),
                  overlayOpacity: showcaseOpacity,
                  child: Icon(Icons.add_circle_outline_outlined),
                ),
                label: translate('pages.quick_add.title'),
              ),
              BottomNavigationBarItem(
                icon: Showcase(
                  key: showcaseJournalIcon,
                  title: translate('walk_through.journal.title'),
                  description: translate('walk_through.journal.description'),
                  targetPadding: EdgeInsets.all(16),
                  overlayOpacity: showcaseOpacity,
                  child: Icon(Icons.event_available_rounded),
                ),
                label: translate('pages.journal.title'),
              ),
              BottomNavigationBarItem(
                icon: Showcase(
                  key: showcaseSchedulesIcon,
                  title: translate('walk_through.schedules.title'),
                  description: translate('walk_through.schedules.description'),
                  targetPadding: EdgeInsets.all(16),
                  overlayOpacity: showcaseOpacity,
                  child: ValueListenableBuilder<int>(
                    valueListenable: DueScheduleCountService().count,

                    builder: (BuildContext context, int value, Widget? child) {
                      return Badge(
                        isLabelVisible: DueScheduleCountService()
                            .shouldShowIndicatorValue(),
                        child: Icon(Icons.next_plan_outlined),
                        label: Text("$value"),
                        textColor: Colors.white,
                        backgroundColor: Colors.red,
                      );
                    },
                  ),
                ),
                label: translate('pages.schedules.title'),
              ),
              BottomNavigationBarItem(
                icon: Showcase(
                  key: showcaseTasksIcon,
                  title: translate('walk_through.tasks.title'),
                  description: translate('walk_through.tasks.description'),
                  targetPadding: EdgeInsets.all(16),
                  overlayOpacity: showcaseOpacity,
                  child: Icon(Icons.task_alt),
                ),
                label: translate('pages.tasks.title'),
              ),
            ],
            selectedItemColor: ACCENT_COLOR,
            unselectedItemColor: Colors.grey.shade600,
            currentIndex: _selectedNavigationIndex,
            onTap: (index) {
              _pageController.animateToPage(
                  index, duration: Duration(milliseconds: 300),
                  curve: Curves.ease);
            },
          ),
        );
      }
    );
  }

  double get showcaseOpacity => isDarkMode(context) ? 0.6 : 0.2;

  _dismissShowcaseBanner() {
    _preferenceService.setBool(PreferenceService.DATA_WALKTHROUGH_SHOWN, true);
    _showBanner = false;
  }

  @override
  void deactivate() {
    _notificationService.removeNotificationClickedHandler(sendEventFromClicked);
    _notificationService.removeActiveNotificationHandler(sendEventFromActiveNotification);
    _scheduleBadgeTimer.cancel();
    super.deactivate();
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchQueryController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: "${translate('common.search')} ...",
        border: InputBorder.none,
        hintStyle: TextStyle(fontSize: 16.0, color: Colors.black45),
      ),
      style: TextStyle(fontSize: 16.0, color: Colors.black),
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

    if (_isSearching) {
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
    ModalRoute.of(this.context)!
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

    // detect an active TRACKING notification to determine there is an ongoing tracking
    //this is a hack. The tracking specific code should not live here but it works for now.
    if (id == TRACKING_NOTIFICATION_ID) {
      _preferenceService.getString(getPrefKeyFromTrackingId()).then((payload) {
        if (payload != null) {
          // simulate click on notification
          sendEventFromClicked(TASK_EVENT_LIST_ROUTING_KEY, true, payload, null);
        }
      });
    }
  }

  sendEventFromClicked(String receiverKey, bool isAppLaunch, String payload, String? actionId) {
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
        _clearOrCloseSearchBar(this.context, true);

        final selectedPageState = getSelectedPage().getGlobalKey().currentState;
        if (selectedPageState != null) {
          debugPrint("explicit call notification handler on $selectedPageState");
          selectedPageState.handleNotificationClickRouted(isAppLaunch, payload, actionId);
        }
        else {
          // If the destination page state is not initialized yet we need to call the handler callback later manually
          Timer.periodic(Duration(milliseconds: 100), (timer) {
            final selectedPageState = getSelectedPage().getGlobalKey().currentState;
            if (selectedPageState != null) {
              timer.cancel();
              debugPrint("delayed call notification handler on $selectedPageState");
              selectedPageState.handleNotificationClickRouted(isAppLaunch, payload, actionId);
            }
          });
        }
      });
    }
  }

  get _isSearching => _searchString != null;

  void _startAppWalkThrough(BuildContext context) {
    ShowCaseWidget.of(context).startShowCase([
      showcaseFloatingButton,
      showcaseJournalIcon,
      showcaseQuickAddIcon,
      showcaseSchedulesIcon,
      showcaseTasksIcon,
      showcaseExtensionsIcon,
    ]);
  }

}
