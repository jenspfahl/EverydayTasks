import 'package:flutter/material.dart';
import 'package:personaltasklogger/service/LocalNotificationService.dart';

import 'ui/PersonalTaskLoggerApp.dart';

const String APP_NAME = "Everyday Tasks";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService().init();

  runApp(PersonalTaskLoggerApp());
}


