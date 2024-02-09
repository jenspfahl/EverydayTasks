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

class DayTimeSettingsScreen extends StatefulWidget {
  @override
  _DayTimeSettingsScreenState createState() => _DayTimeSettingsScreenState();
}

class _DayTimeSettingsScreenState extends State<DayTimeSettingsScreen> {

  final PreferenceService _preferenceService = PreferenceService();



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

    return SettingsList(
      sections: [
        SettingsSection(
          title: Text(translate('pages.settings.date_n_time.configure_daytimes.title'), style: TextStyle(color: ACCENT_COLOR)),
          tiles: [
            _buildSettingsTileForWhenAtDay(AroundWhenAtDay.MORNING),
            _buildSettingsTileForWhenAtDay(AroundWhenAtDay.FORENOON),
            _buildSettingsTileForWhenAtDay(AroundWhenAtDay.NOON),
            _buildSettingsTileForWhenAtDay(AroundWhenAtDay.AFTERNOON),
            _buildSettingsTileForWhenAtDay(AroundWhenAtDay.EVENING),
            _buildSettingsTileForWhenAtDay(AroundWhenAtDay.NIGHT),
          ],
        ),
      ],
    );
  }

  SettingsTile _buildSettingsTileForWhenAtDay(AroundWhenAtDay whenAtDay) {
    return SettingsTile(
            title: Text("${When.fromWhenAtDayToWord(whenAtDay)}"),
            description: Text("${formatTimeOfDay(When.fromWhenAtDayToTimeOfDay(whenAtDay, null))}"),
            onPressed: (context) {
              showTimePicker(context: context, initialTime: When.fromWhenAtDayToTimeOfDay(whenAtDay, null));


            },
          );
  }

  _loadAllPrefs() async {

    final languageSelection = await _preferenceService.getInt(PreferenceService.PREF_LANGUAGE_SELECTION);
    if (languageSelection != null) {
    //  _languageSelection = languageSelection;
    }


  }

}
