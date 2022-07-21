import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/model/ScheduledTask.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/ui/ToggleActionIcon.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/util/dates.dart';

import 'PersonalTaskLoggerApp.dart';
import 'utils.dart';

@immutable
class TaskEventFilter extends StatefulWidget {

  TaskFilterSettings? initialTaskFilterSettings;
  Function(TaskFilterSettings, FilterChangeState) doFilter;

  TaskEventFilter({this.initialTaskFilterSettings, required this.doFilter, Key? key}) :super(key: key);

  @override
  State<StatefulWidget> createState() => TaskEventFilterState();
}

enum FilterChangeState {
  DATE_RANGE_ON, DATE_RANGE_OFF, 
  SEVERITY_ON, SEVERITY_OFF,
  FAVORITE_ON, FAVORITE_OFF, 
  TASK_ON, TASK_OFF, 
  SCHEDULED_ON, SCHEDULED_OFF, 
  ALL_OFF, }

class TaskFilterSettings {
  DateTimeRange? filterByDateRange;
  Severity? filterBySeverity;
  bool filterByFavorites = false;
  Object? filterByTaskOrTemplate;
  List<int>? filterByTaskEventIds;
  // this goes together with filterByTaskEventIds and is only needed to get info about the used schedule
  ScheduledTask? filterByScheduledTask;

  bool isFilterActive() => filterByTaskEventIds != null
      || filterByScheduledTask != null
      || filterByDateRange != null
      || filterBySeverity != null
      || filterByFavorites
      || filterByTaskOrTemplate != null;

  void clearFilters() {
    filterByTaskEventIds = null;
    filterByScheduledTask = null;
    filterByDateRange = null;
    filterBySeverity = null;
    filterByFavorites = false;
    filterByTaskOrTemplate = null;
  }

}

class TaskEventFilterState extends State<TaskEventFilter> {

  final filterIconKey = new GlobalKey<ToggleActionIconState>();
  TaskFilterSettings taskFilterSettings = TaskFilterSettings(); //TODO always from outside

