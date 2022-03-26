
import 'package:flutter/material.dart';

abstract class PageScaffoldState<T extends StatefulWidget> extends State<T> {

  List<Widget>? getActions(BuildContext context);

  void handleFABPressed(BuildContext context);

  void searchQueryUpdated(String? searchQuery);

  handleNotificationClicked(String receiverKey, String payload);
}
