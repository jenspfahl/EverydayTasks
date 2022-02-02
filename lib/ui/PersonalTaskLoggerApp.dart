import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/ScheduledTask.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';

import 'pages/TaskEventList.dart';

class PersonalTaskLoggerApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Task Logger',
      theme: ThemeData(
        primaryColor: Colors.lime,
      ),
      home: PersonalTaskLoggerScaffold(),
    );
  }
}

