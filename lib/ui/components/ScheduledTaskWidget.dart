import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:personaltasklogger/ui/utils.dart';
import 'package:personaltasklogger/util/extensions.dart';

import '../../db/repository/ChronologicalPaging.dart';
import '../../db/repository/ScheduledTaskEventRepository.dart';
import '../../db/repository/ScheduledTaskRepository.dart';
import '../../db/repository/TaskEventRepository.dart';
import '../../db/repository/TaskGroupRepository.dart';
import '../../db/repository/TemplateRepository.dart';
import '../../model/Schedule.dart';
import '../../model/ScheduledTask.dart';
import '../../model/ScheduledTaskEvent.dart';
import '../../model/TaskEvent.dart';
import '../../model/Template.dart';
import '../../model/When.dart';
import '../../service/DueScheduleCountService.dart';
import '../../service/LocalNotificationService.dart';
import '../../util/dates.dart';
import '../../util/units.dart';
import '../PersonalTaskLoggerApp.dart';
import '../PersonalTaskLoggerScaffold.dart';
import '../dialogs.dart';
import '../forms/ScheduledTaskForm.dart';
import '../forms/TaskEventForm.dart';
import '../pages/TaskEventList.dart';

class ScheduledTaskWidget extends StatefulWidget {
  
  final ScheduledTask scheduledTask;
  final bool isInitiallyExpanded;
  final bool Function()? shouldExpand;
  final ValueChanged<bool>? onExpansionChanged;
  final bool Function() isNotificationsEnabled;
  final Function()? onBeforeRouting;
  final Function(TaskEvent?)? onAfterJournalEntryFromScheduleCreated;
  final ValueChanged<ScheduledTask>? onScheduledTaskChanged;
  final ValueChanged<ScheduledTask>? onScheduledTaskDeleted;
  final PagesHolder pagesHolder;
  final bool selectInListWhenChanged;
  final bool? isReadOnly;
  final Widget? leadingIcon;

  ScheduledTaskWidget(this.scheduledTask, {
    Key? key,
    this.shouldExpand,
    this.onExpansionChanged,
    this.onScheduledTaskChanged,
    this.onScheduledTaskDeleted,
    this.onBeforeRouting,
    this.onAfterJournalEntryFromScheduleCreated,
    required this.isNotificationsEnabled,
    required this.isInitiallyExpanded,
    required this.pagesHolder,
    required this.selectInListWhenChanged,
    this.isReadOnly,
    this.leadingIcon,
  }) : super(key: key);
  
  @override
  ScheduledTaskWidgetState createState() => ScheduledTaskWidgetState();


  static Future<TaskEvent?> openAddJournalEntryFromSchedule(BuildContext context, PagesHolder pagesHolder, ScheduledTask scheduledTask) async {
    final templateId = scheduledTask.templateId;
    Template? template;
    if (templateId != null) {
      template = await TemplateRepository.findById(templateId);
    }

    TaskEvent? newTaskEvent = await Navigator.push(context, MaterialPageRoute(builder: (context) {
      if (template != null) {
        return TaskEventForm(
          formTitle: translate('forms.task_event.create.title_from_schedule'),
          template: template,
        );
      }
      else {
        final taskGroup = TaskGroupRepository.findByIdFromCache(
            scheduledTask.taskGroupId);
        return TaskEventForm(
            formTitle: translate('forms.task_event.create.title_from_schedule'),
            taskGroup: taskGroup,
            title: scheduledTask.translatedTitle,
            description:  scheduledTask.translatedDescription
        );
      }
    }));

    if (newTaskEvent != null) {
      final insertedTaskEvent = await TaskEventRepository.insert(newTaskEvent);
      pagesHolder
          .taskEventList
          ?.getGlobalKey()
          .currentState
          ?.addTaskEvent(insertedTaskEvent, justSetState: true);

      scheduledTask.executeSchedule(insertedTaskEvent);
      ScheduledTaskRepository.update(scheduledTask).then((changedScheduledTask) {
        cancelSnoozedNotification(scheduledTask);
        pagesHolder
            .scheduledTaskList
            ?.getGlobalKey()
            .currentState
            ?.updateScheduledTask(scheduledTask, changedScheduledTask);

        DueScheduleCountService().dec();

        final scheduledTaskEvent = ScheduledTaskEvent.fromEvent(insertedTaskEvent, scheduledTask);
        ScheduledTaskEventRepository.insert(scheduledTaskEvent);

        toastInfo(context, translate('forms.task_event.create.success',
            args: {"title" : insertedTaskEvent.translatedTitle}));

        PersonalTaskLoggerScaffoldState? root = context.findAncestorStateOfType();
        if (root != null) {
          final taskEventListState = pagesHolder.taskEventList?.getGlobalKey().currentState;
          if (taskEventListState != null) {
            taskEventListState.clearFilters();
          }
          root.sendEventFromClicked(TASK_EVENT_LIST_ROUTING_KEY, false, insertedTaskEvent.id.toString(), null);
        }
      });
      return insertedTaskEvent;
    }
    else {
      return null;
    }
  }

