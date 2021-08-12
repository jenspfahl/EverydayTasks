
import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';

class AddTaskEventPage extends StatefulWidget implements PageScaffold {

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
    showConfirmationDialog(context, "test", "dummy add task event");
  }

  @override
  State<StatefulWidget> createState() {
    return _AddTaskEventPageState();
  }
}

class _AddTaskEventPageState extends State<AddTaskEventPage> {
  @override
  Widget build(BuildContext context) {
    return Text("dummy add grid");
  }

}


