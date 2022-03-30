
import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:personaltasklogger/db/repository/TemplateRepository.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/TaskTemplate.dart';
import 'package:personaltasklogger/model/TaskTemplateVariant.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/model/TemplateId.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';
import 'package:personaltasklogger/ui/forms/TaskTemplateForm.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';

import '../ToggleActionIcon.dart';
import '../dialogs.dart';
import '../utils.dart';
import 'PageScaffoldState.dart';

@immutable
class TaskTemplateList extends PageScaffold<TaskTemplateListState> {

  final expandIconKey = new GlobalKey<ToggleActionIconState>();

  final Function(Object)? _selectedItem; //TODO to ValueChanged
  final PagesHolder? _pagesHolder;
  final bool? onlyHidden;
  final bool? hideEmptyNodes;
  final bool? expandAll;
  bool isModal = false;

  TaskTemplateList(this._pagesHolder): _selectedItem = null, onlyHidden = null, hideEmptyNodes = null, expandAll = null;
  TaskTemplateList.withSelectionCallback(
      this._selectedItem,
      {this.onlyHidden, this.hideEmptyNodes, this.expandAll, Key? key})
      :  _pagesHolder = null, isModal = true, super(key: key);


  @override
  Widget getTitle() {
    return Text('Tasks');
  }

  @override
  Icon getIcon() {
    return Icon(Icons.task_alt);
  }

  @override
  State<StatefulWidget> createState() => TaskTemplateListState();

  @override
  bool withSearchBar() {
    return true;
  }

  @override
  String getRoutingKey() {
    return "TaskTemplates";
  }

}

class TaskTemplateListState extends PageScaffoldState<TaskTemplateList> with AutomaticKeepAliveClientMixin<TaskTemplateList> {

  String? _selectedNodeKey;
  List<Node> _nodes = [];
  late TreeViewController _treeViewController;
  String? _searchQuery;
  bool? _forceExpandOrCollapseAll;

  /**
   * index 0: TaskTemplates
   * index 1: TaskTemplateVariants
   */
  List<List<Template>> _allTemplates = [];

  @override
  void initState() {
    super.initState();

    final taskTemplatesFuture = TemplateRepository.getAllTaskTemplates(widget.onlyHidden??false);
    final taskTemplateVariantsFuture = TemplateRepository.getAllTaskTemplateVariants(widget.onlyHidden??false);

    _nodes = predefinedTaskGroups.map((group) => createTaskGroupNode(group, [], widget.expandAll??false)).toList();

    Future.wait([taskTemplatesFuture, taskTemplateVariantsFuture]).then((allTemplates) {
      
      setState(() {
        _allTemplates = allTemplates;
        // filter only hidden but non-hidden if have hidden leaves
        _fillNodes(allTemplates, widget.hideEmptyNodes??false, widget.expandAll??false);
      });
    });

    if (widget.hideEmptyNodes??false) {
      _nodes.removeWhere((node) => node.children.isEmpty);
    }
    _treeViewController = TreeViewController(
      children: _nodes,
    );
  }

  void _fillNodes(List<List<Template>> allTemplates, bool hideEmptyNodes, bool expandAll) {
    final taskTemplates = allTemplates[0] as List<TaskTemplate>;
    final taskTemplateVariants = allTemplates[1] as List<TaskTemplateVariant>;
    
    _nodes = predefinedTaskGroups
        .map((group) =>
        createTaskGroupNode(
            group,
            findTaskTemplates(taskTemplates, group)
                .where((template) => (widget.onlyHidden??false)
                  ? true // filter all to filter non-hidden with hidden children
                  : (template.hidden??false)==false
                )
                .map((template) =>
                createTaskTemplateNode(
                    template,
                    group,
                    findTaskTemplateVariants(taskTemplateVariants, template)
                        .where((variant) => _filterSearchQuery(variant.title))
                        .where((variant) => (widget.onlyHidden??false)
                          ? (variant.hidden??false)==true
                          : (variant.hidden??false)==false
                        )
                        .map((variant) =>
                        createTaskTemplateVariantNode(
                            variant,
                            group,
                        ))
                        .toList(),
                        expandAll
                ))
                .where((templateNode) => (widget.onlyHidden??false)
                  ? (templateNode.children.isNotEmpty || ((templateNode.data as Template).hidden??false))
                  : true // bypass
                )
                .where((templateNode) => (_searchQuery != null)
                  ? (templateNode.children.isNotEmpty || _filterSearchQuery(templateNode.label))
                  : true // bypass
                )
                .toList(),
                expandAll
        ))
        .where((taskGroupNode) => (_searchQuery != null)
          ? (taskGroupNode.children.isNotEmpty || _filterSearchQuery(taskGroupNode.label))
          : true // bypass
        )
        .toList();
    
    if (hideEmptyNodes) {
      _nodes.removeWhere((taskGroupNode) => taskGroupNode.children.isEmpty);
    }
    _treeViewController = TreeViewController(
      children: _nodes,
      selectedKey: _selectedNodeKey,
    );
  }

