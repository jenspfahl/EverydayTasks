import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';

import '../main.dart';

class PersonalTaskLoggerApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    var localizationDelegate = LocalizedApp.of(context).delegate;

    return LocalizationProvider(
      state: LocalizationProvider.of(context).state,
      child: MaterialApp(
        title: APP_NAME,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          localizationDelegate
        ],
        supportedLocales: localizationDelegate.supportedLocales,
        locale: localizationDelegate.currentLocale,
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.green[50],
          primarySwatch: Colors.blue,

          appBarTheme: AppBarTheme(
            color: Colors.green[50],
            foregroundColor: Colors.black
          )
         // accentColor: Colors.green,

        ),
        themeMode: ThemeMode.light,
        home: PersonalTaskLoggerScaffold(),
      ),
    );
  }
}

