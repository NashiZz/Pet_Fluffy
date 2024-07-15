// ignore_for_file: camel_case_types

import 'package:Pet_Fluffy/features/page/home.dart';
import 'package:Pet_Fluffy/features/page/map_page.dart';
import 'package:Pet_Fluffy/features/page/pet_all.dart';
import 'package:Pet_Fluffy/features/page/randomMatch.dart';
import 'package:Pet_Fluffy/features/page/setting.dart';
import 'package:Pet_Fluffy/features/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

//หน้า Menu ของ App (Home,Maps,Pets,Setting)
class Navigator_Page extends StatefulWidget {
  //ตั้งตัวแปลไว้ใช้ และ รับค่ามาเพื่อเอามาใช้กำหนดค่า
  final int initialIndex;

  const Navigator_Page({Key? key, required this.initialIndex})
      : super(key: key);

  @override
  State<Navigator_Page> createState() => _NavigatorPageState();
}

class _NavigatorPageState extends State<Navigator_Page> {
  int currentIndex = 0;
  bool isAnonymousUser = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    isAnonymousUser = _authService.isAnonymous();
  }

  List<Widget> widgetOption = [
    const randomMathch_Page(),
    const Maps_Page(),
    const Pet_All_Page(),
    const Setting_Page()
  ];

  //ฟังก์ชันเช็คว่าควรแสดง NavBar หรือไม่
  bool shouldShowNavigationBar(int index) {
    return index != 3;
  }

  //ตรวจสอบว่าค่า initialIndex ถ้าเปลี่ยนแปลง ให้ปรับค่า currentIndex ตามค่าใหม่
  @override
  void didUpdateWidget(covariant Navigator_Page oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        currentIndex = widget.initialIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: widgetOption.elementAt(currentIndex),
        ),
        bottomNavigationBar: Visibility(
          visible: shouldShowNavigationBar(currentIndex),
          child: NavigationBar(
            height: 80,
            elevation: 0,
            destinations: [
              const NavigationDestination(
                  icon: Icon(Icons.home), label: 'Home'),
              const NavigationDestination(
                  icon: Icon(Icons.map_outlined), label: 'Maps'),
              const NavigationDestination(
                  icon: Icon(Icons.pets), label: 'Pets'),
              const NavigationDestination(
                  icon: Icon(Icons.settings), label: 'Setting'),
            ],
            selectedIndex: currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                // จัดการการเข้าถึงหน้าต่างๆในแถบ
                if (isAnonymousUser && index == 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('คุณต้องเข้าสู่ระบบเพื่อดูสัตว์เลี้ยง'),
                    ),
                  );
                } else {
                  currentIndex = index;
                }
              });
            },
          ),
        ),
        floatingActionButton: isAnonymousUser
            ? FloatingActionButton.extended(
                onPressed: () async {
                  // นำทางไปยังหน้าเข้าสู่ระบบหรือสมัครสมาชิก
                  User? user = FirebaseAuth.instance.currentUser;
                  try {
                    await user?.delete();
                    print("Anonymous account deleted");
                    Navigator.pushAndRemoveUntil(
                      // ignore: use_build_context_synchronously
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Home_Page()),
                      (Route<dynamic> route) => false,
                    );
                  } catch (e) {
                    print("Error deleting anonymous account: $e");
                  }
                },
                label: const Text('สมัครสมาชิก/เข้าสู่ระบบ'),
                icon: const Icon(Icons.login),
              )
            : null,
      ),
    );
  }
}
