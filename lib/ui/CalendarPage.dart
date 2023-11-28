import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/TaskGroupRepository.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/ui/utils.dart';

import '../db/repository/ChronologicalPaging.dart';
import '../db/repository/TaskEventRepository.dart';
import 'PersonalTaskLoggerApp.dart';
import 'TaskEventFilter.dart';



@immutable
class CalendarPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _CalendarPageStatus();
  }

}

enum EventType {EVENT, SCHEDULE, BOTH}
enum CalendarMode {DAY, WEEK, MONTH}

class _CalendarPageStatus extends State<CalendarPage> {

  final calendarDayKey = GlobalKey<DayViewState>();
  final calendarController = EventController<TaskEvent>();

  final taskFilterSettings = TaskFilterSettings();

  EventType _eventType = EventType.BOTH;
  late List<bool> _eventTypeSelection;

  CalendarMode _calendarMode = CalendarMode.DAY;
  late List<bool> _calendarModeSelection;


  double _baseScaleFactor = 0.7;
  double _scaleFactor = 0.7;

  @override
  void initState() {
    super.initState();

    _eventTypeSelection = [_eventType != EventType.SCHEDULE, _eventType != EventType.EVENT];
    _calendarModeSelection = List.generate(CalendarMode.values.length, (index) => index == _calendarMode.index);
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getEvents(),
      builder: (BuildContext context, AsyncSnapshot<List<CalendarEventData<TaskEvent>>?> snapshot) {
        if (snapshot.hasData) {
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
                    calendarDayKey.currentState?.jumpToDate(DateTime.now());
                    calendarDayKey.currentState?.jumpToEvent(calendarController.events.first);
                  },
                ),
              ],
            ),
            body: _createBody(context, snapshot.data??List.empty()),
          );
        }
        else {
          return Text("..");
        }
      },
    );
  }

  Widget _createBody(BuildContext context, List<CalendarEventData<TaskEvent>> events) {
    calendarController.addAll(events);

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
                  child: DayView(
                    key: calendarDayKey,
                    controller: calendarController,
                    heightPerMinute: _scaleFactor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<CalendarEventData<TaskEvent>>?> _getEvents() async {

    final paging = ChronologicalPaging(ChronologicalPaging.maxDateTime, ChronologicalPaging.maxId, 1000000);
    final taskEvents = await TaskEventRepository.getAllPaged(paging);

    return taskEvents.map((taskEvent) {
      return CalendarEventData(
        date: taskEvent.startedAt,
        endDate: taskEvent.finishedAtForCalendar,
        event: taskEvent,
        title: taskEvent.translatedTitle,
        description: taskEvent.translatedDescription??"",
        startTime: taskEvent.startedAt,
        endTime: taskEvent.finishedAtForCalendar,
        color: TaskGroupRepository.findByIdFromCache(taskEvent.taskGroupId!).backgroundColor,
        titleStyle: TextStyle(color: Colors.black54),
      );
    }).toList();

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
                Icon(Icons.event_available_rounded, color: isDarkMode(context) ? (_eventType != EventType.SCHEDULE ? PRIMARY_COLOR : null) : null),
              ],
            )
        ),
        SizedBox(
            width: 75,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.next_plan_outlined, color: isDarkMode(context) ? (_eventType != EventType.EVENT  ? PRIMARY_COLOR : null) : null),
              ],
            )
        ),
      ],
      isSelected: _eventTypeSelection,
      onPressed: (int index) {
        setState(() {
          _eventTypeSelection[index] = !_eventTypeSelection[index];
          if (_eventTypeSelection[index]) {
            if (_eventType == EventType.SCHEDULE) {
              _eventType = EventType.BOTH;
            }
            else {
              _eventType = EventType.EVENT;
            }
          }
          else {
            if (_eventType == EventType.SCHEDULE) {
              _eventType = EventType.BOTH;
            }
            else {
              _eventType = EventType.EVENT;
            }
          }

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


