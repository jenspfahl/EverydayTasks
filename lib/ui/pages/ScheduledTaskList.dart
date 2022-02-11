import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/ChronologicalPaging.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskRepository.dart';
import 'package:personaltasklogger/model/Schedule.dart';
import 'package:personaltasklogger/model/ScheduledTask.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/service/LocalNotificationService.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/forms/ScheduledTaskForm.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';
import 'package:personaltasklogger/util/dates.dart';

import '../utils.dart';

class ScheduledTaskList extends StatefulWidget implements PageScaffold {

  _ScheduledTaskListState? _state;

  @override
  State<StatefulWidget> createState() {
    _state = _ScheduledTaskListState();
    return _state!;
  }

  @override
  Widget getTitle() {
    return Text('Schedules');
  }

  @override
  Icon getIcon() {
    return Icon(Icons.next_plan_outlined);
  }

  @override
  List<Widget>? getActions(BuildContext context) {
    return null;
  }

  @override
  void handleFABPressed(BuildContext context) {
    _state?._onFABPressed();
  }

  void updateScheduledTask(int scheduledTaskId) {
    _state?.updateScheduledTask(scheduledTaskId);
  }

  @override
  bool withSearchBar() {
    return false;
  }

  @override
  void searchQueryUpdated(String? searchQuery) {
  }

  @override
  String getKey() {
    return "ScheduledTasks";
  }
}

class _ScheduledTaskListState extends State<ScheduledTaskList> with AutomaticKeepAliveClientMixin<ScheduledTaskList> {
  List<ScheduledTask> _scheduledTasks = [];
  int _selectedTile = -1;
  final _notificationService = LocalNotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.addHandler(handleNotificationClicked);


