
import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:personaltasklogger/db/repository/TemplateRepository.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/TaskTemplate.dart';
import 'package:personaltasklogger/model/TaskTemplateVariant.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';
import 'package:personaltasklogger/ui/forms/TaskTemplateForm.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';

import '../utils.dart';

class TaskTemplateList extends StatefulWidget implements PageScaffold {
  _TaskTemplateListState? _state;
  Function(Object)? _selectedItem;
  PagesHolder? _pagesHolder;

  TaskTemplateList(this._pagesHolder);
  TaskTemplateList.withSelectionCallback(this._selectedItem);


  @override
  Widget getTitle() {
    return Text('Tasks');
  }

  @override
  Icon getIcon() {
    return Icon(Icons.task_alt);
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
    _state = _TaskTemplateListState(_selectedItem);
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
    return "TaskTemplates";
  }
}

class _TaskTemplateListState extends State<TaskTemplateList> with AutomaticKeepAliveClientMixin<TaskTemplateList> {

  String? _selectedNode;
  List<Node> _nodes = [];
  late TreeViewController _treeViewController;
  Function(Object)? _itemSelectedHandler;

  _TaskTemplateListState(this._itemSelectedHandler);

  @override
  void initState() {
    super.initState();

    final taskTemplatesFuture = TemplateRepository.getAllTaskTemplates();
    final taskTemplateVariantsFuture = TemplateRepository.getAllTaskTemplateVariants();

    _nodes = predefinedTaskGroups.map((group) => createTaskGroupNode(group, [])).toList();

    Future.wait([taskTemplatesFuture, taskTemplateVariantsFuture]).then((allTemplates) {
      setState(() {
        final taskTemplates = allTemplates[0] as List<TaskTemplate>;
        final taskTemplateVariants = allTemplates[1] as List<TaskTemplateVariant>;

        _nodes = predefinedTaskGroups.map((group) =>
            createTaskGroupNode(
                group,
                findTaskTemplates(taskTemplates, group).map((template) =>
                    createTaskTemplateNode(
                        template,
                        group,
                        findTaskTemplateVariants(taskTemplateVariants, template)
                            .map((variant) =>
                            createTemplateVariantNode(
                                variant,
                                group
                            )).toList()
                    )).toList()
            )).toList();


        _treeViewController = TreeViewController(
          children: _nodes,
          selectedKey: _selectedNode,
        );
      });
    });

    _treeViewController = TreeViewController(
      children: _nodes,
    );
  }

  Node<TaskGroup> createTaskGroupNode(TaskGroup group,
      List<Node<TaskTemplate>> templates) {
    return Node(
      key: group.getKey(),
      label: group.name,
      icon: group.iconData,
      iconColor: getSharpedColor(group.colorRGB),
      parent: true,
      data: group,
      children: templates,
    );
  }

  Node<TaskTemplate> createTaskTemplateNode(TaskTemplate template,
      TaskGroup group,
      List<Node<dynamic>> templateVariants) {
    return Node(
      key: template.getKey(),
      label: template.title,
      icon: group.iconData,
      iconColor: getShadedColor(group.colorRGB, false),
      data: template,
      children: templateVariants,
    );
  }

  Node<TaskTemplateVariant> createTemplateVariantNode(
      TaskTemplateVariant variant, TaskGroup group) {
    return Node(
      key: variant.getKey(),
      label: variant.title,
      icon: group.iconData,
      iconColor: getShadedColor(group.colorRGB, true),
      data: variant,
    );
  }

  void _addTaskTemplate(TaskTemplate template, TaskGroup taskGroup) {
    setState(() {
      _treeViewController = _treeViewController.withAddNode(
          taskGroup.getKey(),
          createTaskTemplateNode(template, taskGroup, [])
      );
    });
  }

  void _updateTaskTemplate(TaskTemplate template, TaskGroup taskGroup) {
    setState(() {
      final children = _treeViewController.getNode(template.getKey())?.children ?? [];
      _treeViewController = _treeViewController.withUpdateNode(
          template.getKey(),
          createTaskTemplateNode(template, taskGroup, children)
      );
    });
    widget._pagesHolder?.quickAddTaskEventPage?.updateTemplate(template);
  }

