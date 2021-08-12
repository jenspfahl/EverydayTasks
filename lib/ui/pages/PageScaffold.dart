
import 'package:flutter/material.dart';

abstract class PageScaffold extends StatefulWidget {
  String getTitle();
  Icon getIcon();
  List<Widget>? getActions();

  void handleFABPressed(BuildContext context);
  Function() handleActionPressed(int index);
}
