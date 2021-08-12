
import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:personaltasklogger/ui/pages/PageScaffold.dart';

class ScheduledTaskList extends StatefulWidget implements PageScaffold {

  @override
  String getTitle() {
    return 'Schedules';
  }

  @override
  Icon getIcon() {
    return Icon(Icons.next_plan_outlined);
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
    showConfirmationDialog(context, "test", "dummy scheduled task");
  }

  @override
  State<StatefulWidget> createState() {
    return _ScheduledTaskListState();
  }
}

class _ScheduledTaskListState extends State<ScheduledTaskList> {
  @override
  Widget build(BuildContext context) {
    return Text("dummy schedules");
  }

}


