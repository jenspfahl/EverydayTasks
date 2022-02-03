
import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/TaskTemplate.dart';
import 'package:personaltasklogger/model/TaskTemplateVariant.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';

import '../utils.dart';

class TaskTemplateList extends StatefulWidget implements PageScaffold {
  Function(Object)? _selectedItem;

  TaskTemplateList();
  TaskTemplateList.withSelectionCallback(this._selectedItem);


  @override
  String getTitle() {
    return 'Tasks';
  }

  @override
  Icon getIcon() {
    return Icon(Icons.task_alt);
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
    showConfirmationDialog(context, "Manage templates", "Managing templates is not yet supported. Stay tuned until it comes...");
  }

  @override
  State<StatefulWidget> createState() {
    return _TaskTemplateListState(_selectedItem);
  }
}

class _TaskTemplateListState extends State<TaskTemplateList> {

  String? _selectedNode;
  List<Node> _nodes = [];
  late TreeViewController _treeViewController;
  Function(Object)? _selectedItem;

  _TaskTemplateListState(this._selectedItem);

  @override
  void initState() {


    _nodes = predefinedTaskGroups.map((group) => Node(
        key: group.runtimeType.toString() +":"+ group.id.toString(),
        label: group.name,
        icon: group.iconData,
        iconColor: getSharpedColor(group.colorRGB),
        parent: true,
        data: group,
        children: findTaskTemplates(group).map((template) => Node(
          key: template.tId.toString(),
          label: template.title,
          icon: group.iconData,
          iconColor: getShadedColor(group.colorRGB, false),
          data: template,
          children: findTaskTemplateVariants(template).map((variant) => Node(
            key: variant.tId.toString(),
            label: variant.title,
            icon: group.iconData,
            iconColor: getShadedColor(group.colorRGB, true),
            data: variant,
          )).toList()
        )).toList(),
      ),
    ).toList();
    
    
    _treeViewController = TreeViewController(
      children: _nodes,
      selectedKey: _selectedNode,
    );

    super.initState();
  }

  List<TaskTemplateVariant> findTaskTemplateVariants(TaskTemplate template) {
    final predefined = findPredefinedTaskTemplateVariantsByTaskTemplateId(template.tId!.id);
    //TODO overwrite existing ones
    return predefined;
  }

    List<TaskTemplate> findTaskTemplates(TaskGroup group) {
      final predefined = findPredefinedTaskTemplatesByTaskGroupId(group.id!);
      //TODO overwrite existing ones
      return predefined;
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
        colorScheme: Theme.of(context).colorScheme,
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
              if (_selectedItem != null) {
                Object? data = _treeViewController.selectedNode?.data;
                if (data != null) {
                  _selectedItem!(data);
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
  }



