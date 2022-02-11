import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// stolen from https://github.com/iloveteajay/flutter_local_notification/https://github.com/iloveteajay/flutter_local_notification/
class LocalNotificationService {
  //LocalNotificationService a singleton object
  static final LocalNotificationService _notificationService =
  LocalNotificationService._internal();

  static late List<Function(String receiverKey, String id)> _handler = [];

  factory LocalNotificationService() {
    return _notificationService;
  }

  LocalNotificationService._internal();

  static const channelId = 'de.jepfa.ptl.notifications';

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
    AndroidInitializationSettings('ic_launcher');

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
          if (payload != null) {
            var splitted = payload.split("-");
            _handler.forEach((h) => h.call(splitted[0], splitted[1]));
          }
        });
  }

  AndroidNotificationDetails _androidNotificationDetails =
  AndroidNotificationDetails(
    channelId,
    'Personal Task Logger',
    'Notifications about due scheduled tasks',
    playSound: true,
    priority: Priority.high,
    importance: Importance.high,
  );

  Future<void> showNotifications(int id, String title, String message) async {
    await _flutterLocalNotificationsPlugin.show(
      id,
      title, 
      message,
      NotificationDetails(android: _androidNotificationDetails),
      payload: id.toString(),
    );
  }

  Future<void> scheduleNotifications(String receiverKey, int id, String title, message, Duration duration) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        message,
        tz.TZDateTime.now(tz.local).add(duration),
        NotificationDetails(android: _androidNotificationDetails),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload: receiverKey + "-" + id.toString());
  }

  Future<void> cancelNotifications(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}

