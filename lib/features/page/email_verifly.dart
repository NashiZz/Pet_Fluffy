// ignore_for_file: camel_case_types
import 'dart:async';

import 'package:Pet_Fluffy/features/page/login_page.dart';
import 'package:Pet_Fluffy/features/splash_screen/setting_position.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

//หน้า ยืนยัน email ก่อนเข้าใช้งาน app
class EmailVerifly_Page extends StatefulWidget {
  const EmailVerifly_Page({super.key});

  @override
  State<EmailVerifly_Page> createState() => _EmailVerifly_PageState();
}

class _EmailVerifly_PageState extends State<EmailVerifly_Page> {
  Timer? timer;
  late Timer _timer;
  int _start = 60;
  bool isEmailVerify = false;

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void _checkEmailVerification() async {
    await FirebaseAuth.instance.currentUser!.reload();

    setState(() {
      isEmailVerify = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (isEmailVerify) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LocationSelectionPage()),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    isEmailVerify = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerify) {
      _startTimer();
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkEmailVerification(),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkEmailVerification();
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
        child: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: Colors.white,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'ยืนยันที่อยู่อีเมลของคุณ',
                      style: TextStyle(
                          fontStyle: FontStyle.normal,
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'เราเพิ่งส่งลิงก์ยืนยันอีเมลไปที่อีเมลของคุณ โปรดตรวจสอบอีเมลและคลิกลิงก์นั้นเพื่อยืนยันที่อยู่อีเมลของคุณ',
                      style: TextStyle(
                        fontStyle: FontStyle.normal,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'หลังจากที่ผู้ใช้ ยืนยันอีเมลแล้ว จะล๊อคอินเข้าสู่ระบบให้ทันที',
                      style: TextStyle(
                        fontStyle: FontStyle.normal,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _start == 0
                        ? () async {
                            User? user = FirebaseAuth.instance.currentUser;

                            if (user != null && !user.emailVerified) {
                              try {
                                await user.sendEmailVerification();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('ส่งอีเมลยืนยันเรียบร้อยแล้ว'),
                                  ),
                                );
                                setState(() {
                                  _start = 60; // รีเซ็ตเวลาเป็น 60 วินาที
                                  _startTimer(); // เริ่มนับเวลาใหม่
                                });
                              } catch (e) {
                                print('เกิดข้อผิดพลาดในการส่งอีเมล: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('เกิดข้อผิดพลาดในการส่งอีเมล'),
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'ไม่มีผู้ใช้หรือผู้ใช้ไม่ได้ยืนยันอีเมล'),
                                ),
                              );
                            }
                          }
                        : null,
                    style: ButtonStyle(
                      minimumSize: WidgetStateProperty.all(
                          const Size(260, 40)), // กำหนดขนาดของปุ่ม
                    ),
                    child: Text(
                      _start == 0
                          ? "ส่งลิงก์อีเมลอีกครั้ง"
                          : "รอส่งลิงก์ ($_start วินาที)",
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LineAwesomeIcons.arrow_left,
                          size: 24,
                          color: Colors.white,
                        ),
                        TextButton(
                          child: const Text(
                            "กลับไปที่หน้า ล๊อคอิน",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                          onPressed: () {
                            Get.off(() => const LoginPage());
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
