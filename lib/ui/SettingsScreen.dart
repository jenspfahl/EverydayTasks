import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import '../service/PreferenceService.dart';
import 'dialogs.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final PreferenceService _preferenceService = PreferenceService();

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
          title: Text('Common', style: TextStyle(color: Colors.lime[800])),
          tiles: [
            SettingsTile(
              title: Text('Date format'),
              onPressed: (context) {
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
                showChoiceDialog(context, "Choose a duration",
                  ["Long time needed", "Normal", "I read quickly"],
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
    final showActionNotifications = await _preferenceService.getBool(PreferenceService.PREF_SHOW_ACTION_NOTIFICATIONS);
    _showActionNotifications = showActionNotifications??true;
    
    final showActionNotificationDurationSelection = await _preferenceService.getInt(PreferenceService.PREF_SHOW_ACTION_NOTIFICATION_DURATION_SELECTION);
    if (showActionNotificationDurationSelection != null) {
      _showActionNotificationDurationSelection = showActionNotificationDurationSelection;
    }

  }
}
