import 'dart:async';

import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:patterns_canvas/patterns_canvas.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskRepository.dart';
import 'package:personaltasklogger/db/repository/TaskGroupRepository.dart';
import 'package:personaltasklogger/model/ScheduledTask.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/TemplateId.dart';
import 'package:personaltasklogger/ui/components/ScheduledTaskWidget.dart';
import 'package:personaltasklogger/ui/utils.dart';
import 'package:personaltasklogger/util/extensions.dart';

import '../../db/repository/ChronologicalPaging.dart';
import '../../db/repository/TaskEventRepository.dart';
import '../../db/repository/TemplateRepository.dart';
import '../../model/Template.dart';
import '../../model/TitleAndDescription.dart';
import '../../model/When.dart';
import '../../service/PreferenceService.dart';
import '../../util/dates.dart';
import '../PersonalTaskLoggerApp.dart';
import '../PersonalTaskLoggerScaffold.dart';
import '../components/TaskEventFilter.dart';
import '../components/TaskEventWidget.dart';
import 'ScheduledTaskList.dart';
import 'TaskEventList.dart';



@immutable
class CalendarPage extends StatefulWidget {

  final PagesHolder pagesHolder;

  CalendarPage(this.pagesHolder);

  @override
  State<StatefulWidget> createState() {
    return _CalendarPageStatus();
  }

}

enum EventType {EVENT, SCHEDULE, BOTH, NONE}
enum CalendarMode {DAY, WEEK, MONTH}

final scheduledTaskWidgetKey = GlobalKey<ScheduledTaskWidgetState>();

class _CalendarPageStatus extends State<CalendarPage> {

  static const minCalendarDuration = Duration(minutes: 20);
  static const defaultScale = 1.2;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final calendarDayKey = GlobalKey<DayViewState>();
  final calendarWeekKey = GlobalKey<WeekViewState>();
  final calendarMonthKey = GlobalKey<MonthViewState>();
  final calendarController = EventController<TitleAndDescription>();

  double dayAndWeekViewScrollPixels = 0;

  TaskFilterSettings _taskFilterSettings = TaskFilterSettings();

  EventType _eventType = EventType.BOTH;
  late List<bool> _eventTypeSelection;

  CalendarMode _calendarMode = CalendarMode.DAY;
  late List<bool> _calendarModeSelection;

  List<CalendarEventData<TaskEvent>> _taskEventCalendarEvents = [];
  List<CalendarEventData<ScheduledTask>> _scheduledTaskCalendarEvents = [];


  double _baseScaleFactor = defaultScale;
  double _scaleFactor = defaultScale;

  CalendarEventData<TitleAndDescription>? _selectedEvent = null;

  PersistentBottomSheetController? sheetController;

  late Timer _timer;

  bool _isNotificationsDisabled = false;


