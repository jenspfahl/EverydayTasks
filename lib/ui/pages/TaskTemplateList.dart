
import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';

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
  @override
  Widget build(BuildContext context) {
    return Text("dummy templates");
  }

}


