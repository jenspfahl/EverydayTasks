import 'dart:async';

import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:intl/intl.dart';
import 'package:patterns_canvas/patterns_canvas.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskRepository.dart';
import 'package:personaltasklogger/db/repository/TaskGroupRepository.dart';
import 'package:personaltasklogger/model/ScheduledTask.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/ui/components/ScheduledTaskWidget.dart';
import 'package:personaltasklogger/ui/utils.dart';
import 'package:personaltasklogger/util/extensions.dart';

import '../../db/repository/ChronologicalPaging.dart';
import '../../db/repository/TaskEventRepository.dart';
import '../../db/repository/TemplateRepository.dart';
import '../../model/When.dart';
import '../../service/PreferenceService.dart';
import '../../util/dates.dart';
import '../../util/i18n.dart';
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
  final calendarController = EventController<dynamic>();

  double dayAndWeekViewScrollPixels = 0;

  final taskFilterSettings = TaskFilterSettings();

  EventType _eventType = EventType.BOTH;
  late List<bool> _eventTypeSelection;

  CalendarMode _calendarMode = CalendarMode.DAY;
  late List<bool> _calendarModeSelection;

  List<CalendarEventData<TaskEvent>> _taskEvents = [];
  List<CalendarEventData<ScheduledTask>> _scheduledTasks = [];

  double _baseScaleFactor = defaultScale;
  double _scaleFactor = defaultScale;

  CalendarEventData<dynamic>? _selectedEvent = null;

  PersistentBottomSheetController? sheetController;

  late Timer _timer;

  bool _isNotificationsDisabled = false;


  @override
  void initState() {
    super.initState();

    _eventTypeSelection = [true, true];
    _calendarModeSelection = List.generate(CalendarMode.values.length, (index) => index == _calendarMode.index);

    _loadEvents().then((_) {
      _refreshModel();
      _scrollToTime(DateTime.now());
    });

    PreferenceService().getBool(PREF_DISABLE_NOTIFICATIONS).then((value) {
      setState(() {
        if (value != null) {
          _isNotificationsDisabled = value;
        }
      });
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
              initialTaskFilterSettings: taskFilterSettings,
              doFilter: (taskFilterSettings, filterChangeState) {
                setState(() {
                  //TODO
                });
              }),

          IconButton(
            icon: Icon(Icons.today),
            onPressed: () async {
              var when = DateTime.now();
              if (_selectedEvent != null) {
                when = _selectedEvent!.startTime ?? _selectedEvent!.date;
              }
              await _jumpToDateTime(when);
            },
          ),
        ],
      ),
      body: _createBody(context),
    );
  }

  Future<void> _jumpToDateTime(DateTime when) async {
    _jumpToDate(when);
    await Future.delayed(Duration(milliseconds: 100)); // this is a hack to not cancel the first scrolling by the next
    _scrollToTime(when);
  }

  void _refreshModel() {
    calendarController.removeWhere((element) => true);

    if (_eventType == EventType.EVENT || _eventType == EventType.BOTH) {
      calendarController.addAll(_taskEvents);
    }
    if (_eventType == EventType.SCHEDULE || _eventType == EventType.BOTH) {
      calendarController.addAll(_scheduledTasks);
    }
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
                    color: Color(0xFFDCF0FF), //Constants.headerBackground
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
      child: DayView(
        onPageChange: (date, page) {
          calendarDayKey.currentState?.scrollController.jumpTo(dayAndWeekViewScrollPixels);
        },
        key: calendarDayKey,
        eventTileBuilder: _customEventTileBuilder,
        controller: calendarController,
        heightPerMinute: _scaleFactor,
        dateStringBuilder: _headerDayBuilder,
        onEventTap: _customTabHandler,
        scrollOffset: dayAndWeekViewScrollPixels,
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
          eventTileBuilder: _customEventTileBuilder,
          controller: calendarController,
          heightPerMinute: _scaleFactor,
          onEventTap: _customTabHandler,
          headerStringBuilder: _headerWeekBuilder,
          weekDayBuilder: (date) {
            final isToday = date.day == DateTime.now().day;
            return Center(
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
            );
          },
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

  MonthView<dynamic> _buildMonthView(DateTime now, BuildContext context) {
    return MonthView(
      onPageChange: (date, page) {
        _scrollToTime(now);
      },
      key: calendarMonthKey,
      cellBuilder: _customCellBuilder,
      controller: calendarController,
      cellAspectRatio: 1/(_scaleFactor * 1.8),
      weekDayStringBuilder: (day) => getWeekdayOf((day + 1) % 7, context).characters.first.toUpperCase(),
      headerStringBuilder: _headerMonthBuilder,
      onDateLongPress: (date) async {
        debugPrint("date=$date");
        await _jumpToDateTime(date); //TODO scroll to now time of this date DOESNT JUMP TO GIVEN DATE!!

        setState(() {
          _calendarMode = CalendarMode.DAY; //TODO
        });
      },
    );
  }
  
  TextStyle _getTextStyleForToday(bool isToday) {
    return TextStyle(
      fontSize: isToday ? 18 : null,
      color: isToday ? BUTTON_COLOR : null,
      fontWeight: isToday ? FontWeight.bold : null,
    );
  }

  double _calculateScrollOffset(DateTime now) {
    final hourHeight = _scaleFactor * 60;
    final height = hourHeight * (now.hour - 1);
    return height;
  }

  Future<bool> _loadEvents() async {

    final paging = ChronologicalPaging(ChronologicalPaging.maxDateTime, ChronologicalPaging.maxId, 1000000);
    final taskEvents = await TaskEventRepository.getAllPaged(paging);
    final scheduledTasks = await ScheduledTaskRepository.getAllPaged(paging);


    await Future.forEach(scheduledTasks, (ScheduledTask scheduledTask) async {
      final event = await _mapScheduledTaskToCalendarEventData(scheduledTask);

      _scheduledTasks.add(event);
    });

    _taskEvents = taskEvents.map((taskEvent) => _mapTaskEventToCalendarEventData(taskEvent))
        .toList();

    return true;
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
    
    final event = CalendarEventData(
      date: scheduledTask.getNextSchedule()!,
      endDate: scheduledTask.getNextSchedule()!,
      event: scheduledTask,
      title: scheduledTask.translatedTitle,
      description: scheduledTask.translatedDescription??"",
      startTime: scheduledTask.getNextSchedule()!,
      endTime: scheduledTask.getNextSchedule()!.add(duration),
      color: TaskGroupRepository.findByIdFromCache(scheduledTask.taskGroupId).backgroundColor,
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
      color: TaskGroupRepository.findByIdFromCache(taskEvent.taskGroupId!).backgroundColor,
      titleStyle: TextStyle(color: Colors.black54),
    );
  }

  _customTabHandler(List<CalendarEventData<dynamic>> events, DateTime date) {
    final event = events[0];
    _handleTapEvent(event);
  }

  _customTileHandler(CalendarEventData<dynamic> event, DateTime date) {
    _handleTapEvent(event);
  }

  void _handleTapEvent(CalendarEventData<dynamic> event) {
    if (_selectedEvent != event) {
      debugPrint("open $sheetController");
      _updateSelectedEvent(event);
      sheetController = scaffoldKey.currentState?.showBottomSheet((context) {
        return _buildEventSheet(context, event.event);
      });
      sheetController?.closed
          .whenComplete(() => _updateSelectedEvent(null));
    }
    else {
      _unselectEvent();
    }
  }

  Widget _buildEventSheet(BuildContext context, dynamic event) {
    final taskGroup = _getTaskGroupFromEvent(event);
    return _buildEventSheetContent(event, taskGroup);
  }

  Widget _buildEventSheetContent(event, TaskGroup? taskGroup) {
    String? title;
    if (event is TaskEvent) {
      title = event.translatedTitle;
      return GestureDetector(
        onLongPress: () {
          sheetController?.close();
          Navigator.pop(context);
          if (appScaffoldKey.currentState != null) {
            appScaffoldKey.currentState!.sendEventFromClicked(TASK_EVENT_LIST_ROUTING_KEY, false, event.id.toString(), null);
          }
        },
        child: TaskEventWidget(event,
          isInitiallyExpanded: false,
          onTaskEventChanged: (changedTaskEvent) {
            _taskEvents.removeWhere((event) => event.event == changedTaskEvent);
            final updatedEvent = _mapTaskEventToCalendarEventData(changedTaskEvent);
            _taskEvents.add(updatedEvent);
            _refreshModel();
            setState(() => _selectedEvent = updatedEvent);
          },
          onTaskEventDeleted: (deletedTaskEvent) {
            debugPrint("try remove task event id ${deletedTaskEvent.id}");
            _taskEvents.removeWhere((event) => event.event!.id == deletedTaskEvent.id);
            _unselectEvent();
            _refreshModel();
          },
          pagesHolder: widget.pagesHolder,
          selectInListWhenChanged: false,
        ),
      );
    }
    else if (event is ScheduledTask) {
      title = event.translatedTitle;
      return GestureDetector(
        onLongPress: () {
          sheetController?.close();
          Navigator.pop(context);
          if (appScaffoldKey.currentState != null) {
            appScaffoldKey.currentState!.sendEventFromClicked(SCHEDULED_TASK_LIST_ROUTING_KEY, false, event.id.toString(), null);
          }
        },
        child: ScheduledTaskWidget(event,
          key: scheduledTaskWidgetKey,
          isInitiallyExpanded: false,
          onScheduledTaskChanged: (changedScheduledTask) async {
            _scheduledTasks.removeWhere((event) => event.event?.id == changedScheduledTask.id);
            final updatedEvent = await _mapScheduledTaskToCalendarEventData(changedScheduledTask);
            _scheduledTasks.add(updatedEvent);
            _refreshModel();  //TODO find a mor lightweight way
            setState(() => _selectedEvent = updatedEvent);
          },
          onScheduledTaskDeleted: (deletedScheduledTask) {
            _scheduledTasks.removeWhere((event) => event.event!.id == deletedScheduledTask.id);
            _unselectEvent();
            _refreshModel();
          },
          pagesHolder: widget.pagesHolder,
          selectInListWhenChanged: false,
          isNotificationsEnabled: () {
            return !_isNotificationsDisabled;
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

  _updateSelectedEvent(CalendarEventData<dynamic>? event) {
    setState(() => _selectedEvent = event);
  }

  Widget _customEventTileBuilder(
      DateTime date,
      List<CalendarEventData<dynamic>> events,
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

  String _headerDayBuilder(DateTime date, {DateTime? secondaryDate}) =>
    "${formatToDate(date, context, showWeekdays: true)}";

  String _headerWeekBuilder(DateTime date, {DateTime? secondaryDate}) =>
    "${formatToDate(date, context, showWeekdays: false)} ${secondaryDate != null ? " - ${formatToDate(secondaryDate, context, showWeekdays: false)}" : ""}";

  String _headerMonthBuilder(DateTime date, {DateTime? secondaryDate}) =>
    "${getMonthOf((date.month - 1) % 12, context)} ${date.year}";


  Widget _buildEventWidget(CalendarEventData<dynamic> event, List<CalendarEventData<dynamic>> events) {
    final isSelected = event == _selectedEvent;
    final object = event.event;
    final taskGroupId = object is TaskEvent ? object.taskGroupId : object is ScheduledTask ? object.taskGroupId : null;
    final taskGroup = _getTaskGroup(taskGroupId);
    final backgroundColor = isSelected ? taskGroup?.softColor??event.color : event.color;
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
            color: taskGroup.accentColor,
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
              : Colors.black54, // event.color.accent,
          );
  }

  _getEventBorder(bool isSelected, object, Color backgroundColor) => isSelected ? Border.all(color: Colors.black54) :  object is ScheduledTask ? _getBorderForScheduledTask(object, backgroundColor) : null;

  Widget _customCellBuilder(
      date, List<CalendarEventData<dynamic>> events, bool isToday, bool isInMonth) {

    return FilledCell<dynamic>(
      date: date,
      shouldHighlight: isToday,
      backgroundColor: isInMonth ? Color(0xffffffff) : Color(0xfff0f0f0),
      events: events,
      getEventWidget: (events, index) {
        final event = events[index];
        final isSelected = event == _selectedEvent;
        final object = event.event;
        final taskGroupId = object is TaskEvent ? object.taskGroupId : object is ScheduledTask ? object.taskGroupId : null;
        final taskGroup = _getTaskGroup(taskGroupId);
        final backgroundColor = isSelected ? taskGroup?.softColor??event.color : event.color;
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

          _refreshModel();
        });
        _unselectEvent();
      },
    );
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
        setState(() {
          _calendarModeSelection[_calendarMode.index] = false;
          _calendarModeSelection[index] = true;
          _calendarMode = CalendarMode.values.elementAt(index);
        });
      },
    );
  }

  _getBorderForScheduledTask(ScheduledTask scheduledTask, Color defaultColor) {
    Color color = (scheduledTask.isDueNow() || scheduledTask.isNextScheduleOverdue(false) ? Colors.red : scheduledTask.getDueBackgroundColor(context)) ?? defaultColor;
    return Border.all(color: color);
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


