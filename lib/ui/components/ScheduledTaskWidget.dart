import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/utils.dart';

import '../../model/ScheduledTask.dart';

class ScheduledTaskWidget extends StatefulWidget {
  final ScheduledTask scheduledTask;

  ScheduledTaskWidget(this.scheduledTask);
  
  @override
  ScheduledTaskWidgetState createState() => ScheduledTaskWidgetState();
}

class ScheduledTaskWidgetState extends State<ScheduledTaskWidget> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Text("mock te");
  }


}