import 'package:flutter/material.dart';
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

final pinQuickAddPageIconKey = new GlobalKey<ToggleActionIconState>();

@immutable
class QuickAddTaskEventPage extends PageScaffold<QuickAddTaskEventPageState> {
  final PagesHolder _pagesHolder;

  QuickAddTaskEventPage(this._pagesHolder);

  @override
  Widget getTitle() {
    return Text('QuickAdd');
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
  List<Template> _templates = [];

  SortBy _sortBy = SortBy.GROUP;
  bool _pinQuickAddPage = false;


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

    TemplateRepository.getAllFavorites().then((templates) {
      setState(() {
        _templates = templates;
        _sortList();
      });
    });
  }

  @override
  void searchQueryUpdated(String? searchQuery) {
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: OrientationBuilder(
        builder: (context, orientation) {
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
                      "Delete QuickAdd for '${template.title}'",
                      "Are you sure to remove this QuickAdd? This will not affect the associated task.",
                      icon: const Icon(Icons.warning_amber_outlined),
                      okPressed: () {
                        template.favorite = false;
                        TemplateRepository.save(template).then((template) {
                          toastInfo(context, "Removed '${template.title}' from QuickAdd");

                          setState(() {
                            _templates.remove(template);
                            _sortList();
                          });
                        });
                        Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow
                      },
                      cancelPressed: () =>
                          Navigator.pop(context), // dismiss dialog, should be moved in Dialogs.dart somehow
                    );
                  },
                  onTap: () async {
                    TaskEvent? newTaskEvent = await Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return TaskEventForm(
                          formTitle: "Create new journal entry",
                          template: template );
                    }));

                    if (newTaskEvent != null) {
                      TaskEventRepository.insert(newTaskEvent).then((newTaskEvent) {
                        toastInfo(context, "New journal entry with name '${newTaskEvent.title}' created");
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
                          Text(template.title, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                );
              });
        }
      ),
    );
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

    return [
      IconButton(
          icon: pinQuickAddPage,
          onPressed: () {
            _pinQuickAddPage = !_pinQuickAddPage;
            _updatePinQuickAddPage(_pinQuickAddPage, withSnackMsg: true);
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
                          Text("Sort by category"),
                        ]
                    ),
                    value: '1'),
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          createCheckIcon(_sortBy == SortBy.TITLE),
                          const Spacer(),
                          Text("Sort by title"),
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
                    child: const Text('What do you want to create?'),
                  ),
                  OutlinedButton(
                    child: const Text('New QuickAdd'),
                    onPressed: () {
                      Navigator.pop(super.context);

                      _onCreateQuickAddPressed();
                    },
                  ),
                  ElevatedButton(
                    child: const Text('New journal entry'),
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
    showTemplateDialog(context, "New journal entry", "Select a category or task to be used for the journal entry.",
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
                formTitle: "Create new journal entry",
                taskGroup: _selectedTemplateItem as TaskGroup,);
            }
            else if (_selectedTemplateItem is Template) {
              return TaskEventForm(
                formTitle: "Create new journal entry",
                template: _selectedTemplateItem as Template,);
            }
            else {
              return TaskEventForm(formTitle: "Create new journal entry");
            }
          }));
    
          if (newTaskEvent != null) {
            TaskEventRepository.insert(newTaskEvent).then((newTaskEvent) {
              toastInfo(super.context, "New journal entry with name '${newTaskEvent.title}' created");
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

  void _onCreateQuickAddPressed() {
    Object? selectedTemplateItem;

    showTemplateDialog(context, "New QuickAdd", "Add a task to be added to QuickAdd.",
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
            toastInfo(context, "'${template.title}' still present");
          }
          else {
            setState(() {
              toastInfo(context, "Added '${template.title}' to QuickAdd");
              _templates.add(template);
              _sortList();
            });
          }
        });
      }
    }, cancelPressed: () {
      Navigator.pop(super.context);
    });
  }

  void updateTemplate(Template template) {
    setState(() {
      final index = _templates.indexOf(template);
      if (index != -1) {
        _templates.removeAt(index);
        _templates.insert(index, template);
      }
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
      _sortList();
    });
  }


  void _sortList() {
    _templates..sort((t1, t2) {
      if (_sortBy == SortBy.GROUP) {
        final g1 = t1.taskGroupId;
        final g2 = t2.taskGroupId;
        final c = g2.compareTo(g1);
        if (c == 0) {
          return _sortByTitleAndId(t1, t2);
        }
        return c;
      }
      else if (_sortBy == SortBy.TITLE) {
        return _sortByTitleAndId(t1, t2);
      }
      else {
        return t1.compareTo(t2);
      }
    });
  }

  int _sortByTitleAndId(Template t1, Template t2) {
    final d1 = t1.title.toLowerCase();
    final d2 = t2.title.toLowerCase();
    final c = d1.compareTo(d2);
    if (c == 0) {
      return t1.tId!.compareTo(t2.tId!);
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
          toastInfo(context, "QuickAdd page pinned");
        }

      }
      else {
        if (withSnackMsg) {
          toastInfo(context, "QuickAdd page unpinned");
        }
      }
      _preferenceService.setBool(PREF_PIN_QUICK_ADD, _pinQuickAddPage);
    });
  }
}