  void _onFABPressed() {
    if (_treeViewController.selectedKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an item first')));
      return;
    }
    Object? selectedItem = _treeViewController.selectedNode?.data;
    TaskGroup? taskGroup;
    Template? template;
    late String message;
    Widget? action1;
    Widget? action2;
    if (selectedItem is TaskGroup) {
      taskGroup = selectedItem;
      message = "Add a new task underneath '${taskGroup.name}'.";
      action1 = ElevatedButton(
        child: const Text('Create new task'),
        onPressed: () async {
          Navigator.pop(context);
          Template? newTemplate = await Navigator.push(
              context, MaterialPageRoute(builder: (context) {
            return TaskTemplateForm(
              taskGroup!,
              formTitle: "Create new task",
              createNew: true,
            );
          }));

          if (newTemplate != null) {
            TemplateRepository.insert(newTemplate).then((newTemplate) {
              ScaffoldMessenger.of(super.context).showSnackBar(
                  SnackBar(content: Text(
                      'New task with name \'${newTemplate.title}\' created')));
              _addTaskTemplate(newTemplate as TaskTemplate, taskGroup!);
            });
          }
        },
      );
    }
    else if (selectedItem is Template) {
      template = selectedItem as Template;
      taskGroup = findPredefinedTaskGroupById(template.taskGroupId);
      if (template.isVariant()) {
        message = "Change the selected variant or clone it as a new one.";
        action1 = OutlinedButton(
          child: const Text('Change current variant'),
          onPressed: () async {},
        );
        action2 = ElevatedButton(
          child: const Text('Clone new variant'),
          onPressed: () async {},
        );
      }
      else {
        message =
        "Change the selected task or create a new variant underneath it.";
        action1 = OutlinedButton(
          child: const Text('Change current task'),
          onPressed: () async {
            Navigator.pop(context);
            Template? changedTemplate = await Navigator.push(
                context, MaterialPageRoute(builder: (context) {
              return TaskTemplateForm(
                taskGroup!,
                formTitle: "Change task '${template?.title}'",
                template: template,
                createNew: false,
              );
            }));

            if (changedTemplate != null) {
              TemplateRepository.save(changedTemplate)
                  .then((_) {
                ScaffoldMessenger.of(super.context).showSnackBar(
                    SnackBar(content: Text(
                        'Task with name \'${changedTemplate.title}\' changed')));
                _updateTaskTemplate(changedTemplate as TaskTemplate, taskGroup!);
              });
            }
          },
        );
        action2 = ElevatedButton(
          child: const Text('Create new variant'),
          onPressed: () async {},
        );
      }
    }

    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          var sheetChildren = <Widget>[
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(message),
            ),
          ];
          if (action1 != null) sheetChildren.add(action1);
          if (action2 != null) sheetChildren.add(action2);
          return Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: sheetChildren,
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    TreeViewTheme _treeViewTheme = TreeViewTheme(
      expanderTheme: ExpanderThemeData(
          type: ExpanderType.caret,
          modifier: ExpanderModifier.none,
          position: ExpanderPosition.end,
          size: 20),
      labelStyle: TextStyle(
        fontSize: 16,
        letterSpacing: 0.3,
      ),
      parentLabelStyle: TextStyle(
        fontSize: 16,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w800,
      ),
      /*  iconTheme: IconThemeData(
        size: 18,
      ),*/
      colorScheme: Theme
          .of(context)
          .colorScheme,
    );

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: TreeView(
        controller: _treeViewController,
        allowParentSelect: true,
        supportParentDoubleTap: false,
        onExpansionChanged: (key, expanded) =>
            _expandNode(key, expanded),
        onNodeTap: (key) {
          debugPrint('Selected: $key');
          setState(() {
            _selectedNode = key;
            _treeViewController =
                _treeViewController.copyWith(selectedKey: key);
            if (_itemSelectedHandler != null) {
              Object? data = _treeViewController.selectedNode?.data;
              if (data != null) {
                _itemSelectedHandler!(data);
              }
            }
          });
        },
        theme: _treeViewTheme,
      ),
    );
  }

  _expandNode(String key, bool expanded) {
    String msg = '${expanded ? "Expanded" : "Collapsed"}: $key';
    debugPrint(msg);
    Node? node = _treeViewController.getNode(key);
    if (node != null) {
      List<Node> updated = _treeViewController.updateNode(
          key, node.copyWith(expanded: expanded));
      setState(() {
        _treeViewController = _treeViewController.copyWith(children: updated);
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  Iterable<TaskTemplate> findTaskTemplates(List<TaskTemplate> taskTemplates,
      TaskGroup group) {
    return taskTemplates.where((template) => template.taskGroupId == group.id);
  }

  Iterable<TaskTemplateVariant> findTaskTemplateVariants(List<TaskTemplateVariant> taskTemplateVariants,
      TaskTemplate taskTemplate) {
    return taskTemplateVariants.where((variant) => variant.taskTemplateId == taskTemplate.tId!.id);
  }

}

