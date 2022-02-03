import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/IdPaging.dart';
import 'package:personaltasklogger/db/repository/TaskEventRepository.dart';
import 'package:personaltasklogger/db/repository/TaskTemplateRepository.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/TaskTemplate.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/forms/TaskEventForm.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';

class QuickAddTaskEventPage extends StatefulWidget implements PageScaffold {
  _QuickAddTaskEventPageState? _state;

  @override
  String getTitle() {
    return 'Add Task Event';
  }

  @override
  Icon getIcon() {
    return Icon(Icons.add_circle_outline_outlined);
  }

  @override
  List<Widget>? getActions() {
    return null;
  }

  @override
  Function() handleActionPressed(int index) {
    // TODO: implement handleActionPressed
    throw UnimplementedError();
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
}

class _QuickAddTaskEventPageState extends State<QuickAddTaskEventPage> {
  List<Template> _templates = [];

  @override
  void initState() {
    super.initState();

    final paging = IdPaging(IdPaging.maxId, 100);
    TaskTemplateRepository.getAllFavsPaged(paging).then((taskTemplates) {
      setState(() {
        _templates = taskTemplates;
        _templates..sort();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              childAspectRatio: 7 / 6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10),
          itemCount: _templates.length,
          itemBuilder: (BuildContext ctx, index) {
            final template = _templates[index];
            final taskGroup = findPredefinedTaskGroupById(template.taskGroupId);
            return GestureDetector(
              onLongPressStart: (details) {
                print("long pressing");
              },
              onTap: () async {
                TaskEvent? newTaskEvent = await Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return TaskEventForm(
                      formTitle: "Create new event from quick",
                      template: template );
                }));

                if (newTaskEvent != null) {
                  TaskEventRepository.insert(newTaskEvent).then((newTaskEvent) {
                    ScaffoldMessenger.of(super.context).showSnackBar(
                        SnackBar(content: Text('New task event with name \'${newTaskEvent.title}\' created')));
                    //TODO add to ui in TaskEventList._addTaskEvent(newTaskEvent);
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
          }),
    );
  }

  void _onFABPressed() {
    Object? selectedTemplateItem;

    showTemplateDialog(context, "Select a task template",
        selectedItem: (selectedItem) {
      setState(() {
        selectedTemplateItem = selectedItem;
      });
    }, okPressed: () async {
      if (selectedTemplateItem is TaskTemplate) {
        var taskTemplate = selectedTemplateItem as TaskTemplate;
        var addToState = false;
        TaskTemplateRepository.findById(taskTemplate.tId!)
            .then((foundTaskTemplate) {
          debugPrint("found: $foundTaskTemplate");
          if (foundTaskTemplate != null) {
            addToState = foundTaskTemplate.favorite == false;
            foundTaskTemplate.favorite = true;
            TaskTemplateRepository.update(foundTaskTemplate);
            taskTemplate = foundTaskTemplate;
          } else {
            taskTemplate.favorite = true;
            TaskTemplateRepository.insert(taskTemplate);
            addToState = true;
          }
          Navigator.pop(
              context); // dismiss dialog, should be moved in Dialogs.dart somehow

          ScaffoldMessenger.of(super.context).showSnackBar(SnackBar(
              content: Text('Added \'${taskTemplate.title}\' to short cut')));

          if (addToState) {
            setState(() {
              _templates.add(taskTemplate);
              _templates..sort();
            });
          }
        });
      } else {
        SnackBar(content: Text("Please select a template or a variant"));
      }
    }, cancelPressed: () {
      Navigator.pop(super.context);
    });
  }
}
