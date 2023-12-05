import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskRepository.dart';
import 'package:personaltasklogger/db/repository/TaskGroupRepository.dart';
import 'package:personaltasklogger/model/ScheduledTask.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/ui/utils.dart';
import 'package:personaltasklogger/util/extensions.dart';

import '../db/repository/ChronologicalPaging.dart';
import '../db/repository/TaskEventRepository.dart';
import '../db/repository/TemplateRepository.dart';
import '../model/When.dart';
import 'PersonalTaskLoggerApp.dart';
import 'TaskEventFilter.dart';



@immutable
class CalendarPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _CalendarPageStatus();
  }

}

enum EventType {EVENT, SCHEDULE, BOTH, NONE}
enum CalendarMode {DAY, WEEK, MONTH}

class _CalendarPageStatus extends State<CalendarPage> {

  final calendarDayKey = GlobalKey<DayViewState>();
  final calendarWeekKey = GlobalKey<WeekViewState>();
  final calendarMonthKey = GlobalKey<MonthViewState>();
  final calendarController = EventController<dynamic>();

  final taskFilterSettings = TaskFilterSettings();

  EventType _eventType = EventType.BOTH;
  late List<bool> _eventTypeSelection;

  CalendarMode _calendarMode = CalendarMode.DAY;
  late List<bool> _calendarModeSelection;

  List<CalendarEventData<TaskEvent>> _taskEvents = [];
  List<CalendarEventData<ScheduledTask>> _scheduledTasks = [];

  double _baseScaleFactor = 0.7;
  double _scaleFactor = 0.7;

  @override
  void initState() {
    super.initState();

    _eventTypeSelection = [true, true];
    _calendarModeSelection = List.generate(CalendarMode.values.length, (index) => index == _calendarMode.index);

    _loadEvents().then((_) {
      _refreshModel();
      _scrollToTime(DateTime.now());
    });

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
      appBar: AppBar(
        title: Text("Task Calendar"),
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
            onPressed: () {
              final now = DateTime.now();
              _scrollToTime(now);        ;
              _jumpToDate(now);
            },
          ),
        ],
      ),
      body: _createBody(context),
    );
  }

  void _refreshModel() {
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
                      ? DayView(
                          onPageChange: (date, page) {
                            _scrollToTime(now);
                          },
                          key: calendarDayKey,
                          eventTileBuilder: _customEventTileBuilder,
                          controller: calendarController,
                          heightPerMinute: _scaleFactor,
                        )
                      : _calendarMode == CalendarMode.WEEK
                        ? WeekView(
                            onPageChange: (date, page) {
                              _scrollToTime(now);
                            },
                            key: calendarWeekKey,
                            eventTileBuilder: _customEventTileBuilder,
                            controller: calendarController,
                            heightPerMinute: _scaleFactor,
                          )
                        : MonthView(
                            onPageChange: (date, page) {
                              _scrollToTime(now);        ;
                            },
                            key: calendarMonthKey,
                            //cellBuilder: ,
                            controller: calendarController,
                            cellAspectRatio: 1/(_scaleFactor * 3.5),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      final template = await TemplateRepository.findById(scheduledTask.templateId!);
      var duration = Duration(minutes: 30);
      if (template != null && template.when != null && template.when!.durationHours != null) {
        duration = When.fromDurationHoursToDuration(
            template.when!.durationHours!, template.when!.durationExactly);
      }
      duration = duration.min(Duration(minutes: 15));

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

      _scheduledTasks.add(event);
    });

    _taskEvents = taskEvents.map((taskEvent) {
      final duration = taskEvent.startedAt.difference(taskEvent.finishedAt).abs().min(Duration(minutes: 30));

      return CalendarEventData(
        date: taskEvent.startedAt,
        endDate: taskEvent.startedAt.add(duration),
        event: taskEvent,
        title: taskEvent.translatedTitle,
        description: taskEvent.translatedDescription??"",
        startTime: taskEvent.startedAt,
        endTime: taskEvent.startedAt.add(duration),
        color: TaskGroupRepository.findByIdFromCache(taskEvent.taskGroupId!).backgroundColor,
        titleStyle: TextStyle(color: Colors.black54),
      );
    }).toList();

    return true;
  }

  Widget _customEventTileBuilder(
      DateTime date,
      List<CalendarEventData<dynamic>> events,
      Rect boundary,
      DateTime startDuration,
      DateTime endDuration) {

    final isSelected = false; //TODO
    final event = events[0]; //TODO why a list?
    final object = event.event;
    final taskGroupId = object is TaskEvent ? object.taskGroupId : object is ScheduledTask ? object.taskGroupId : null;
    final taskGroup = taskGroupId != null ? TaskGroupRepository.findByIdFromCache(taskGroupId) : null;
    final icon = taskGroup != null
        ? Icon(
            taskGroup.getIcon(true).icon,
            color: taskGroup.accentColor,
            size: 16 * _scaleFactor)
        : null;
    if (events.isNotEmpty)
      return RoundedEventTile(
        borderRadius: BorderRadius.circular(6.0),
        icon: icon,
        title: event.title,
        titleStyle:
            TextStyle(
              fontSize: (14 * _scaleFactor).max(18),
              fontStyle: object is ScheduledTask ? FontStyle.italic : null,
              fontWeight: object is ScheduledTask && (object.isDueNow() || object.isNextScheduleOverdue(false)) ? FontWeight.bold : null,
              color: object is ScheduledTask
                ? (object.isDueNow() || object.isNextScheduleOverdue(false) )
                  ? Colors.red
                  : object.getDueColor(context, lighter: true)
                : Colors.black54, // event.color.accent,
            ),
        descriptionStyle: event.descriptionStyle,
        totalEvents: events.length,
        padding: EdgeInsets.all(3.0),
        border: isSelected ? Border.all(color: Colors.black54) : null,
        backgroundColor: event.color,
      );
    else
      return Container();
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

          calendarController.removeWhere((element) => true);
          _refreshModel();
        });
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


}


