import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
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
  final _exampleDate = DateTime(2022, DateTime.december, 31);

  int _dateFormatSelection = 1;
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

    return SettingsList(
      sections: [
        SettingsSection(
          title: Text('Dates', style: TextStyle(color: Colors.lime[800])),
          tiles: [
            SettingsTile(
              title: Text('Used date format'),
              description: Text("E.g. '${getDateFormat(context, _dateFormatSelection, false).format(_exampleDate)}'"),
              onPressed: (context) {
                final locale = Localizations.localeOf(context).languageCode;
                initializeDateFormatting(locale);
                final yMd = DateFormat.yMd(locale);
                final yMMMd = DateFormat.yMMMd(locale);
                final yMMMMd = DateFormat.yMMMMd(locale);

                showChoiceDialog(context, "Choose a date format",
                    [
                      yMd.format(_exampleDate),
                      yMMMd.format(_exampleDate),
                      yMMMMd.format(_exampleDate),
                    ],
                    initialSelected: _dateFormatSelection,
                    okPressed: () {
                      Navigator.pop(context);
                      _preferenceService.setInt(PreferenceService.PREF_DATE_FORMAT_SELECTION, _dateFormatSelection);
                      _preferenceService.dateFormatSelection = _dateFormatSelection;
                      setState(() {

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
        SettingsSection(
          title: Text('Data', style: TextStyle(color: Colors.lime[800])),
          tiles: [
            SettingsTile(
              title: Text('Delete old journal entries'),
              onPressed: (context) {
              },
            ),
          ],
        ),
      ],
    );
  }

  _loadAllPrefs() async {
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
