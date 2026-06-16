import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'notification_helper_stub.dart'
    if (dart.library.html) 'notification_helper_web.dart'
    as helper;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isMobileInitialized = false;

  Future<void> initialize() async {
    if (kIsWeb) {
      helper.requestWebNotificationPermission();
      return;
    }

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
      );
      _isMobileInitialized = true;
    } catch (e) {
      debugPrint("Mobile Notification initialize failed: $e");
    }
  }

  Future<void> showNotification({required String title, required String body}) async {
    if (kIsWeb) {
      helper.showWebNotification(title, body);
      return;
    }

    if (!_isMobileInitialized) return;

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'hydration_reminder_channel',
        'Hydration Reminders',
        channelDescription: 'Motivational alerts to drink water regularly',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: DateTime.now().millisecond,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint("Mobile showNotification failed: $e");
    }
  }
}
