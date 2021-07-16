import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';

import 'PersonalTaskLoggerHome.dart';

class PersonalTaskLoggerApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Task Logger',
      theme: ThemeData(
        primaryColor: Colors.lime,
      ),
      home: PersonalTaskLoggerHome(),
    );
  }
}

