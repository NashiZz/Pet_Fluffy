import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
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

  Future<void> requestExactAlarmPermission() async {
    if (await Permission.scheduleExactAlarm.isDenied) {
      await openAppSettings();
    }
  }

  static Future<void> scheduledNotification(
      String title, String body, String date, String pet_type) async {
    print(
        'Notification Scheduled: Title: $title, Body: $body, Date: $date, Pet Type: $pet_type');

    final DateTime now = DateTime.now();
    print('Current DateTime: $now');

    DateTime dateSend = DateTime.parse(date);
    print('Parsed Date: $dateSend');

    DateTime newDateSend;
    if (pet_type == 'สุนัข') {
      newDateSend = dateSend.add(Duration(days: 2));
    } else {
      newDateSend = dateSend.add(Duration(days: 3));
    }

    print('New Date to Send Notification: $newDateSend');

    if (newDateSend.isAfter(now)) {
      Duration difference = newDateSend.difference(now);
      int daysDifference = difference.inDays;

      print('Days Difference: $daysDifference');

      if (daysDifference <= 0) {
        int daylate = daysDifference.abs();
        print('Notification is late by $daylate days');
      } else {
        var androidDetails = AndroidNotificationDetails(
          'important_notification',
          'My Channel',
          importance: Importance.max,
          priority: Priority.high,
          channelShowBadge: true, // แสดง badge บนไอคอนแอป
        );

        var iosDetails = const DarwinNotificationDetails();
        var notificationDetails =
            NotificationDetails(android: androidDetails, iOS: iosDetails);

        print('Scheduling notification...');
        await _notification.zonedSchedule(
            0,
            title,
            body,
            tz.TZDateTime.now(tz.local).add(Duration(seconds: daysDifference)),
            notificationDetails,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode:
                AndroidScheduleMode.inexactAllowWhileIdle); // เปลี่ยนโหมดตรงนี้

        print('Notification Scheduled Successfully');
      }
    } else {
      print(
          'The new scheduled date is not in the future. No notification will be sent.');
    }
  }
}
