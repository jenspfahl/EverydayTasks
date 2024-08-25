import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:personaltasklogger/db/repository/ChronologicalPaging.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskRepository.dart';
import 'package:personaltasklogger/model/Schedule.dart';
import 'package:personaltasklogger/model/ScheduledTask.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/service/DueScheduleCountService.dart';
import 'package:personaltasklogger/service/LocalNotificationService.dart';
import 'package:personaltasklogger/service/PreferenceService.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/forms/ScheduledTaskForm.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';
import 'package:personaltasklogger/util/dates.dart';
import 'package:personaltasklogger/util/extensions.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../db/repository/TaskGroupRepository.dart';
import '../../util/units.dart';
import '../components/ScheduledTaskWidget.dart';
import '../components/ToggleActionIcon.dart';
import '../utils.dart';
import 'PageScaffoldState.dart';
import 'QuickAddTaskEventPage.dart';


final String PREF_DISABLE_NOTIFICATIONS = "scheduledTasks/disableNotifications";
final String PREF_SORT_BY = "scheduledTasks/sortedBy";
final String PREF_HIDE_INACTIVE = "scheduledTasks/hideInactive";
final String PREF_IMPORTANT_ON_TOP = "scheduledTasks/importantOnTop";
final String PREF_PIN_SCHEDULES = "scheduledTasks/pinPage";

final pinSchedulesPageIconKey = new GlobalKey<ToggleActionIconState>();
final disableNotificationIconKey = new GlobalKey<ToggleActionIconState>();
final SCHEDULED_TASK_LIST_ROUTING_KEY = "ScheduledTasks";

@immutable
class ScheduledTaskList extends PageScaffold<ScheduledTaskListState> {

  final PagesHolder _pagesHolder;

  ScheduledTaskList(this._pagesHolder);

  @override
  State<StatefulWidget> createState() => ScheduledTaskListState();

  @override
  Widget getTitle() {
    return Text(translate('pages.schedules.title'));
  }

  @override
  Icon getIcon() {
    return Icon(Icons.next_plan_outlined);
  }

  @override
  bool withSearchBar() {
    return false;
  }

  @override
  String getRoutingKey() {
    return SCHEDULED_TASK_LIST_ROUTING_KEY;
  }
}

enum SortBy {PROGRESS, REMAINING_TIME, GROUP, TITLE,}

enum GroupCriteria {
  NOT_DUE, 
  DUE_TOMORROW,  // only available when sort by remaining time
  DUE_AFTER_TOMORROW,  // only available when sort by remaining time
  DUE_TODAY, // only available when sort by remaining time
  DUE, 
  DUE_SINCE_YESTERDAY, // only available when sort by remaining time
  DUE_AND_IMPORTANT,
  PAUSED,
  INACTIVE,
  COMPLETED
}

class ScheduledTaskListState extends PageScaffoldState<ScheduledTaskList> with AutomaticKeepAliveClientMixin<ScheduledTaskList> {

  final _listScrollController = AutoScrollController(suggestedRowHeight: 40);

  Set<GroupCriteria> _hiddenTiles = Set();

  List<ScheduledTask> _scheduledTasks = [];
  bool _initialLoaded = false;
  int? _selectedTileId;
  bool _disableNotification = false;
  SortBy _sortBy = SortBy.PROGRESS;
  bool _hideInactive = false;
  bool _importantOnTop = true;
  bool _statusTileHidden = true;
  bool _pinSchedulesPage = false;

  int _totalRunningSchedules = 0;
  int _totalDueSchedules = 0;
  int _totalOverdueSchedules = 0;
  int _dueBeforeTodaySchedules = 0;
  int _dueAndImportantSchedules = 0;
  int _dueTodaySchedules = 0;
  int _dueTomorrowSchedules = 0;
  int _dueAfterTomorrowSchedules = 0;
  int _pausedSchedules = 0;
  int _inactiveSchedules = 0;

  final _notificationService = LocalNotificationService();
  final _preferenceService = PreferenceService();

  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _preferenceService.getInt(PREF_SORT_BY).then((value) {
      if (value != null) {
        setState(() {
          _sortBy = SortBy.values.elementAt(value);
        });
      }
    });

    _preferenceService.getBool(PREF_HIDE_INACTIVE).then((value) {
      if (value != null) {
        setState(() {
          _hideInactive = value;
        });
      }
    });

