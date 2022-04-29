import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:personaltasklogger/db/repository/TemplateRepository.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/TemplateId.dart';
import 'package:personaltasklogger/ui/TaskEventFilter.dart';
import 'package:personaltasklogger/ui/pages/TaskEventList.dart';
import 'package:personaltasklogger/ui/utils.dart';
import 'package:personaltasklogger/util/dates.dart';
import 'package:fl_chart/fl_chart.dart';

import "package:collection/collection.dart";

import '../model/Template.dart';
import '../util/units.dart';


class TaskEventStats extends StatefulWidget {

  TaskEventListState taskEventListState;

  TaskEventStats(this.taskEventListState);


  @override
  State<StatefulWidget> createState() {
    return _TaskEventStatsState();
  }
}

enum DataType {DURATION, COUNT}
enum SortBy {NAME, VALUE}
enum GroupBy {TASK_GROUP, TEMPLATE}

class _TaskEventStatsState extends State<TaskEventStats> {

  int _touchedIndex = -1;

  GroupBy _groupBy = GroupBy.TASK_GROUP;
  late List<bool> _groupBySelection;

  DataType _dataType = DataType.DURATION;
  late List<bool> _dataTypeSelection;

  @override
  void initState() {
    if (widget.taskEventListState.taskFilterSettings.filterByTaskOrTemplate != null) {
      _updateGroupByByFilter(FilterChangeState.TASK_ON);
    }
    if (widget.taskEventListState.taskFilterSettings.filterByTaskEventIds != null) {
      _updateGroupByByFilter(FilterChangeState.SCHEDULED_ON);
    }

    _dataTypeSelection = List.generate(DataType.values.length, (index) => index == _dataType.index);
    _groupBySelection = List.generate(GroupBy.values.length, (index) => index == _groupBy.index);

    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Journal Statistics"),
        actions: [
          TaskEventFilter(
              initialTaskFilterSettings: widget.taskEventListState.taskFilterSettings,
              doFilter: (taskFilterSettings, filterChangeState) {
                setState(() {
                  _updateGroupByByFilter(filterChangeState);
                  widget.taskEventListState.taskFilterSettings = taskFilterSettings;
                  widget.taskEventListState.doFilter();
                });
              }),
        ],
      ),
      body: _createBody(),
    );
  }
  
  Widget _createBody() {

    Map<int?, List<TaskEvent>> groupedTaskEvents = groupBy(
        widget.taskEventListState.getVisibleTaskEvents(), (event) => event.taskGroupId);

    Map<int?, Map<TemplateId?, dynamic>> dataMap = groupedTaskEvents.map((taskGroupId, taskEvents) {
      if (_groupBy == GroupBy.TASK_GROUP) {
        return MapEntry(
            taskGroupId,
            Map.fromEntries([MapEntry(
              null,
              _aggregateValue(taskEvents))]));
      }
      else if (_groupBy == GroupBy.TEMPLATE) {
        Map<TemplateId?, List<TaskEvent>> groupedTemplates = groupBy(taskEvents, (event) => event.originTemplateId);

        Map<TemplateId?, dynamic> templateDataMap = groupedTemplates.map((templateId, subTaskEvents) {
          return MapEntry(
              templateId,
              _aggregateValue(subTaskEvents));
        });

        return MapEntry(taskGroupId, templateDataMap);
      }
      else {
        throw Exception("Programming error: unknown GroupBy: $_groupBy");
      }
    });

    final dataList = dataMap.entries
        .expand((e) => e.value.entries
            .map((templateMap) => SliceData(e.key, templateMap.key,  templateMap.value))
          )
        .sorted((a, b) {
          final c = _getDataValue(a.value).compareTo(_getDataValue(b.value));
          if (c == 0) {
            return a.taskGroupId??-1.compareTo(b.taskGroupId??-1);
          }
          return c;
    }).reversed;

    final totalValue = dataMap.entries
        .expand((e) => e.value.entries.map((e) => _getDataValue(e.value)))
        .fold(0.0, (double previous, current) => previous + current);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              _createDataButton(),
              Spacer(),
              _createGroupByButton(),
            ],
          ),
        ),
        AspectRatio(
          aspectRatio: MediaQuery.of(context).orientation == Orientation.portrait ? 1.2 : 2.7,
          child: Stack(
            children: [
              Visibility(
                visible: _showIconInCircle(),
                child: Center(
                  child: _getTaskGroupIcon(_getTaskGroupFromFilter()),
                ),
              ),
              PieChart(
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
                    centerSpaceRadius: _groupBy == GroupBy.TEMPLATE ? 30 : 0,
                    sections: _createSections(dataList, totalValue),
                ),
                swapAnimationDuration: Duration(milliseconds: 75),
              ),
            ],
          ),
        ),
        _buildLegend(dataList, totalValue),
      ],
    );
  }

  List<PieChartSectionData> _createSections(Iterable<SliceData> dataList, num totalValue) {
    return dataList.mapIndexed((i, data) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final r = _groupBy == GroupBy.TEMPLATE ? 70.0 : 100.0;
      final radius = isTouched ? r * 1.1 : r;

      final value = _getDataValue(data.value);

      int? taskGroupId = data.taskGroupId;
      final taskGroup = taskGroupId != null
          ? findPredefinedTaskGroupById(taskGroupId)
          : null;

      var percentValue = _valueToPercent(value, totalValue);
      return PieChartSectionData(
        color: data.templateId == null
            ? getSharpedColor(getTaskGroupColor(taskGroupId, false), 2.2)
            : getTaskGroupColor(taskGroupId, data.templateId!.isVariant),
        value: value,
        title: _valueToPercentString(percentValue, i),
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
          child: _showIconInCircle() ? null : _getTaskGroupIcon(taskGroup),
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

  Widget _buildLegend(Iterable<SliceData> dataList, double totalValue) {

    return Expanded(
      child: FutureBuilder(
        future: _createLegendElements(dataList, totalValue),
        builder: (context, AsyncSnapshot<List<Container>> snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return snapshot.data!.length > index ? snapshot.data![index] : Text("-unknown-");
              },
            );
          }
          else if (snapshot.hasError) {
            return Text("Error " + snapshot.error.toString());
          }
          else {
            return Text("loading..");
          }
        },
      ),
    );

  }

  Future<List<Container>> _createLegendElements(Iterable<SliceData> dataList, double totalValue) async {
    final legendElementFutures = dataList.mapIndexed((i, data) async {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.1 : 16.0;
      final fontWeight = isTouched ? FontWeight.bold : null;
    
      int? taskGroupId = data.taskGroupId;
      final taskGroup = taskGroupId != null
          ? findPredefinedTaskGroupById(taskGroupId)
          : null;
    
      final template = data.templateId != null ? await TemplateRepository.findById(data.templateId!) : null;

      var title = "-unknown-";
      if (template != null) {
        title = template.title;
      }
      else if (taskGroup != null) {
        title = _groupBy == GroupBy.TASK_GROUP
            ? taskGroup.name
            : "-others-";
      }
      final groupedByPresentation = Row(
          children: [
            taskGroup?.getIcon(true) ?? Text("?"),
            Text(truncate(title, length: 30), //TODO cutting this is not enough for long durarion strings
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isTouched ? 14.1 : 14.0,
                fontWeight: fontWeight)),
          ]);
    
      var bgColor = data.templateId == null
            ? getSharpedColor(getTaskGroupColor(taskGroupId, false), 1.9)
            : getTaskGroupColor(taskGroupId, data.templateId!.isVariant);
      return Container(
        height: 30,
       /* color: data.templateId == null
            ? (taskGroup != null ? taskGroup.backgroundColor : null)
            : getTaskGroupColor(taskGroupId, !data.templateId!.isVariant),*/
        color: bgColor.withAlpha((bgColor.alpha * 0.6).toInt()),
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
              groupedByPresentation,
              Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: Text(_getDataValueAsString(data.value),
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
    
    legendElementFutures.insert(0, Future.value(Container(
      height: 30, child: Text("Total $totalValueAsString",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold)))
    ));
    return Future.wait(legendElementFutures);
  }

  Icon _getTaskGroupIcon(TaskGroup? taskGroup) {
    return taskGroup != null
        ? taskGroup.getIcon(true)
        : Icon(Icons.question_mark_outlined,
          color: Colors.grey,);
  }

  String _valueToPercentString(int percentValue, int index) {
    return percentValue < 1
        ? ""
        : ((percentValue == 1 && index % 2 == 0)
          ? ""
          : "$percentValue%");
  }

  int _valueToPercent(double value, num total) {
    if (total == 0) {
      return 0;
    }
    return (value * 100 / total).round();
  }

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
          _dataTypeSelection[_dataType.index] = false;
          _dataTypeSelection[index] = true;
          _dataType = DataType.values.elementAt(index);
        });
      },
    );
  }


  Widget _createGroupByButton() {
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
                const Icon(Icons.category_outlined,),
                const Text("Categories", textAlign: TextAlign.center),
              ],
            )
        ),
        SizedBox(
            width: 75,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.task_alt),
                const Text("Tasks", textAlign: TextAlign.center),
              ],
            )
        ),
      ],
      isSelected: _groupBySelection,
      onPressed: (int index) {
        setState(() {
          _groupBySelection[_groupBy.index] = false;
          _groupBySelection[index] = true;
          _groupBy = GroupBy.values.elementAt(index);
        });
      },
    );
  }


  void _updateGroupByByFilter(FilterChangeState filterChangeState) {
    debugPrint("old: $_groupBy $filterChangeState");

    if (filterChangeState == FilterChangeState.TASK_ON
        || filterChangeState == FilterChangeState.SCHEDULED_ON) {
      _groupBy = GroupBy.TEMPLATE;
    }
    else if (filterChangeState == FilterChangeState.TASK_OFF
        || filterChangeState == FilterChangeState.SCHEDULED_OFF
        || filterChangeState == FilterChangeState.ALL_OFF) {
      _groupBy = GroupBy.TASK_GROUP;
    }
    debugPrint("new: $_groupBy");
    _groupBySelection = List.generate(GroupBy.values.length, (index) => index == _groupBy.index);
  }

  bool _showIconInCircle() => widget.taskEventListState.taskFilterSettings.filterByTaskOrTemplate != null
      && _groupBy == GroupBy.TEMPLATE;

  TaskGroup? _getTaskGroupFromFilter() {
    if (widget.taskEventListState.taskFilterSettings.filterByTaskOrTemplate is TaskGroup) {
      return widget.taskEventListState.taskFilterSettings.filterByTaskOrTemplate as TaskGroup;
    }
    else if (widget.taskEventListState.taskFilterSettings.filterByTaskOrTemplate is Template) {
      final template = widget.taskEventListState.taskFilterSettings.filterByTaskOrTemplate as Template;
      return findPredefinedTaskGroupById(template.taskGroupId);
    }
    else if (widget.taskEventListState.taskFilterSettings.filterByScheduledTask != null) {
      return findPredefinedTaskGroupById(widget.taskEventListState.taskFilterSettings.filterByScheduledTask!.taskGroupId);
    }
    else {
      return null;
    }
  }

}

class SliceData {
  int? taskGroupId;
  TemplateId? templateId;
  dynamic value;

  SliceData(this.taskGroupId, this.templateId, this.value);
}
