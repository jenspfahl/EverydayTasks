import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';

import '../main.dart';

class PersonalTaskLoggerApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: APP_NAME,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.green[50],
        primarySwatch: Colors.blue,

       // accentColor: Colors.green,

      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.orangeAccent,
        buttonColor: Colors.orange,
        accentColor: Colors.orangeAccent,
        /* dark theme settings */
      ),
      themeMode: ThemeMode.light,
      /* ThemeMode.system to follow system theme,
         ThemeMode.light for light theme,
         ThemeMode.dark for dark theme
      */
      home: PersonalTaskLoggerScaffold(),
    );
  }
}

