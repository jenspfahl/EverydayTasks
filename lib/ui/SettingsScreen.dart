import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:personaltasklogger/model/When.dart';
import 'package:settings_ui/settings_ui.dart';

import '../service/PreferenceService.dart';
import '../util/dates.dart';
import '../util/i18n.dart';
import 'dialogs.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final PreferenceService _preferenceService = PreferenceService();

  int _dateFormatSelection = 1;
  int _languageSelection = 0;
  bool? _showTimeOfDayAsText;
  bool? _showWeekdays;
  bool? _showActionNotifications;
  int _showActionNotificationDurationSelection = 1;

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
          title: Text(translate('pages.settings.common.title'), style: TextStyle(color: Colors.lime[800])),
          tiles: [
            SettingsTile(
              title: Text(translate('pages.settings.common.language.title')),
              description: Text(_getLanguageSelectionAsString(_preferenceService.languageSelection)),
              onPressed: (context) {

                showChoiceDialog(context, translate('pages.settings.common.language.dialog.title'),
                    [
                      _getLanguageSelectionAsString(0),
                      _getLanguageSelectionAsString(1),
                      _getLanguageSelectionAsString(2),
                    ],
                    initialSelected: _languageSelection,
                    okPressed: () {
                      Navigator.pop(context);
                      _preferenceService.setInt(PreferenceService.PREF_LANGUAGE_SELECTION, _languageSelection)
                      .then((value) {
                        _preferenceService.languageSelection = _languageSelection;

                        setState(() {
                          _preferenceService.getPreferredLocale().then((locale) {
                            Locale newLocale;
                            if (locale == null) {
                              newLocale = currentLocale(context);
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
                      _loadAllPrefs();
                    },
                    selectionChanged: (selection) {
                      _languageSelection = selection;
                    }
                );
              },
            ),
          ],
        ),
        SettingsSection(
          title: Text(translate('pages.settings.date_n_time.title'), style: TextStyle(color: Colors.lime[800])),
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

                showChoiceDialog(context, translate('pages.settings.date_n_time.used_date_format.dialog.title'),
                    [
                      yMd.format(exampleDate),
                      yMMMd.format(exampleDate),
                      yMMMMd.format(exampleDate),
                    ],
                    initialSelected: _dateFormatSelection,
                    okPressed: () {
                      Navigator.pop(context);
                      _preferenceService.setInt(PreferenceService.PREF_DATE_FORMAT_SELECTION, _dateFormatSelection)
                      .then((value) {
                        _preferenceService.dateFormatSelection = _dateFormatSelection;
                        setState(() {});
                      });
                    },
                    cancelPressed: () {
                      Navigator.pop(context);
                      _loadAllPrefs();
                    },
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
                _preferenceService.setBool(PreferenceService.PREF_SHOW_WEEKDAYS, value)
                    .then((value) => setState(() => _showWeekdays = value));
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
                _preferenceService.setBool(PreferenceService.PREF_SHOW_TIME_OF_DAY_AS_TEXT, value)
                    .then((value) => setState(() => _showTimeOfDayAsText = value));
              },
            ),
          ],
        ),
        SettingsSection(
          title: Text(translate('pages.settings.action_feedback.title'), style: TextStyle(color: Colors.lime[800])),
          tiles: [
            SettingsTile.switchTile(
              title: Text(translate('pages.settings.action_feedback.show_action_feedback.title')),
              description: Text(translate('pages.settings.action_feedback.show_action_feedback.description')),
              initialValue: _showActionNotifications,
              onToggle: (bool value) {
                _preferenceService.setBool(PreferenceService.PREF_SHOW_ACTION_NOTIFICATIONS, value)
                  .then((value) => setState(() => _showActionNotifications = value));
              },
            ),
            SettingsTile(
              enabled: _showActionNotifications??false,
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
                    _loadAllPrefs();
                  },
                  selectionChanged: (selection) {
                    _showActionNotificationDurationSelection = selection;
                  }
                );
              },
            ),
          ],
        ),
        /*SettingsSection(
          title: Text('Data', style: TextStyle(color: Colors.lime[800])),
          tiles: [
            SettingsTile(
              title: Text('Delete old journal entries'),
              onPressed: (context) {
              },
            ),
          ],
        ),*/
      ],
    );
  }

  _loadAllPrefs() async {

    final languageSelection = await _preferenceService.getInt(PreferenceService.PREF_LANGUAGE_SELECTION);
    if (languageSelection != null) {
      _languageSelection = languageSelection;
    }

    final showTimeOfDayAsText = await _preferenceService.getBool(PreferenceService.PREF_SHOW_TIME_OF_DAY_AS_TEXT);
    _showTimeOfDayAsText = showTimeOfDayAsText??true;
    _preferenceService.showTimeOfDayAsText = showTimeOfDayAsText!;
    
    final showWeekdays = await _preferenceService.getBool(PreferenceService.PREF_SHOW_WEEKDAYS);
    _showWeekdays = showWeekdays??true;
    _preferenceService.showWeekdays = _showWeekdays!;

    final dateFormatSelection = await _preferenceService.getInt(PreferenceService.PREF_DATE_FORMAT_SELECTION);
    if (dateFormatSelection != null) {
      _dateFormatSelection = dateFormatSelection;
      _preferenceService.dateFormatSelection = _dateFormatSelection;
    }

    final showActionNotifications = await _preferenceService.getBool(PreferenceService.PREF_SHOW_ACTION_NOTIFICATIONS);
    _showActionNotifications = showActionNotifications??true;

    final showActionNotificationDurationSelection = await _preferenceService.getInt(PreferenceService.PREF_SHOW_ACTION_NOTIFICATION_DURATION_SELECTION);
    if (showActionNotificationDurationSelection != null) {
      _showActionNotificationDurationSelection = showActionNotificationDurationSelection;
    }

  }

  String _getLanguageSelectionAsString(int languageSelection) {
    switch (languageSelection) {
      case 1: return translate('pages.settings.common.language.dialog.options.english');
      case 2: return translate('pages.settings.common.language.dialog.options.german');
    }
    return translate('pages.settings.common.language.dialog.options.system_default');
  }

}
