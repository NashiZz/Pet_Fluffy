import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart'as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationHelper{
  static final _notification = FlutterLocalNotificationsPlugin();

  static init() {
    _notification.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings()
    ));
    tz.initializeTimeZones();
  }

  static scheduledNotification (String title,String body,String date) async {
    var androidDetails = AndroidNotificationDetails('important_notification' , 'My Channel',importance: Importance.max,priority: Priority.high);

    var iosDetails = const DarwinNotificationDetails();
    var notificationDetails = NotificationDetails(android: androidDetails,iOS: iosDetails);
    await _notification.zonedSchedule(0, title, body, tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)), notificationDetails, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime
    ,androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
  }
}