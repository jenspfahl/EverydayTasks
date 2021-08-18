
import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/TaskTemplate.dart';
import 'package:personaltasklogger/model/TaskTemplateVariant.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';

import '../utils.dart';

class TaskTemplateList extends StatefulWidget implements PageScaffold {

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
    showConfirmationDialog(context, "test", "dummy template");
  }

  @override
  State<StatefulWidget> createState() {
    return _TaskTemplateListState();
  }
}

class _TaskTemplateListState extends State<TaskTemplateList> {

  String? _selectedNode;
  List<Node> _nodes = [];
  late TreeViewController _treeViewController;
  bool docsOpen = true;
  bool deepExpanded = true;

  @override
  void initState() {


    _nodes = predefinedTaskGroups.map((group) => Node(
        key: group.id.toString(),
        label: group.name,
        icon: group.iconData,
        iconColor: getSharpedColor(group.colorRGB),
        //selectedIconColor: getColorWithOpacity(group.colorRGB, 1),

        data: group,
        children: findTaskTemplatesByTaskGroupId(group.id!).map((template) => Node(
          key: template.id.toString(),
          label: template.title,
          data: template,
          children: findTaskTemplateVariantsByTaskTemplateId(template.id!).map((variant) => Node(
            key: variant.id.toString(),
            label: variant.title,
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
      iconTheme: IconThemeData(
        size: 18,
        color: Colors.grey.shade800,
      ),
      colorScheme: Theme.of(context).colorScheme,
    );

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: TreeView(
        controller: _treeViewController,
        allowParentSelect: true,
        supportParentDoubleTap: true,
        onNodeTap: (key) {
          debugPrint('Selected: $key');
          setState(() {
            _selectedNode = key;
            _treeViewController =
                _treeViewController.copyWith(selectedKey: key);
          });
        },
        theme: _treeViewTheme,
      ),
    );
  }

}


