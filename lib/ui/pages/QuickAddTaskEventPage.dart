import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/IdPaging.dart';
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

import '../utils.dart';

final String PREF_SORT_BY = "quickAdd/sortedBy";

class QuickAddTaskEventPage extends StatefulWidget implements PageScaffold {
  _QuickAddTaskEventPageState? _state;
  PagesHolder _pagesHolder;

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
  List<Widget>? getActions(BuildContext context) {
    return [
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
                          createCheckIcon(_state?._sortBy == SortBy.GROUP),
                          const Spacer(),
                          Text("Sort by category"),
                        ]
                    ),
                    value: '1'),
                PopupMenuItem<String>(
                    child: Row(
                        children: [
                          createCheckIcon(_state?._sortBy == SortBy.TITLE),
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
                  _state?._updateSortBy(SortBy.GROUP);
                  break;
                }
              case '2' :
                {
                  _state?._updateSortBy(SortBy.TITLE);
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
    _state?._onFABPressed();
  }

  @override
  State<StatefulWidget> createState() {
    _state = _QuickAddTaskEventPageState();
    return _state!;
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
    return "QuickAdd";
  }
}

enum SortBy {GROUP, TITLE,}

class _QuickAddTaskEventPageState extends State<QuickAddTaskEventPage> with AutomaticKeepAliveClientMixin<QuickAddTaskEventPage> {
  List<Template> _templates = [];
  SortBy _sortBy = SortBy.GROUP;
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
                      "Delete QuickAdd for \'${template.title}\'",
                      "Are you sure to remove this QuickAdd? This will not affect the associated task.",
                      okPressed: () {
                        template.favorite = false;
                        TemplateRepository.save(template).then((_) {
                          ScaffoldMessenger.of(super.context).showSnackBar(SnackBar(
                              content: Text('Removed \'${template.title}\' from QuickAdd')));

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
                        ScaffoldMessenger.of(super.context).showSnackBar(
                            SnackBar(content: Text('New journal entry with name \'${newTaskEvent.title}\' created')));
                        widget._pagesHolder.taskEventList?.addTaskEvent(newTaskEvent);
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

  void _onFABPressed() {
    Object? selectedTemplateItem;

    showTemplateDialog(context, "Select a task to be added to QuickAdd",
        selectedItem: (selectedItem) {
      setState(() {
        selectedTemplateItem = selectedItem;
      });
    }, okPressed: () async {
      if (selectedTemplateItem is Template) {
        var template = selectedTemplateItem as Template;
        template.favorite = true;
        TemplateRepository.save(template).then((_) {
          Navigator.pop(
              context); // dismiss dialog, should be moved in Dialogs.dart somehow

          ScaffoldMessenger.of(super.context).showSnackBar(SnackBar(
              content: Text('Added \'${template.title}\' to QuickAdd')));

          if (!_templates.contains(template)) {
            setState(() {
              _templates.add(template);
              _sortList();
            });
          }
        });
      }
      else {
        SnackBar(content: Text("Please select a task"));
      }
    }, cancelPressed: () {
      Navigator.pop(super.context);
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
        final d1 = t1.taskGroupId;
        final d2 = t2.taskGroupId;
        return d1.compareTo(d2);
      }
      else if (_sortBy == SortBy.TITLE) {
        final d1 = t1.title.toLowerCase();
        final d2 = t2.title.toLowerCase();
        final c = d1.compareTo(d2);
        if (c == 0) {
          return t1.title.toLowerCase().compareTo(t2.title.toLowerCase());
        }
        return c;
      }
      else {
        return t1.compareTo(t2);
      }
    });
  }

}