  static void cancelSnoozedNotification(ScheduledTask scheduledTask) {
    LocalNotificationService().cancelNotification(scheduledTask.id! + LocalNotificationService.RESCHEDULED_IDS_RANGE);
  }
}

class ScheduledTaskWidgetState extends State<ScheduledTaskWidget> {
  
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final scheduledTask = widget.scheduledTask;
    final taskGroup = TaskGroupRepository.findByIdFromCache(scheduledTask.taskGroupId);
    final expansionWidgets = _createExpansionWidgets(scheduledTask);

    return  Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile( //better use ExpansionPanel?
          key: GlobalKey(),
          // this makes updating all tiles if state changed
          title: _isExpanded
              ? Row(
                children: [
                  if (scheduledTask.important) Icon(Icons.priority_high),
                  Text(kReleaseMode ? scheduledTask.translatedTitle : "${scheduledTask.translatedTitle} (id=${scheduledTask.id})"),
                ],
              )
              : Row(
            children: [
              if (scheduledTask.important) Icon(Icons.priority_high),
              taskGroup.getIcon(true),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                child: Text(truncate(kReleaseMode ? scheduledTask.translatedTitle : "${scheduledTask.translatedTitle} (id=${scheduledTask.id})", length: 30)),
              )
            ],
          ),
          subtitle: Column(
            children: [
              _isExpanded ? taskGroup.getTaskGroupRepresentation(context, useIconColor: true) : _buildShortProgressText(scheduledTask),
              Visibility(
                visible: scheduledTask.active && !scheduledTask.isOneTimeCompleted,
                child: Opacity(
                  opacity: scheduledTask.isPaused ? 0.3 : 1,
                  child: LinearProgressIndicator(
                    value: scheduledTask.isNextScheduleOverdue(true) ? null : scheduledTask.getNextRepetitionIndicatorValue(),
                    color: scheduledTask.isNextScheduleOverdue(false)
                        ? Colors.red[500]
                        : (scheduledTask.isNextScheduleReached()
                        ? scheduledTask.getDueColor(context, lighter: false)
                        : null),
                    backgroundColor: scheduledTask.getDueBackgroundColor(context),
                  ),
                ),
              ),
            ],
          ),
          leading: widget.leadingIcon,
          children: expansionWidgets,
          collapsedBackgroundColor: taskGroup.backgroundColor(context),
          backgroundColor: taskGroup.softColor(context),
          textColor: isDarkMode(context) ? BUTTON_COLOR.shade300 : BUTTON_COLOR,
          initiallyExpanded: widget.shouldExpand != null ? widget.shouldExpand!() : _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
              if (widget.onExpansionChanged != null) {
                widget.onExpansionChanged!(expanded);
              }
            });
          },
        )
    );
  }


  Widget _buildShortProgressText(ScheduledTask scheduledTask) {
    String text = "";
    if (!scheduledTask.active || scheduledTask.lastScheduledEventOn == null) {
      text = "- ${translate('pages.schedules.overview.inactive')} -";
    }
    else if (scheduledTask.isOneTimeCompleted) {
      text = "- ${translate('pages.schedules.overview.completed')} -";
    }
    else if (scheduledTask.isPaused) {
      text = "- ${translate('pages.schedules.overview.paused')} -";
    }
    else {
      if (scheduledTask.isNextScheduleOverdue(false)) {
        text = scheduledTask.isNextScheduleOverdue(true)
            ? "${translate('pages.schedules.overview.overdue').capitalize()}!"
            : "${translate('pages.schedules.overview.due').capitalize()}!";
      }
      else if (scheduledTask.isDueNow()) {
        text ="${translate('pages.schedules.overview.due_now').capitalize()}!";
      }
      else {
        text = "${translate('common.words.in_for_times')} ${formatDuration(scheduledTask.getMissingDuration()!,
            true, usedClause(context, Clause.dative))}";
      }
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: TextStyle(fontSize: 10)),
    );
  }


  List<Widget> _createExpansionWidgets(ScheduledTask scheduledTask) {
    var expansionWidgets = <Widget>[];

    if (scheduledTask.translatedDescription != null && scheduledTask.translatedDescription!.isNotEmpty) {
      expansionWidgets.add(Padding(
        padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 16),
        child: Text(scheduledTask.translatedDescription!),
      ));
    }

    List<Widget> content = [];
    var nextSchedule = scheduledTask.getNextSchedule();
    if (!scheduledTask.active || scheduledTask.lastScheduledEventOn == null) {
      content.add(Text("- ${translate('pages.schedules.overview.inactive')} -"));
    }
    else if (scheduledTask.isPaused) {
      content.add(Text("- ${translate('pages.schedules.overview.paused')} -"));
    }
    else if (scheduledTask.isOneTimeCompleted) {
      content.add(Text("- ${translate('pages.schedules.overview.completed')} -"));
    }
    else {
      content.add(
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: scheduledTask.isNextScheduleOverdue(true) || scheduledTask.isDueNow()
                      ? Icon(Icons.warning_amber_outlined, color: scheduledTask.isDueNow()
                      ? scheduledTask.getDueColor(context, lighter: true)
                      : Colors.red)
                      : Icon(Icons.watch_later_outlined,
                      color: _getIconColorForMode()), // in TaskEventList, the icons are not black without setting the color, donät know why ...
                ),
                Text(_getDueMessage(scheduledTask), softWrap: true),
              ]
          )
      );
      content.add(const Text(""));
      content.add(
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(MdiIcons.arrowExpandRight,
                      color: _getIconColorForMode()),
                ),
                Text(_getScheduledMessage(scheduledTask)),
              ]
          )
      );
      content.add(const Text(""));

      var repetitionString = scheduledTask.schedule.repetitionStep != RepetitionStep.CUSTOM
          ? Schedule.fromRepetitionStepToString(scheduledTask.schedule.repetitionStep)
          : Schedule.fromCustomRepetitionToString(scheduledTask.schedule.customRepetition);

      if (scheduledTask.schedule.repetitionMode == RepetitionMode.ONE_TIME) {
        repetitionString = translate('model.repetition_mode.one_time');
      }
      else if (scheduledTask.schedule.repetitionMode == RepetitionMode.FIXED) {
        String? fixedRepetition;
        if (scheduledTask.schedule.isWeekBased()) {
          final s = Schedule.getStringFromWeeklyBasedSchedules(scheduledTask.schedule.weekBasedSchedules, context);
          if (s != null) {
            fixedRepetition = s;
          }
          else {
            fixedRepetition = getShortWeekdayOf(nextSchedule!.weekday, context);
          }
        }
        if (scheduledTask.schedule.isMonthBased()) {
          final s = Schedule.getStringFromMonthlyBasedSchedules(scheduledTask.schedule.monthBasedSchedules, context);
          if (s != null) {
            fixedRepetition = s;
          }
          else {
            fixedRepetition = getDayOfMonth(nextSchedule!.day, context);
          }
        }
        if (scheduledTask.schedule.isYearBased()) {
          final s = Schedule.getStringFromYearlyBasedSchedules(scheduledTask.schedule.yearBasedSchedules, context);
          if (s != null) {
            fixedRepetition = s;
          }
          else {
            fixedRepetition = formatAllYearDate(AllYearDate(nextSchedule!.day, MonthOfYear.values[nextSchedule.month - 1]), context);
          }
        }
        if (fixedRepetition != null) {
          repetitionString = "$repetitionString ($fixedRepetition)";
        }
        else {
          repetitionString = "$repetitionString (${translate('model.repetition_mode.fixed')})";
        }
      }

      content.add(
        Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.next_plan_outlined,
                    color: _getIconColorForMode()),
              ),
              Flexible(child: Text(repetitionString)),
            ]
        ),
      );
      if (widget.isReadOnly != true
          && scheduledTask.active
          && !scheduledTask.isPaused
          && scheduledTask.reminderNotificationEnabled == true
          && widget.isNotificationsEnabled()) {

        if (scheduledTask.isDue()) {
          content.add(const Text(""));
          content.add(
            Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.notifications_active_outlined,
                        color: _getIconColorForMode()),
                  ),
                  Flexible(
                    child: Wrap(
                      direction: Axis.horizontal,
                      children: [
                        Text(translate('pages.schedules.overview.reminder_passed') + "   "),
                        Padding(
                          padding: const EdgeInsets.all(0),
                          child: GestureDetector(
                            child: Text(translate('pages.schedules.overview.remind_again').capitalize(),
                              style: TextStyle(color: BUTTON_COLOR, fontWeight: FontWeight.w500),
                            ),
                            onTap: () {
                              final taskGroup = TaskGroupRepository.findByIdFromCache(scheduledTask.taskGroupId);
                              final remindIn = scheduledTask.reminderNotificationRepetition??CustomRepetition(1, RepetitionUnit.HOURS);

                              final state = widget.pagesHolder
                                  .scheduledTaskList
                                  ?.getGlobalKey()
                                  .currentState;
                              state?.scheduleNotification(scheduledTask.id!, scheduledTask, taskGroup,
                                  remindIn.toDuration(),
                                  scheduledTask.schedule.repetitionMode == RepetitionMode.FIXED, false);
                              toastInfo(context, translate('pages.schedules.overview.remind_again_successful',
                                  args: {"when": Schedule.fromCustomRepetitionToUnit(remindIn, usedClause(context, Clause.dative))}));
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
            ),
          );
        }
        else {
          content.add(const Text(""));
          content.add(
            Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.notifications_none,
                        color: _getIconColorForMode()),
                  ),
                  Text(translate('pages.schedules.overview.reminder_activated')),
                ]
            ),
          );
        }

      }
    }

    if (widget.isReadOnly != true) {
      var resetIcon = scheduledTask.schedule.repetitionMode == RepetitionMode.DYNAMIC
          ? Icons.replay
          : scheduledTask.schedule.repetitionMode == RepetitionMode.FIXED
          ? Icons.skip_next
          : Icons.stop;
      expansionWidgets.addAll([
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: content,
          ),
        ),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Visibility(
              visible: scheduledTask.active,
              child: ButtonBar(
                alignment: MainAxisAlignment.start,
                buttonPadding: EdgeInsets.symmetric(horizontal: 0.0),
                children: [
                  SizedBox(
                    width: 50,
                    child: Visibility(
                      visible: !scheduledTask.isOneTimeCompleted,
                      child: TextButton(
                        child: Icon(Icons.check,
                            color: isDarkMode(context)
                                ? BUTTON_COLOR.shade300
                                : BUTTON_COLOR),
                        onPressed: () async {
                          if (scheduledTask.isPaused) {
                            toastError(context, translate(
                                'pages.schedules.errors.cannot_resume'));
                            return;
                          }
                          ScheduledTaskWidget.openAddJournalEntryFromSchedule(
                              context, widget.pagesHolder, scheduledTask).then((
                              createdTaskEvent) {
                            setState(() {}); // refresh ui
                            if (widget.onAfterJournalEntryFromScheduleCreated !=
                                null)
                              widget.onAfterJournalEntryFromScheduleCreated!(
                                  createdTaskEvent);
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Visibility(
                      visible: !scheduledTask.isOneTimeCompleted,
                      child: TextButton(
                        child: Icon(resetIcon,
                            color: isDarkMode(context)
                                ? BUTTON_COLOR.shade300
                                : BUTTON_COLOR),
                        onPressed: () {
                          if (scheduledTask.isPaused) {
                            toastError(context, translate(
                                'pages.schedules.errors.cannot_reset'));
                            return;
                          }

                          var newNextDueDate = scheduledTask.simulateExecuteSchedule(null);


                          if (scheduledTask.schedule.repetitionMode == RepetitionMode.FIXED) {
                            if (!scheduledTask.isDue()) {
                              // get schedule after next due date to move forward
                              newNextDueDate = scheduledTask.getNextScheduleAfter(newNextDueDate);
                            }
                          }
                          else if (scheduledTask.schedule.repetitionMode == RepetitionMode.ONE_TIME) {
                            newNextDueDate = scheduledTask.getNextSchedule();
                          }

                          var nextDueDateAsString = formatToDateOrWord(
                              newNextDueDate!, context,
                              withPreposition: true,
                              makeWhenOnLowerCase: true);

                          String title, message, i18nKeyForSuccess;
                          if (scheduledTask.schedule.repetitionMode == RepetitionMode.FIXED) {
                            title = translate('pages.schedules.action.move_forward.title');
                            message = translate(
                                'pages.schedules.action.move_forward.message',
                                args: {
                                  "title": scheduledTask.translatedTitle,
                                  "nextDueDate": nextDueDateAsString,
                                  "newNextDueDate": formatToTime(newNextDueDate)
                                });
                            i18nKeyForSuccess = 'pages.schedules.action.move_forward.success';
                          }
                          else if (scheduledTask.schedule.repetitionMode == RepetitionMode.ONE_TIME) {
                            title = translate('pages.schedules.action.one_time.title');
                            message = translate(
                                'pages.schedules.action.one_time.message',
                                args: {
                                  "title": scheduledTask.translatedTitle,
                                });
                            i18nKeyForSuccess = 'pages.schedules.action.one_time.success';
                          }
                          else { // dynamic
                            title = translate('pages.schedules.action.reset.title');
                            message = (newNextDueDate != nextSchedule)
                                ? translate(
                                'pages.schedules.action.reset.message_then',
                                args: {
                                  "title": scheduledTask.translatedTitle,
                                  "nextDueDate": nextDueDateAsString,
                                  "newNextDueDate": formatToTime(newNextDueDate)
                                })
                                : translate(
                                'pages.schedules.action.reset.message_still',
                                args: {
                                  "title": scheduledTask.translatedTitle,
                                  "nextDueDate": nextDueDateAsString,
                                  "newNextDueDate": formatToTime(newNextDueDate)
                                });
                            i18nKeyForSuccess = 'pages.schedules.action.reset.success';
                          }

                          showConfirmationDialog(
                            context,
                            title,
                            message,
                            icon: Icon(resetIcon),
                            okPressed: () {
                              if (scheduledTask.schedule.repetitionMode == RepetitionMode.FIXED) {
                                // because the schedule snaps to the next due date we have to substract one day
                                scheduledTask.lastScheduledEventOn = newNextDueDate?.subtract(Duration(days: 1));
                              }
                              else {
                                scheduledTask.executeSchedule(null);
                              }
                              ScheduledTaskRepository.update(scheduledTask)
                                  .then((changedScheduledTask) {
                                final state = widget.pagesHolder
                                    .scheduledTaskList
                                    ?.getGlobalKey()
                                    .currentState;
                                ScheduledTaskWidget.cancelSnoozedNotification(
                                    scheduledTask);
                                state?.updateScheduledTask(
                                    scheduledTask, changedScheduledTask);

                                setState(() {
                                  scheduledTask.apply(changedScheduledTask);
                                });

                                if (widget.onScheduledTaskChanged != null)
                                  widget.onScheduledTaskChanged!(
                                      changedScheduledTask);

                                toastInfo(context, translate(
                                    i18nKeyForSuccess,
                                    args: {
                                      "title": changedScheduledTask
                                          .translatedTitle
                                    }));
                              });
                              Navigator.pop(
                                  context); // dismiss dialog, should be moved in Dialogs.dart somehow

                              DueScheduleCountService().dec();
                            },
                            cancelPressed: () =>
                                Navigator.pop(context),
                            neutralButton: scheduledTask.schedule.repetitionMode != RepetitionMode.ONE_TIME
                                ? TextButton(
                                  child: Text(translate('common.words.custom')
                                      .capitalize() + ELLIPSIS),
                                  onPressed: () {
                                    showTweakedDatePicker(
                                        context,
                                        helpText: translate(
                                            'pages.schedules.action.reset.title_custom',
                                            args: {
                                              "title": scheduledTask
                                                  .translatedTitle
                                            }),
                                        initialDate: newNextDueDate,
                                        selectableDayPredicate: (date) {
                                          return scheduledTask.schedule
                                              .appliesToFixedSchedule(date);
                                        }
                                    ).then((selectedDate) {
                                      if (selectedDate != null) {
                                        scheduledTask.setNextSchedule(
                                            selectedDate);
                                        ScheduledTaskRepository.update(
                                            scheduledTask).then((
                                            changedScheduledTask) {
                                          final state = widget.pagesHolder
                                              .scheduledTaskList
                                              ?.getGlobalKey()
                                              .currentState;
                                          ScheduledTaskWidget
                                              .cancelSnoozedNotification(
                                              scheduledTask);
                                          state?.updateScheduledTask(
                                              scheduledTask,
                                              changedScheduledTask);

                                          setState(() {
                                            scheduledTask.apply(
                                                changedScheduledTask);
                                          });

                                          if (widget.onScheduledTaskChanged !=
                                              null)
                                            widget.onScheduledTaskChanged!(
                                                changedScheduledTask);

                                          toastInfo(context, translate(
                                              'pages.schedules.action.reset.success_custom',
                                              args: {
                                                "title": changedScheduledTask
                                                    .translatedTitle
                                              }));
                                        });
                                        Navigator.pop(
                                            context); // dismiss dialog, should be moved in Dialogs.dart somehow
                                      }
                                      else {
                                        Navigator.pop(context);
                                      }
                                    });
                                  })
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ButtonBar(
              alignment: scheduledTask.active
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              buttonPadding: EdgeInsets.symmetric(horizontal: 0.0),
              children: [
                Visibility(
                  visible: scheduledTask.active,
                  child: SizedBox(
                    width: 50,
                    child: Visibility(
                      visible: !scheduledTask.isOneTimeCompleted,
                      child: TextButton(
                          child: Icon(
                              scheduledTask.isPaused ? Icons.play_arrow : Icons
                                  .pause,
                              color: isDarkMode(context)
                                  ? BUTTON_COLOR.shade300
                                  : BUTTON_COLOR),
                          onPressed: () {
                            if (scheduledTask.isPaused) {
                              scheduledTask.resume();
                              DueScheduleCountService().incIfDue(scheduledTask);
                            }
                            else {
                              scheduledTask.pause();
                              DueScheduleCountService().decIfDue(scheduledTask);
                            }
                            ScheduledTaskRepository.update(scheduledTask)
                                .then((changedScheduledTask) {
                              final state = widget.pagesHolder
                                  .scheduledTaskList
                                  ?.getGlobalKey()
                                  .currentState;
                              ScheduledTaskWidget.cancelSnoozedNotification(
                                  scheduledTask);
                              state?.updateScheduledTask(
                                  scheduledTask, changedScheduledTask);

                              setState(() {
                                scheduledTask.apply(changedScheduledTask);
                              });

                              if (widget.onScheduledTaskChanged != null)
                                widget.onScheduledTaskChanged!(
                                    changedScheduledTask);

                              var msg = changedScheduledTask.isPaused
                                  ? translate(
                                  'pages.schedules.action.pause_resume.paused',
                                  args: {
                                    "title": changedScheduledTask
                                        .translatedTitle
                                  })
                                  : translate(
                                  'pages.schedules.action.pause_resume.resumed',
                                  args: {
                                    "title": changedScheduledTask
                                        .translatedTitle
                                  });
                              toastInfo(context, msg);
                            });
                          }
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: TextButton(
                    child: Icon(Icons.checklist,
                        color: isDarkMode(context)
                            ? BUTTON_COLOR.shade300
                            : BUTTON_COLOR),
                    onPressed: () {
                      ScheduledTaskEventRepository
                          .getByScheduledTaskIdPaged(
                          scheduledTask.id, ChronologicalPaging.start(10000))
                          .then((scheduledTaskEvents) {
                        if (scheduledTaskEvents.isNotEmpty) {
                          widget.onBeforeRouting?.call();
                          PersonalTaskLoggerScaffoldState? root = appScaffoldKey
                              .currentState;
                          if (root != null) {
                            final taskEventListState = widget.pagesHolder
                                .taskEventList
                                ?.getGlobalKey()
                                .currentState;
                            if (taskEventListState != null) {
                              taskEventListState.filterByTaskEventIds(
                                  scheduledTask,
                                  scheduledTaskEvents.map((e) => e.taskEventId)
                              );
                            }
                            root.sendEventFromClicked(
                                TASK_EVENT_LIST_ROUTING_KEY, false, "noop",
                                null);
                          }
                        }
                        else {
                          toastInfo(context, translate(
                              'pages.schedules.errors.no_journal_entries'),
                              forceShow: true);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            ButtonBar(
              alignment: MainAxisAlignment.end,
              buttonPadding: EdgeInsets.symmetric(horizontal: 0.0),
              children: [
                SizedBox(
                  width: 50,
                  child: TextButton(
                    onPressed: () async {
                      if (scheduledTask.isPaused) {
                        toastError(context, translate(
                            'pages.schedules.errors.cannot_change_paused'));
                        return;
                      }
                      ScheduledTask? changedScheduledTask = await Navigator
                          .push(context, MaterialPageRoute(builder: (context) {
                        return ScheduledTaskForm(
                          formTitle: translate('forms.schedule.change.title',
                              args: {"title": scheduledTask.translatedTitle}),
                          scheduledTask: scheduledTask,
                          taskGroup: TaskGroupRepository.findByIdFromCache(
                              scheduledTask.taskGroupId),
                        );
                      }));

                      if (changedScheduledTask != null) {
                        ScheduledTaskRepository.update(changedScheduledTask)
                            .then((changedScheduledTask) {
                          final state = widget.pagesHolder
                              .scheduledTaskList
                              ?.getGlobalKey()
                              .currentState;
                          ScheduledTaskWidget.cancelSnoozedNotification(
                              changedScheduledTask);
                          state?.updateScheduledTask(
                              scheduledTask, changedScheduledTask);

                          setState(() {
                            scheduledTask.apply(changedScheduledTask);
                          });

                          if (widget.onScheduledTaskChanged != null)
                            widget.onScheduledTaskChanged!(
                                changedScheduledTask);

                          toastInfo(context,
                              translate('forms.schedule.change.success',
                                  args: {
                                    "title": changedScheduledTask
                                        .translatedTitle
                                  }));

                          DueScheduleCountService().gather();
                        });
                      }
                    },
                    child: Icon(Icons.edit,
                        color: isDarkMode(context)
                            ? BUTTON_COLOR.shade300
                            : BUTTON_COLOR),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: TextButton(
                    onPressed: () {
                      showConfirmationDialog(
                        context,
                        translate('pages.schedules.action.deletion.title'),
                        translate('pages.schedules.action.deletion.message',
                            args: {"title": scheduledTask.translatedTitle}),
                        icon: const Icon(Icons.warning_amber_outlined),
                        okPressed: () {
                          ScheduledTaskRepository.delete(scheduledTask).then(
                                (_) {
                              ScheduledTaskEventRepository
                                  .getByScheduledTaskIdPaged(scheduledTask.id!,
                                  ChronologicalPaging.start(10000))
                                  .then((scheduledTaskEvents) {
                                scheduledTaskEvents.forEach((
                                    scheduledTaskEvent) {
                                  ScheduledTaskEventRepository.delete(
                                      scheduledTaskEvent);
                                });
                              });

                              toastInfo(context, translate(
                                  'pages.schedules.action.deletion.success',
                                  args: {
                                    "title": scheduledTask.translatedTitle
                                  }));
                              widget.pagesHolder
                                  .scheduledTaskList
                                  ?.getGlobalKey()
                                  .currentState
                                  ?.removeScheduledTask(scheduledTask);

                              if (widget.onScheduledTaskDeleted != null)
                                widget.onScheduledTaskDeleted!(scheduledTask);

                              DueScheduleCountService().decIfDue(scheduledTask);
                            },
                          );
                          Navigator.pop(
                              context); // dismiss dialog, should be moved in Dialogs.dart somehow
                        },
                        cancelPressed: () =>
                            Navigator.pop(
                                context), // dismiss dialog, should be moved in Dialogs.dart somehow
                      );
                    },
                    child: Icon(Icons.delete,
                        color: isDarkMode(context)
                            ? BUTTON_COLOR.shade300
                            : BUTTON_COLOR),
                  ),
                ),
              ],
            ),
          ],
        ),
      ]);
    }
    else {
      content.add(Text(""));
      expansionWidgets.addAll(content);
    }
    return expansionWidgets;
  }

  Color _getIconColorForMode() => isDarkMode(context) ? Colors.white : Colors.black45;


  String _getDueMessage(ScheduledTask scheduledTask) {
    final nextSchedule = scheduledTask.getNextSchedule()!;

    if (scheduledTask.isNextScheduleOverdue(false)) {
      final dueString = scheduledTask.isNextScheduleOverdue(true)
          ? translate('pages.schedules.overview.overdue').capitalize()
          : translate('pages.schedules.overview.due').capitalize();
      return "$dueString ${translate('common.words.for_for_times')} ${formatDuration(scheduledTask.getMissingDuration()!,
          true, usedClause(context, Clause.dative))} "
          "\n"
          "(${formatToDateOrWord(
          scheduledTask.getNextSchedule()!, context, withPreposition: true,
          makeWhenOnLowerCase: true)})!";

    }
    else if (scheduledTask.isDueNow()) {
      return translate('pages.schedules.overview.due_now').capitalize() + "!";
    }
    else {
      return "${translate('pages.schedules.overview.due').capitalize()} ${translate('common.words.in_for_times')} ${formatDuration(scheduledTask.getMissingDuration()!,
          true, usedClause(context, Clause.dative))} "
          "\n"
          "(${formatToDateOrWord(nextSchedule, context, withPreposition: true,
          makeWhenOnLowerCase: true)} "
          "${scheduledTask.schedule.toStartAtAsString().toLowerCase()})";
    }
  }


  String _getScheduledMessage(ScheduledTask scheduledTask) {
    final passedDuration = scheduledTask.getPassedDuration();
    var passedString = "";
    if (passedDuration != null) {
      passedString = passedDuration.isNegative
          ? "${translate('common.words.in_for_times')} " + formatDuration(passedDuration, true, usedClause(context, Clause.dative))
          : translate('common.words.ago_for_times', args: {"when": formatDuration(passedDuration.abs(), true, usedClause(context, Clause.dative))});
    }
    return "${translate('pages.schedules.overview.scheduled').capitalize()} $passedString "
        "\n"
        "(${formatToDateOrWord(scheduledTask.lastScheduledEventOn!, context, withPreposition: true, makeWhenOnLowerCase: true)})";
  }

}