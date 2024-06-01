// ignore_for_file: camel_case_types

import 'package:Pet_Fluffy/features/page/home.dart';
import 'package:Pet_Fluffy/features/page/navigator_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Splash_Page extends StatefulWidget {
  const Splash_Page({Key? key}) : super(key: key);

  @override
  State<Splash_Page> createState() => _SplashPageState();
}

class _SplashPageState extends State<Splash_Page> {
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _isMounted = true; //วิดเจ็ตได้ถูกติดตั้งและกำลังทำงานอยู่
  }

  @override
  void dispose() {
    _isMounted = false;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ทำงานที่ต้องการ
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      // รอเสร็จสิ้นการโหลดและนำทางไปยังหน้าที่เหมาะสม
      Future.delayed(const Duration(seconds: 3), () {
        if (_isMounted) {
          if (user != null && user.emailVerified) {
            // หากผู้ใช้ล็อกอินแล้วและยืนยันอีเมลแล้ว นำทางไปยังหน้า Navigator Page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const Navigator_Page(initialIndex: 0),
              ),
            );
          } else {
            // หากผู้ใช้ยังไม่ได้ล็อกอินหรือยังไม่ได้ยืนยันอีเมล นำทางไปยังหน้า Home Page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const Home_Page(),
              ),
            );
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cruelty_free,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              'Pet Fluffy',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.white,
                fontSize: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
