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

enum DataType {DURATION, COUNT}

class _TaskEventStatsState extends State<TaskEventStats> {

  int _touchedIndex = -1;
  DataType _dataType = DataType.DURATION;

  late List<bool> _dataTypeSelection;
  int? _dataTypeIndex;

  @override
  void initState() {
    _dataTypeIndex = _dataType.index;
    _dataTypeSelection = List.generate(DataType.values.length, (index) => index == _dataTypeIndex);
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text("Journal Statistics"),
    ),
    body: _createBody(),
    );
  }
  
  Widget _createBody() {

    Map<int?, List<TaskEvent>> groupedTaskEvents = groupBy(widget.taskEvents, (event) => event.taskGroupId);

    Map<int?, dynamic> dataMap = groupedTaskEvents.map((taskGroupId, taskEvents) {
      return MapEntry(
          taskGroupId,
          _aggregateValue(taskEvents));
      }
    );

    final dataList = dataMap.entries
        .map((e) => Pair(e.key, e.value))
        .sorted((a, b) {
          final c = _getDataValue(a.second).compareTo(_getDataValue(b.second));
          if (c == 0) {
            return a.first??-1.compareTo(b.first??-1);
          }
          return c;
    }).reversed;

    final totalValue = dataMap.entries
        .map((e) => _getDataValue(e.value))
        .fold(0.0, (double previous, current) => previous + current);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _createDataButton(),
        ),
        AspectRatio(
          aspectRatio: MediaQuery.of(context).orientation == Orientation.portrait ? 1.2 : 2.7,
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
        _buildLegend(dataList, totalValue),
      ],
    );
  }

  List<PieChartSectionData> _showingSections(Iterable<Pair> dataList, num totalValue) {
    return dataList.mapIndexed((i, data) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;

      final value = _getDataValue(data.second);

      int? taskGroupId = data.first;
      final taskGroup = taskGroupId != null
          ? findPredefinedTaskGroupById(taskGroupId)
          : null;

      var percentValue = _valueToPercent(value, totalValue);
      return PieChartSectionData(
        color: getSharpedColor(getTaskGroupColor(taskGroupId, false)),
        value: value,
        title: _valueToPercentString(percentValue),
        radius: radius,
        titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
        ),
        badgeWidget: GestureDetector(
          behavior: HitTestBehavior.translucent,
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
        titlePositionPercentageOffset: (percentValue <= 5) ? (i % 2 == 0 ? 0.9 : 0.8) : 0.6, // avoid overlapping titles
        badgePositionPercentageOffset: (percentValue <= 5 && i % 2 == 0) ? 1.45 : 1.2, // avoid overlapping icons
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
          return Items(count).toString();
        }
    }
  }

  Widget _buildLegend(Iterable<Pair> dataList, double totalValue) {
    final legendElements = dataList.mapIndexed((i, data) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.1 : 16.0;
      final fontWeight = isTouched ? FontWeight.bold : null;

      int? taskGroupId = data.first;
      final taskGroup = taskGroupId != null
          ? findPredefinedTaskGroupById(taskGroupId)
          : null;

      return Container(
        height: 30,
        color: taskGroup != null ? taskGroup.backgroundColor : null,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
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
              taskGroup != null
                  ? taskGroup.getTaskGroupRepresentation(
                    useIconColor: true,
                    textStyle: TextStyle(
                      fontSize: isTouched ? 14.1 : 14.0,
                      fontWeight: fontWeight))
                  : Text("?"),
              Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: Text(_getDataValueAsString(data.second),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight)
                ),
              )
            ],
          ),
        ),
      );
    }).toList();

    final totalValueAsString = _dataType == DataType.DURATION
      ? formatDuration(Duration(minutes: totalValue.toInt()))
      : Items(totalValue.toInt());

    legendElements.insert(0, Container(
      height: 30, child: Text("Total $totalValueAsString",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold)))
    );
    return Expanded(
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: legendElements
      ),
    );
  }

  Icon _getTaskGroupIcon(TaskGroup? taskGroup) {
    return taskGroup != null
        ? taskGroup.getIcon(true)
        : Icon(Icons.question_mark_outlined,
          color: Colors.grey,);
  }

  _valueToPercentString(int percentValue) {
    return "${percentValue}%";
  }

  int _valueToPercent(double value, num total) => (value * 100 / total).round();

  Widget _createDataButton() {
    return ToggleButtons(
      borderRadius: BorderRadius.all(Radius.circular(5.0)),
      renderBorder: true,
      borderWidth: 1.5,
      borderColor: Colors.grey,
      color: Colors.grey.shade600,
      selectedBorderColor: Colors.blue,
      children: [
        SizedBox(
          width: 75,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined),
              const Text("Duration", textAlign: TextAlign.center),
            ],
          )
        ),
        SizedBox(
          width: 75,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.numbers_outlined),
              const Text("Total count", textAlign: TextAlign.center),
            ],
          )
        ),
      ],
      isSelected: _dataTypeSelection,
      onPressed: (int index) {
        setState(() {
          if (_dataTypeIndex != null) {
            _dataTypeSelection[_dataTypeIndex!] = false;
          }
          _dataTypeSelection[index] = true;
          _dataType = DataType.values.elementAt(index);
          _dataTypeIndex = index;
        });
      },
    );
  }

}
