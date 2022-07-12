import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/db/repository/TaskEventRepository.dart';
import 'package:personaltasklogger/db/repository/TemplateRepository.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/service/PreferenceService.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/forms/TaskEventForm.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';
import 'package:personaltasklogger/ui/pages/PageScaffoldState.dart';

import '../ToggleActionIcon.dart';
import '../utils.dart';
import 'PageScaffoldState.dart';
import 'TaskEventList.dart';

final String PREF_SORT_BY = "quickAdd/sortedBy";
final String PREF_PIN_QUICK_ADD = "quickAdd/pinPage";
final String PREF_GROUP_BY_CATEGORY = "quickAdd/groupByCategory";

@immutable
class QuickAddTaskEventPage extends PageScaffold<QuickAddTaskEventPageState> {
  final PagesHolder _pagesHolder;

  QuickAddTaskEventPage(this._pagesHolder);

  @override
  Widget getTitle() {
    return Text(translate('pages.quick_add.title'));
  }

  @override
  Icon getIcon() {
    return Icon(Icons.add_circle_outline_outlined);
  }

  @override
  State<StatefulWidget> createState() => QuickAddTaskEventPageState();

  @override
  bool withSearchBar() {
    return false;
  }

  @override
  String getRoutingKey() {
    return "QuickAdd";
  }

}

enum SortBy {GROUP, TITLE,}

class QuickAddTaskEventPageState extends PageScaffoldState<QuickAddTaskEventPage> with AutomaticKeepAliveClientMixin<QuickAddTaskEventPage> {

  final pinQuickAddPageIconKey = new GlobalKey<ToggleActionIconState>();
  final groupByCategoryIconKey = new GlobalKey<ToggleActionIconState>();

  List<Template> _templates = [];

  SortBy _sortBy = SortBy.GROUP;
  bool _pinQuickAddPage = false;
  bool _groupByCategory = false;
  TaskGroup? _groupedByTaskGroup;


  final _preferenceService = PreferenceService();

  @override
  void initState() {
    super.initState();

    _preferenceService.getInt(PREF_SORT_BY).then((value) {
      if (value != null) {
        setState(() {
          _sortBy = SortBy.values.elementAt(value);
        });
      }
    });

    _loadQuickAdds();
  }

  @override
  reload() {
    _loadQuickAdds();
  }

  @override
  void searchQueryUpdated(String? searchQuery) {
  }