  Node<TaskGroup> createTaskGroupNode(TaskGroup group,
      List<Node<TaskTemplate>> templates, bool expandAll) {
    return Node(
      key: group.getKey(),
      label: group.name,
      icon: group.iconData,
      iconColor: getSharpedColor(group.colorRGB),
      parent: true,
      data: group,
      children: templates,
      expanded: _forceExpandOrCollapseAll != null
          ? _forceExpandOrCollapseAll!
          : (expandAll || _containsSelectedNode(templates) || _containsExpandedChildren(templates)),

    );
  }

  @override
  void searchQueryUpdated(String? searchQuery) {
    if (_searchQuery == searchQuery) {
      return;
    }
    setState(() {
      _searchQuery = searchQuery;
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        _selectedNodeKey = null;
        _forceExpandOrCollapseAll = null;
        _fillNodes(_allTemplates, false, true);
      }
      else {
        _fillNodes(_allTemplates, false, false);
      }
    });
  }

  @override
  List<Widget>? getActions(BuildContext context) {
    final expandIcon = ToggleActionIcon(Icons.unfold_less, Icons.unfold_more, isAllExpanded(), widget.expandIconKey);

    return [
      IconButton(
          icon: const Icon(Icons.undo),
          onPressed: () {
            Object? selectedTemplate;
            showTemplateDialog(context, "Select a task", "Restore a removed predefined task.",
              selectedItem: (selected) {
                selectedTemplate = selected;
              },
              onlyHidden: true,
              hideEmptyNodes: true,
              expandAll: true,
                okPressed: () async {
                  if (selectedTemplate is TaskTemplate) {
                    // restore task
                    final taskTemplate = selectedTemplate as TaskTemplate;

                    if (_treeViewController.getNode(taskTemplate.getKey()) != null) {
                      debugPrint("Node ${taskTemplate.getKey()} still exists");
                      return;
                    }

                    TemplateRepository.undelete(taskTemplate).then((template) {
                      Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Task \'${template.title}\' restored.')));

                      final taskGroup = findPredefinedTaskGroupById(taskTemplate.taskGroupId);
                      setState(() {
                        _addTaskTemplate(template as TaskTemplate, taskGroup);
                      });
                    });
                  }
                  else if (selectedTemplate is TaskTemplateVariant) {
                    final taskTemplateVariant = selectedTemplate as TaskTemplateVariant;
                    // restore variant
                    TemplateRepository.findByIdJustDb(TemplateId.forTaskTemplate(taskTemplateVariant.taskTemplateId))
                    .then((foundParentInDb) {
                      if (foundParentInDb != null && foundParentInDb.hidden == true) {
                        // restore parent first
                        TemplateRepository.undelete(foundParentInDb).then((template) {
                          final taskGroup = findPredefinedTaskGroupById(foundParentInDb.taskGroupId);
                          setState(() {
                            _addTaskTemplate(template as TaskTemplate, taskGroup);
                          });

                          // now restore variant
                          TemplateRepository.undelete(taskTemplateVariant).then((template) {
                            Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    'Variant \'${template.title}\' and parent task restored.')));

                            final taskGroup = findPredefinedTaskGroupById(template.taskGroupId);
                            setState(() {
                              _addTaskTemplateVariant(taskTemplateVariant, taskGroup, foundParentInDb as TaskTemplate);
                            });
                          });
                        });
                      }
                      else {
                        // actually restore it
                        TemplateRepository.undelete(taskTemplateVariant).then((template) {
                          Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Variant \'${template.title}\' restored.')));

                          final taskGroup = findPredefinedTaskGroupById(template.taskGroupId);
                          setState(() {
                            _addTaskTemplateVariant(taskTemplateVariant, taskGroup, foundParentInDb as TaskTemplate);
                          });
                        });
                      }
                    });
                  }
                }, cancelPressed: () {
                  Navigator.pop(context);
                }
            );
          },
      ),
      IconButton(
        icon: expandIcon,
        onPressed: () {
          if (isAllExpanded()) {
            collapseAll();
            widget.expandIconKey.currentState?.refresh(false);
          }
          else {
            expandAll();
            widget.expandIconKey.currentState?.refresh(true);
          }
        },
      ),
    ];
  }

  @override
  void handleFABPressed(BuildContext context) {
    _onFABPressed();
  }

  Node<TaskTemplate> createTaskTemplateNode(TaskTemplate template,
      TaskGroup group,
      List<Node<dynamic>> templateVariants, bool expandAll) {
    debugPrint("${template.tId} is hidden ${template.hidden}");
    return Node(
      key: template.getKey(),
      label: template.title,
      icon: group.iconData,
      iconColor: getShadedColor(group.colorRGB, false),
      data: template,
      children: templateVariants,
      expanded: _forceExpandOrCollapseAll != null
          ? _forceExpandOrCollapseAll!
          : (expandAll || _containsSelectedNode(templateVariants)),
    );
  }

  Node<TaskTemplateVariant> createTaskTemplateVariantNode(
      TaskTemplateVariant variant, TaskGroup group) {
    return Node(
      key: variant.getKey(),
      label: variant.title,
      icon: group.iconData,
      iconColor: getShadedColor(group.colorRGB, true),
      data: variant,
    );
  }

  void _addTaskTemplate(TaskTemplate template, TaskGroup parent) {
    if (_treeViewController.getNode(template.getKey()) != null) {
      debugPrint("Node ${template.getKey()} still exists");
      return;
    }
    _allTemplates[0].add(template);
    setState(() {
      _treeViewController = _treeViewController.withAddNode(
          parent.getKey(),
          createTaskTemplateNode(template, parent, [], widget.expandAll??false,
          )
      );
      _updateSelection(template.getKey());
    });
  }  
  
  void _addTaskTemplateVariant(TaskTemplateVariant variant, TaskGroup taskGroup, TaskTemplate parent) {
    if (_treeViewController.getNode(variant.getKey()) != null) {
      debugPrint("Node ${variant.getKey()} still exists");
      return;
    }

    _allTemplates[1].add(variant);
    setState(() {
      _treeViewController = _treeViewController.withAddNode(
          parent.getKey(),
          createTaskTemplateVariantNode(variant, taskGroup)
      );
      _updateSelection(variant.getKey());
    });
  }

  void _updateTaskTemplate(TaskTemplate template, TaskGroup taskGroup) {
    _allTemplates[0].remove(template);
    _allTemplates[0].add(template);

    setState(() {
      final children = _treeViewController.getNode(template.getKey())?.children ?? [];
      _treeViewController = _treeViewController.withUpdateNode(
          template.getKey(),
          createTaskTemplateNode(template, taskGroup, children, widget.expandAll??false)
      );
    });
    widget._pagesHolder?.quickAddTaskEventPage?.getGlobalKey().currentState?.updateTemplate(template);
  }

  void _updateTaskTemplateVariant(TaskTemplateVariant template, TaskGroup taskGroup) {
    _allTemplates[1].remove(template);
    _allTemplates[1].add(template);

    setState(() {
      _treeViewController = _treeViewController.withUpdateNode(
          template.getKey(),
          createTaskTemplateVariantNode(template, taskGroup)
      );
    });
    widget._pagesHolder?.quickAddTaskEventPage?.getGlobalKey().currentState?.updateTemplate(template);
  }

  void _removeTemplate(Template template) {
    if (template.isVariant()) {
      _allTemplates[1].remove(template);
    }
    else {
      _allTemplates[0].remove(template);
    }
    setState(() {
      _treeViewController = _treeViewController.withDeleteNode(
          template.getKey(),
      );
    });
    widget._pagesHolder?.quickAddTaskEventPage?.getGlobalKey().currentState?.removeTemplate(template);
  }

  void _onFABPressed() {
    if (_treeViewController.selectedKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an item first')));
      return;
    }
    Object? selectedItem = _treeViewController.selectedNode?.data;
    bool hasChildren = _treeViewController.selectedNode?.children.isNotEmpty ?? false;
    TaskGroup? taskGroup;
    Template? template;
    late String message;
    Widget? createAction;
    Widget? changeAction;
    Widget? deleteAction;
    if (selectedItem is TaskGroup) {
      taskGroup = selectedItem;
      message = "Add a new task underneath '${taskGroup.name}'.";
      createAction = ElevatedButton(
        child: const Text('Add new task'),
        onPressed: () async {
          Navigator.pop(context);
          Template? newTemplate = await Navigator.push(
              context, MaterialPageRoute(builder: (context) {
            return TaskTemplateForm(
              taskGroup!,
              formTitle: "Add new task",
              createNew: true,
            );
          }));

          if (newTemplate != null) {
            TemplateRepository.save(newTemplate).then((newTemplate) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(
                      'New task with name \'${newTemplate.title}\' added')));
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
        message = "Change or remove the selected variant or clone it as a new one.";
        createAction = ElevatedButton(
          child: const Text('Add cloned variant'),
          onPressed: () async {
            Navigator.pop(context);
            Template? changedTemplate = await Navigator.push(
                context, MaterialPageRoute(builder: (context) {
              return TaskTemplateForm(
                taskGroup!,
                formTitle: "Add cloned variant",
                title: template!.title + " (cloned)",
                template: template,
                createNew: true,
              );
            }));

            if (changedTemplate != null) {
              TemplateRepository.save(changedTemplate)
                  .then((changedTemplate) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                        'Variant with name \'${changedTemplate.title}\' cloned')));
                final variant = changedTemplate as TaskTemplateVariant;
                debugPrint("base variant: ${variant.taskTemplateId}");
                TemplateRepository.getById(TemplateId.forTaskTemplate(variant.taskTemplateId)).then((foundTemplate) {
                  debugPrint("foundTemplate: $foundTemplate");
                  _addTaskTemplateVariant(variant, taskGroup!, foundTemplate as TaskTemplate);
                });
              });
            }
          },
        );
        changeAction = TextButton(
          child: const Icon(Icons.edit),
          onPressed: () async {
            Navigator.pop(context);
            Template? changedTemplate = await Navigator.push(
                context, MaterialPageRoute(builder: (context) {
              return TaskTemplateForm(
                taskGroup!,
                formTitle: "Change variant '${template?.title}'",
                template: template,
                createNew: false,
              );
            }));

            if (changedTemplate is Template) {
              TemplateRepository.save(changedTemplate)
                  .then((changedTemplate) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                        'Variant with name \'${changedTemplate.title}\' changed')));
                _updateTaskTemplateVariant(changedTemplate as TaskTemplateVariant, taskGroup!);
              });
            }
          },
        );
        deleteAction = _createRemoveTemplateAction(template, hasChildren);
      }
      else {
        message = "Change or remove the selected task or add a new variant underneath it.";
        createAction = ElevatedButton(
          child: const Text('Add new variant'),
          onPressed: () async {
            Navigator.pop(context);
            Template? newVariant = await Navigator.push(
                context, MaterialPageRoute(builder: (context) {
              return TaskTemplateForm(
                taskGroup!,
                formTitle: "Add new variant",
                template: template,
                title: template!.title + " (variant)",
                createNew: true,
              );
            }));

            if (newVariant != null) {
              TemplateRepository.save(newVariant)
                  .then((changedTemplate) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                        'Variant with name \'${changedTemplate.title}\' added')));
                _addTaskTemplateVariant(changedTemplate as TaskTemplateVariant, taskGroup!, template as TaskTemplate);
              });
            }
          },
        );
        changeAction = TextButton(
          child: const Icon(Icons.edit),
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

            if (changedTemplate is Template) {
              TemplateRepository.save(changedTemplate)
                  .then((changedTemplate) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                        'Task with name \'${changedTemplate.title}\' changed')));
                _updateTaskTemplate(changedTemplate as TaskTemplate, taskGroup!);
              });
            }
          },
        );
      }
      deleteAction = _createRemoveTemplateAction(template, hasChildren);
    }

    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          final buttonBarChildren = <Widget>[];
          final sheetChildren = <Widget>[
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(message),
            ),
          ];
          if (createAction != null) sheetChildren.add(createAction);
          if (changeAction != null) buttonBarChildren.add(changeAction);
          if (deleteAction != null) buttonBarChildren.add(deleteAction);
          sheetChildren.add(ButtonBar(

            alignment: MainAxisAlignment.center,
        //    buttonPadding: EdgeInsets.symmetric(horizontal: 0.0),
            children: buttonBarChildren,
          ));
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

  Widget _createRemoveTemplateAction(Template template, bool hasChildren) {
    final taskOrVariant = template.isVariant() ? "variant" : "task";
    var message = "";
    if (template.isPredefined()) {
      message = "This will remove the current $taskOrVariant by hiding it. You can restore it by clicking on the restore action icon.";
    }
    else {
      message = "This will remove the current $taskOrVariant. This cannot be underdone!";
    }
    return TextButton(
      child: const Icon(Icons.delete),
      onPressed: () {
        if (hasChildren) {
          ScaffoldMessenger.of(super.context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Remove underneath variants first!')));
          Navigator.pop(context); // dismiss bottom sheet
          return;
        }

        showConfirmationDialog(
          context,
          "Delete $taskOrVariant '${template.title}'",
          message,
          okPressed: () {
            Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow
            Navigator.pop(context); // dismiss bottom sheet

            TemplateRepository.delete(template).then((template) {

              ScaffoldMessenger.of(super.context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'The $taskOrVariant \'${template.title}\' has been deleted')));

              _removeTemplate(template);
            });
          },
          cancelPressed: () =>
              Navigator.pop(context), // dismiss dialog, should be moved in Dialogs.dart somehow
        );
      },
    );
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
      padding: widget.isModal ? EdgeInsets.fromLTRB(0, 8, 0, 0) : EdgeInsets.all(16.0),
      child: TreeView(
        controller: _treeViewController,
        allowParentSelect: true,
        supportParentDoubleTap: false,
        onExpansionChanged: (key, expanded) =>
            _expandNode(key, expanded),
        onNodeTap: (key) {
          debugPrint('Selected: $key');
          setState(() {
            _updateSelection(key);
          });
        },
        theme: _treeViewTheme,
      ),
    );
  }

  void _updateSelection(String key) {
    _selectedNodeKey = key;
    _forceExpandOrCollapseAll = null;
    _treeViewController =
        _treeViewController.copyWith(selectedKey: key);
    
    if (widget._selectedItem != null) {
      Object? data = _treeViewController.selectedNode?.data;
      if (data != null) {
        widget._selectedItem!(data);
      }
    }
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

  @override
  handleNotificationClickRouted(bool isAppLaunch, String payload) {
  }

  Iterable<TaskTemplate> findTaskTemplates(List<TaskTemplate> taskTemplates,
      TaskGroup group) {
    return taskTemplates.where((template) => template.taskGroupId == group.id);
  }

  Iterable<TaskTemplateVariant> findTaskTemplateVariants(List<TaskTemplateVariant> taskTemplateVariants,
      TaskTemplate taskTemplate) {
    return taskTemplateVariants.where((variant) => variant.taskTemplateId == taskTemplate.tId!.id);
  }

  bool _filterSearchQuery(String string) {
    return _searchQuery == null || _searchQuery!.isEmpty || string.toLowerCase().contains(_searchQuery!.toLowerCase());
  }

  bool _containsSelectedNode(List<Node<dynamic>> templateNodes) {
    return templateNodes.where((templateNode) => templateNode.key == _selectedNodeKey).isNotEmpty;
  }

  bool _containsExpandedChildren(List<Node<dynamic>> templateNodes) {
    return templateNodes.where((templateNode) => templateNode.expanded).isNotEmpty;
  }

  bool isAllExpanded() => _forceExpandOrCollapseAll == true;

  void expandAll() {
    setState(() {
      _forceExpandOrCollapseAll = true;
      _fillNodes(_allTemplates, true, true);
    });
  }

  void collapseAll() {
    setState(() {
      _forceExpandOrCollapseAll = false;
      _fillNodes(_allTemplates, true, false);
    });
  }

  bool isSearchingActive() => _searchQuery != null;
}



