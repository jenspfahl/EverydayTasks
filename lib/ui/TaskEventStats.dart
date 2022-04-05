import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/ui/utils.dart';
import 'package:personaltasklogger/util/dates.dart';
import 'package:fl_chart/fl_chart.dart';

import "package:collection/collection.dart";


class TaskEventStats extends StatefulWidget {

  List<TaskEvent> taskEvents;

  TaskEventStats(this.taskEvents);


  @override
  State<StatefulWidget> createState() {
    return _TaskEventStatsState();
  }
}

enum SortBy {NAME, VALUE}

enum DataType {COUNT, DURATION}

class _TaskEventStatsState extends State<TaskEventStats> {

  int _touchedIndex = 0;
  DataType _dataType = DataType.DURATION;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text("Journal Statistics"),
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: _createChart(),
      ),
    )
    );
  }
  
  Widget _createChart() {

    Map<int?, List<TaskEvent>> groupedTaskEvents = groupBy(widget.taskEvents, (event) => event.taskGroupId);

    Map<int?, dynamic> dataMap = groupedTaskEvents.map((taskGroupId, taskEvents) {
      return MapEntry(
          taskGroupId,
          _aggregateValue(taskEvents));
      }
    );

    final dataList = dataMap.entries
        .map((e) => Pair(e.key, e.value));
    //TODO sort map


    return AspectRatio(
      aspectRatio: 1,
      child: PieChart(
        PieChartData(
            pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                }),
            borderData: FlBorderData(
              show: false,
            ),
            sectionsSpace: 0,
            centerSpaceRadius: 0,
            sections: _showingSections(dataList)),
      ),
    );
  }




  List<PieChartSectionData> _showingSections(Iterable<Pair> rawDataList) {
    return rawDataList.mapIndexed((i, data) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;
      final widgetSize = isTouched ? 55.0 : 40.0;

      int? taskGroupId = data.first;
      final value = _getValue(data.second);
      final taskGroup = taskGroupId != null
          ? findPredefinedTaskGroupById(taskGroupId)
          : null;
      final taskGroupName = taskGroup != null
          ? taskGroup.name
          : "-unknown-";

      return PieChartSectionData(
        color: getSharpedColor(getTaskGroupColor(taskGroupId, false)),
        value: value,
        title: taskGroupName,
        radius: radius,
        titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xffffffff)),
        badgeWidget: taskGroup?.getIcon(true),
        badgePositionPercentageOffset: .98,
      );
    }).toList();
  }

  dynamic _aggregateValue(List<TaskEvent> taskEvents) {
      switch (_dataType) {
      case DataType.DURATION: {
        return _sumDuration(taskEvents);
      }
      case DataType.COUNT: {
        return taskEvents.length;
      }
    }
  }

  Duration _sumDuration(List<TaskEvent> taskEvents) {
    return taskEvents
        .map((event) => event.duration)
        .fold(Duration(), (previousDuration, duration) => previousDuration + duration);
  }

  double _getValue(dynamic value) {
    switch (_dataType) {
      case DataType.DURATION:
        {
          Duration duration = value;
          return duration.inMinutes.toDouble();
        }
      case DataType.COUNT:
        {
          int count = value;
          return count.toDouble();
        }
    }
  }
  
} 