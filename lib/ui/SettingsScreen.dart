import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:personaltasklogger/model/When.dart';
import 'package:settings_ui/settings_ui.dart';

import '../service/PreferenceService.dart';
import '../util/dates.dart';
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
      appBar: AppBar(title: Text('Settings')),
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
          title: Text('Common', style: TextStyle(color: Colors.lime[800])),
          tiles: [
            SettingsTile(
              title: Text('Language'),
              description: Text(_preferenceService.getLanguageSelectionAsString(_preferenceService.languageSelection)),
              onPressed: (context) {

                showChoiceDialog(context, "Choose a language",
                    [
                      _preferenceService.getLanguageSelectionAsString(0),
                      _preferenceService.getLanguageSelectionAsString(1),
                      _preferenceService.getLanguageSelectionAsString(2),
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
                              newLocale = Locale(Localizations.localeOf(context).languageCode);
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
          title: Text('Date & Time', style: TextStyle(color: Colors.lime[800])),
          tiles: [
            SettingsTile(
              title: Text('Used date format'),
              description: Text("E.g. '${getDateFormat(context, _dateFormatSelection, false, false).format(exampleDate)}'"),
              onPressed: (context) {
                final locale = Localizations.localeOf(context).languageCode;
                initializeDateFormatting(locale);
                final yMd = DateFormat.yMd(locale);
                final yMMMd = DateFormat.yMMMd(locale);
                final yMMMMd = DateFormat.yMMMMd(locale);

                showChoiceDialog(context, "Choose a date format",
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
              title: Text('Show weekday'),
              description: Text('Shows the weekday for dates'),
              initialValue: _showWeekdays,
              onToggle: (bool value) {
                _preferenceService.showWeekdays = value;
                _preferenceService.setBool(PreferenceService.PREF_SHOW_WEEKDAYS, value)
                    .then((value) => setState(() => _showWeekdays = value));
              },
            ),
            SettingsTile.switchTile(
              title: Text('Show daytime as word'),
              description: Text("E.g. shows '${When.fromWhenAtDayToString(AroundWhenAtDay.EVENING)}' for the evening"),
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
          title: Text('Action feedback', style: TextStyle(color: Colors.lime[800])),
          tiles: [
            SettingsTile.switchTile(
              title: Text('Show action feedback'),
              description: Text('Shows a short message after several user actions'),
              initialValue: _showActionNotifications,
              onToggle: (bool value) {
                _preferenceService.setBool(PreferenceService.PREF_SHOW_ACTION_NOTIFICATIONS, value)
                  .then((value) => setState(() => _showActionNotifications = value));
              },
            ),
            SettingsTile(
              enabled: _showActionNotifications??false,
              title: Text('Action feedback duration'),
              description: Text('Duration before messages disappear'),
              onPressed: (context) {
                showChoiceDialog(context, "Choose your read duration",
                  ["I need more time", "Normal", "I read quickly", "I am super fast"],
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
}
