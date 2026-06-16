import 'package:web/web.dart' as web;
import 'dart:js_interop';

bool get isWebNotificationSupported => true;

Future<void> requestWebNotificationPermission() async {
  try {
    if (web.Notification.permission != 'granted' && web.Notification.permission != 'denied') {
      await web.Notification.requestPermission().toDart;
    }
  } catch (e) {
    // Ignored
  }
}

void showWebNotification(String title, String body) async {
  try {
    if (web.Notification.permission == 'granted') {
      web.Notification(title, web.NotificationOptions(body: body));
    } else if (web.Notification.permission != 'denied') {
      final permission = await web.Notification.requestPermission().toDart;
      if ((permission).toDart == 'granted') {
        web.Notification(title, web.NotificationOptions(body: body));
      }
    }
  } catch (e) {
    // Ignored
  }
}
