import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/ui/ToggleActionIcon.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/util/dates.dart';

@immutable
class TaskEventFilter extends StatefulWidget {

  TaskFilterSettings? initialTaskFilterSettings;
  Function(TaskEventFilterState) doFilter;

  TaskEventFilter({this.initialTaskFilterSettings, required this.doFilter, Key? key}) :super(key: key);

  @override
  State<StatefulWidget> createState() => TaskEventFilterState();
}

class TaskFilterSettings {
  DateTimeRange? filterByDateRange;
  Severity? filterBySeverity;
  bool filterByFavorites = false;
  Object? filterByTaskOrTemplate;
  List<int>? filterByTaskEventIds;
}

class TaskEventFilterState extends State<TaskEventFilter> {

  final filterIconKey = new GlobalKey<ToggleActionIconState>();
  TaskFilterSettings taskFilterSettings = TaskFilterSettings();

  @override
  void initState() {
    if (widget.initialTaskFilterSettings != null) {
      taskFilterSettings = widget.initialTaskFilterSettings!;
    }
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    final filterIcon = ToggleActionIcon(Icons.filter_alt, Icons.filter_alt_outlined, isFilterActive(), filterIconKey);

    return GestureDetector(
      child: Padding(padding: EdgeInsets.symmetric(horizontal: 6.0),
          child: filterIcon),
      onTapDown: (details) {
        showPopUpMenuAtTapDown(
            context,
            details,
            [
              PopupMenuItem<String>(
                  child: Row(
                      children: [
                        Icon(
                          taskFilterSettings.filterByDateRange != null ? Icons.calendar_today : Icons.calendar_today_outlined,
                          color: taskFilterSettings.filterByDateRange != null ? Colors.blueAccent : null,
                        ),
                        const Spacer(),
                        Text(taskFilterSettings.filterByDateRange != null
                            ?  "${formatToDateOrWord(taskFilterSettings.filterByDateRange!.start)} to ${formatToDateOrWord(taskFilterSettings.filterByDateRange!.end).toLowerCase()}"
                            : "Filter by date range"),
                      ]
                  ),
                  value: '1'),
              PopupMenuItem<String>(
                  child: Row(
                      children: [
                        taskFilterSettings.filterBySeverity != null
                            ? severityToIcon(taskFilterSettings.filterBySeverity!, Colors.blueAccent)
                            : Icon(Icons.fitness_center_rounded),
                        const Spacer(),
                        Text(taskFilterSettings.filterBySeverity != null
                            ? severityToString(taskFilterSettings.filterBySeverity!)
                            : "Filter by severity"),
                      ]
                  ),
                  value: '2'),
              PopupMenuItem<String>(
                  child: Row(
                      children: [
                        Icon(
                          taskFilterSettings.filterByFavorites ? Icons.favorite : Icons.favorite_border,
                          color: taskFilterSettings.filterByFavorites ? Colors.blueAccent : null,
                        ),
                        const Spacer(),
                        const Text("Filter favorites"),
                      ]
                  ),
                  value: '3'),
              PopupMenuItem<String>(
                  child: Row(
                      children: [
                        taskFilterSettings.filterByTaskOrTemplate != null
                            ? taskFilterSettings.filterByTaskOrTemplate is TaskGroup
                            ? (taskFilterSettings.filterByTaskOrTemplate as TaskGroup).getIcon(true)
                            : (taskFilterSettings.filterByTaskOrTemplate as Template).getIcon(true)
                            : const Icon(Icons.task_alt),
                        const Spacer(),
                        Text(taskFilterSettings.filterByTaskOrTemplate != null
                            ? taskFilterSettings.filterByTaskOrTemplate is TaskGroup
                            ? (taskFilterSettings.filterByTaskOrTemplate as TaskGroup).name
                            : (taskFilterSettings.filterByTaskOrTemplate as Template).title
                            : "Filter by task"),
                      ]
                  ),
                  value: '4'),
              PopupMenuItem<String>(
                  child: Row(
                      children: [
                        Icon(
                          isFilterActive() ? Icons.clear : Icons.clear_outlined,
                          color: isFilterActive() ? Colors.blueAccent : null,
                        ),
                        const Spacer(),
                        const Text("Clear filters"),
                      ]
                  ),
                  value: '5'),
            ]
        ).then((selected) {
          switch (selected) {
            case '1' : {
              if (taskFilterSettings.filterByDateRange == null) {
                showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(Duration(days: 365)),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                  currentDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          // TODO i don't know why but without that the app bar text id white here !!!
                          onPrimary: Colors.black, // header text color
                        ),

                      ),
                      child: child!,
                    );},
                ).then((dateRange) {
                  if (dateRange != null) {
                    taskFilterSettings.filterByDateRange = dateRange;
                    widget.doFilter(this);
                    filterIconKey.currentState?.refresh(isFilterActive());
                  }
                });
              }
              else {
                taskFilterSettings.filterByDateRange = null;
                widget.doFilter(this);
                filterIconKey.currentState?.refresh(isFilterActive());
              }
              break;
            }

            case '2' : {
              showSeverityPicker(
                  context, taskFilterSettings.filterBySeverity, true, (selected) {
                taskFilterSettings.filterBySeverity = selected;
                widget.doFilter(this);
                filterIconKey.currentState?.refresh(isFilterActive());
                Navigator.pop(context);
              });
              break;
            }

            case '3' : {
              taskFilterSettings.filterByFavorites = !taskFilterSettings.filterByFavorites;
              widget.doFilter(this);
              filterIconKey.currentState?.refresh(isFilterActive());
              break;
            }

            case '4' : {
              if (taskFilterSettings.filterByTaskOrTemplate == null) {
                Object? selectedItem = null;
                showTemplateDialog(context, "Filter by task", "Select a category or task to filter by.",
                  selectedItem: (item) {
                    selectedItem = item;
                  },
                  okPressed: () {
                    Navigator.pop(context);
                    taskFilterSettings.filterByTaskOrTemplate = selectedItem;
                    widget.doFilter(this);
                    filterIconKey.currentState?.refresh(isFilterActive());
                  },
                  cancelPressed: () =>
                      Navigator.pop(context), // dis
                );
              }
              else {
                taskFilterSettings.filterByTaskOrTemplate = null;
                widget.doFilter(this);
                filterIconKey.currentState?.refresh(isFilterActive());
              }
              break;
            }
            case '5' : {
              clearFilters();
              widget.doFilter(this);
              filterIconKey.currentState?.refresh(isFilterActive());
              break;
            }
          }
        });
      },
    );
  }

  bool isFilterActive() => taskFilterSettings.filterByTaskEventIds != null
      || taskFilterSettings.filterByDateRange != null
      || taskFilterSettings.filterBySeverity != null
      || taskFilterSettings.filterByFavorites
      || taskFilterSettings.filterByTaskOrTemplate != null;

  void clearFilters() {
    taskFilterSettings.filterByTaskEventIds = null;
    taskFilterSettings.filterByDateRange = null;
    taskFilterSettings.filterBySeverity = null;
    taskFilterSettings.filterByFavorites = false;
    taskFilterSettings.filterByTaskOrTemplate = null;
  }

  void refresh(TaskFilterSettings? taskFilterSettings) {
    setState(() {
      if (taskFilterSettings != null) {
        this.taskFilterSettings = taskFilterSettings;
        filterIconKey.currentState?.refresh(isFilterActive());
      }
    });
  }

}
