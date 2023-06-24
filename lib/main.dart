import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/db/repository/TaskGroupRepository.dart';
import 'package:personaltasklogger/service/LocalNotificationService.dart';
import 'package:personaltasklogger/service/PreferenceService.dart';

import 'ui/PersonalTaskLoggerApp.dart';

const String APP_NAME = "Everyday Tasks";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService().init();
  await TaskGroupRepository.loadAll(true); // load caches

  var delegate = await LocalizationDelegate.create(
    preferences: PreferenceService(),
    fallbackLocale: 'en',
    supportedLocales: ['en', 'de']);

  runApp(LocalizedApp(delegate, PersonalTaskLoggerApp()));
}


