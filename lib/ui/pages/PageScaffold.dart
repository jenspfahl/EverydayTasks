
import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';

abstract class PageScaffold extends StatefulWidget {
  String getTitle();
  Icon getIcon();
  List<Widget>? getActions(BuildContext context);

  void handleFABPressed(BuildContext context);
}
