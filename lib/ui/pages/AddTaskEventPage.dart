import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/IdPaging.dart';
import 'package:personaltasklogger/db/repository/TaskEventRepository.dart';
import 'package:personaltasklogger/db/repository/TemplateRepository.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/forms/TaskEventForm.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';
import 'package:personaltasklogger/ui/pages/TaskEventList.dart';

import '../PersonalTaskLoggerScaffold.dart';

class QuickAddTaskEventPage extends StatefulWidget implements PageScaffold {
  _QuickAddTaskEventPageState? _state;
  TaskEventList _taskEventList;

  QuickAddTaskEventPage(this._taskEventList);

  @override
  String getTitle() {
    return 'QuickAdd Task Events';
  }

  @override
  Icon getIcon() {
    return Icon(Icons.add_circle_outline_outlined);
  }

  @override
  List<Widget>? getActions(BuildContext context) {
    return null;
  }

  @override
  void handleFABPressed(BuildContext context) {
    _state?._onFABPressed();
  }

  @override
  State<StatefulWidget> createState() {
    _state = _QuickAddTaskEventPageState(_taskEventList);
    return _state!;
  }
}

class _QuickAddTaskEventPageState extends State<QuickAddTaskEventPage> with AutomaticKeepAliveClientMixin<QuickAddTaskEventPage> {
  TaskEventList _taskEventList;
  List<Template> _templates = [];

  _QuickAddTaskEventPageState(this._taskEventList);

  @override
  void initState() {
    super.initState();

    final paging = IdPaging(IdPaging.maxId, 100);
    TemplateRepository.getAllFavorites().then((templates) {
      setState(() {
        _templates = templates;
        _templates..sort();
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
                      "Are you sure to remove this QuickAdd? This will not affect the template itself.",
                      okPressed: () {
                        template.favorite = false;
                        TemplateRepository.update(template).then((changedScheduledTask) {
                          ScaffoldMessenger.of(super.context).showSnackBar(SnackBar(
                              content: Text('Removed \'${template.title}\' from QuickAdd')));

                          setState(() {
                            _templates.remove(template);
                            _templates..sort();
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
                          formTitle: "Create new event from QuickAdd",
                          template: template );
                    }));

                    if (newTaskEvent != null) {
                      TaskEventRepository.insert(newTaskEvent).then((newTaskEvent) {
                        ScaffoldMessenger.of(super.context).showSnackBar(
                            SnackBar(content: Text('New task event with name \'${newTaskEvent.title}\' created')));
                        _taskEventList.addTaskEvent(newTaskEvent);
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
        var addToState = false;
        TemplateRepository.findById(template.tId!)
            .then((foundTaskTemplate) {
          debugPrint("found: $foundTaskTemplate");
          if (foundTaskTemplate != null) {
            addToState = foundTaskTemplate.favorite == false;
            foundTaskTemplate.favorite = true;
            TemplateRepository.update(foundTaskTemplate);
            template = foundTaskTemplate;
          } else {
            template.favorite = true;
            TemplateRepository.insert(template);
            addToState = true;
          }
          Navigator.pop(
              context); // dismiss dialog, should be moved in Dialogs.dart somehow

          ScaffoldMessenger.of(super.context).showSnackBar(SnackBar(
              content: Text('Added \'${template.title}\' to QuickAdd')));

          if (addToState) {
            setState(() {
              _templates.add(template);
              _templates..sort();
            });
          }
        });
      }
      else {
        SnackBar(content: Text("Please select a template or a variant"));
      }
    }, cancelPressed: () {
      Navigator.pop(super.context);
    });
  }

  @override
  bool get wantKeepAlive => true;
}
