// ignore_for_file: camel_case_types

import 'package:Pet_Fluffy/features/page/map_page.dart';
import 'package:Pet_Fluffy/features/page/pet_all.dart';
import 'package:Pet_Fluffy/features/page/randomMatch.dart';
import 'package:Pet_Fluffy/features/page/setting.dart';
import 'package:flutter/material.dart';

class Navigator_Page extends StatefulWidget {
  //ตั้งตัวแปลไว้ใช้ และ รับค่ามาเพื่อเอามาใช้กำหนดค่า
  final int initialIndex;

  const Navigator_Page({Key? key, required this.initialIndex}) : super(key: key);

  @override
  State<Navigator_Page> createState() => _NavigatorPageState();
}

class _NavigatorPageState extends State<Navigator_Page> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }
  
  List widgetOption = [
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
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Maps'),
              NavigationDestination(icon: Icon(Icons.pets), label: 'Pets'),
              NavigationDestination(icon: Icon(Icons.settings), label: 'Setting'),
            ],
            selectedIndex: currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}