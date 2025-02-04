import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:personaltasklogger/model/When.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../service/PreferenceService.dart';
import '../../util/dates.dart';
import '../../util/i18n.dart';
import '../PersonalTaskLoggerApp.dart';
import '../dialogs.dart';
import 'DayTimeSettingsScreen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final PreferenceService _preferenceService = PreferenceService();

  int _dateFormatSelection = 1;
  int _languageSelection = 0;
  bool _showTimeOfDayAsText = false;
  bool _darkTheme = false;
  bool _showWeekdays = false;
  bool _showActionNotifications = false;
  int _showActionNotificationDurationSelection = 1;
  bool _executeSchedulesOnTaskEvent = true;
  bool _showBadgeForDueSchedules = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(translate('navigation.menus.settings'))),
      body: FutureBuilder(
        future: _loadAllPrefs(),
        builder: (context, AsyncSnapshot snapshot) => _buildSettingsList(),
      ),
    );
  }

  Widget _buildSettingsList()  {

    final exampleDate = DateTime(2022, DateTime.december, 31);
    var localizationDelegate = LocalizedApp.of(context).delegate;

    return SettingsList(
      sections: [
        SettingsSection(
          title: Text(translate('pages.settings.common.title'), style: TextStyle(color: ACCENT_COLOR)),
          tiles: [
            SettingsTile(
              title: Text(translate('pages.settings.common.language.title')),
              description: Text(_getLanguageSelectionAsString(_preferenceService.languageSelection, localizationDelegate)),
              onPressed: (context) {
                var languageSelection = _languageSelection;
                showChoiceDialog(context, translate('pages.settings.common.language.dialog.title'),
                    [
                      _getLanguageSelectionAsString(0, localizationDelegate),
                      _getLanguageSelectionAsString(1, localizationDelegate),
                      _getLanguageSelectionAsString(2, localizationDelegate),
                      _getLanguageSelectionAsString(3, localizationDelegate),
                      _getLanguageSelectionAsString(4, localizationDelegate),
                      _getLanguageSelectionAsString(5, localizationDelegate),
                      _getLanguageSelectionAsString(6, localizationDelegate),
                    ],
                    initialSelected: languageSelection,
                    okPressed: () {
                      Navigator.of(context).pop("ok");
                      debugPrint("store language $languageSelection");

                      _preferenceService.setInt(PreferenceService.PREF_LANGUAGE_SELECTION, languageSelection)
                      .then((_) {
                        setState(() {
                          _languageSelection = languageSelection;
                          _preferenceService.languageSelection = languageSelection;
                          _preferenceService.getPreferredLocale().then((locale) {
                            Locale newLocale;
                            if (locale == null) {
                              newLocale = systemLocale(context);
                            }
                            else {
                              newLocale = locale;
                            }
                            debugPrint("change locale to $newLocale");
                            localizationDelegate.changeLocale(newLocale);
                          });
                        });
                      });
                    },
                    cancelPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _loadAllPrefs();
                      });
                    },
                    selectionChanged: (selection) {
                      languageSelection = selection;
                      debugPrint("language changed to $languageSelection");
                    }
                ).then((value) {
                  debugPrint("value = $value");

                  if (value == null) {
                    // dismiss
                    setState(() {
                      debugPrint("language choice dismissed");
                      _loadAllPrefs();
                    });
                  }
                });
              },
            ),
            SettingsTile.switchTile(
              title: Text(translate('pages.settings.common.theme.title')),
              initialValue: _darkTheme,
              onToggle: (bool value) {
                _preferenceService.darkTheme = value;
                _preferenceService.setBool(PreferenceService.PREF_DARK_THEME, value);
                setState(() {
                  _darkTheme = value;
                  AppBuilder.of(context)?.rebuild();
                });
              },
            ),
          ],
        ),
        SettingsSection(
          title: Text(translate('pages.settings.date_n_time.title'), style: TextStyle(color: ACCENT_COLOR)),
          tiles: [
            SettingsTile(
              title: Text(translate('pages.settings.date_n_time.used_date_format.title')),
              description: Text(
                  translate(
                      'pages.settings.date_n_time.used_date_format.description',
                      args: {'example_date' : getDateFormat(context, _dateFormatSelection, false, false).format(exampleDate),
                      })),
              onPressed: (context) {
                final locale = currentLocale(context).toString();
                initializeDateFormatting(locale);
                final yMd = DateFormat.yMd(locale);
                final yMMMd = DateFormat.yMMMd(locale);
                final yMMMMd = DateFormat.yMMMMd(locale);
                final iso = DateFormat('yyyy-MM-dd');

                showChoiceDialog(context, translate('pages.settings.date_n_time.used_date_format.dialog.title'),
                    [
                      yMd.format(exampleDate),
                      yMMMd.format(exampleDate),
                      yMMMMd.format(exampleDate),
                      iso.format(exampleDate),
                    ],
                    initialSelected: _dateFormatSelection,
                    okPressed: () {
                      Navigator.pop(context);
                      _preferenceService.setInt(PreferenceService.PREF_DATE_FORMAT_SELECTION, _dateFormatSelection)
                      .then((value) {
                        _preferenceService.dateFormatSelection = _dateFormatSelection;
                      });
                      setState(() {});
                    },
                    cancelPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _loadAllPrefs();
                      });                    },
                    selectionChanged: (selection) {
                      _dateFormatSelection = selection;
                    }
                );
              },
            ),
            SettingsTile.switchTile(
              title: Text(translate('pages.settings.date_n_time.show_weekdays.title')),
              description: Text(translate('pages.settings.date_n_time.show_weekdays.description')),
              initialValue: _showWeekdays,
              onToggle: (bool value) {
                _preferenceService.showWeekdays = value;
                _preferenceService.setBool(PreferenceService.PREF_SHOW_WEEKDAYS, value);
                setState(() => _showWeekdays = value);
              },
            ),
            SettingsTile.switchTile(
              title: Text(translate('pages.settings.date_n_time.show_daytime_as_word.title')),
              description: Text(
                  translate(
                      'pages.settings.date_n_time.show_daytime_as_word.description',
                      args: {'evening' : When.fromWhenAtDayToString(AroundWhenAtDay.EVENING),})),
              initialValue: _showTimeOfDayAsText,
              onToggle: (bool value) {
                _preferenceService.showTimeOfDayAsText = value;
                _preferenceService.setBool(PreferenceService.PREF_SHOW_TIME_OF_DAY_AS_TEXT, value);
                 setState(() => _showTimeOfDayAsText = value);
              },
            ),
            SettingsTile(
              title: Text(translate('pages.settings.date_n_time.configure_daytimes.title')),
              description: Text(
                  translate('pages.settings.date_n_time.configure_daytimes.description')),
              onPressed: (context) {
                Navigator.push(super.context, MaterialPageRoute(builder: (context) => DayTimeSettingsScreen()));
              },
            ),
          ],
        ),
        SettingsSection(
          title: Text(translate('pages.settings.action_feedback.title'), style: TextStyle(color: ACCENT_COLOR)),
          tiles: [
            SettingsTile.switchTile(
              title: Text(translate('pages.settings.action_feedback.show_action_feedback.title')),
              description: Text(translate('pages.settings.action_feedback.show_action_feedback.description')),
              initialValue: _showActionNotifications,
              onToggle: (bool value) {
                _preferenceService.setBool(PreferenceService.PREF_SHOW_ACTION_NOTIFICATIONS, value);
                setState(() => _showActionNotifications = value);
              },
            ),
            SettingsTile(
              enabled: _showActionNotifications,
              title: Text(translate('pages.settings.action_feedback.duration.title')),
              description: Text(translate('pages.settings.action_feedback.duration.description')),
              onPressed: (context) {
                showChoiceDialog(context, translate('pages.settings.action_feedback.duration.dialog.title'),
                  [
                    translate('pages.settings.action_feedback.duration.dialog.options.slow'),
                    translate('pages.settings.action_feedback.duration.dialog.options.normal'),
                    translate('pages.settings.action_feedback.duration.dialog.options.quick'),
                    translate('pages.settings.action_feedback.duration.dialog.options.fast'),
                  ],
                  initialSelected: _showActionNotificationDurationSelection,
                  okPressed: () {
                    Navigator.pop(context);
                    _preferenceService.setInt(PreferenceService.PREF_SHOW_ACTION_NOTIFICATION_DURATION_SELECTION, _showActionNotificationDurationSelection);
                  },
                  cancelPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _loadAllPrefs();
                    });
                  },
                  selectionChanged: (selection) {
                    _showActionNotificationDurationSelection = selection;
                  }
                );
              },
            ),
          ],
        ),
        SettingsSection(
          title: Text(translate('pages.settings.behaviour.title'), style: TextStyle(color: ACCENT_COLOR)),
          tiles: [
            SettingsTile.switchTile(
              title: Text(translate('pages.settings.behaviour.set_schedules_automatically_done.title')),
              description: Text(translate('pages.settings.behaviour.set_schedules_automatically_done.description')),
              initialValue: _executeSchedulesOnTaskEvent,
              onToggle: (bool value) {
                _preferenceService.setBool(PreferenceService.PREF_EXECUTE_SCHEDULES_ON_TASK_EVENT, value);
                setState(() => _executeSchedulesOnTaskEvent = value);
              },
            ),
            SettingsTile.switchTile(
              title: Text(translate('pages.settings.behaviour.show_schedules_count_as_badge.title')),
              description: Text(translate('pages.settings.behaviour.show_schedules_count_as_badge.description')),
              initialValue: _showBadgeForDueSchedules,
              onToggle: (bool value) {
                _preferenceService.setBool(PreferenceService.PREF_SHOW_BADGE_FOR_DUE_SCHEDULES, value);
                _preferenceService.showBadgeForDueSchedules = value;
                setState(() => _showBadgeForDueSchedules = value);
              },
            ),
          ],
        ),
      ],
    );
  }

  _loadAllPrefs() async {

    final languageSelection = await _preferenceService.getInt(PreferenceService.PREF_LANGUAGE_SELECTION);
    if (languageSelection != null) {
      _languageSelection = languageSelection;
      debugPrint("language is $_languageSelection");
    }

    final showTimeOfDayAsText = await _preferenceService.getBool(PreferenceService.PREF_SHOW_TIME_OF_DAY_AS_TEXT);
    if (showTimeOfDayAsText != null) {
      _showTimeOfDayAsText = showTimeOfDayAsText;
      _preferenceService.showTimeOfDayAsText = showTimeOfDayAsText;
    }
    else {
      _showTimeOfDayAsText = true; // default
    }
    
    final showWeekdays = await _preferenceService.getBool(PreferenceService.PREF_SHOW_WEEKDAYS);
    if (showWeekdays != null) {
      _showWeekdays = showWeekdays;
      _preferenceService.showWeekdays = showWeekdays;
    }
    else {
      _showWeekdays = true; // default
    }

    final darkTheme = await _preferenceService.getBool(PreferenceService.PREF_DARK_THEME);
    if (darkTheme != null) {
      _darkTheme = darkTheme;
      _preferenceService.darkTheme = darkTheme;
    }
    else {
      _darkTheme = false; // default
    }

    final dateFormatSelection = await _preferenceService.getInt(PreferenceService.PREF_DATE_FORMAT_SELECTION);
    if (dateFormatSelection != null) {
      _dateFormatSelection = dateFormatSelection;
      _preferenceService.dateFormatSelection = _dateFormatSelection;
    }

    final showActionNotifications = await _preferenceService.getBool(PreferenceService.PREF_SHOW_ACTION_NOTIFICATIONS);
    if (showActionNotifications != null) {
      _showActionNotifications = showActionNotifications;
    }
    else {
      _showActionNotifications = true; // default
    }

    final showActionNotificationDurationSelection = await _preferenceService.getInt(PreferenceService.PREF_SHOW_ACTION_NOTIFICATION_DURATION_SELECTION);
    if (showActionNotificationDurationSelection != null) {
      _showActionNotificationDurationSelection = showActionNotificationDurationSelection;
    }

    final executeSchedulesOnTaskEvent = await _preferenceService.getBool(PreferenceService.PREF_EXECUTE_SCHEDULES_ON_TASK_EVENT);
    if (executeSchedulesOnTaskEvent != null) {
      _executeSchedulesOnTaskEvent = executeSchedulesOnTaskEvent;
    }
    else {
      _executeSchedulesOnTaskEvent = true; // default
    }

    final showBadgeForDueSchedules = await _preferenceService.getBool(PreferenceService.PREF_SHOW_BADGE_FOR_DUE_SCHEDULES);
    if (showBadgeForDueSchedules != null) {
      _showBadgeForDueSchedules = showBadgeForDueSchedules;
    }
    else {
      _showBadgeForDueSchedules = true; // default
    }
  }

  String _getLanguageSelectionAsString(int languageSelection, LocalizationDelegate localizationDelegate) {
    switch (languageSelection) {
      case 1: return translate('pages.settings.common.language.dialog.options.english');
      case 2: return translate('pages.settings.common.language.dialog.options.german');
      case 3: return translate('pages.settings.common.language.dialog.options.french');
      case 4: return translate('pages.settings.common.language.dialog.options.russian');
      case 5: return translate('pages.settings.common.language.dialog.options.spain');
      case 6: return translate('pages.settings.common.language.dialog.options.chinese');
    }
    final systemLanguage = Platform.localeName
        .split("_")
        .first;
    final appLanguages = localizationDelegate.supportedLocales
        .map((e) => e.languageCode);

    final systemLanguageSupported = appLanguages.contains(systemLanguage);
    final label = translate('pages.settings.common.language.dialog.options.system_default');
    if (systemLanguageSupported) {
      return label;
    }
    else {
      final hint = translate('pages.settings.common.language.language_not_supported',
          args: {"languageCode" : systemLanguage});
      return "$label\n($hint)";
    }

  }

}
