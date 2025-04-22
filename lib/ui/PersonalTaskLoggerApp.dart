import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/service/PreferenceService.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerScaffold.dart';

import '../main.dart';

final PRIMARY_COLOR = Colors.green[50]!;
final BUTTON_COLOR = Colors.blue;
final ACCENT_COLOR = Colors.lime[800];


class PersonalTaskLoggerApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    if (mediaQueryData.disableAnimations) {
      timeDilation = 0.0001;
    }


    var localizationDelegate = LocalizedApp.of(context).delegate;
    return AppBuilder(builder: (context) {
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
              useMaterial3: false,
              brightness: Brightness.dark,
              primaryColor: PRIMARY_COLOR,
              checkboxTheme: CheckboxThemeData(
                fillColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? BUTTON_COLOR : Colors.grey),
              ),
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.white : Colors.grey),
                trackColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? BUTTON_COLOR : Colors.grey),
              ),
             radioTheme: RadioThemeData(
               overlayColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.white : Colors.grey),
               fillColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? BUTTON_COLOR : Colors.grey),
             ),
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
            useMaterial3: false,
            brightness: Brightness.light,
            primaryColor: PRIMARY_COLOR,
            primarySwatch: BUTTON_COLOR,

            appBarTheme: AppBarTheme(
              color: PRIMARY_COLOR,
              foregroundColor: Colors.black
            )
           // accentColor: Colors.green,

          ),
          themeMode: PreferenceService().darkTheme ? ThemeMode.dark : ThemeMode.light,
          home: PersonalTaskLoggerScaffold(),
        ),
      );
    }
  );
  }

}

// from https://hillel.dev/2018/08/15/flutter-how-to-rebuild-the-entire-app-to-change-the-theme-or-locale/
class AppBuilder extends StatefulWidget {
  final Function(BuildContext) builder;

  const AppBuilder(
      {Key? key, required this.builder})
      : super(key: key);

  @override
  AppBuilderState createState() => new AppBuilderState();

  static AppBuilderState? of(BuildContext context) {
    return context.findAncestorStateOfType<AppBuilderState>();
  }
}

class AppBuilderState extends State<AppBuilder> {

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  void rebuild() {
    setState(() {});
  }


}