  @override
  void initState() {
    if (widget.initialTaskFilterSettings != null) {
      taskFilterSettings = widget.initialTaskFilterSettings!;
    }
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    final filterIcon = ToggleActionIcon(Icons.filter_alt, Icons.filter_alt_outlined, taskFilterSettings.isFilterActive(), filterIconKey);

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
                          color: taskFilterSettings.filterByDateRange != null ? BUTTON_COLOR : null,
                        ),
                        const Spacer(),
                        Text(taskFilterSettings.filterByDateRange != null
                            ?  "${formatToDateWithFormatSelection(taskFilterSettings.filterByDateRange!.start, context, 1, false)} ${translate('common.words.to_for_times')} ${formatToDateWithFormatSelection(taskFilterSettings.filterByDateRange!.end, context, 1, false)}"
                            : translate('filter.menu.by_date_range')),
                      ]
                  ),
                  value: '1'),
              PopupMenuItem<String>(
                  child: Row(
                      children: [
                        taskFilterSettings.filterBySeverity != null
                            ? severityToIcon(taskFilterSettings.filterBySeverity!, BUTTON_COLOR)
                            : Icon(Icons.fitness_center_rounded),
                        const Spacer(),
                        Text(taskFilterSettings.filterBySeverity != null
                            ? severityToString(taskFilterSettings.filterBySeverity!)
                            : translate('filter.menu.by_severity')),
                      ]
                  ),
                  value: '2'),
              PopupMenuItem<String>(
                  child: Row(
                      children: [
                        Icon(
                          taskFilterSettings.filterByFavorites ? Icons.favorite : Icons.favorite_border,
                          color: taskFilterSettings.filterByFavorites ? BUTTON_COLOR : null,
                        ),
                        const Spacer(),
                        Text(translate('filter.menu.by_favorites')),
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
                            : Icon(taskFilterSettings.filterByTaskEventIds != null ? Icons.checklist : Icons.task_alt,
                                color: taskFilterSettings.filterByTaskEventIds != null
                                    ? _getColorFromScheduledTask(taskFilterSettings.filterByScheduledTask!)
                                    : null),
                        const Spacer(),
                        Text(taskFilterSettings.filterByTaskOrTemplate != null
                            ? taskFilterSettings.filterByTaskOrTemplate is TaskGroup
                            ? (taskFilterSettings.filterByTaskOrTemplate as TaskGroup).translatedName
                            : (taskFilterSettings.filterByTaskOrTemplate as Template).translatedTitle
                            : (taskFilterSettings.filterByTaskEventIds != null
                              ? translate('filter.menu.by_schedule')
                              : translate('filter.menu.by_task'))),
                      ]
                  ),
                  value: '4'),
              PopupMenuItem<String>(
                  child: Row(
                      children: [
                        Icon(
                          taskFilterSettings.isFilterActive() ? Icons.clear : Icons.clear_outlined,
                          color: taskFilterSettings.isFilterActive() ? BUTTON_COLOR : null,
                        ),
                        const Spacer(),
                        Text(translate('filter.menu.clear_all')),
                      ]
                  ),
                  value: '5'),
            ]
        ).then((selected) {
          switch (selected) {
            case '1' : {
            //  if (taskFilterSettings.filterByDateRange == null) {
              showTweakedDateRangePicker(context,
                  initialDateRange: taskFilterSettings.filterByDateRange,
                ).then((dateRange) {
                  if (dateRange != null) {
                    taskFilterSettings.filterByDateRange = dateRange;
                    widget.doFilter(taskFilterSettings, FilterChangeState.DATE_RANGE_ON);
                    filterIconKey.currentState?.refresh(taskFilterSettings.isFilterActive());
                  }
                });
             /* }
              else {
                taskFilterSettings.filterByDateRange = null;
                widget.doFilter(this, FilterChangeState.DATE_RANGE_OFF);
                filterIconKey.currentState?.refresh(isFilterActive());
              }*/
              break;
            }

            case '2' : {
              showSeverityPicker(
                  context, taskFilterSettings.filterBySeverity, true, (selected) {
                taskFilterSettings.filterBySeverity = selected;
                widget.doFilter(taskFilterSettings, selected != null ? FilterChangeState.SEVERITY_ON : FilterChangeState.SEVERITY_OFF);
                filterIconKey.currentState?.refresh(taskFilterSettings.isFilterActive());
                Navigator.pop(context);
              });
              break;
            }

            case '3' : {
              taskFilterSettings.filterByFavorites = !taskFilterSettings.filterByFavorites;
              widget.doFilter(taskFilterSettings, taskFilterSettings.filterByFavorites ? FilterChangeState.FAVORITE_ON : FilterChangeState.FAVORITE_OFF);
              filterIconKey.currentState?.refresh(taskFilterSettings.isFilterActive());
              break;
            }

            case '4' : {
              if (taskFilterSettings.filterByTaskEventIds != null) {
                toastInfo(context, translate('filter.hint_filter_by_schedule',
                    args: {
                      "title": taskFilterSettings.filterByScheduledTask!.translatedTitle,
                      "clearAll": translate('filter.menu.clear_all')}));
                return;
              }
              //if (taskFilterSettings.filterByTaskOrTemplate == null) {
                Object? selectedItem = null;
                showTemplateDialog(context,
                  translate('filter.filter_by_task_title'),
                  translate('filter.filter_by_task_description'),
                  initialSelectedKey: taskFilterSettings.filterByTaskOrTemplate is TaskGroup
                    ? (taskFilterSettings.filterByTaskOrTemplate as TaskGroup).getKey()
                    : (taskFilterSettings.filterByTaskOrTemplate is Template
                        ? (taskFilterSettings.filterByTaskOrTemplate as Template).getKey()
                        : null),
                  selectedItem: (item) {
                    selectedItem = item;
                  },
                  okPressed: () {
                    if (selectedItem != null) {
                      Navigator.pop(context);
                      taskFilterSettings.filterByTaskOrTemplate = selectedItem;
                      widget.doFilter(taskFilterSettings, selectedItem != null
                          ? FilterChangeState.TASK_ON
                          : FilterChangeState.TASK_OFF);
                      filterIconKey.currentState?.refresh(
                          taskFilterSettings.isFilterActive());
                    }
                  },
                  cancelPressed: () =>
                      Navigator.pop(context), // dis
                );
             /* }
              else {
                taskFilterSettings.filterByTaskOrTemplate = null;
                widget.doFilter(this, FilterChangeState.TASK_OFF);
                filterIconKey.currentState?.refresh(isFilterActive());
              }*/
              break;
            }
            case '5' : {
              taskFilterSettings.clearFilters();
              widget.doFilter(taskFilterSettings, FilterChangeState.ALL_OFF);
              filterIconKey.currentState?.refresh(taskFilterSettings.isFilterActive());
              break;
            }
          }
        });
      },
    );
  }

  void refresh(TaskFilterSettings? taskFilterSettings) {
    setState(() {
      if (taskFilterSettings != null) {
        this.taskFilterSettings = taskFilterSettings;
        filterIconKey.currentState?.refresh(taskFilterSettings.isFilterActive());
      }
    });
  }

  Color _getColorFromScheduledTask(ScheduledTask scheduledTask) {
    final taskGroup = findPredefinedTaskGroupById(scheduledTask.taskGroupId);
    return getSharpedColor(taskGroup.colorRGB);
  }

}
