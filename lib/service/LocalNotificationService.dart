import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../main.dart';

const CHANNEL_ID_SCHEDULES = 'de.jepfa.ptl.notifications.schedules';
const CHANNEL_ID_TRACKING = 'de.jepfa.ptl.notifications.tracking';


// stolen from https://github.com/iloveteajay/flutter_local_notification/https://github.com/iloveteajay/flutter_local_notification/
class LocalNotificationService {

  static final int RESCHEDULED_IDS_RANGE = 10000000;

  static final LocalNotificationService _notificationService = LocalNotificationService._internal();

  static List<Function(String receiverKey, bool isAppLaunch, String payload, String? actionId)> _notificationClickedHandler = [];
  static List<Function(int id, String? channelId)> _activeNotificationHandler = [];

  factory LocalNotificationService() {
    return _notificationService;
  }

  LocalNotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  void addNotificationClickedHandler(Function(String receiverKey, bool isAppLaunch, String payload, String? actionId) handler) {
    _notificationClickedHandler.add(handler);
  }

  void removeNotificationClickedHandler(Function(String receiverKey, bool isAppLaunch, String payload, String? actionId) handler) {
    _notificationClickedHandler.remove(handler);
  }

  void addActiveNotificationHandler(Function(int id, String? channelId) handler) {
    _activeNotificationHandler.add(handler);
  }

  void removeActiveNotificationHandler(Function(int id, String? channelId) handler) {
    _activeNotificationHandler.remove(handler);
  }

  @pragma('vm:entry-point')
  static Future<void> handleNotificationResponseInBackground(NotificationResponse response) async {
    debugPrint('bg action pressed: ${response.actionId} p=${response.payload}');
    if (response.actionId == "snooze") {
      final payload = response.payload;
      if (payload != null) {
        final firstIndex = payload.indexOf("-###");
        if (firstIndex != -1) {
          final parametersAsString = payload.substring(firstIndex + 4);
          debugPrint("extracted params=$parametersAsString");
          Map<String, dynamic> parameters = jsonDecode(parametersAsString);

          List<dynamic>? actionsStrings = parameters['actions'];
          List<AndroidNotificationAction>? actions = actionsStrings != null
              ? actionsStrings
              .map((s) => s.split("-"))
              .map((splitted) => AndroidNotificationAction(splitted[0], splitted[2], showsUserInterface: splitted[1]=="true"))
              .toList()
              : null;

          final notificationService = LocalNotificationService();
          int id = parameters['id'];

          // hack to move the id out of ScheduledTaskId range to not overwrite them
          int newId = id < RESCHEDULED_IDS_RANGE ? RESCHEDULED_IDS_RANGE + id : id;

          await notificationService.init();
          notificationService.scheduleNotification(
              parameters['receiverKey'],
              newId,
              parameters['title'],
              parameters['message'],
              kReleaseMode ? Duration(hours: 1) : Duration(minutes: 1), //TODO make this configurable
              parameters['channelId'],
              parameters['color'] != null ? Color(parameters['color']): null,
              actions,
              false
          );
        }
      }
      else {
        debugPrint("cannot reschedule notification");
      }
    }
  }

  Future<void> init() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher_notif');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    tz.initializeTimeZones();

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          debugPrint('action pressed: ${response.actionId}');
          final payload = response.payload;
          if (payload != null) {
            if (_notificationClickedHandler.isNotEmpty) {
              _handlePayload(false, payload, response.actionId);
            }
          }
        },
        onDidReceiveBackgroundNotificationResponse: handleNotificationResponseInBackground
    );
  }

  Future<void> showNotification(String receiverKey, int id, String title, String message, String channelId, bool keepAsProgress, String payload, [Color? color, List<AndroidNotificationAction>? actions]) async {
    await _flutterLocalNotificationsPlugin.show(
      id,
      title, 
      message,
      NotificationDetails(android: _createNotificationDetails(color, channelId, keepAsProgress, actions, true)),
      payload: receiverKey + "-" + payload,
    );
  }

  Future<void> scheduleNotification(String receiverKey, int id, String title, message, Duration duration, String channelId,
      [Color? color, List<AndroidNotificationAction>? actions, bool withTranslation = true]) async {
    final when = tz.TZDateTime.now(tz.local).add(duration);

    final parameterMap = {
      'receiverKey' : receiverKey,
      'id' : id,
      'title' : title,
      'message' : message,
      'channelId' : channelId,
      'color' : color?.value,
      'actions' : actions?.map((a) => a.id + "-" + a.showsUserInterface.toString() + "-" + a.title).toList(),
    };
    final parametersAsJson = jsonEncode(parameterMap);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        message,
        when.subtract(Duration(seconds: when.second)), // trunc seconds
        NotificationDetails(android: _createNotificationDetails(color, channelId, false, actions, withTranslation)),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: receiverKey + "-" + id.toString() + "-###" + parametersAsJson);
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  void handleAppLaunchNotification() {
    _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails()
        .then((notification) {
          final payload = notification?.notificationResponse?.payload;
          if (payload != null) {
            _handlePayload(true, payload, notification?.notificationResponse?.actionId);
          }
    });

    _flutterLocalNotificationsPlugin.pendingNotificationRequests().then((pendingNotifications) {
      pendingNotifications.forEach((element) {debugPrint("pending notification: ${element.id} ${element.title} ${element.payload}");});
    });

    AndroidFlutterLocalNotificationsPlugin? nativePlugin = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation();
    nativePlugin?.getActiveNotifications().then((activeNotifications) {
      activeNotifications.forEach((element) {
        _handleActiveNotification(element.id, element.channelId);
      });

    });
  }

  void _handlePayload(bool isAppLaunch, String payload, String? actionId) {
    debugPrint("_handlePayload=$payload $isAppLaunch");

    var splitted = payload.split("-");
    if (splitted.length >= 2) {
      final receiverKey = splitted[0];
      final actualPayload = splitted[1];
      _notificationClickedHandler.forEach((h) =>
          h.call(receiverKey, isAppLaunch, actualPayload, actionId));
    }
  }
  
  void _handleActiveNotification(int id, String? channelId) {
    debugPrint("active notification: $id $channelId");
    _activeNotificationHandler.forEach((h) => h.call(id, channelId));
  }


  AndroidNotificationDetails _createNotificationDetails(Color? color, String channelId,
      bool keepAsProgress, List<AndroidNotificationAction>? actions, bool withTranslation) {
    return AndroidNotificationDetails(
      channelId,
      channelId == CHANNEL_ID_SCHEDULES
          ? withTranslation ? translate("system.notifications.channel_schedules") : APP_NAME
          : channelId == CHANNEL_ID_TRACKING
          ? withTranslation ? translate("system.notifications.channel_tracking") : APP_NAME
          : withTranslation ? translate("system.notifications.channel_others") : APP_NAME,
      color: color,
      playSound: !keepAsProgress,
      indeterminate: keepAsProgress,
      usesChronometer: keepAsProgress,
      showProgress: keepAsProgress,
      autoCancel: !keepAsProgress,
      icon: null, //TODO have TaskGroup Icons would be an option
      ongoing: keepAsProgress,
      priority: Priority.high,
      importance: Importance.high,
      actions: actions,
    );
  }
}