    final paging = ChronologicalPaging(ChronologicalPaging.maxDateTime, ChronologicalPaging.maxId, 100);
    ScheduledTaskRepository.getAllPaged(paging).then((scheduledTasks) {
      setState(() {
        _scheduledTasks = scheduledTasks;
        _scheduledTasks..sort();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildList();
  }
  
  @override
  void deactivate() {
    _notificationService.removeHandler(handleNotificationClicked);
    super.deactivate();
  }

  void updateScheduledTask(int scheduledTaskId) {
    debugPrint("received scheduledTaskId:" + scheduledTaskId.toString());
    setState(() {
      final found = _scheduledTasks.firstWhereOrNull((element) => element.id == scheduledTaskId);
      debugPrint("found in list: " + found.toString());
      if (found != null) {
        var index = _scheduledTasks.indexOf(found);
        debugPrint("index in list: " + index.toString());
        if (index != -1) {
          ScheduledTaskRepository.getById(scheduledTaskId)
              .then((freshScheduledTask) {
            _scheduledTasks.removeAt(index);
            _scheduledTasks.insert(index, freshScheduledTask);
            debugPrint("exchanged: " + freshScheduledTask.toString());
            _scheduledTasks..sort();
          });
        }
      }
    });
  }

  Widget _buildList() {
    return Padding(
        padding: EdgeInsets.all(8.0),
        child: ListView.builder(
            itemCount: _scheduledTasks.length,
            itemBuilder: (context, index) {
              var scheduledTask = _scheduledTasks[index];
              var taskGroup = findPredefinedTaskGroupById(scheduledTask.taskGroupId);
              return _buildRow(index, scheduledTask, taskGroup);
            }),
    );
  }

  handleNotificationClicked(String receiverKey, String id) {
    if (receiverKey == widget.getKey()) {
      setState(() {
        final clickedScheduledTask = _scheduledTasks.firstWhere((scheduledTask) => scheduledTask.id.toString() == id);
        _selectedTile = _scheduledTasks.indexOf(clickedScheduledTask);
      });
    }
  }

  Widget _buildRow(int index, ScheduledTask scheduledTask, TaskGroup taskGroup) {
    final expansionWidgets = _createExpansionWidgets(scheduledTask);
    return Padding(
        padding: EdgeInsets.all(4.0),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile( //better use ExpansionPanel?
            key: GlobalKey(),
            // this makes updating all tiles if state changed
            title: Text(kReleaseMode ? scheduledTask.title : "${scheduledTask.title} (id=${scheduledTask.id})"),
            subtitle: Column(
              children: [
                taskGroup.getTaskGroupRepresentation(useIconColor: true),
                Visibility(
                  visible: scheduledTask.active,
                  child: LinearProgressIndicator(
                    value: scheduledTask.getNextRepetitionIndicatorValue(),
                    color: scheduledTask.isNextScheduleReached() ? Colors.red[500] : null,
                  ),
                ),
              ],
            ),
            children: expansionWidgets,
            collapsedBackgroundColor: getTaskGroupColor(scheduledTask.taskGroupId, true),
            backgroundColor: getTaskGroupColor(scheduledTask.taskGroupId, false),
            initiallyExpanded: index == _selectedTile,
            onExpansionChanged: ((expanded) {
              setState(() {
                _selectedTile = expanded ? index : -1;
              });
            }),
          )
        ),
    );
  }

  List<Widget> _createExpansionWidgets(ScheduledTask scheduledTask) {
    var expansionWidgets = <Widget>[];

    if (scheduledTask.description != null && scheduledTask.description!.isNotEmpty) {
      expansionWidgets.add(Padding(
        padding: EdgeInsets.all(4.0),
        child: Text(scheduledTask.description!),
      ));
    }
    expansionWidgets.addAll([
      Padding(
        padding: EdgeInsets.all(4.0),
        child: Text(getDetailsMessage(scheduledTask)),
      ),
      Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Visibility(
            visible: scheduledTask.active,
            child: ButtonBar(
              alignment: MainAxisAlignment.start,
              children: [
                TextButton(
                  child: Icon(Icons.replay),
                  onPressed: () {
                    showConfirmationDialog(
                      context,
                      "Reset schedule",
                      "Are you sure to reset \'${scheduledTask.title}\' ? This will change the due date to the origin.",
                      okPressed: () {
                        scheduledTask.executeSchedule(null);
                        ScheduledTaskRepository.update(scheduledTask).then((changedScheduledTask) {
                          ScaffoldMessenger.of(super.context).showSnackBar(
                              SnackBar(content: Text('Schedule with name \'${changedScheduledTask.title}\' reset done')));
                          _updateScheduledTask(scheduledTask, changedScheduledTask);
                        });
                        Navigator.pop(context);// dismiss dialog, should be moved in Dialogs.dart somehow
                      },
                      cancelPressed: () =>
                          Navigator.pop(context), // dismiss dialog, should be moved in Dialogs.dart somehow
                    );
                  },
                ),
              ],
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  ScheduledTask? changedScheduledTask = await Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ScheduledTaskForm(
                        formTitle: "Change scheduledTask \'${scheduledTask.title}\'",
                        scheduledTask: scheduledTask,
                        taskGroup: findPredefinedTaskGroupById(scheduledTask.taskGroupId),
                    );
                  }));

                  if (changedScheduledTask != null) {
                    ScheduledTaskRepository.update(changedScheduledTask).then((changedScheduledTask) {
                      ScaffoldMessenger.of(super.context).showSnackBar(
                          SnackBar(content: Text('Schedule with name \'${changedScheduledTask.title}\' updated')));
                      _updateScheduledTask(scheduledTask, changedScheduledTask);
                    });
                  }
                },
                child: const Icon(Icons.edit),
              ),
              TextButton(
                onPressed: () {
                  showConfirmationDialog(
                    context,
                    "Delete Schedule",
                    "Are you sure to delete \'${scheduledTask.title}\' ?",
                    okPressed: () {
                      ScheduledTaskRepository.delete(scheduledTask).then(
                            (_) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Schedule \'${scheduledTask.title}\' deleted')));
                          _removeScheduledTask(scheduledTask);
                        },
                      );
                      Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow
                    },
                    cancelPressed: () =>
                        Navigator.pop(context), // dismiss dialog, should be moved in Dialogs.dart somehow
                  );
                },
                child: const Icon(Icons.delete),
              ),
            ],
          ),
        ],
      ),
    ]);
    return expansionWidgets;
  }


  String getDetailsMessage(ScheduledTask scheduledTask) {
    var debug = kReleaseMode ? "" : "last:${scheduledTask.lastScheduledEventOn}, next:${scheduledTask.getNextSchedule()}, ratio: ${scheduledTask.getNextRepetitionIndicatorValue()}\n";
    if (scheduledTask.active) {
      if (scheduledTask.isNextScheduleReached()) {
        return debug +
            "Overdue ${formatToDateOrWord(
            scheduledTask.getNextSchedule()!, true).toLowerCase()} "
            "for ${formatDuration(scheduledTask.getMissingDuration()!, true)} ";
      }
      debugPrint(scheduledTask.schedule.customRepetition?.toString());
      if (scheduledTask.schedule.repetitionStep == RepetitionStep.CUSTOM
          && scheduledTask.schedule.customRepetition!.repetitionUnit == RepetitionUnit.HOURS) {
        return debug +
            "Due ${formatToDateOrWord(scheduledTask.getNextSchedule()!, true)
                .toLowerCase()} "
                "in ${formatDuration(scheduledTask.getMissingDuration()!)} "
                "at ${formatToTime(scheduledTask.getNextSchedule()!)}";
      }
      else {
        return debug +
            "Due ${formatToDateOrWord(scheduledTask.getNextSchedule()!, true)
                .toLowerCase()} "
                "in ${formatDuration(scheduledTask.getMissingDuration()!)} "
                "${scheduledTask.schedule.toStartAtAsString().toLowerCase()}";
      }
    }
    else {
      return debug +
          "- currently inactive -";
    }
  }


  void _addScheduledTask(ScheduledTask scheduledTask) {
    setState(() {
      _scheduledTasks.add(scheduledTask);
      _scheduledTasks..sort();
      _selectedTile = _scheduledTasks.indexOf(scheduledTask);
    });

    _rescheduleNotification(scheduledTask);
  }

  void _updateScheduledTask(ScheduledTask origin, ScheduledTask updated) {
    setState(() {
      final index = _scheduledTasks.indexOf(origin);
      if (index != -1) {
        _scheduledTasks.removeAt(index);
        _scheduledTasks.insert(index, updated);
      }
      _scheduledTasks..sort();
      _selectedTile = _scheduledTasks.indexOf(updated);
    });

    _rescheduleNotification(updated);
  }

  void _removeScheduledTask(ScheduledTask scheduledTask) {
    setState(() {
      _scheduledTasks.remove(scheduledTask);
      _selectedTile = -1;
    });

    _cancelNotification(scheduledTask);
  }


  void _onFABPressed() {
    Object? selectedTemplateItem;

    showTemplateDialog(context, "Select a task to be scheduled",
        selectedItem: (selectedItem) {
          setState(() {
            selectedTemplateItem = selectedItem;
          });
        },
        okPressed: () async {
          if (selectedTemplateItem is Template) {
            Navigator.pop(context);
            ScheduledTask? newScheduledTask = await Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ScheduledTaskForm(
                formTitle: "Create new schedule ",
                taskGroup: findPredefinedTaskGroupById((selectedTemplateItem as Template).taskGroupId),
                template: selectedTemplateItem as Template,
              );
            }));

            if (newScheduledTask != null) {
              ScheduledTaskRepository.insert(newScheduledTask).then((newScheduledTask) {
                ScaffoldMessenger.of(super.context).showSnackBar(
                    SnackBar(content: Text('New schedule with name \'${newScheduledTask.title}\' created')));
                _addScheduledTask(newScheduledTask);
              });
            }
          }
          else {
            SnackBar(content: Text( "Please select a template or a variant"));
          }
        },
        cancelPressed: () {
          Navigator.pop(super.context);
        });

  }

  @override
  bool get wantKeepAlive => true;


  void _rescheduleNotification(ScheduledTask scheduledTask) {
    _cancelNotification(scheduledTask);
    final missingDuration = scheduledTask.getMissingDuration();
    if (scheduledTask.active && missingDuration != null) {
      _notificationService.scheduleNotifications(
          widget.getKey(),
          scheduledTask.id!,
          "Due scheduled task",
          "Scheduled task '${scheduledTask.title}' is due!",
          missingDuration);
    }
  }

  void _cancelNotification(ScheduledTask scheduledTask) {
    _notificationService.cancelNotifications(scheduledTask.id!);
  }


}