  @override
  void initState() {
    super.initState();

    _eventTypeSelection = [true, true];
    _calendarModeSelection = List.generate(CalendarMode.values.length, (index) => index == _calendarMode.index);

    final fTaskEvents = _loadFirstTaskEvents(CalendarConstants.maxDate, ChronologicalPaging.maxId);
    final fScheduledTasks = _loadSchedulesTasks();
    Future.wait([fTaskEvents, fScheduledTasks]).then((events) {
      final taskEvents = events.first;
      final scheduledTasks = events.last;

      _mapAndAddTaskEventsToCalendar(taskEvents);
      _mapAndAddScheduledTasksToCalendar(scheduledTasks);

      _loadRemainingTaskEvents(taskEvents.lastOrNull as TaskEvent?);

      _scrollToTime(DateTime.now());

    });

    PreferenceService().getBool(PREF_DISABLE_NOTIFICATIONS).then((value) {
      setState(() {
        if (value != null) {
          _isNotificationsDisabled = value;
        }
      });
    });

    PreferenceService().getInt(PreferenceService.DATA_CURRENT_CALENDAR_MODE).then((value) {
      if (value != null) {
        _updateCalendarMode(CalendarMode.values[value]);
      }
    });
    PreferenceService().getInt(PreferenceService.DATA_CURRENT_EVENT_TYPE).then((value) {
      if (value != null) {
        setState(() {
          _eventType = EventType.values[value];
          if (_eventType == EventType.EVENT) {
            _eventTypeSelection = [true, false];
          }
          else if (_eventType == EventType.SCHEDULE) {
            _eventTypeSelection = [false, true];
          }
          else if (_eventType == EventType.BOTH) {
            _eventTypeSelection = [true, true];
          }
          else {
            // if NONE was stored for some reason, change to BOTH to not display nothing
            _eventType = EventType.BOTH;
            _eventTypeSelection = [true, true];
          }
          _refreshModelAndFilterCalendar();
        });
      }
    });

    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      setState(() {
        debugPrint(".. Calender refresh #${_timer.tick} ..");
      });
      scheduledTaskWidgetKey.currentState?.setState(() {
        // force update time constraints
        debugPrint(".. ST Widget refresh #${_timer.tick} ..");
      });
    });

  }

  _mapAndAddScheduledTasksToCalendar(List<TitleAndDescription> scheduledTasks) async {
    final eventData = await Future.wait(scheduledTasks.map((e) => _mapScheduledTaskToCalendarEventData(e as ScheduledTask)));
    _scheduledTaskCalendarEvents.addAll(eventData);
    if (_eventType == EventType.SCHEDULE || _eventType == EventType.BOTH) {
      calendarController.addAll(eventData);
    }
  }

  _mapAndAddTaskEventsToCalendar(List<TitleAndDescription> taskEvents) async {
    final eventData = taskEvents.map((e) => _mapTaskEventToCalendarEventData(e as TaskEvent)).toList();
    _taskEventCalendarEvents.addAll(eventData);
    if (_eventType == EventType.EVENT || _eventType == EventType.BOTH) {
      calendarController.addAll(eventData);
    }

    taskEvents.forEach((taskEvent) async {
      final eventData = _mapTaskEventToCalendarEventData(taskEvent as TaskEvent);
      _taskEventCalendarEvents.add(eventData);
      _addToCalendar(eventData);
    });
  }

  void _loadRemainingTaskEvents(TaskEvent? lastTaskEvent) {
    if (lastTaskEvent != null) {
      debugPrint("load remaining (last id = ${lastTaskEvent.id})");
      _loadFirstTaskEvents(lastTaskEvent.startedAt, lastTaskEvent.id!).then((taskEvents) {
        _mapAndAddTaskEventsToCalendar(taskEvents);
        _loadRemainingTaskEvents(taskEvents.lastOrNull as TaskEvent?);
      });
    }
  }

  @override
  void deactivate() {
    _timer.cancel();
    super.deactivate();
  }

  void _scrollToTime(DateTime date) {
    calendarDayKey.currentState?.scrollController.jumpTo(_calculateScrollOffset(date));
    calendarWeekKey.currentState?.scrollController.jumpTo(_calculateScrollOffset(date));
    //calendarMonthKey.currentState?.scrollController.jumpTo(_calculateScrollOffset(date));
  }

  void _jumpToDate(DateTime date) {
    calendarDayKey.currentState?.jumpToDate(date);
    calendarWeekKey.currentState?.jumpToWeek(date);
    calendarMonthKey.currentState?.jumpToMonth(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(translate('pages.calendar.title')),
        actions: [
          TaskEventFilter(
              initialTaskFilterSettings: _taskFilterSettings,
              visibleFilterOptions: {FilterOption.TASK_OR_TEMPLATE},
              doFilter: (taskFilterSettings, filterChangeState) {
                setState(() {
                  _taskFilterSettings = taskFilterSettings;
                });
                _doFilter();
              }),

          IconButton(
            icon: Icon(Icons.today),
            onPressed: () async {
              await _jumpToSelectionOrToday();
            },
          ),
        ],
      ),
      body: _createBody(context),
    );
  }

  Future<void> _jumpToSelectionOrToday() async {
    var when = DateTime.now();
    if (_selectedEvent != null) {
      when = _selectedEvent!.startTime ?? _selectedEvent!.date;
    }
    await _jumpToDateTime(when);
  }


  void _doFilter() {
    _refreshModelAndFilterCalendar();
  }

  bool _filterByTaskOrTemplate(int taskGroupId, TemplateId? templateId) {
    if (!_taskFilterSettings.isFilterActive()) {
      //bypass
      return true;
    }

    if (_taskFilterSettings.filterByTaskOrTemplate is TaskGroup) {
      final _taskGroup = _taskFilterSettings.filterByTaskOrTemplate as TaskGroup;
      if (taskGroupId == _taskGroup.id) {
        return true;
      }
    }
    if (_taskFilterSettings.filterByTaskOrTemplate is Template) {
      final filterTemplate = _taskFilterSettings.filterByTaskOrTemplate as Template;
      if (templateId == null) {
        return false; // remove events with no template at all
      }
      if (filterTemplate.isVariant()) {
        if (templateId == filterTemplate.tId) {
          return true;
        }
      }
      else {
        final parentTemplateId = TemplateRepository.getParentId(templateId.id); // returns a taskTemplate or null, never a variant
        if (parentTemplateId == filterTemplate.tId!.id || templateId == filterTemplate.tId) {
          return true;
        }
      }
    }
    return false; 
  }

  Future<void> _jumpToDateTime(DateTime when) async {
    _jumpToDate(when);
    await Future.delayed(Duration(milliseconds: 100)); // this is a hack to not cancel the first scrolling by the next
    _scrollToTime(when);
  }

  Future<void> _addModel(TitleAndDescription event) async {
    if (event is TaskEvent) {
      var newTaskEventCalendarEventData = _mapTaskEventToCalendarEventData(event);
      _taskEventCalendarEvents.add(newTaskEventCalendarEventData);
      _addToCalendar(newTaskEventCalendarEventData);
    }
    else if (event is ScheduledTask) {
      final updatedEvent = await _mapScheduledTaskToCalendarEventData(event);
      _scheduledTaskCalendarEvents.add(updatedEvent);

      _addToCalendar(updatedEvent);
    }
  }

  void _addToCalendar(CalendarEventData<TitleAndDescription> event) {
    if (_filterEvent(event.event!)) {
      calendarController.add(event);
    }
  }

  void _updateModel(TitleAndDescription event) {
    _deleteModel(event);
    _addModel(event);
  }
  
  void _deleteModel(TitleAndDescription event) {
    if (event is TaskEvent) {
      _taskEventCalendarEvents.removeWhere((e) => e.event == event);
      calendarController.removeWhere((element) => element.event == event);
    }
    else if (event is ScheduledTask) {
      _scheduledTaskCalendarEvents.removeWhere((e) => e.event == event);
      calendarController.removeWhere((element) => element.event == event);
    }
  }
  
  void _refreshModelAndFilterCalendar() {
    calendarController.removeWhere((element) => true);

    if (_eventType == EventType.EVENT || _eventType == EventType.BOTH) {
      _taskEventCalendarEvents.forEach((event) {
        if (_filterEvent(event.event!)) {
          calendarController.add(event);
        }
      });
    }

    if (_eventType == EventType.SCHEDULE || _eventType == EventType.BOTH) {
      _scheduledTaskCalendarEvents.forEach((event) {
        if (_filterEvent(event.event!)) {
          calendarController.add(event);
        }
      });
    }
  }

  bool _filterEvent(TitleAndDescription event) {
    if (event is TaskEvent && (_eventType == EventType.EVENT || _eventType == EventType.BOTH)) {
      return _filterByTaskOrTemplate(event.taskGroupId!, event.originTemplateId);
    }
    if (event is ScheduledTask && (_eventType == EventType.SCHEDULE || _eventType == EventType.BOTH)) {
      return _filterByTaskOrTemplate(event.taskGroupId, event.templateId);
    }
    return false;
  }


  Widget _createBody(BuildContext context) {
    final now = DateTime.now();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (details) {
        if (details.pointerCount == 2) {
          _baseScaleFactor = _scaleFactor;
          debugPrint("scale start $_scaleFactor");
        }
      },
      onScaleUpdate: (details) {
        if (details.pointerCount == 2) {
          setState(() {
            _scaleFactor = (_baseScaleFactor * details.scale).clamp(0.4, 4);
            debugPrint("scale upd $_scaleFactor");
          });
        }
      },
      child: Column(
        children: [
          SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _createTypeButtons(),
                    Spacer(),
                    _createModeButtons(),
                  ],
                ),
              ),),
          Expanded(
            flex: 10,
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    color: _getCalendarAccentColor(), //Constants.headerBackground
                    width: 16,
                  ),
                ),
                Expanded(
                  flex: 20,
                  child: _calendarMode == CalendarMode.DAY
                      ? _buildDayView()
                      : _calendarMode == CalendarMode.WEEK
                        ? _buildWeekView()
                        : _buildMonthView(now, context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  NotificationListener<Notification> _buildDayView() {
    return NotificationListener(
      child: DayView<TitleAndDescription>(
        onPageChange: (date, page) {
          calendarDayKey.currentState?.scrollController.jumpTo(dayAndWeekViewScrollPixels);
        },
        key: calendarDayKey,
        backgroundColor: _getCalendarBackgroundColor(),
        eventTileBuilder: _customEventTileBuilder,
        controller: calendarController,
        heightPerMinute: _scaleFactor,
        dateStringBuilder: _headerDayBuilder,
        onEventTap: _customTabHandler,
        timeStringBuilder: _headerTimeBuilder,
        timeLineWidth: 47,
        scrollOffset: dayAndWeekViewScrollPixels,
        liveTimeIndicatorSettings: _getTimeIndicatorSettings(),
        hourIndicatorSettings: _getHourIndicatorSettings(),
        headerStyle: _getHeaderStyle(),
      ),
      onNotification: (notification) {
        final scrollController = calendarDayKey.currentState?.scrollController;
        if (notification is ScrollEndNotification && scrollController != null) {
          if (scrollController.positions.isNotEmpty) {
            dayAndWeekViewScrollPixels = scrollController.positions.first.pixels;
            debugPrint(
                "dayViewScrollPixels=$dayAndWeekViewScrollPixels");
            return true;
          }
        }
        return false;
      },
    );
  }
  
  NotificationListener<Notification> _buildWeekView() {
    return NotificationListener(
      child: WeekView(
          onPageChange: (date, page) {
            calendarWeekKey.currentState?.scrollController.jumpTo(dayAndWeekViewScrollPixels);
          },
          scrollOffset: dayAndWeekViewScrollPixels,
          key: calendarWeekKey,
          backgroundColor: _getCalendarBackgroundColor(),
          eventTileBuilder: _customEventTileBuilder,
          controller: calendarController,
          heightPerMinute: _scaleFactor,
          liveTimeIndicatorSettings: _getTimeIndicatorSettings(),
          onEventTap: _customTabHandler,
          headerStringBuilder: _headerWeekBuilder,
          timeLineStringBuilder: _headerTimeBuilder,
          timeLineWidth: 47,
          hourIndicatorSettings: _getHourIndicatorSettings(),
          weekDayBuilder: (date) {
            final isToday = date.day == DateTime.now().day;
            return GestureDetector(
                onLongPress: () => _onDateLongPress(
                  DateTime(
                    date.year,
                    date.month,
                    date.day,
                  ),
                ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(date.getWeekdayName().characters.first.toUpperCase(),
                      style: _getTextStyleForToday(isToday)),
                    Text(date.day.toString(),
                        style: _getTextStyleForToday(isToday)),
                  ],
                ),
              ),
            );
          },
          onDateLongPress: _onDateLongPress,
          headerStyle: _getHeaderStyle(),
      ),
      onNotification: (notification) {
        final scrollController = calendarWeekKey.currentState?.scrollController;
        if (notification is ScrollEndNotification && scrollController != null) {
          if (scrollController.positions.isNotEmpty) {
            dayAndWeekViewScrollPixels = scrollController.positions.first.pixels;
            debugPrint(
                "dayViewScrollPixels=$dayAndWeekViewScrollPixels");
            return true;
          }
        }
        return false;
      },
    );
  }

  MonthView<TitleAndDescription> _buildMonthView(DateTime now, BuildContext context) {
    return MonthView(
      onPageChange: (date, page) {
        _scrollToTime(now);
      },
      key: calendarMonthKey,
      cellBuilder: _customCellBuilder,
      controller: calendarController,
      cellAspectRatio: 1/(_scaleFactor * 1.8),
      borderColor: _getGridColor(),
      borderSize: 0.75,
      weekDayBuilder: (index) => WeekDayTile(
        dayIndex: index,
        backgroundColor: _getCalendarBackgroundColor(),
        textStyle: TextStyle(
          fontSize: 17,
          color: isDarkMode(context) ? Colors.white : Colors.black,
        ),
        weekDayStringBuilder: (day) => getNarrowWeekdayOf(day, context).toUpperCase(),
      ),
      headerStringBuilder: _headerMonthBuilder,
      onDateLongPress: _onDateLongPress,
      headerStyle: _getHeaderStyle(),
    );
  }


  HourIndicatorSettings _getHourIndicatorSettings() {
    return HourIndicatorSettings(
      height: _scaleFactor,
      color: isDarkMode(context) ? Colors.white24 : Color(0xffdddddd),
      offset: 5,
    );
  }

  HourIndicatorSettings _getTimeIndicatorSettings() => HourIndicatorSettings(color: _getGridColor());

  Color _getGridColor() => isDarkMode(context) ? Colors.white70 : Colors.grey;

  HeaderStyle _getHeaderStyle() {
    return HeaderStyle(
      leftIcon: Icon(
        Icons.chevron_left,
        size: 30,
        color: getActionIconColor(context),
      ),
      rightIcon: Icon(
        Icons.chevron_right,
        size: 30,
        color: getActionIconColor(context),
      ),
      decoration: BoxDecoration(color: _getCalendarAccentColor()),
    );
  }

  Future<void> _onDateLongPress(DateTime date) async {
    _updateCalendarMode(CalendarMode.DAY);
    await Future.delayed(Duration(milliseconds: 50)); // this is a hack to not cancel the first scrolling by the next
    await _jumpToDateTime(date.add(Duration(minutes: TimeOfDay.now().toMinutes())));
  }
  
  TextStyle _getTextStyleForToday(bool isToday) {
    return TextStyle(
      fontSize: isToday ? 18 : null,
     // color: isToday ? Colors.black : null,
      fontWeight: isToday ? FontWeight.bold : null,
    );
  }

  double _calculateScrollOffset(DateTime now) {
    final hourHeight = _scaleFactor * 60;
    final height = hourHeight * (now.hour - 1);
    return height;
  }

  Future<List<TitleAndDescription>> _loadFirstTaskEvents(DateTime date, int id) async {

    final paging = ChronologicalPaging(date, id, 500);
    return await TaskEventRepository.getAllPaged(paging);
  }

  Future<List<TitleAndDescription>> _loadSchedulesTasks() async {

    final paging = ChronologicalPaging(CalendarConstants.maxDate, ChronologicalPaging.maxId, 10000);
    final scheduledTasks = await ScheduledTaskRepository.getAllPaged(paging);

    return scheduledTasks.where((e) => e.active).toList();
  }

  Future<CalendarEventData<ScheduledTask>> _mapScheduledTaskToCalendarEventData(ScheduledTask scheduledTask) async {
    var duration = minCalendarDuration;
    
    if (scheduledTask.templateId != null) {
      final template = await TemplateRepository.findById(scheduledTask.templateId!);
      if (template != null && template.when != null && template.when!.durationHours != null) {
        duration = When.fromDurationHoursToDuration(template.when!.durationHours!, template.when!.durationExactly);
      }
      duration = duration.min(minCalendarDuration);
    }

    var title = scheduledTask.translatedTitle;
    var startAt = scheduledTask.getNextSchedule()!;
    var endAt = scheduledTask.getNextSchedule()!.add(duration);
    if (TimeOfDay.fromDateTime(startAt).toDouble() > TimeOfDay.fromDateTime(endAt).toDouble()) {
      endAt = startAt.withoutTime.add(Duration(minutes: (60 * 24) - 1)); // cut end to one minute before end of day
      //TODO render event part for the next day
      title = "$title >>>";
    }

    final event = CalendarEventData(
      date: scheduledTask.getNextSchedule()!,
      endDate: scheduledTask.getNextSchedule()!,
      event: scheduledTask,
      title: title,
      description: scheduledTask.translatedDescription??"",
      startTime: startAt,
      endTime: endAt,
      color: TaskGroupRepository.findByIdFromCache(scheduledTask.taskGroupId).backgroundColor(context),
      titleStyle: TextStyle(color: Colors.black54),
    );
    return event;
  }

  CalendarEventData<TaskEvent> _mapTaskEventToCalendarEventData(TaskEvent taskEvent) {
    final duration = taskEvent.startedAt.difference(taskEvent.finishedAt).abs().min(minCalendarDuration);
    var title = taskEvent.translatedTitle;
    var startAt = taskEvent.startedAt;
    var endAt = taskEvent.startedAt.add(duration);
    if (TimeOfDay.fromDateTime(startAt).toDouble() > TimeOfDay.fromDateTime(endAt).toDouble()) {
      endAt = startAt.withoutTime.add(Duration(minutes: (60 * 24) - 1)); // cut end to one minute before end of day
      //TODO render event part for the next day
      title = "$title >>>";
    }
    
    return CalendarEventData(
      date: taskEvent.startedAt,
      endDate: taskEvent.startedAt.add(duration),
      event: taskEvent,
      title: title,
      description: taskEvent.translatedDescription??"",
      startTime: startAt,
      endTime: endAt,
      color: TaskGroupRepository.findByIdFromCache(taskEvent.taskGroupId!).backgroundColor(context),
      titleStyle: TextStyle(color: Colors.black54),
    );
  }

  _customTabHandler(List<CalendarEventData<TitleAndDescription>> events, DateTime date) {
    final event = events[0];
    _handleTapEvent(event);
  }

  _customTileHandler(CalendarEventData<TitleAndDescription> event, DateTime date) {
    _handleTapEvent(event);
  }

  void _handleTapEvent(CalendarEventData<TitleAndDescription> event) {
    if (_selectedEvent != event) {
      debugPrint("open $sheetController");
      _updateSelectedEvent(event);
      sheetController = scaffoldKey.currentState?.showBottomSheet((context) {
        return _buildEventSheet(context, event.event!);
      });
      sheetController?.closed
          .whenComplete(() => _updateSelectedEvent(null));
    }
    else {
      _unselectEvent();
    }
  }

  Widget _buildEventSheet(BuildContext context, TitleAndDescription event) {
    final taskGroup = _getTaskGroupFromEvent(event);
    return _buildEventSheetContent(event, taskGroup);
  }

  Widget _buildEventSheetContent(event, TaskGroup? taskGroup) {
    if (event is TaskEvent) {
      return GestureDetector(
        onLongPress: () {
          sheetController?.close();
          Navigator.pop(context);
          if (appScaffoldKey.currentState != null) {
            final taskEventListState = widget.pagesHolder.taskEventList?.getGlobalKey().currentState;
            if (taskEventListState != null) {
              taskEventListState.clearFilters();
            }
            appScaffoldKey.currentState!.sendEventFromClicked(TASK_EVENT_LIST_ROUTING_KEY, false, event.id.toString(), null);
          }
        },
        child: TaskEventWidget(event,
          isInitiallyExpanded: false,
          onTaskEventChanged: (changedTaskEvent) {
            _updateModel(changedTaskEvent);
            final updatedEvent = _mapTaskEventToCalendarEventData(changedTaskEvent);
            setState(() => _selectedEvent = updatedEvent);
          },
          onTaskEventDeleted: (deletedTaskEvent) {
            _unselectEvent();
            _deleteModel(deletedTaskEvent);
          },
          pagesHolder: widget.pagesHolder,
          selectInListWhenChanged: false,
        ),
      );
    }
    else if (event is ScheduledTask) {
      final scheduledTask = event;
      return GestureDetector(
        onLongPress: () {
          sheetController?.close();
          Navigator.pop(context);
          if (appScaffoldKey.currentState != null) {
            appScaffoldKey.currentState!.sendEventFromClicked(SCHEDULED_TASK_LIST_ROUTING_KEY, false, scheduledTask.id.toString(), null);
          }
        },
        child: ScheduledTaskWidget(scheduledTask,
          key: scheduledTaskWidgetKey,
          isInitiallyExpanded: false,
          onScheduledTaskChanged: (changedScheduledTask) async {
            _updateModel(changedScheduledTask);
            final updatedEvent = await _mapScheduledTaskToCalendarEventData(changedScheduledTask);
            setState(() => _selectedEvent = updatedEvent);
          },
          onScheduledTaskDeleted: (deletedScheduledTask) {
            _unselectEvent();
            _deleteModel(deletedScheduledTask);
          },
          pagesHolder: widget.pagesHolder,
          selectInListWhenChanged: false,
          isNotificationsEnabled: () {
            return !_isNotificationsDisabled;
          },
          onBeforeRouting: () {
            // close all and exit calendar before routing to somewhere else
            sheetController?.close();
            Navigator.pop(context);
          },
          onAfterJournalEntryFromScheduleCreated: (taskEvent) async {
            if (taskEvent != null) {
              _addModel(taskEvent);
              _updateModel(scheduledTask);
              final updatedEvent = await _mapScheduledTaskToCalendarEventData(scheduledTask);
              setState(() => _selectedEvent = updatedEvent);
            }
          },
        ),
      );
    }

    return Container();
  }

  TaskGroup? _getTaskGroupFromEvent(event) {
    if (event is TaskEvent) {
      return _getTaskGroup(event.taskGroupId);
    }
    else if (event is ScheduledTask) {
      return _getTaskGroup(event.taskGroupId);
    }
    return null;
  }

  void _unselectEvent() {
    debugPrint("close $sheetController");
    sheetController?.close(); 
    sheetController = null;
    _updateSelectedEvent(null);
  }

  _updateSelectedEvent(CalendarEventData<TitleAndDescription>? event) {
    setState(() => _selectedEvent = event);
  }

  Widget _customEventTileBuilder(
      DateTime date,
      List<CalendarEventData<TitleAndDescription>> events,
      Rect boundary,
      DateTime startDuration,
      DateTime endDuration) {
    
    if (events.isNotEmpty) {
      final event = events[0]; //get first element for the date to be rendered (there should only be one)
      return _buildEventWidget(event, events);
    } else {
      return Container();
    }
  }

  String _headerTimeBuilder(DateTime date, {DateTime? secondaryDate}) =>
    "${formatToTime(date)}";

  String _headerDayBuilder(DateTime date, {DateTime? secondaryDate}) {
    final word = formatToWord(date);
    if (word != null) {
      return "${formatToDate(date, context, showWeekdays: true)} ($word)";
    }
    else {
      return "${formatToDate(date, context, showWeekdays: true)}";
    }
  }

  String _headerWeekBuilder(DateTime date, {DateTime? secondaryDate}) =>
    "${formatToDate(date, context, showWeekdays: false)} ${secondaryDate != null ? " - ${formatToDate(secondaryDate, context, showWeekdays: false)}" : ""}";

  String _headerMonthBuilder(DateTime date, {DateTime? secondaryDate}) =>
    "${getMonthOf((date.month - 1) % 12, context)} ${date.year}";


  Widget _buildEventWidget(CalendarEventData<TitleAndDescription> event, List<CalendarEventData<TitleAndDescription>> events) {
    final isSelected = event == _selectedEvent;
    final object = event.event;
    final taskGroupId = object is TaskEvent ? object.taskGroupId : object is ScheduledTask ? object.taskGroupId : null;
    final taskGroup = _getTaskGroup(taskGroupId);
    final backgroundColor = isSelected ? taskGroup?.softColor(context) ?? event.color : event.color;
    final icon = _getEventIcon(taskGroup);
    
    return CustomPaint(
      painter: object is ScheduledTask ? StripePainter(Colors.transparent, backgroundColor.withOpacity(0.1), _calendarMode == CalendarMode.DAY ? 21 : 7) : null,
    
      child: RoundedEventTile(
        borderRadius: BorderRadius.circular(6.0),
        icon: icon,
        title: event.title,
        titleStyle:
            _getEventTextStyle(object),
        descriptionStyle: event.descriptionStyle,
        totalEvents: events.length,
        padding: EdgeInsets.all(3.0),
        border: _getEventBorder(isSelected, object, backgroundColor),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Icon? _getEventIcon(TaskGroup? taskGroup) {
    final icon = taskGroup != null
        ? Icon(
            taskGroup.getIcon(true).icon,
            color: taskGroup.accentColor(context),
            size: (16 * _scaleFactor).max(16),
          )
        : null;
    return icon;
  }

  TextStyle _getEventTextStyle(object) {
    return TextStyle(
            fontSize: (14 * _scaleFactor).max(14),
            fontStyle: object is ScheduledTask ? FontStyle.italic : null,
            fontWeight: object is ScheduledTask && (object.isDueNow() || object.isNextScheduleOverdue(false)) ? FontWeight.bold : null,
            color: object is ScheduledTask
              ? (object.isDueNow() || object.isNextScheduleOverdue(false) )
                ? Colors.red
                : object.getDueColor(context, lighter: true)
              : (isDarkMode(context) ? Colors.white70 : Colors.black54), // event.color.accent,
          );
  }

  Border? _getEventBorder(bool isSelected, object, Color backgroundColor) {
    final selectedColor = isDarkMode(context) ? Colors.white38 : Colors.black54;
    if (object is TaskEvent) {
      return isSelected
          ? Border.all(color: selectedColor, width: 1.2)
          : null;
    }
    else if (object is ScheduledTask) {
      bool isDue = object.isDueNow() || object.isNextScheduleOverdue(false);
      Color color = isDue
          ? Colors.red
          : backgroundColor;
      return Border.all(color: isSelected ? selectedColor : color, width: isSelected ? 1.2 : 0.5);
    }
    return null;
  }

  Widget _customCellBuilder(
      date, List<CalendarEventData<TitleAndDescription>> events, bool isToday, bool isInMonth) {

    return FilledCell<TitleAndDescription>(
      date: date,
      shouldHighlight: isToday,
      backgroundColor: isInMonth
          ? (isDarkMode(context) ? Colors.black12: Color(0xffffffff))
          : (isDarkMode(context) ? Colors.black : Color(0xfff0f0f0)),
      events: events,
      titleColor: isDarkMode(context) ? Colors.white : Colors.black,
      getEventWidget: (events, index) {
        final event = events[index];
        final isSelected = event == _selectedEvent;
        final object = event.event;
        final taskGroupId = object is TaskEvent ? object.taskGroupId : object is ScheduledTask ? object.taskGroupId : null;
        final taskGroup = _getTaskGroup(taskGroupId);
        final backgroundColor = isSelected ? taskGroup?.softColor(context) ?? event.color : event.color;
        final icon = _getEventIcon(taskGroup);

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4.0),
            border: _getEventBorder(isSelected, object, backgroundColor),
          ),
          margin: EdgeInsets.symmetric(
              vertical: 2.0, horizontal: 3.0),
          padding: const EdgeInsets.all(2.0),
          alignment: Alignment.center,
          child: CustomPaint(
            painter: object is ScheduledTask ? StripePainter(Colors.transparent, backgroundColor.withOpacity(0.1), 7) : null,
            child: Row(
              children: [
                if (icon != null)
                  icon,
                if (icon != null)
                  Text(" "),
                Expanded(
                  child: Text(
                    event.title,
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    style: _getEventTextStyle(object),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      onTileTap: _customTileHandler,//widget.onEventTap,
      //dateStringBuilder: widget.dateStringBuilder,
    );
  }

  Color _getCalendarBackgroundColor() => isDarkMode(context) ? Colors.black12 : Colors.white;

  Color _getCalendarAccentColor() => isDarkMode(context) ? Colors.blueGrey : Color(0xFFDCF0FF);

  TaskGroup? _getTaskGroup(int? taskGroupId) {
    final taskGroup = taskGroupId != null ? TaskGroupRepository.findByIdFromCache(taskGroupId) : null;
    return taskGroup;
  }

  Widget _createTypeButtons() {
    return ToggleButtons(
      borderRadius: BorderRadius.all(Radius.circular(5.0)),
      renderBorder: true,
      borderWidth: 1.5,
      borderColor: Colors.grey,
      color: Colors.grey.shade600,
      selectedBorderColor: BUTTON_COLOR,
      children: [
        SizedBox(
            width: 75,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available_rounded, color: isDarkMode(context) ? (_eventType == EventType.EVENT || _eventType == EventType.BOTH  ? PRIMARY_COLOR : null) : null),
              ],
            )
        ),
        SizedBox(
            width: 75,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.next_plan_outlined, color: isDarkMode(context) ? (_eventType == EventType.SCHEDULE || _eventType == EventType.BOTH ? PRIMARY_COLOR : null) : null),
              ],
            )
        ),
      ],
      isSelected: _eventTypeSelection,
      onPressed: (int index) {
        setState(() {
          _eventTypeSelection[index] = !_eventTypeSelection[index];
          if (_eventTypeSelection[EventType.EVENT.index] && _eventTypeSelection[EventType.SCHEDULE.index]) {
            _eventType = EventType.BOTH;
          }
          else if (_eventTypeSelection[EventType.EVENT.index]) {
            _eventType = EventType.EVENT;
          }
          else if (_eventTypeSelection[EventType.SCHEDULE.index]) {
            _eventType = EventType.SCHEDULE;
          }
          else {
            _eventType = EventType.NONE;
          }
        });
        final storeEventType = _eventType == EventType.NONE ? EventType.BOTH : _eventType;
        PreferenceService().setInt(PreferenceService.DATA_CURRENT_EVENT_TYPE, storeEventType.index);
        _refreshModelAndFilterCalendar();
        _unselectEvent();
      },
    );
  }

  void _updateCalendarMode(CalendarMode mode) {
    final jumpToToday = mode != CalendarMode.MONTH && _calendarMode == CalendarMode.MONTH && dayAndWeekViewScrollPixels == 0;
    setState(() {
      _calendarModeSelection[_calendarMode.index] = false;
      _calendarModeSelection[mode.index] = true;
      _calendarMode = mode;
    });
    PreferenceService().setInt(PreferenceService.DATA_CURRENT_CALENDAR_MODE, mode.index);
    if (jumpToToday) {
      _jumpToSelectionOrToday();
    }
  }


  Widget _createModeButtons() {
    return ToggleButtons(
      borderRadius: BorderRadius.all(Radius.circular(5.0)),
      renderBorder: true,
      borderWidth: 1.5,
      borderColor: Colors.grey,
      color: Colors.grey.shade600,
      selectedBorderColor: BUTTON_COLOR,
      children: [
        SizedBox(
            width: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_view_day, color: isDarkMode(context) ? (_calendarMode == CalendarMode.DAY ? PRIMARY_COLOR : null) : null,),
              ],
            )
        ),
        SizedBox(
            width: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_view_week, color: isDarkMode(context) ? (_calendarMode == CalendarMode.WEEK ? PRIMARY_COLOR : null) : null,),
              ],
            )
        ),
        SizedBox(
            width: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_view_month, color: isDarkMode(context) ? (_calendarMode == CalendarMode.MONTH ? PRIMARY_COLOR : null) : null),
              ],
            )
        ),
      ],
      isSelected: _calendarModeSelection,
      onPressed: (int index) {
        _updateCalendarMode(CalendarMode.values.elementAt(index));
      },
    );
  }

}


class StripePainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final int stripeCount;

  StripePainter(this.color1, this.color2, this.stripeCount);

  @override
  void paint(Canvas canvas, Size size) {
    DiagonalStripesThick(bgColor: color1, fgColor: color2, featuresCount: stripeCount).paintOnWidget(canvas, size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}


