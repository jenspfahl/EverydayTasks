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

  int _touchedIndex = -1;
  DataType _dataType = DataType.DURATION;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text("Journal Statistics"),
    ),
    body: SingleChildScrollView(
      child: _createChart(),
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
        .map((e) => Pair(e.key, e.value))
        .sorted((a, b) => _getDataValue(a.second).compareTo(_getDataValue(b.second))).reversed;

    final totalValue = dataMap.entries
        .map((e) => _getDataValue(e.value))
        .fold(0.0, (double previous, current) => previous + current);

    return Column(
      children: [
        AspectRatio(
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
                sectionsSpace: 0.9,
                centerSpaceRadius: 0,
                sections: _showingSections(dataList, totalValue)),
          ),
        ),
        const SizedBox(
          height: 28,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _buildLegend(dataList),
        )
      ],
    );
  }




  List<PieChartSectionData> _showingSections(Iterable<Pair> dataList, num totalValue) {
    return dataList.mapIndexed((i, data) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;

      int? taskGroupId = data.first;
      final value = _getDataValue(data.second);
      final taskGroup = taskGroupId != null
          ? findPredefinedTaskGroupById(taskGroupId)
          : null;
      final taskGroupName = _getTaskGroupName(taskGroup);

      return PieChartSectionData(
        color: getSharpedColor(getTaskGroupColor(taskGroupId, false)),
        value: value,
        title: _valueToPercent(value, totalValue),
        radius: radius,
        titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
        ),
        badgeWidget: GestureDetector(
            onTapDown: (details) {
              setState(() {
                debugPrint("index=$i");
                _touchedIndex = i;
              });
            },
            onTapUp: (details) {
              setState(() {
                _touchedIndex = -1;
              });
            },
          child: _getTaskGroupIcon(taskGroup),
        ),
        badgePositionPercentageOffset: i % 2 == 0 ? 1.2 : 1.2, // TODO avoid overlapping icons
      );
    }).toList();
  }

  String _getTaskGroupName(TaskGroup? taskGroup) {
    final taskGroupName = taskGroup != null
        ? taskGroup.name
        : "-unknown-";
    return taskGroupName;
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

  double _getDataValue(dynamic value) {
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
  
  String _getDataValueAsString(dynamic value) {
    switch (_dataType) {
      case DataType.DURATION:
        {
          Duration duration = value;
          return formatDuration(duration);
        }
      case DataType.COUNT:
        {
          int count = value;
          return "$count items";
        }
    }
  }

  Widget _buildLegend(Iterable<Pair> dataList) {
    final legendElements = dataList.mapIndexed((i, data) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.1 : 16.0;

      int? taskGroupId = data.first;
      final taskGroup = taskGroupId != null
          ? findPredefinedTaskGroupById(taskGroupId)
          : null;

      return GestureDetector(
        onTapDown: (details) {
          setState(() {
            _touchedIndex = i;
          });
        },
        onTapUp: (details) {
          setState(() {
            _touchedIndex = -1;
          });
        },
        child: Row(
          children: [
            taskGroup != null ? taskGroup.getTaskGroupRepresentation(useIconColor: true, useBackgroundColor: isTouched) : Text("?"),
            Spacer(),
            Text(_getDataValueAsString(data.second),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isTouched ? FontWeight.bold : null)
            )
          ],
        ),
      );
    }).toList();

    return Column(children: legendElements);
  }

  Icon _getTaskGroupIcon(TaskGroup? taskGroup) {
    return taskGroup != null
        ? taskGroup.getIcon(true)
        : Icon(Icons.question_mark_outlined,
          color: Colors.grey,);
  }

  _valueToPercent(double value, num total) {
    return "${(value * 100 / total).round()}%";
  }

}
