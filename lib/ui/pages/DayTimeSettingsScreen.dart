import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/db/repository/KeyValueRepository.dart';
import 'package:personaltasklogger/model/When.dart';
import 'package:personaltasklogger/ui/dialogs.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../db/repository/mapper.dart';
import '../../service/PreferenceService.dart';
import '../../util/dates.dart';
import '../PersonalTaskLoggerApp.dart';

class DayTimeSettingsScreen extends StatefulWidget {
  @override
  _DayTimeSettingsScreenState createState() => _DayTimeSettingsScreenState();
}

class _DayTimeSettingsScreenState extends State<DayTimeSettingsScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('navigation.menus.settings')),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              showConfirmationDialog(context,
                  translate('pages.settings.date_n_time.reset_daytimes.title'),
                  translate('pages.settings.date_n_time.reset_daytimes.description'),
                  okPressed: () async {
                    AroundWhenAtDay.values.forEach((whenAtDay) {
                      if (whenAtDay != AroundWhenAtDay.CUSTOM && whenAtDay != AroundWhenAtDay.NOW) {
                        setState(() {
                          PreferenceService().resetWhenAtDayTimeOfDay(whenAtDay);
                        });
                        KeyValueRepository.delete(whenAtDay.toString());
                      }
                    });
                    Navigator.pop(context);
                  }, cancelPressed: () {
                    Navigator.pop(context);
                  }
              );
            },
          ),
        ],
      ),
      body: _buildSettingsList(),
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
    final timeOfDay = PreferenceService().getWhenAtDayTimeOfDay(whenAtDay);
    return SettingsTile(
      title: Text("${When.fromWhenAtDayToWord(whenAtDay)}"),
      description: Text("${formatTimeOfDay(timeOfDay)}"),
      onPressed: (context) {
        showTimePicker(context: context, initialTime: timeOfDay).then((value) {
          if (value != null) {
            setState(() {
              PreferenceService().setWhenAtDayTimeOfDay(whenAtDay, value);
            });
            KeyValueRepository.save(whenAtDay.toString(), timeOfDayToEntity(value).toString());
          }
        });
      },
    );
  }


}
