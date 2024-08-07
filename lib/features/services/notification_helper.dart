import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationHelper {
  static final _notification = FlutterLocalNotificationsPlugin();

  static init() {
    _notification.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings()));
    tz.initializeTimeZones();
  }

  static Future<void> scheduledNotification(
      String title, String body, String date, String pet_type ) async {
    if (pet_type == 'สุนัข') {
      final DateTime now = DateTime.now();
      DateTime dateSend = DateTime.parse(date);
      DateTime newDateSend = dateSend.add(Duration(days: 2));
      if (newDateSend.isAfter(now)) {
        Duration difference = newDateSend.difference(now);
        int daysDifference = difference.inDays;

        if (daysDifference <= 0) {
          int daylate = daysDifference.abs();
          print(daylate);
          
        } else {
          var androidDetails = AndroidNotificationDetails(
              'important_notification', 'My Channel',
              importance: Importance.max, priority: Priority.high);

          var iosDetails = const DarwinNotificationDetails();
          var notificationDetails =
              NotificationDetails(android: androidDetails, iOS: iosDetails);
          await _notification.zonedSchedule(
              0,
              title,
              body,
              tz.TZDateTime.now(tz.local).add(Duration(days: daysDifference)),
              notificationDetails,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
        }
      }
    } else {
      final DateTime now = DateTime.now();
      DateTime dateSend = DateTime.parse(date);
      DateTime newDateSend = dateSend.add(Duration(days: 3));
      if (newDateSend.isAfter(now)) {
        Duration difference = newDateSend.difference(now);
        int daysDifference = difference.inDays;

        if (daysDifference <= 0) {
          int daylate = daysDifference.abs();
          print(daylate);
          
        } else {
          var androidDetails = AndroidNotificationDetails(
              'important_notification', 'My Channel',
              importance: Importance.max, priority: Priority.high);

          var iosDetails = const DarwinNotificationDetails();
          var notificationDetails =
              NotificationDetails(android: androidDetails, iOS: iosDetails);
          await _notification.zonedSchedule(
              0,
              title,
              body,
              tz.TZDateTime.now(tz.local).add(Duration(days: daysDifference)),
              notificationDetails,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
        }
      }
    }
  }
}
