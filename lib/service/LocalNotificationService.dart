import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../main.dart';

const CHANNEL_ID_SCHEDULES = 'de.jepfa.ptl.notifications.schedules';
const CHANNEL_ID_TRACKING = 'de.jepfa.ptl.notifications.tracking';


// stolen from https://github.com/iloveteajay/flutter_local_notification/https://github.com/iloveteajay/flutter_local_notification/
class LocalNotificationService {

  static final LocalNotificationService _notificationService = LocalNotificationService._internal();

  static late List<Function(String receiverKey, String id)> _handler = [];

  factory LocalNotificationService() {
    return _notificationService;
  }

  LocalNotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  void addHandler(Function(String receiverKey, String id) handler) {
    _handler.add(handler);
  }

  void removeHandler(Function(String receiverKey, String id) handler) {
    _handler.remove(handler);
  }

  Future<void> init() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher_notif');

    final IOSInitializationSettings initializationSettingsIOS =
    IOSInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        macOS: null);

    tz.initializeTimeZones();

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {
          // TODO seems not be invoked when the app was closed before
          if (payload != null) {
            if (_handler.isNotEmpty) {
              _handlePayload(payload);
            }
          }
        });
  }

  Future<void> showNotifications(int id, String title, String message, String channelId, [Color? color]) async {
    await _flutterLocalNotificationsPlugin.show(
      id,
      title, 
      message,
      NotificationDetails(android: _createNotificationDetails(color, channelId)),
      payload: id.toString(),
    );
  }

  Future<void> scheduleNotifications(String receiverKey, int id, String title, message, Duration duration, String channelId, [Color? color]) async {
    final when = tz.TZDateTime.now(tz.local).add(duration);
    await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        message,
        when.subtract(Duration(seconds: when.second)), // trunc seconds
        NotificationDetails(android: _createNotificationDetails(color, channelId)),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: receiverKey + "-" + id.toString());
  }

  Future<void> cancelNotifications(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  void handleAppLaunchNotification() {
    _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails()
        .then((notification) {
          final payload = notification?.payload;
          if (payload != null) {
            _handlePayload(payload);
          }
    });
  }

  void _handlePayload(String payload) {
    var splitted = payload.split("-");
    _handler.forEach((h) => h.call(splitted[0], splitted[1]));
  }


  AndroidNotificationDetails _createNotificationDetails(Color? color, String channelId) {
    return AndroidNotificationDetails(
      channelId,
      APP_NAME,
      'Notifications about due scheduled tasks',
      color: color,
      playSound: true,
      priority: Priority.high,
      importance: Importance.high,
    );
  }
}

