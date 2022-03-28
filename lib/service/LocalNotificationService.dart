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

  static List<Function(String receiverKey, bool isAppLaunch, String payload)> _notificationClickedHandler = [];
  static List<Function(int id, String? channelId)> _activeNotificationHandler = [];

  factory LocalNotificationService() {
    return _notificationService;
  }

  LocalNotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  void addNotificationClickedHandler(Function(String receiverKey, bool isAppLaunch, String payload) handler) {
    _notificationClickedHandler.add(handler);
  }

  void removeNotificationClickedHandler(Function(String receiverKey, bool isAppLaunch, String payload) handler) {
    _notificationClickedHandler.remove(handler);
  }

  void addActiveNotificationHandler(Function(int id, String? channelId) handler) {
    _activeNotificationHandler.add(handler);
  }

  void removeActiveNotificationHandler(Function(int id, String? channelId) handler) {
    _activeNotificationHandler.remove(handler);
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
          if (payload != null) {
            if (_notificationClickedHandler.isNotEmpty) {
              _handlePayload(false, payload);
            }
          }
        });
  }

  Future<void> showNotification(String receiverKey, int id, String title, String message, String channelId, bool keepAsProgress, String payload, [Color? color]) async {
    await _flutterLocalNotificationsPlugin.show(
      id,
      title, 
      message,
      NotificationDetails(android: _createNotificationDetails(color, channelId, keepAsProgress)),
      payload: receiverKey + "-" + payload,
    );
  }

  Future<void> scheduleNotification(String receiverKey, int id, String title, message, Duration duration, String channelId, [Color? color]) async {
    final when = tz.TZDateTime.now(tz.local).add(duration);
    await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        message,
        when.subtract(Duration(seconds: when.second)), // trunc seconds
        NotificationDetails(android: _createNotificationDetails(color, channelId, false)),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: receiverKey + "-" + id.toString());
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
          final payload = notification?.payload;
          if (payload != null) {
            _handlePayload(true, payload);
          }
    });

    _flutterLocalNotificationsPlugin.pendingNotificationRequests().then((pendingNotifications) {
      pendingNotifications.forEach((element) {debugPrint("pending notification: ${element.id} ${element.title} ${element.payload}");});
    });

    AndroidFlutterLocalNotificationsPlugin? nativePlugin = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation();
    nativePlugin?.getActiveNotifications().then((activeNotifications) {
      activeNotifications?.forEach((element) {
        _handleActiveNotification(element.id, element.channelId);
      });

    });
  }

  void _handlePayload(bool isAppLaunch, String payload) {
    debugPrint("_handlePayload=$payload $isAppLaunch");

    var index = payload.indexOf("-");
    if (index != -1) {
      final receiverKey = payload.substring(0, index);
      final actualPayload = payload.substring(index + 1);
      _notificationClickedHandler.forEach((h) => h.call(receiverKey, isAppLaunch, actualPayload));
    }
  }
  
  void _handleActiveNotification(int id, String? channelId) {
    debugPrint("active notification: $id $channelId");
    _activeNotificationHandler.forEach((h) => h.call(id, channelId));
  }


  AndroidNotificationDetails _createNotificationDetails(Color? color, String channelId, bool keepAsProgress) {
    return AndroidNotificationDetails(
      channelId,
      APP_NAME,
      channelId == CHANNEL_ID_SCHEDULES
          ? 'Notifications about due scheduled tasks'
          : channelId == CHANNEL_ID_TRACKING
          ? 'Tracking notifications'
          : "Common notifications",
      color: color,
      playSound: !keepAsProgress,
      indeterminate: keepAsProgress,
      usesChronometer: keepAsProgress,
      showProgress: keepAsProgress,
      autoCancel: !keepAsProgress,
      ongoing: keepAsProgress,
      priority: Priority.high,
      importance: Importance.high,
    );
  }
}