  @override
  Widget build(BuildContext context) {
    final color = _groupedByTaskGroup?.backgroundColor;
    var goUp = OutlinedButton(
      child: Icon(Icons.arrow_back),
      style: OutlinedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        side: BorderSide.none,
        minimumSize: Size(double.infinity, 30), // double.infinity is the width and 30 is the height
      ),
      onPressed: () {
        _groupedByTaskGroup = null;
        _loadQuickAdds();
      },
    );
    var tiles = OrientationBuilder(
              builder: (context, orientation) {
                if (_groupByCategory && _groupedByTaskGroup == null) {
                  return _buildTaskGroupTiles(orientation);
                }
                else {
                  return _buildTemplateTiles(orientation);
                }
              }
            );
    if (_groupedByTaskGroup != null) {
      return Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            goUp,
            Expanded(
              child: tiles,
            ),
          ],
        ),
      );
    }
    else {
      return Padding(
        padding: EdgeInsets.all(16.0),
        child: tiles,
      );
    }
  }

  @override
  List<Widget>? getActions(BuildContext context) {
    final pinQuickAddPage = ToggleActionIcon(Icons.push_pin, Icons.push_pin_outlined, _pinQuickAddPage, pinQuickAddPageIconKey);
    _preferenceService.getBool(PREF_PIN_QUICK_ADD).then((value) {
      if (value != null) {
        _updatePinQuickAddPage(value, withSnackMsg: false);
      }
      else {
        pinQuickAddPageIconKey.currentState?.refresh(_pinQuickAddPage);
      }
    });

    final groupByCategoryIcon = ToggleActionIcon(Icons.category, Icons.category_outlined, _groupByCategory, groupByCategoryIconKey);
    _preferenceService.getBool(PREF_GROUP_BY_CATEGORY).then((value) {
      if (value != null) {
        _updateGroupByCategory(value, withSnackMsg: false);
      }
      else {
        groupByCategoryIconKey.currentState?.refresh(_groupByCategory);
      }
    });

    return [
      IconButton(
          icon: pinQuickAddPage,
          onPressed: () {
            _pinQuickAddPage = !_pinQuickAddPage;
            _updatePinQuickAddPage(_pinQuickAddPage, withSnackMsg: true);
          }),
      IconButton(
          icon: groupByCategoryIcon,
          onPressed: () {
            _groupByCategory = !_groupByCategory;
            _updateGroupByCategory(_groupByCategory, withSnackMsg: true);
          }),
      GestureDetector(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(Icons.sort_outlined)),
        onTapDown: (details) {
          showPopUpMenuAtTapDown(
              context,
              details,
              [
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          createCheckIcon(_sortBy == SortBy.GROUP),
                          const Spacer(),
                          Text(translate('pages.quick_add.menu.sorting.by_category')),
                        ]
                    ),
                    value: '1'),
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          createCheckIcon(_sortBy == SortBy.TITLE),
                          const Spacer(),
                          Text(translate('pages.quick_add.menu.sorting.by_title')),
                        ]
                    ),
                    value: '2'),

              ]
          ).then((selected) {
            switch (selected) {
              case '1' :
                {
                  _updateSortBy(SortBy.GROUP);
                  break;
                }
              case '2' :
                {
                  _updateSortBy(SortBy.TITLE);
                  break;
                }
            }
          });
        },
      ),
    ];
  }

  @override
  void handleFABPressed(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(translate('pages.quick_add.action.description')),
                  ),
                  OutlinedButton(
                    child: Text(translate('pages.quick_add.action.new_quick_add.title')),
                    onPressed: () {
                      Navigator.pop(super.context);

                      _onCreateQuickAddPressed();
                    },
                  ),
                  ElevatedButton(
                    child: Text(translate('pages.quick_add.action.new_journal_entry.title')),
                    onPressed: () {
                      Navigator.pop(context);
                      _onCreateTaskEventPressed(context);
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  void _onCreateTaskEventPressed(BuildContext context) async {
    Object? _selectedTemplateItem;
    showTemplateDialog(context,
        translate('pages.quick_add.action.new_journal_entry.title'),
        translate('pages.quick_add.action.new_journal_entry.description'),
        selectedItem: (selectedItem) {
          setState(() {
            _selectedTemplateItem = selectedItem;
          });
        },
        okPressed: () async {
          Navigator.pop(super.context);
          TaskEvent? newTaskEvent = await Navigator.push(super.context, MaterialPageRoute(builder: (context) {
            if (_selectedTemplateItem is TaskGroup) {
              return TaskEventForm(
                formTitle: translate('forms.task_event.title'),
                taskGroup: _selectedTemplateItem as TaskGroup,);
            }
            else if (_selectedTemplateItem is Template) {
              return TaskEventForm(
                formTitle: translate('forms.task_event.title'),
                template: _selectedTemplateItem as Template,);
            }
            else {
              return TaskEventForm(formTitle: translate('forms.task_event.title'));
            }
          }));
    
          if (newTaskEvent != null) {
            TaskEventRepository.insert(newTaskEvent).then((newTaskEvent) {
              toastInfo(super.context, translate('forms.task_event.new_task_event_created',
                  args: {"title" : newTaskEvent.translatedTitle}));
              _handleNewTaskEvent(newTaskEvent);
            });
          }
        },
        cancelPressed: () {
          Navigator.pop(super.context);
        });
  }

  void _handleNewTaskEvent(TaskEvent newTaskEvent) {
    widget._pagesHolder.taskEventList?.getGlobalKey().currentState?.addTaskEvent(newTaskEvent);

    if (_pinQuickAddPage != true) {
      PersonalTaskLoggerScaffoldState? root = context.findAncestorStateOfType();
      if (root != null) {
        final taskEventListState = widget._pagesHolder.taskEventList
            ?.getGlobalKey()
            .currentState;
        if (taskEventListState != null) {
          taskEventListState.clearFilters();
          root.sendEventFromClicked(TASK_EVENT_LIST_ROUTING_KEY, false, newTaskEvent.id.toString());
        }
      }
    }
  }
  
  GridView _buildTemplateTiles(Orientation orientation) {
    return GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150,
            childAspectRatio: (orientation == Orientation.landscape ? 12 : 7) / 6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10),
        itemCount: _templates.length,
        itemBuilder: (BuildContext ctx, index) {
          final template = _templates[index];
          final taskGroup = findPredefinedTaskGroupById(template.taskGroupId);
          return GestureDetector(
            onLongPressStart: (details) {
              showConfirmationDialog(
                context,
                translate('pages.quick_add.deletion.title'),
                translate('pages.quick_add.deletion.description',
                  args: {"title" : template.translatedTitle}),
                icon: const Icon(Icons.warning_amber_outlined),
                okPressed: () {
                  template.favorite = false;
                  TemplateRepository.save(template).then((template) {
                    toastInfo(context, translate('pages.quick_add.deletion.success',
                        args: {"title" : template.translatedTitle}));

                    setState(() {
                      _templates.remove(template);
                      _sortTemplateList();
                    });
                  });
                  Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow
                },
                cancelPressed: () =>
                    Navigator.pop(context), // dismiss dialog, should be moved in Dialogs.dart somehow
              );
            },
            onTap: () async {
              TaskEvent? newTaskEvent = await Navigator.push(
                  context, MaterialPageRoute(builder: (context) {
                return TaskEventForm(
                    formTitle: translate('forms.task_event.title'),
                    template: template);
              }));

              if (newTaskEvent != null) {
                TaskEventRepository.insert(newTaskEvent).then((
                    newTaskEvent) {
                  toastInfo(context,
                      translate('forms.task_event.new_task_event_created',
                          args: {"title" : newTaskEvent.translatedTitle}));
                  _handleNewTaskEvent(newTaskEvent);
                });
              }
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: taskGroup.backgroundColor,
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    taskGroup.getIcon(true),
                    Text(template.translatedTitle, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        });
  }

  GridView _buildTaskGroupTiles(Orientation orientation) {
    final taskGroups = _templates
      .map((template) => findPredefinedTaskGroupById(template.taskGroupId))
      .toSet()
      .toList();

    taskGroups..sort((t1, t2) {
      if (_sortBy == SortBy.GROUP) {
        final g1 = t1.id!;
        final g2 = t2.id!;
        final c = g2.compareTo(g1);
        if (c == 0) {
          return _sortTaskGroupByTitleAndId(t1, t2);
        }
        return c;
      }
      else if (_sortBy == SortBy.TITLE) {
        return _sortTaskGroupByTitleAndId(t1, t2);
      }
      else {
        return t1.compareTo(t2);
      }
    });

    return GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150,
            childAspectRatio: (orientation == Orientation.landscape ? 12 : 7) / 6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10),
        itemCount: taskGroups.length,
        itemBuilder: (BuildContext ctx, index) {
          final taskGroup = taskGroups[index];
          return GestureDetector(
            onTap: () async {
              _groupedByTaskGroup = taskGroup;
              _loadQuickAdds();
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: taskGroup.backgroundColor,
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    taskGroup.getIcon(true),
                    Text(taskGroup.translatedName, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),)
                  ],
                ),
              ),
            ),
          );
        });
  }

  void _onCreateQuickAddPressed() {
    Object? selectedTemplateItem;

    showTemplateDialog(context,
        translate('pages.quick_add.action.new_quick_add.title'),
        translate('pages.quick_add.action.new_quick_add.description'),
        selectedItem: (selectedItem) {
      setState(() {
        selectedTemplateItem = selectedItem;
      });
    }, okPressed: () async {
      if (selectedTemplateItem is Template) {
        var template = selectedTemplateItem as Template;
        template.favorite = true;
        TemplateRepository.save(template).then((template) {
          Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow

          if (_templates.contains(template)) {
            toastInfo(context, translate('pages.quick_add.addition.exists',
                args: {"title" : template.translatedTitle}));
          }
          else {
            updateTemplate(template);
            toastInfo(context, translate('pages.quick_add.addition.success',
                args: {"title" : template.translatedTitle}));
          }
        });
      }
    }, cancelPressed: () {
      Navigator.pop(super.context);
    });
  }

  void updateTemplate(Template template) {
    setState(() {
      if (_groupByCategory) {
        _groupedByTaskGroup = findPredefinedTaskGroupById(template.taskGroupId);
      }
      _loadQuickAdds();
    });
  }

  void removeTemplate(Template template) {
    setState(() {
      final index = _templates.indexOf(template);
      if (index != -1) {
        _templates.removeAt(index);
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  void _updateSortBy(SortBy sortBy) {
    _preferenceService.setInt(PREF_SORT_BY, sortBy.index);
    setState(() {
      _sortBy = sortBy;
      _sortTemplateList();
    });
  }


  void _sortTemplateList() {
    _templates..sort((t1, t2) {
      if (_sortBy == SortBy.GROUP) {
        final g1 = t1.taskGroupId;
        final g2 = t2.taskGroupId;
        final c = g2.compareTo(g1);
        if (c == 0) {
          return _sortTemplateByTitleAndId(t1, t2);
        }
        return c;
      }
      else if (_sortBy == SortBy.TITLE) {
        return _sortTemplateByTitleAndId(t1, t2);
      }
      else {
        return t1.compareTo(t2);
      }
    });
  }

  int _sortTemplateByTitleAndId(Template t1, Template t2) {
    final d1 = t1.translatedTitle.toLowerCase();
    final d2 = t2.translatedTitle.toLowerCase();
    final c = d1.compareTo(d2);
    if (c == 0) {
      return t1.tId!.compareTo(t2.tId!);
    }
    return c;
  }

  int _sortTaskGroupByTitleAndId(TaskGroup t1, TaskGroup t2) {
    final d1 = t1.translatedName.toLowerCase();
    final d2 = t2.translatedName.toLowerCase();
    final c = d1.compareTo(d2);
    if (c == 0) {
      return t1.id!.compareTo(t2.id!);
    }
    return c;
  }

  @override
  handleNotificationClickRouted(bool isAppLaunch, String payload) {
  }


  void _updatePinQuickAddPage(bool value, {required bool withSnackMsg}) {
    setState(() {
      _pinQuickAddPage = value;
      pinQuickAddPageIconKey.currentState?.refresh(_pinQuickAddPage);
      if (_pinQuickAddPage) {
        if (withSnackMsg) {
          toastInfo(context, translate('pages.quick_add.menu.pinning.pinned'));
        }

      }
      else {
        if (withSnackMsg) {
          toastInfo(context, translate('pages.quick_add.menu.pinning.unpinned'));
        }
      }
      _preferenceService.setBool(PREF_PIN_QUICK_ADD, _pinQuickAddPage);
    });
  }


  void _updateGroupByCategory(bool value, {required bool withSnackMsg}) {
    setState(() {
      _groupByCategory = value;
      groupByCategoryIconKey.currentState?.refresh(_groupByCategory);
      if (_groupByCategory) {
        if (withSnackMsg) {
          toastInfo(context, translate('pages.quick_add.menu.grouping.by_categories'));
        }

      }
      else {
        _groupedByTaskGroup = null;
        if (withSnackMsg) {
          toastInfo(context, translate('pages.quick_add.menu.grouping.not_by_categories'));
        }
      }
      _preferenceService.setBool(PREF_GROUP_BY_CATEGORY, _groupByCategory);
      _loadQuickAdds();
    });
  }

  void _loadQuickAdds() {
    TemplateRepository.getAllFavorites().then((templates) {
      setState(() {
        _templates = templates
            .where((template) => _groupedByTaskGroup == null || _groupedByTaskGroup!.id == template.taskGroupId)
            .toList();
        _sortTemplateList();
      });
    });
  }
}
