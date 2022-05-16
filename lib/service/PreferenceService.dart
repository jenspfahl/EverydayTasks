import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {

  static final PREF_SHOW_TIME_OF_DAY_AS_TEXT = "common/showTimeOfDayAsText";
  
  static final PREF_SHOW_WEEKDAYS = "common/showWeekdays";
  static final PREF_DATE_FORMAT_SELECTION = "common/dateFormatSelection";
  
  static final PREF_SHOW_ACTION_NOTIFICATIONS = "common/showActionNotifications";
  static final PREF_SHOW_ACTION_NOTIFICATION_DURATION_SELECTION = "common/showActionNotificationDurationSelection";

  static final PreferenceService _notificationService = PreferenceService._internal();

  static List<Function(String receiverKey, String id)> _handler = [];

  factory PreferenceService() {
    return _notificationService;
  }

  PreferenceService._internal() {
    getBool(PreferenceService.PREF_SHOW_TIME_OF_DAY_AS_TEXT)
        .then((value) {
          if (value != null) {
            showTimeOfDayAsText = value;
          }
    }); 
    getBool(PreferenceService.PREF_SHOW_WEEKDAYS)
        .then((value) {
          if (value != null) {
            showWeekdays = value;
          }
    });
    getInt(PreferenceService.PREF_DATE_FORMAT_SELECTION)
        .then((value) {
      if (value != null) {
        dateFormatSelection = value;
      }
    });
  }

  bool showTimeOfDayAsText = true;
  bool showWeekdays = true;
  int dateFormatSelection = 1;

  Future<String?> getString(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString(key);
  }

  Future<int?> getInt(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getInt(key);
  }

  Future<bool?> getBool(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool(key);
  }

  Future<bool> setString(String key, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setString(key, value);
  }

  Future<bool> setInt(String key, int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setInt(key,value);
  }

  Future<bool> setBool(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setBool(key, value);
  }

  Future<bool> remove(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.remove(key);
  }

}