    _preferenceService.getBool(PREF_IMPORTANT_ON_TOP).then((value) {
      if (value != null) {
        setState(() {
          _importantOnTop = value;
        });
      }
    });

    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      setState(() {
        // update all
        _sortList();
        _calcOverallStats();
        debugPrint(".. ST timer refresh #${_timer.tick} ..");
      });
    });

    _loadSchedules(rescheduleNotification: false); // reschedule is done after loading global notification disabled preference

    Permission.notification.request().then((status) {
      debugPrint("notification permission = $status");
      if (status == PermissionStatus.denied) {
        toastInfo(context, translate("system.notifications.denied_permission_message"));
      }
    });

  }

  void _loadSchedules({required bool rescheduleNotification}) {
    final paging = ChronologicalPaging(ChronologicalPaging.maxDateTime, ChronologicalPaging.maxId, 10000);
    ScheduledTaskRepository.getAllPaged(paging).then((scheduledTasks) {
      setState(() {
        _scheduledTasks = scheduledTasks;
        _initialLoaded = true;
        _sortList();
        _calcOverallStats();
        if (rescheduleNotification) {
          _rescheduleAllSchedules();
        }
        _preferenceService.getBool(PreferenceService.DATA_SHOW_SCHEDULED_SUMMARY)
            .then((value) {
              if (value != null) {
                setState(() => _statusTileHidden = !value);
              }
        });
    
      });
    });
  }

  @override
  reload() {
    _notificationService.cancelAllNotifications().then((value) {
      _loadSchedules(rescheduleNotification: true);
    });
    DueScheduleCountService().gather();
  }

  @override
  void searchQueryUpdated(String? searchQuery) {
  }

  @override
  List<Widget>? getActions(BuildContext context) {
    final pinSchedulesPage = ToggleActionIcon(Icons.push_pin, Icons.push_pin_outlined, _pinSchedulesPage, pinSchedulesPageIconKey);
    final disableNotificationIcon = ToggleActionIcon(Icons.notifications_on_outlined, Icons.notifications_off_outlined, !_disableNotification, disableNotificationIconKey);

    _preferenceService.getBool(PREF_PIN_SCHEDULES).then((value) {
      if (value != null) {
        _updatePinSchedulesPage(value, withSnackMsg: false);
      }
      else {
        pinSchedulesPageIconKey.currentState?.refresh(_pinSchedulesPage);
      }
    });
    _preferenceService.getBool(PREF_DISABLE_NOTIFICATIONS).then((value) {
        _updateDisableNotifications(value??false, withSnackMsg: false);
    });
    
    return [
      IconButton(
          icon: pinSchedulesPage,
          onPressed: () {
            _pinSchedulesPage = !_pinSchedulesPage;
            _updatePinSchedulesPage(_pinSchedulesPage, withSnackMsg: true);
          }),
      IconButton(
          icon: disableNotificationIcon,
          onPressed: () {
            _updateDisableNotifications(!_disableNotification, withSnackMsg: true);
          }),
      GestureDetector(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(Icons.sort_outlined)),
        onTapDown: (details) {
          showPopUpMenuAtTapDown(
              context,
              details,
              [
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          createCheckIcon(_sortBy == SortBy.PROGRESS),
                          const Spacer(),
                          Text(translate('pages.schedules.menu.sorting.by_progress')),
                        ]
                    ),
                    value: '1'),
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          createCheckIcon(_sortBy == SortBy.REMAINING_TIME),
                          const Spacer(),
                          Text(translate('pages.schedules.menu.sorting.by_remaining_time')),
                        ]
                    ),
                    value: '2'),
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          createCheckIcon(_sortBy == SortBy.GROUP),
                          const Spacer(),
                          Text(translate('pages.schedules.menu.sorting.by_category')),
                        ]
                    ),
                    value: '3'),
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          createCheckIcon(_sortBy == SortBy.TITLE),
                          const Spacer(),
                          Text(translate('pages.schedules.menu.sorting.by_title')),
                        ]
                    ),
                    value: '4'),
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          Checkbox(
                            value: _hideInactive,
                            onChanged: (value) {
                              if (value != null) {
                                _updateSortBy(_sortBy, !_hideInactive, _importantOnTop);
                                Navigator.of(context).pop();
                              }
                            },
                            visualDensity: VisualDensity(horizontal: VisualDensity.minimumDensity, vertical: 0.0),
                          ),
                          const Spacer(),
                          Text(translate('pages.schedules.menu.sorting.hide_non_active')),
                        ]
                    ),
                    value: '5'),
                if (_sortBy == SortBy.PROGRESS || _sortBy == SortBy.REMAINING_TIME)
                  PopupMenuItem<String>(
                      child: Row(
                          children: [
                            Checkbox(
                              value: _importantOnTop,
                              onChanged: (value) {
                                if (value != null) {
                                  _updateSortBy(_sortBy, _hideInactive, !_importantOnTop);
                                  Navigator.of(context).pop();
                                }
                              },
                              visualDensity: VisualDensity(horizontal: VisualDensity.minimumDensity, vertical: 0.0),
                            ),
                            const Spacer(),
                            Text(translate('pages.schedules.menu.sorting.important_on_top')),
                          ]
                      ),
                      value: '6'),


              ]
          ).then((selected) {
            switch (selected) {
              case '1' :
                {
                  _updateSortBy(SortBy.PROGRESS, _hideInactive, _importantOnTop);
                  break;
                }
              case '2' :
                {
                  _updateSortBy(SortBy.REMAINING_TIME, _hideInactive, _importantOnTop);
                  break;
                }
              case '3' :
                {
                  _updateSortBy(SortBy.GROUP, _hideInactive, _importantOnTop);
                  break;
                }
              case '4' :
                {
                  _updateSortBy(SortBy.TITLE, _hideInactive, _importantOnTop);
                  break;
                }
              case '5' :
                {
                  _updateSortBy(_sortBy, !_hideInactive, _importantOnTop);
                  break;
                }
              case '6' :
                {
                  _updateSortBy(_sortBy, _hideInactive, !_importantOnTop);
                  break;
                }
            }
          });
        },
      ),
    ];
  }

  void _updateDisableNotifications(bool value, {required bool withSnackMsg}) {
    setState(() {
      _disableNotification = value;
      disableNotificationIconKey.currentState?.refresh(!_disableNotification);
      if (_disableNotification) {
        _notificationService.cancelAllNotifications();
        if (withSnackMsg) {
          toastInfo(context, translate('pages.schedules.menu.notifications.disabled'));
        }

      }
      else {
        _rescheduleAllSchedules();
        if (withSnackMsg) {
          toastInfo(context, translate('pages.schedules.menu.notifications.enabled'));
        }
      }
      _preferenceService.setBool(PREF_DISABLE_NOTIFICATIONS, _disableNotification);
    });
  }

  void _rescheduleAllSchedules() {
    _scheduledTasks.forEach((scheduledTask) =>
        _rescheduleNotification(scheduledTask,
            withCancel: false,
            withCancelFixedMode: scheduledTask.schedule.repetitionMode == RepetitionMode.FIXED)
    );
  }

  @override
  void handleFABPressed(BuildContext context) {
    _onFABPressed();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildList();
  }
  
  @override
  void deactivate() {
    _timer.cancel();
    super.deactivate();
  }

  void updateScheduledTaskFromEvent(ScheduledTask scheduledTask) {
    debugPrint("received scheduledTaskId:" + scheduledTask.id.toString());
    setState(() {
      final found = _scheduledTasks.firstWhereOrNull((element) => element.id == scheduledTask.id);
      debugPrint("found in list: " + found.toString());
      if (found != null) {
        var index = _scheduledTasks.indexOf(found);
        debugPrint("index in list: " + index.toString());
        if (index != -1) {
          _scheduledTasks.removeAt(index);
          _scheduledTasks.insert(index, scheduledTask);
          debugPrint("exchanged: " + scheduledTask.lastScheduledEventOn.toString());
          _sortList();
        }
      }
    });
  }

  Widget _buildList() {

    final statusTile = Column(
      children: [
        TextButton(
          style: ButtonStyle(
            alignment: Alignment.centerLeft,
            visualDensity: VisualDensity.compact,
            padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.zero),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                Text(
                  "${Schedules(_totalRunningSchedules).toStringWithAdjective(translate('pages.schedules.overview.running'))}, $_totalDueSchedules ${translate('pages.schedules.overview.due')}, ${translate('common.words.thereof')} $_totalOverdueSchedules ${translate('pages.schedules.overview.overdue')}",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10.0,
                  ),
                ),
                Icon(
                  _statusTileHidden ? Icons.arrow_drop_down_sharp : Icons.arrow_drop_up_sharp,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          onPressed: () {
            setState(() {
              _setStatusTileHidden(!_statusTileHidden);
            });
          },
        ),
        Visibility(
          visible: !_statusTileHidden,
          child: GestureDetector(
            child: Column(
              children: [
                if (_importantOnTop) _createStatusRow(Icons.priority_high, Colors.red, translate('common.words.important').capitalize(), _dueAndImportantSchedules),
                _createStatusRow(Icons.warning_amber_outlined, Colors.red, translate('pages.schedules.overview.due_yesterday_and_before'), _dueBeforeTodaySchedules),
                _createStatusRow(Icons.warning_amber_outlined, Colors.red, translate('pages.schedules.overview.due_today'), _dueTodaySchedules),
                _createStatusRow(Icons.schedule, Colors.blue, translate('pages.schedules.overview.due_tomorrow'), _dueTomorrowSchedules),
                _createStatusRow(Icons.schedule, Colors.blue, translate('pages.schedules.overview.due_after_tomorrow'), _dueAfterTomorrowSchedules),
                _createStatusRow(Icons.pause, getActionIconColor(context), translate('pages.schedules.overview.paused_schedules'), _pausedSchedules),
                _createStatusRow(Icons.check_box_outline_blank, getActionIconColor(context), translate('pages.schedules.overview.inactive_schedules'), _inactiveSchedules),
                Divider(),
              ],
            ),
            onTapDown: (_) {
              setState(() {
                _setStatusTileHidden(true);
              });
            },
            onPanUpdate: (details) {
              if (details.delta.dy < 0) {
                setState(() {
                  _setStatusTileHidden(true);
                });
              }
            },
          ),
        ),
      ],
    );

    Map<GroupCriteria, int> groupCounters = HashMap();
    _scheduledTasks.forEach((scheduledTask) {
      final criteria = _getGroupingCriteria(scheduledTask, _sortBy, _importantOnTop);
      if (criteria != null) {
        if (_hideInactive && criteria == GroupCriteria.INACTIVE) {
          // don't count inactive if hidden
        }
        else {
          final counter = groupCounters[criteria];
          groupCounters[criteria] = (counter ?? 0) + 1;
        }
      }
    });

    return Padding(
        padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          children: [
            statusTile,
            Expanded(
              child: ListView.builder(
                  itemCount: _scheduledTasks.length,
                  controller: _listScrollController,
                  itemBuilder: (context, index) {
                    var scheduledTask = _scheduledTasks[index];
                    var previousScheduledTask = index > 0 ? _scheduledTasks[index - 1] : null;
                    var taskGroup = TaskGroupRepository.findByIdFromCache(scheduledTask.taskGroupId);
                    var row = _buildRow(index, scheduledTask, taskGroup);
                    final criteria = _getGroupingCriteria(scheduledTask, _sortBy, _importantOnTop);
                    final previousCriteria = previousScheduledTask != null
                        ? _getGroupingCriteria(previousScheduledTask, _sortBy, _importantOnTop)
                        : null;


                    if (criteria != null && previousCriteria != criteria) {
                      if (_hideInactive && criteria == GroupCriteria.INACTIVE) {
                        // don't count inactive if hidden
                      }
                      else {
                        final scheduleCount = Schedules(groupCounters[criteria] ?? 0);
  
                        row = Column(children: [
                          if (_statusTileHidden) Divider(),
                          _buildGroupHeader(criteria, scheduleCount),
                          row,
                        ]);
                      }
                    }

                    return AutoScrollTag(
                      key: ValueKey(index),
                      controller: _listScrollController,
                      index: index,
                      child: row,
                    );
                  }),
            ),
          ],
        ),
    );
  }

  Widget _buildGroupHeader(GroupCriteria criteria, Schedules scheduleCount) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 0, 0),
      child: TextButton(
          style: ButtonStyle(
            alignment: Alignment.centerLeft,
            visualDensity: VisualDensity.compact,
            padding: MaterialStateProperty.all<EdgeInsets>(
                EdgeInsets.zero),
          ),
          child: Row(
            children: [
              Text("${_translateCriteria(criteria).capitalize()} ($scheduleCount)",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10.0,
                ),
              ),
              Icon(
                _hiddenTiles.contains(criteria)
                    ? Icons.arrow_drop_down_sharp
                    : Icons.arrow_drop_up_sharp,
                color: Colors.grey,
              ),
            ],
          ),
          onPressed: () {
            setState(() {
              if (_hiddenTiles.contains(criteria)) {
                _hiddenTiles.remove(criteria);
              } else {
                _hiddenTiles.add(criteria);
              }
            });
          },
        ),
    );
  }

  Widget _createStatusRow(IconData iconData, Color color, String text, int data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(iconData, color: color),
          Spacer(),
          Text(text, style: TextStyle(color: color)),
          Spacer(),
          Text(data.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold)
          ),
        ],),
    );
  }

  handleNotificationClickRouted(bool isAppLaunch, String payload, String? actionId) {
    if (_initialLoaded) {
      _handleNotificationClicked(payload, actionId);
    }
    else {
      // wait until loaded
      Timer.periodic(Duration(milliseconds: 100), (timer) {
        if (_initialLoaded) {
          timer.cancel();
          debugPrint("jump to schedule after initial load");
          _handleNotificationClicked(payload, actionId);
        }
      });
    }
  }

  void _handleNotificationClicked(String payload, String? actionId) {
    setState(() {
      final notificationId = int.tryParse(payload);
      if (notificationId != null) {
        debugPrint("notificationId = $notificationId");
        int scheduleId = notificationId.abs(); // consider pre-notification
        // first remove mask for rescheduled notifications
        if (scheduleId >= SNOOZED_NOTIFICATION_ID_OFFSET) {
          scheduleId = scheduleId % SNOOZED_NOTIFICATION_ID_OFFSET;
        }
        // then remove mask for fixed further notifications
        if (scheduleId >= FIXED_SCHEDULE_NOTIFICATION_OFFSET) {
          scheduleId = int.parse(scheduleId.toString().substring(1));
        }

        debugPrint("scheduleId = $scheduleId");
        final clickedScheduledTask = _scheduledTasks.firstWhereOrNull((scheduledTask) => scheduledTask.id == scheduleId);
        if (clickedScheduledTask != null) {
          _updateSelectedTile(clickedScheduledTask);
          if (actionId == "track") {
            ScheduledTaskWidget.openAddJournalEntryFromSchedule(context, widget._pagesHolder, clickedScheduledTask);
          }
        }
      }
    });
  }

  Widget _buildRow(int index, ScheduledTask scheduledTask, TaskGroup taskGroup) {
    final isExpanded = scheduledTask.id == _selectedTileId;
    final criteria = _getGroupingCriteria(scheduledTask, _sortBy, _importantOnTop);

    if (_hideInactive && !scheduledTask.active) {
      return Container();
    }
    return Visibility(
      visible: criteria == null || !_hiddenTiles.contains(criteria),
      child: Padding(
          padding: EdgeInsets.all(4.0),
          child: ScheduledTaskWidget(scheduledTask,
            isInitiallyExpanded: isExpanded,
            shouldExpand: () => scheduledTask.id == _selectedTileId,
            onExpansionChanged: ((expanded) {
              setState(() {
                _selectedTileId = expanded ? scheduledTask.id : null;
              });
            }),
            pagesHolder: widget._pagesHolder,
            selectInListWhenChanged: true,
            isNotificationsEnabled: () => !_disableNotification,
          ),
      ),
    );
  }

  void _addScheduledTask(ScheduledTask scheduledTask) {
    setState(() {
      _scheduledTasks.add(scheduledTask);
      _sortList();
      _updateSelectedTile(scheduledTask);
      _rescheduleNotification(scheduledTask, withCancel: false);
      _calcOverallStats();
    });

  }

  void updateScheduledTask(ScheduledTask origin, ScheduledTask updated) {
    setState(() {
      final index = _scheduledTasks.indexOf(origin);
      if (index != -1) {
        _scheduledTasks.removeAt(index);
        _scheduledTasks.insert(index, updated);
      }
      _sortList();
      _updateSelectedTile(updated);
      _calcOverallStats();

      _rescheduleNotification(updated,
          withCancelFixedMode: origin.schedule.repetitionMode == RepetitionMode.FIXED);

    });

  }

  void _sortList() {
    _scheduledTasks..sort((s1, s2) {
      if (_sortBy == SortBy.PROGRESS) {
        if (_importantOnTop) {
          if (s1.important && s1.isDue() && !s2.important) {
            return -1;
          }
          else if (!s1.important && s2.important && s2.isDue()) {
            return 1;
          }
        }

        if (s1.active && !s2.active) {
          return -1;
        }
        else if (!s1.active && s2.active) {
          return 1;
        }

        if (s1.isOneTimeCompleted && !s2.isOneTimeCompleted) {
          return 1;
        }
        else if (!s1.isOneTimeCompleted && s2.isOneTimeCompleted) {
          return -1;
        }

        return _sortByProgress(s1, s2);
      }
      else if (_sortBy == SortBy.REMAINING_TIME) {
        if (_importantOnTop) {
          if (s1.important && s1.isDue() && !s2.important) {
            return -1;
          }
          else if (!s1.important && s2.important && s2.isDue()) {
            return 1;
          }
        }
        final n1 = s1.active ? s1.getNextSchedule() : null;
        final n2 = s2.active ? s2.getNextSchedule() : null;
        if (n1 == null && n2 != null) {
          return 1;
        }
        else if (n1 != null && n2 == null) {
          return -1;
        }
        else if (n1 == null && n2 == null) {
          return _sortByTitleAndId(s1, s2);
        }
        else if (s1.isOneTimeCompleted && !s2.isOneTimeCompleted) {
          return 1;
        }
        else if (!s1.isOneTimeCompleted && s2.isOneTimeCompleted) {
          return -1;
        }
        else if (s1.isPaused && !s2.isPaused) {
          return 1;
        }
        else if (!s1.isPaused && s2.isPaused) {
          return -1;
        }
        final c = n1!.compareTo(n2!);
        if (c == 0) {
          return _sortByProgress(s1, s2);
        }
        return c;
      }
      else if (_sortBy == SortBy.GROUP) {
        final g1 = s1.taskGroupId;
        final g2 = s2.taskGroupId;
        final c = g2.compareTo(g1);
        if (c == 0) {
          return _sortByTitleAndId(s1, s2);
        }
        return c;
      }
      else if (_sortBy == SortBy.TITLE) {
        return _sortByTitleAndId(s1, s2);
      }
      else {
        return s1.compareTo(s2);
      }
    });
  }

  int _sortByProgress(ScheduledTask s1, ScheduledTask s2) {
    final n1 = s1.active ? s1.getNextRepetitionIndicatorValue() : null;
    final n2 = s2.active ? s2.getNextRepetitionIndicatorValue() : null;
    if (n1 == null && n2 != null) {
      return 1;
    }
    else if (n1 != null && n2 == null) {
      return -1;
    }
    else if (n1 == null && n2 == null) {
      return _sortByTitleAndId(s1, s2);
    }
    final c = n2!.compareTo(n1!); // reverse
    if (c == 0) {
      return _sortByTitleAndId(s1, s2);
    }
    return c;
  }

  void removeScheduledTask(ScheduledTask scheduledTask) {
    setState(() {
      _scheduledTasks.remove(scheduledTask);
      _selectedTileId = null;
      _calcOverallStats();

      _cancelNotification(scheduledTask);
    });

  }


  void _onFABPressed() {
    Object? selectedTemplateItem;

    showTemplateDialog(context,
        translate('pages.schedules.action.addition.title'),
        translate('pages.schedules.action.addition.message'),
        selectedItem: (selectedItem) {
          setState(() {
            selectedTemplateItem = selectedItem;
          });
        },
        okPressed: () async {
            if (selectedTemplateItem == null) {
              return;
            }
            Navigator.pop(context);
            ScheduledTask? newScheduledTask = await Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ScheduledTaskForm(
                formTitle: translate('forms.schedule.create.title'),
                taskGroup: selectedTemplateItem is Template
                  ? TaskGroupRepository.findByIdFromCache((selectedTemplateItem as Template).taskGroupId)
                  : selectedTemplateItem as TaskGroup,
                template: selectedTemplateItem is Template
                  ? selectedTemplateItem as Template
                  : null,
              );
            }));

            if (newScheduledTask != null) {
              ScheduledTaskRepository.insert(newScheduledTask).then((newScheduledTask) {

                toastInfo(context, translate('forms.schedule.create.success',
                  args: {"title": newScheduledTask.translatedTitle}));

                _addScheduledTask(newScheduledTask);

                DueScheduleCountService().gather();
              });
            }
        },
        cancelPressed: () {
          Navigator.pop(super.context);
        });

  }

  @override
  bool get wantKeepAlive => true;


  void _rescheduleNotification(ScheduledTask scheduledTask,
      {bool withCancel = true, withCancelFixedMode = true}) {
    if (scheduledTask.reminderNotificationEnabled == false) {
      _cancelNotification(scheduledTask, alsoFixedMode: true);
      return;
    }
    final missingDuration = scheduledTask.getMissingDuration();
    if (missingDuration != null) {
      debugPrint("reschedule ${scheduledTask.id!} with missing duration: $missingDuration");

      if (withCancel) {
        _cancelNotification(scheduledTask, alsoFixedMode: withCancelFixedMode);
      }

      if (scheduledTask.active && !scheduledTask.isPaused && _disableNotification == false) {
        final taskGroup = TaskGroupRepository.findByIdFromCache(
            scheduledTask.taskGroupId);
        _scheduleNotification(scheduledTask, taskGroup, missingDuration);
      }
    }
  }

  void _scheduleNotification(ScheduledTask scheduledTask, TaskGroup taskGroup, Duration missingDuration) {
    if (scheduledTask.schedule.repetitionMode == RepetitionMode.FIXED) {
      var lastScheduled = scheduledTask.lastScheduledEventOn!;

      forFixedNotificationIds(scheduledTask.id!, (notificationId, isLast) {
        final nextMissingDuration = scheduledTask.getMissingDurationAfter(lastScheduled);
        debugPrint("schedule $notificationId, lastScheduled $lastScheduled nextMissingDuration $nextMissingDuration isLast $isLast");
        scheduleNotification(notificationId, scheduledTask, taskGroup, nextMissingDuration, true, isLast);

        lastScheduled = scheduledTask.getNextScheduleAfter(lastScheduled)!;
      });
    }
    else {
      scheduleNotification(scheduledTask.id!, scheduledTask, taskGroup, missingDuration, false, false);
    }
  }

  void scheduleNotification(int id, ScheduledTask scheduledTask, TaskGroup taskGroup, 
      Duration missingDuration, bool isFixed, bool isLast) {

    final preNotificationDuration = scheduledTask.preNotification?.toDuration();

    if (scheduledTask.preNotificationEnabled == true && preNotificationDuration != null) {
      var title = isFixed
          ? translate('pages.schedules.notification.pre_notification.title_fixed_task')
          : translate('pages.schedules.notification.pre_notification.title_normal_task');
      var messageKey = isFixed
          ? 'pages.schedules.notification.pre_notification.message_fixed_task'
          : 'pages.schedules.notification.pre_notification.message_normal_task';

      if (scheduledTask.important) {
        title = "${translate('common.words.important').capitalize()}: $title";
      }

      final preMinutes = missingDuration.inMinutes - preNotificationDuration.inMinutes;
      final duration = Duration(minutes: preMinutes);

      title = "$title (${taskGroup.translatedName})";
      final message = translate(messageKey, args: {
        "title": scheduledTask.translatedTitle,
        "when": Schedule.fromCustomRepetitionToUnit(scheduledTask.preNotification!, usedClause(context, Clause.dative))
      });

      // negative id space for pre-notifications
      _doScheduleNotification( -id, scheduledTask, taskGroup, duration, title, message, null);

    }
    
    
    var title = isFixed
            ? translate('pages.schedules.notification.title_fixed_task')
            : translate('pages.schedules.notification.title_normal_task');
    var messageKey = isFixed
            ? isLast
              ? 'pages.schedules.notification.message_fixed_last_task'
              : 'pages.schedules.notification.message_fixed_task'
            : 'pages.schedules.notification.message_normal_task';

    if (scheduledTask.important) {
      title = "${translate('common.words.important').capitalize()}: $title";
    }

    final snooze = scheduledTask.reminderNotificationRepetition??CustomRepetition(1, RepetitionUnit.HOURS);

    title = "$title (${taskGroup.translatedName})";
    final message = translate(messageKey, args: {"title": scheduledTask.translatedTitle});
    _doScheduleNotification(id, scheduledTask, taskGroup, missingDuration, title, message, snooze);
    
    
  }
  void _doScheduleNotification(int id, ScheduledTask scheduledTask, TaskGroup taskGroup, 
      Duration missingDuration, String title, String message, CustomRepetition? snooze) {
    
    _notificationService.scheduleNotification(
        widget.getRoutingKey(),
        id,
        title,
        message,
        missingDuration,
        CHANNEL_ID_SCHEDULES,
        taskGroup.backgroundColor(context),
        [
          AndroidNotificationAction("track", translate('pages.schedules.notification.action_track'), showsUserInterface: true),
          if (snooze != null)
            AndroidNotificationAction("snooze", translate('pages.schedules.notification.action_snooze',
              args: {"when" : Schedule.fromCustomRepetitionToUnit(snooze, usedClause(context, Clause.dative))}), showsUserInterface: false),
        ],
        true,
        snooze,
    );
  }

  void _cancelNotification(ScheduledTask scheduledTask, {alsoFixedMode = true}) {
    // cancel dynamic mode
    debugPrint("cancel dynamic ${scheduledTask.id!}");
    _notificationService.cancelNotification(scheduledTask.id!);
    _notificationService.cancelNotification(scheduledTask.id! * -1); // pre-notification

    // cancel fixed mode
    if (alsoFixedMode) {
      forFixedNotificationIds(scheduledTask.id!, (notificationId, _) {
        debugPrint("cancel fixed $notificationId");
        _notificationService.cancelNotification(notificationId);
        _notificationService.cancelNotification(notificationId * -1); // pre-notification
      });
      forFixedNotificationIdsLegacy(scheduledTask.id!, (notificationId, _) {
        debugPrint("legacy cancel fixed $notificationId");
        _notificationService.cancelNotification(notificationId);
        _notificationService.cancelNotification(notificationId * -1); // pre-notification
      });
    }

    ScheduledTaskWidget.cancelSnoozedNotification(scheduledTask);

  }

  forFixedNotificationIds(int scheduledTaskId, Function(int, bool) f) {
    const amount = 10;
    List.generate(amount, (baseId) => FIXED_SCHEDULE_NOTIFICATION_OFFSET * (baseId + 1) + scheduledTaskId)
        .forEach((id) => f(id, id ~/ FIXED_SCHEDULE_NOTIFICATION_OFFSET  == amount));
  }

  forFixedNotificationIdsLegacy(int scheduledTaskId, Function(int, bool) f) {
    const amount = 10;
    int base = scheduledTaskId * FIXED_SCHEDULE_NOTIFICATION_OFFSET;
    List.generate(amount, (baseId) => base + baseId + 1)
        .forEach((id) => f(id, id - base  == amount));
  }

  void _updateSortBy(SortBy sortBy, bool hideInactive, bool importantOnTop) {
    _preferenceService.setInt(PREF_SORT_BY, sortBy.index);
    _preferenceService.setBool(PREF_HIDE_INACTIVE, hideInactive);
    _preferenceService.setBool(PREF_IMPORTANT_ON_TOP, importantOnTop);
    setState(() {
      final sortByChanged = _sortBy != sortBy;
      _sortBy = sortBy;

      _hideInactive = hideInactive;
      _importantOnTop = importantOnTop;
      if (sortByChanged) {
        _hiddenTiles.clear(); // make all visible
        _selectedTileId = null; // don't select any
      }
      _sortList();
    });
  }

  int _sortByTitleAndId(ScheduledTask s1, ScheduledTask s2) {
    final d1 = s1.translatedTitle.toLowerCase();
    final d2 = s2.translatedTitle.toLowerCase();
    final c = d1.compareTo(d2);
    if (c == 0) {
      return s1.id!.compareTo(s2.id!);
    }
    return c;
  }

  void _calcOverallStats() {
    setState(() {
      _totalRunningSchedules = 0;
      _totalDueSchedules = 0;
      _totalOverdueSchedules = 0;
      _dueBeforeTodaySchedules = 0;
      _dueAndImportantSchedules = 0;
      _dueTodaySchedules = 0;
      _dueTomorrowSchedules = 0;
      _dueAfterTomorrowSchedules = 0;
      _pausedSchedules = 0;
      _inactiveSchedules = 0;

      final now = DateTime.now();
      _scheduledTasks
          .forEach((scheduledTask) {

          if (!scheduledTask.active) {
            _inactiveSchedules++;
          }
          else if (scheduledTask.isPaused) {
            _pausedSchedules++;
          }
          else if (!scheduledTask.isOneTimeCompleted) {
            _totalRunningSchedules++;

            if (scheduledTask.isDue()) {
              _totalDueSchedules++;
              if (scheduledTask.important) {
                _dueAndImportantSchedules++;
              }
            }
            if (scheduledTask.isNextScheduleOverdue(true)) {
              _totalOverdueSchedules++;
            }

            final nextSchedule = scheduledTask.getNextSchedule();
            if (nextSchedule != null) {
              if (nextSchedule.isBefore(truncToDate(now))) {
                _dueBeforeTodaySchedules++;
              }
              if (isToday(nextSchedule)) {
                _dueTodaySchedules++;
              }
              if (isTomorrow(nextSchedule)) {
                _dueTomorrowSchedules++;
              }
              if (isAfterTomorrow(nextSchedule)) {
                _dueAfterTomorrowSchedules++;
              }
            }
          }
      });
    });
  }

  void _updatePinSchedulesPage(bool value, {required bool withSnackMsg}) {
    setState(() {
      _pinSchedulesPage = value;
      pinSchedulesPageIconKey.currentState?.refresh(_pinSchedulesPage);
      if (_pinSchedulesPage) {
        if (withSnackMsg) {
          toastInfo(context, translate('pages.schedules.menu.pinning.pinned'));
        }

      }
      else {
        if (withSnackMsg) {
          toastInfo(context, translate('pages.schedules.menu.pinning.unpinned'));
        }
      }
      _preferenceService.setBool(PREF_PIN_SCHEDULES, _pinSchedulesPage);
      if (_pinSchedulesPage) {
        _preferenceService.setBool(PREF_PIN_QUICK_ADD, false);
        pinQuickAddPageIconKey.currentState?.refresh(false);
      }
    });
  }

  void _setStatusTileHidden(bool value) {
    _statusTileHidden = value;
    _preferenceService.setBool(PreferenceService.DATA_SHOW_SCHEDULED_SUMMARY, !value);
  }

  _updateSelectedTile(ScheduledTask? scheduledTask) {
    _selectedTileId = scheduledTask?.id;
    if (scheduledTask != null) {
      int index = _scheduledTasks.indexOf(scheduledTask);
      if (index >= 0) {
        _listScrollController.scrollToIndex(
            index, duration: Duration(milliseconds: 1));
      }
    }
  }

  GroupCriteria? _getGroupingCriteria(ScheduledTask scheduledTask, SortBy sortBy, bool importantOnTop) {
    if (_sortBy == SortBy.PROGRESS) {
      if (!scheduledTask.active) {
        return GroupCriteria.INACTIVE;
      }
      if (scheduledTask.isOneTimeCompleted) {
        return GroupCriteria.COMPLETED;
      }
      if (scheduledTask.isDue()) {
        if (importantOnTop && scheduledTask.important) {
          return GroupCriteria.DUE_AND_IMPORTANT;
        }
        return GroupCriteria.DUE;
      }
      else {
        return GroupCriteria.NOT_DUE;
      }
    }
    else if (_sortBy == SortBy.REMAINING_TIME) {
      if (!scheduledTask.active) {
        return GroupCriteria.INACTIVE;
      }
      if (scheduledTask.isOneTimeCompleted) {
        return GroupCriteria.COMPLETED;
      }
      if (scheduledTask.isPaused) {
        return GroupCriteria.PAUSED;
      }

      final nextDueDate = scheduledTask.getNextSchedule()!;
      if (scheduledTask.isDue()) {
        if (importantOnTop && scheduledTask.important) {
          return GroupCriteria.DUE_AND_IMPORTANT;
        }
        if (truncToDate(nextDueDate).isBefore(truncToDate(DateTime.now()))) {
          return GroupCriteria.DUE_SINCE_YESTERDAY;
        }
       
        return GroupCriteria.DUE_TODAY;
      }
      else {
        if (isToday(nextDueDate)) {
          return GroupCriteria.DUE_TODAY;
        }
        if (isTomorrow(nextDueDate)) {
          return GroupCriteria.DUE_TOMORROW;
        }
        if (isAfterTomorrow(nextDueDate)) {
          return GroupCriteria.DUE_AFTER_TOMORROW;
        }
        return GroupCriteria.NOT_DUE;
      }
    }
    return null;
  }

  String _translateCriteria(GroupCriteria criteria) {
    switch (criteria) {
      case GroupCriteria.NOT_DUE: return translate('pages.schedules.overview.later_due');
      case GroupCriteria.DUE_SINCE_YESTERDAY: return translate('pages.schedules.overview.due_yesterday_and_before');
      case GroupCriteria.DUE_TODAY: return translate('pages.schedules.overview.due_today');
      case GroupCriteria.DUE_TOMORROW: return translate('pages.schedules.overview.due_tomorrow');
      case GroupCriteria.DUE_AFTER_TOMORROW: return translate('pages.schedules.overview.due_after_tomorrow');
      case GroupCriteria.DUE: return translate('pages.schedules.overview.due');
      case GroupCriteria.DUE_AND_IMPORTANT: return "${translate('common.words.important').capitalize()}!";
      case GroupCriteria.PAUSED: return "${translate('pages.schedules.overview.paused').capitalize()}";
      case GroupCriteria.INACTIVE: return "${translate('pages.schedules.overview.inactive').capitalize()}";
      case GroupCriteria.COMPLETED: return "${translate('pages.schedules.overview.completed').capitalize()}";
    }
  }
  
}


