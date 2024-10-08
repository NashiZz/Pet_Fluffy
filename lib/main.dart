import 'package:Pet_Fluffy/features/api/notification_api.dart';
import 'package:Pet_Fluffy/features/services/notification_helper.dart';
import 'package:Pet_Fluffy/features/splash_screen/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';


final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  //Flutter framework ถูกเรียกใช้งานก่อนที่จะเริ่มทำงานต่างๆกับ plugin หรือ firebase
  WidgetsFlutterBinding.ensureInitialized();
  NotificationHelper.init();
  //ทำการเชื่อมต่อแอปกับ Firebase
  await Firebase.initializeApp();
  await FirebaseApi().initNotifications();

  //กำหนดการตั้งค่าเริ่มต้นสำหรับการแจ้ง
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  //กำหนดการตั้งค่าเริ่มต้นสำหรับการเริ่มต้นการใช้งาน Firebase Cloud Messaging
  const InitializationSettings initializationSettings =
      InitializationSettings(android: androidInitializationSettings);

  await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await initializeDateFormatting('th_TH');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pet Fluffy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        // Set Font
        textTheme: GoogleFonts.kanitTextTheme(
          Theme.of(context).textTheme,
        ),
        primaryTextTheme: GoogleFonts.kanitTextTheme(
          Theme.of(context).primaryTextTheme,
        ),
      ),
      home: const Splash_Page(),
    );
  }
}
