// ignore_for_file: camel_case_types

import 'dart:async';

import 'package:Pet_Fluffy/features/page/adminFile/admin_home.dart';
import 'package:Pet_Fluffy/features/page/home.dart';
import 'package:Pet_Fluffy/features/page/navigator_page.dart';
import 'package:Pet_Fluffy/features/splash_screen/setting_position.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Splash_Page extends StatefulWidget {
  const Splash_Page({Key? key}) : super(key: key);

  @override
  State<Splash_Page> createState() => _SplashPageState();
}

class _SplashPageState extends State<Splash_Page> {
  bool _isMounted = false;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
<<<<<<< HEAD
    _isMounted = true;

    // ตรวจสอบสถานะการเชื่อมต่อเริ่มต้น
    _checkInitialConnectivity();

    // ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        // เชื่อมต่ออินเทอร์เน็ตแล้ว
        _handleUserNavigation();
      } else {
        // ยังไม่เชื่อมต่ออินเทอร์เน็ต
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่มีการเชื่อมต่ออินเทอร์เน็ต'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
=======
    _isMounted = true; //วิดเจ็ตได้ถูกติดตั้งและกำลังทำงานอยู่
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
  }

  @override
  void dispose() {
    _isMounted = false;
    _connectivitySubscription.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _checkInitialConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // ยังไม่เชื่อมต่ออินเทอร์เน็ต
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่มีการเชื่อมต่ออินเทอร์เน็ต'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

<<<<<<< HEAD
  void _handleUserNavigation() async {
    // รอเสร็จสิ้นการโหลดและนำทางไปยังหน้าที่เหมาะสม
    await Future.delayed(const Duration(seconds: 3));

    if (_isMounted) {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        if (user.isAnonymous) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const Navigator_Page(initialIndex: 0),
            ),
          );
        } else if (user.emailVerified) {
          final userDocRef =
              FirebaseFirestore.instance.collection('user').doc(user.uid);
          final userData = await userDocRef.get();

          if (userData.exists) {
            final lat = userData.data()?['lat'];
            final lng = userData.data()?['lng'];
            final status = userData.data()?['status'];

            if (status == 'แอดมิน') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const AdminHomePage(),
                ),
              );
            } else {
              if (lat != null && lng != null) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const Navigator_Page(initialIndex: 0),
                  ),
                );
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const LocationSelectionPage(),
                  ),
                );
              }
            }
=======
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
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const Home_Page(),
              ),
            );
          }
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const Home_Page(),
            ),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const Home_Page(),
          ),
        );
      }
    }
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
