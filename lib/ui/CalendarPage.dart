import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:calendar_view/calendar_view.dart';
import 'dart:ui';

import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/TaskGroupRepository.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';

import '../db/repository/ChronologicalPaging.dart';
import '../db/repository/TaskEventRepository.dart';
import 'PersonalTaskLoggerApp.dart';



@immutable
class CalendarPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _CalendarPageStatus();
  }

}


class _CalendarPageStatus extends State<CalendarPage> {

  final calendarDeyKey = GlobalKey<DayViewState>();


  @override
  void initState() {
    super.initState();
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
                /*TaskEventFilter(
                initialTaskFilterSettings: widget.taskEventListState.taskFilterSettings,
                doFilter: (taskFilterSettings, filterChangeState) {
                  setState(() {
                    _updateGroupByByFilter(filterChangeState);
                    widget.taskEventListState.taskFilterSettings = taskFilterSettings;
                    widget.taskEventListState.doFilter();
                  });
                }),*/
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
    final calendarController = EventController<TaskEvent>();
    calendarController.addAll(events);
//    calendarDeyKey.currentState?.jumpToDate(DateTime.now());

    return DayView(
      key: calendarDeyKey,
      controller: calendarController,
    );
  }

  Future<List<CalendarEventData<TaskEvent>>?> _getEvents() async {

    final paging = ChronologicalPaging(ChronologicalPaging.maxDateTime, ChronologicalPaging.maxId, 1000000);
    final taskEvents = await TaskEventRepository.getAllPaged(paging);

    return taskEvents.map((taskEvent) {
      return CalendarEventData(
        date: taskEvent.startedAt,
        endDate: taskEvent.finishedAt,
        event: taskEvent,
        title: taskEvent.translatedTitle,
        description: taskEvent.translatedDescription??"",
        startTime: taskEvent.startedAt,
        endTime: taskEvent.finishedAt,
        color: TaskGroupRepository.findByIdFromCache(taskEvent.taskGroupId!).backgroundColor,
        titleStyle: TextStyle(color: Colors.black54),
      );
    }).toList();

  }
}


