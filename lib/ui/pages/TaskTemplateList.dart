
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskEventRepository.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskRepository.dart';
import 'package:personaltasklogger/db/repository/TemplateRepository.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/TaskTemplate.dart';
import 'package:personaltasklogger/model/TaskTemplateVariant.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/model/TemplateId.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';
import 'package:personaltasklogger/ui/forms/TaskTemplateForm.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';

import '../../db/repository/TaskGroupRepository.dart';
import '../components/ToggleActionIcon.dart';
import '../dialogs.dart';
import '../forms/TaskGroupForm.dart';
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
  final String? initialSelectedKey;
  
  TaskTemplateList(this._pagesHolder): _selectedItem = null, onlyHidden = null, hideEmptyNodes = null, expandAll = null, initialSelectedKey = null;
  TaskTemplateList.withSelectionCallback(
      this._selectedItem,
      {this.onlyHidden, this.hideEmptyNodes, this.expandAll, this.initialSelectedKey, Key? key})
      :  _pagesHolder = null, isModal = true, super(key: key);


  @override
  Widget getTitle() {
    return Text(translate('pages.tasks.title'));
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

    _loadTemplates(widget.initialSelectedKey);
  }

  void _loadTemplates(String? selectedNodeKey) {
    final taskTemplatesFuture = TemplateRepository.getAllTaskTemplates(widget.onlyHidden??false);
    final taskTemplateVariantsFuture = TemplateRepository.getAllTaskTemplateVariants(widget.onlyHidden??false);
    
    _nodes = TaskGroupRepository.getAllCached(inclHidden: widget.onlyHidden??false)
        .map((group) => _createTaskGroupNode(group, [], widget.expandAll??false))
        .toList();
    
    Future.wait([taskTemplatesFuture, taskTemplateVariantsFuture]).then((allTemplates) {
    
      setState(() {
        _allTemplates = allTemplates;
        _selectedNodeKey = selectedNodeKey; // before fillNodes to expand selection
        // filter only hidden but non-hidden if have hidden leaves
        _fillNodes(allTemplates, widget.hideEmptyNodes??false, widget.expandAll??false);
    
        if (_selectedNodeKey != null) {
          _updateSelection(_selectedNodeKey!);
        }
      });
    });
    
    if (widget.hideEmptyNodes??false) {
      _nodes.removeWhere((node) => node.children.isEmpty && (node.data is TaskGroup && (node.data as TaskGroup).hidden != true));
    }
    _treeViewController = TreeViewController(
      children: _nodes,
    );
  }
  
  @override
  reload() {
    _loadTemplates(widget.initialSelectedKey);
  }

  void _fillNodes(List<List<Template>> allTemplates, bool hideEmptyNodes, bool expandAll) {
    final taskTemplates = allTemplates[0] as List<TaskTemplate>;
    final taskTemplateVariants = allTemplates[1] as List<TaskTemplateVariant>;
    
    _nodes = TaskGroupRepository.getAllCached(inclHidden: widget.onlyHidden??false)
        .map((group) =>
        _createTaskGroupNode(
            group,
            findTaskTemplates(taskTemplates, group)
                .where((template) => (widget.onlyHidden??false)
                  ? true // filter all to filter non-hidden with hidden children
                  : (template.hidden??false)==false
                )
                .map((template) =>
                _createTaskTemplateNode(
                    template,
                    group,
                    findTaskTemplateVariants(taskTemplateVariants, template)
                        .where((variant) => _filterSearchQuery(variant.translatedTitle))
                        .where((variant) => (widget.onlyHidden??false)
                          ? (variant.hidden??false)==true
                          : (variant.hidden??false)==false
                        )
                        .map((variant) =>
                        _createTaskTemplateVariantNode(
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
      _nodes.removeWhere((taskGroupNode) => taskGroupNode.children.isEmpty && (taskGroupNode.data as TaskGroup).hidden != true);

    }
    _treeViewController = TreeViewController(
      children: _nodes,
      selectedKey: _selectedNodeKey,
    );
  }

  Node<TaskGroup> _createTaskGroupNode(TaskGroup group,
      List<Node<TaskTemplate>> templates, bool expandAll) {
    return Node(
      key: group.getKey(),
      label: kReleaseMode ? group.translatedName : '${group.translatedName} (id=${group.id})',
      icon: group.iconData,
      iconColor: group.foregroundColor(context),
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
            Object? selectedObject;
            showTemplateDialog(context,
                translate('pages.tasks.menu.restore_a_task.title'),
                translate('pages.tasks.menu.restore_a_task.description'),
              selectedItem: (selected) {
                selectedObject = selected;
              },
              onlyHidden: true,
              hideEmptyNodes: true,
              expandAll: true,
                okPressed: () async {
                  if (selectedObject is TaskGroup) {
                    final taskGroup = selectedObject as TaskGroup;
                    TaskGroupRepository.undelete(taskGroup).then((restoredTaskGroup) {
                      Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow

                      toastInfo(context, translate('pages.tasks.menu.restore_a_task.success_group',
                          args: {"name" : restoredTaskGroup.translatedName}));

                      setState(() {
                        _updateTaskGroup(restoredTaskGroup);
                      });
                    });
                  }
                  else if (selectedObject is TaskTemplate) {
                    // restore task
                    final taskTemplate = selectedObject as TaskTemplate;

                    if (_treeViewController.getNode(taskTemplate.getKey()) != null) {
                      debugPrint("Node ${taskTemplate.getKey()} still exists");
                      return;
                    }

                    TemplateRepository.undelete(taskTemplate).then((template) {
                      Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow

                      toastInfo(context, translate('pages.tasks.menu.restore_a_task.success_task',
                          args: {"title" : template.translatedTitle}));

                      final taskGroup = TaskGroupRepository.findByIdFromCache(taskTemplate.taskGroupId);
                      setState(() {
                        _updateTaskGroup(taskGroup);
                        _addTaskTemplate(template as TaskTemplate, taskGroup);
                      });
                    });
                  }
                  else if (selectedObject is TaskTemplateVariant) {
                    final taskTemplateVariant = selectedObject as TaskTemplateVariant;
                    // restore variant
                    TemplateRepository.findByIdJustDb(TemplateId.forTaskTemplate(taskTemplateVariant.taskTemplateId))
                    .then((foundParentInDb) {
                      if (foundParentInDb != null && foundParentInDb.hidden == true) {
                        // restore parent first
                        TemplateRepository.undelete(foundParentInDb).then((template) {
                          final taskGroup = TaskGroupRepository.findByIdFromCache(foundParentInDb.taskGroupId);
                          setState(() {
                            _addTaskTemplate(template as TaskTemplate, taskGroup);
                          });

                          // now restore variant
                          TemplateRepository.undelete(taskTemplateVariant).then((template) {
                            Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow

                            toastInfo(context, translate('pages.tasks.menu.restore_a_task.success_variant_parent_task',
                                args: {"title" : template.translatedTitle}));

                            final taskGroup = TaskGroupRepository.findByIdFromCache(template.taskGroupId);
                            setState(() {
                              _updateTaskGroup(taskGroup);
                              _addTaskTemplateVariant(taskTemplateVariant, taskGroup, foundParentInDb as TaskTemplate);
                            });
                          });
                        });
                      }
                      else {
                        // actually restore it
                        TemplateRepository.undelete(taskTemplateVariant).then((template) {
                          Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow

                          toastInfo(context, translate('pages.tasks.menu.restore_a_task.success_variant',
                              args: {"title" : template.translatedTitle}));

                          if (foundParentInDb is TaskTemplate) {
                            final taskGroup = TaskGroupRepository.findByIdFromCache(
                                template.taskGroupId);
                            setState(() {
                              _addTaskTemplateVariant(
                                  taskTemplateVariant, taskGroup,
                                  foundParentInDb);
                            });
                          }
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
          updateExpanded(isAllExpanded());
        },
      ),
    ];
  }

  void updateExpanded(bool isAllExpanded) {
    if (isAllExpanded) {
      _collapseAll();
      widget.expandIconKey.currentState?.refresh(false);
    }
    else {
      _expandAll();
      widget.expandIconKey.currentState?.refresh(true);
    }
  }

  @override
  void handleFABPressed(BuildContext context) {
    _onFABPressed();
  }

  Node<TaskTemplate> _createTaskTemplateNode(TaskTemplate template,
      TaskGroup group,
      List<Node<dynamic>> templateVariants, bool expandAll) {
    debugPrint("${template.tId} is hidden ${template.hidden}");
    return Node(
      key: template.getKey(),
      label: template.translatedTitle,
      icon: group.iconData,
      iconColor: group.softColor(context),
      data: template,
      children: templateVariants,
      expanded: _forceExpandOrCollapseAll != null
          ? _forceExpandOrCollapseAll!
          : (expandAll || _containsSelectedNode(templateVariants)),
    );
  }

  Node<TaskTemplateVariant> _createTaskTemplateVariantNode(
      TaskTemplateVariant variant, TaskGroup group) {
    return Node(
      key: variant.getKey(),
      label: variant.translatedTitle,
      icon: group.iconData,
      iconColor: group.backgroundColor(context),
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
          _createTaskTemplateNode(template, parent, [], widget.expandAll??false,
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
          _createTaskTemplateVariantNode(variant, taskGroup)
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
          _createTaskTemplateNode(template, taskGroup, children, widget.expandAll??false)
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
          _createTaskTemplateVariantNode(template, taskGroup)
      );
    });
    widget._pagesHolder?.quickAddTaskEventPage?.getGlobalKey().currentState?.updateTemplate(template);
  }

  void _updateTaskGroup(TaskGroup taskGroup) {
    setState(() {
      widget.expandIconKey.currentState?.refresh(false); // expand all is false
      _loadTemplates(taskGroup.getKey());
    });
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
    Node? selectedNode = _getNode(_treeViewController);
    Object? selectedItem = selectedNode?.data;
    bool hasChildren = selectedNode?.children.isNotEmpty ?? false;
    TaskGroup? taskGroup;
    Template? template;
    late String message;
    Widget? createAction;
    Widget? changeAction;
    Widget? deleteAction;
    if (selectedItem == null) {
      message = translate('pages.tasks.action.description_nothing_selected');
      createAction = ElevatedButton(
        child: Text(translate('pages.tasks.action.create_task_group.title')),
        onPressed: () async {
          Navigator.pop(context);
          TaskGroup? createdTaskGroup = await Navigator.push(
              context, MaterialPageRoute(builder: (context) {
            return TaskGroupForm(
              null,
              formTitle: translate('pages.tasks.action.create_task_group.title'),
            );
          }));

          if (createdTaskGroup != null) {
            TaskGroupRepository.save(createdTaskGroup)
                .then((savedTaskGroup) {

              toastInfo(context, translate('pages.tasks.action.create_task_group.success',
                  args: {"name": savedTaskGroup.translatedName}));

              _updateTaskGroup(savedTaskGroup);
            });
          }
        },
      );
    }
    else if (selectedItem is TaskGroup) {
      taskGroup = selectedItem;
      message = translate('pages.tasks.action.description_group',
          args: {"groupName" : taskGroup.translatedName});
      createAction = ElevatedButton(
        child: Text(translate('pages.tasks.action.add_task.title')),
        onPressed: () async {
          Navigator.pop(context);
          Template? newTemplate = await Navigator.push(
              context, MaterialPageRoute(builder: (context) {
            return TaskTemplateForm(
              taskGroup!,
              formTitle: translate('pages.tasks.action.add_task.title'),
              createNew: true,
            );
          }));

          if (newTemplate != null) {
            TemplateRepository.save(newTemplate).then((newTemplate) {
              toastInfo(context, translate('pages.tasks.action.add_task.success',
                  args: {"title" : newTemplate.translatedTitle}));
              _addTaskTemplate(newTemplate as TaskTemplate, taskGroup!);
            });
          }
        },
      );
      changeAction = TextButton(
        child: const Icon(Icons.edit),
        onPressed: () async {
          Navigator.pop(context);
          TaskGroup? changedTaskGroup = await Navigator.push(
              context, MaterialPageRoute(builder: (context) {
            return TaskGroupForm(
              taskGroup,
              formTitle: translate('pages.tasks.action.change_task_group.title'),
            );
          }));

          if (changedTaskGroup != null) {
            TaskGroupRepository.save(changedTaskGroup)
                .then((changedTaskGroup) {

              toastInfo(context, translate('pages.tasks.action.change_task_group.success',
                  args: {"name": changedTaskGroup.translatedName}));

              _updateTaskGroup(changedTaskGroup);
            });
          }
        },
      );
      deleteAction = _createRemoveTaskGroupAction(taskGroup, hasChildren);
    }
    else if (selectedItem is Template) {
      template = selectedItem;
      taskGroup = TaskGroupRepository.findByIdFromCache(template.taskGroupId);
      if (template.isVariant()) {
        message = translate('pages.tasks.action.description_variant',
            args: {"title" : template.translatedTitle});
        createAction = ElevatedButton(
          child: Text(translate('pages.tasks.action.clone_variant.title')),
          onPressed: () async {
            Navigator.pop(context);
            Template? changedTemplate = await Navigator.push(
                context, MaterialPageRoute(builder: (context) {
              return TaskTemplateForm(
                taskGroup!,
                formTitle: translate('pages.tasks.action.clone_variant.title'),
                title: template!.translatedTitle + " (${translate('pages.tasks.action.clone_variant.cloned_postfix')})",
                template: template,
                createNew: true,
              );
            }));

            if (changedTemplate != null) {
              TemplateRepository.save(changedTemplate)
                  .then((changedTemplate) {

                toastInfo(context, translate('pages.tasks.action.clone_variant.success',
                  args: {"title": changedTemplate.translatedTitle}));

                final variant = changedTemplate as TaskTemplateVariant;
                debugPrint("base variant: ${variant.taskTemplateId}");
                TemplateRepository.findById(TemplateId.forTaskTemplate(variant.taskTemplateId)).then((foundTemplate) {
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
                formTitle: translate('pages.tasks.action.change_variant.title'),
                template: template,
                createNew: false,
              );
            }));

            if (changedTemplate is Template) {
              TemplateRepository.save(changedTemplate)
                  .then((changedTemplate) {

                toastInfo(context, translate('pages.tasks.action.change_variant.success',
                  args: {"title": changedTemplate.translatedTitle}));

                _updateTaskTemplateVariant(changedTemplate as TaskTemplateVariant, taskGroup!);
              });
            }
          },
        );
        deleteAction = _createRemoveTemplateAction(template, hasChildren);
      }
      else {
        message = translate('pages.tasks.action.description_task',
            args: {"title" : template.translatedTitle});
        createAction = ElevatedButton(
          child: Text(translate('pages.tasks.action.add_variant.title')),
          onPressed: () async {
            Navigator.pop(context);
            Template? newVariant = await Navigator.push(
                context, MaterialPageRoute(builder: (context) {
              return TaskTemplateForm(
                taskGroup!,
                formTitle: translate('pages.tasks.action.add_variant.title'),
                template: template,
                title: template!.translatedTitle + " (${translate('pages.tasks.action.add_variant.variant_postfix')})",
                createNew: true,
              );
            }));

            if (newVariant != null) {
              TemplateRepository.save(newVariant)
                  .then((changedTemplate) {

                toastInfo(context, translate('pages.tasks.action.add_variant.success',
                  args: {"title": changedTemplate.translatedTitle}));

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
                formTitle: translate('pages.tasks.action.change_task.title'),
                template: template,
                createNew: false,
              );
            }));

            if (changedTemplate is Template) {
              TemplateRepository.save(changedTemplate)
                  .then((changedTemplate) {

                toastInfo(context, translate('pages.tasks.action.add_task.success',
                  args: {"title": changedTemplate.translatedTitle}));

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
    var message = "";
    if (template.isPredefined()) {
      message = translate(template.isVariant()
          ? 'pages.tasks.action.remove_variant.message_predefined'
          : 'pages.tasks.action.remove_task.message_predefined',
          args: {"title": template.translatedTitle});
    }
    else {
      message = translate(template.isVariant()
          ? 'pages.tasks.action.remove_variant.message_custom'
          : 'pages.tasks.action.remove_task.message_custom',
          args: {"title": template.translatedTitle});
    }
    return TextButton(
      child: const Icon(Icons.delete),
      onPressed: () {
        if (hasChildren) {
          toastError(context, translate('pages.tasks.action.remove_task.error_has_children'));
          Navigator.pop(context); // dismiss bottom sheet
          return;
        }

        showConfirmationDialog(
          context,
          translate(template.isVariant()
              ? 'pages.tasks.action.remove_variant.title'
              : 'pages.tasks.action.remove_task.title'),
          message,
          icon: const Icon(Icons.warning_amber_outlined),
          okPressed: () {
            Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow
            Navigator.pop(context); // dismiss bottom sheet

            TemplateRepository.delete(template).then((template) {

              toastInfo(context, translate(template.isVariant()
                  ? 'pages.tasks.action.remove_variant.success'
                  : 'pages.tasks.action.remove_task.success',
                  args: {"title": template.translatedTitle}));

              _removeTemplate(template);
            });
          },
          cancelPressed: () =>
              Navigator.pop(context), // dismiss dialog, should be moved in Dialogs.dart somehow
        );
      },
    );
  }

  Widget _createRemoveTaskGroupAction(TaskGroup taskGroup, bool hasChildren) {
    var message = "";
    if (taskGroup.isPredefined()) {
      message = translate('pages.tasks.action.remove_task_group.message_predefined',
          args: {"name": taskGroup.translatedName});
    }
    else {
      message = translate('pages.tasks.action.remove_task_group.message_custom',
          args: {"name": taskGroup.translatedName});
    }
    return TextButton(
      child: const Icon(Icons.delete),
      onPressed: () async {
        if (hasChildren) {
          toastError(context, translate('pages.tasks.action.remove_task_group.error_has_children')); //TODO allow hiding with children
          Navigator.pop(context); // dismiss bottom sheet
          return;
        }
        final usedTaskGroupCount = await ScheduledTaskRepository.countByTaskGroupId(taskGroup.id!);
        if (usedTaskGroupCount != null && usedTaskGroupCount > 0) {
          toastError(context, translate('pages.tasks.action.remove_task_group.error_has_schedules'));
          Navigator.pop(context); // dismiss bottom sheet
          return;
        }

        showConfirmationDialog(
          context,
          translate('pages.tasks.action.remove_task_group.title'),
          message,
          icon: const Icon(Icons.warning_amber_outlined),
          okPressed: () {
            Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow
            Navigator.pop(context); // dismiss bottom sheet

            TaskGroupRepository.delete(taskGroup).then((taskGroup) {

              toastInfo(context, translate('pages.tasks.action.remove_task_group.success',
                  args: {"name": taskGroup.translatedName}));

              _updateTaskGroup(taskGroup);
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
          type: ExpanderType.plusMinus, //TODO wrong direction
          modifier: ExpanderModifier.none,
          position: ExpanderPosition.end,
          color: isDarkMode(context) ? Colors.white60 : Colors.black54,
          size: 14),
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
        supportParentDoubleTap: true, //TODO check it out
        onExpansionChanged: (key, expanded) =>
            _expandNode(key, expanded),
        onNodeTap: (key) {
          debugPrint('Selected: $key $_selectedNodeKey');
          setState(() {
            if (_selectedNodeKey == key) {
              _updateSelection(null);
            }
            else {
              _updateSelection(key);
            }
          });
        },
        theme: _treeViewTheme,
      ),
    );
  }

  void _updateSelection(String? key) {
    _selectedNodeKey = key;
    _forceExpandOrCollapseAll = null;
    _treeViewController =
       TreeViewController(
        children: _treeViewController.children,
        selectedKey: _selectedNodeKey,
      );
    
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
  handleNotificationClickRouted(bool isAppLaunch, String payload, String? actionId) {
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

  void _expandAll() {
    setState(() {
      _forceExpandOrCollapseAll = true;
      _fillNodes(_allTemplates, widget.hideEmptyNodes??false, true);
    });
  }

  void _collapseAll() {
    setState(() {
      _forceExpandOrCollapseAll = false;
      _fillNodes(_allTemplates, widget.hideEmptyNodes??false, false);
    });
  }

  bool isSearchingActive() => _searchQuery != null;

  Node? _getNode(TreeViewController treeViewController) {
    final selectedKey = _treeViewController.selectedKey;
    if (selectedKey != null) {
      return selectedKey.isEmpty ? null : treeViewController.getNode(
          selectedKey);
    }
    return null;
  }
}



