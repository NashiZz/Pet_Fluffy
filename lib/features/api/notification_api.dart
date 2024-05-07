
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Payload: ${message.data}');
}

class FirebaseApi {
  // final _firebaseMessageing = FirebaseMessaging.instance;

  // void handleMessage(RemoteMessage? message) {
  //   if (message == null) {
  //     return;
  //   }
  // }

  // Future initNotifications() async {
  //   await FirebaseMessaging.instance
  //       .setForegroundNotificationPresentationOptions(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );
  // }

  // Future<void> initNotifications() async {
  //   await _firebaseMessageing.requestPermission();
  //   final fCMToken = await _firebaseMessageing.getToken();
  //   print('Token: $fCMToken');
  //   FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  // }
}
