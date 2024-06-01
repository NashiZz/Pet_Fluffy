// ignore_for_file: camel_case_types

import 'package:Pet_Fluffy/features/page/navigator_page.dart';
import 'package:Pet_Fluffy/features/page/pet_page.dart';
import 'package:flutter/material.dart';

//หน้า การเพิ่ม Pet ก่อนเริ่มใช้งาน App
class Setting_Pet_Page extends StatefulWidget {
  const Setting_Pet_Page({super.key});

  @override
  State<Setting_Pet_Page> createState() => _Setting_Pet_PageState();
}

class _Setting_Pet_PageState extends State<Setting_Pet_Page> {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pets,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              'คุณต้องการเพิ่มข้อมูลสัตว์เลี้ยงหรือไม่?',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Pet_Page()),
                    );
                  },
                  style: ButtonStyle(
                    minimumSize: MaterialStateProperty.all(
                        const Size(260, 40)), // กำหนดความกว้างและความสูงของปุ่ม
                  ),
                  child: const Text('เพิ่ม'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const Navigator_Page(initialIndex: 0)),
                    );
                  },
                  style: ButtonStyle(
                    minimumSize: MaterialStateProperty.all(
                        const Size(260, 40)), // กำหนดความกว้างและความสูงของปุ่ม
                  ),
                  child: const Text('ข้าม'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
