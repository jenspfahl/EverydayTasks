
import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/pages/PageScaffoldState.dart';

abstract class PageScaffold<T extends PageScaffoldState> extends StatefulWidget {
  PageScaffold() : super(key: new GlobalKey<T>());
  GlobalKey<T> getGlobalKey() => key as GlobalKey<T>;

  String getRoutingKey();
  Widget getTitle();
  Icon getIcon();
  bool withSearchBar();

}
