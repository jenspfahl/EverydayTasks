import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';

import '../main.dart';

final PRIMARY_COLOR = Colors.green[50]!;
final BUTTON_COLOR = Colors.blue;
final ACCENT_COLOR = Colors.lime[800];

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
        darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: PRIMARY_COLOR,
         //   primarySwatch: BUTTON_COLOR,
            checkboxTheme: CheckboxThemeData(
              fillColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? BUTTON_COLOR : Colors.grey),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.white : Colors.grey),
              trackColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? BUTTON_COLOR : Colors.grey),
            ),

           // unselectedWidgetColor: BUTTON_COLOR,
         /*   switchTheme: SwitchThemeData(
              overlayColor: BUTTON_COLOR,
            ),*/
            buttonTheme: ButtonThemeData(
              colorScheme: ColorScheme.dark(
                background: BUTTON_COLOR,
              )
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              foregroundColor: Colors.white,
              backgroundColor: BUTTON_COLOR
            ),
            appBarTheme: AppBarTheme(
                color: PRIMARY_COLOR,
                foregroundColor: Colors.black
            )
          // accentColor: Colors.green,

        ),
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: PRIMARY_COLOR,
          primarySwatch: BUTTON_COLOR,

          appBarTheme: AppBarTheme(
            color: PRIMARY_COLOR,
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

