import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/db/repository/TaskGroupRepository.dart';
import 'package:personaltasklogger/service/LocalNotificationService.dart';
import 'package:personaltasklogger/service/PreferenceService.dart';
import 'package:personaltasklogger/util/dates.dart';

import 'ui/PersonalTaskLoggerApp.dart';

const String APP_NAME = "Everyday Tasks";
const SUPPORTED_LANGUAGES = ['en', 'de', 'fr', 'ru'];


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService().init();
  await TaskGroupRepository.loadAll(true); // load caches
  await PreferenceService().initWhenAtDayTimes();
  await fillDayNumberCache();


  var delegate = await LocalizationDelegate.create(
    preferences: PreferenceService(),
    fallbackLocale: 'en',
    supportedLocales: SUPPORTED_LANGUAGES);

  runApp(LocalizedApp(delegate, PersonalTaskLoggerApp()));
}


