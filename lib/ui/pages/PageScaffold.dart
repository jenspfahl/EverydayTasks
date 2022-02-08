
import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';

abstract class PageScaffold extends StatefulWidget {
  Widget getTitle();
  Icon getIcon();
  List<Widget>? getActions(BuildContext context);

  bool withSearchBar();

  void handleFABPressed(BuildContext context);

  void searchQueryUpdated(String? searchQuery);
}
