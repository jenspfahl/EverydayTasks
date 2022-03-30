
import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/pages/PageScaffoldState.dart';

abstract class PageScaffold<T extends PageScaffoldState> extends StatefulWidget {
  PageScaffold({Key? key}) : super(key: key == null ? new GlobalKey<T>() : key);
  GlobalKey<T> getGlobalKey() => key as GlobalKey<T>;

  String getRoutingKey();
  Widget getTitle();
  Icon getIcon();
  bool withSearchBar();

}
