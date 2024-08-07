// ignore_for_file: use_build_context_synchronously, avoid_print
import 'dart:developer';

import 'package:Pet_Fluffy/features/page/adminFile/admin_home.dart';
import 'package:Pet_Fluffy/features/page/home.dart';
import 'package:Pet_Fluffy/features/page/navigator_page.dart';
import 'package:Pet_Fluffy/features/page/reset_password.dart';
import 'package:Pet_Fluffy/features/page/sign_up_page.dart';
import 'package:Pet_Fluffy/features/services/auth.dart';
import 'package:Pet_Fluffy/features/splash_screen/setting_position.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:line_awesome_flutter/line_awesome_flutter.dart';

//หน้า Login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSigning = false;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  //ทำการลบตัวควบคุม หลังจากใช้งานเสร็จ เพื่อป้องกันการรั่วไหลของทรัพยากร
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Home_Page()),
                (route) => false);
          },
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              width: size.width,
              height: size.height,
              padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "เข้าสู่ระบบ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: Colors.black,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.grey),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            hintText: "อีเมล์",
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.grey),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            hintText: "รหัสผ่าน",
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 15),
                          ),
                        ),
                      ),
                      forgetPassword(context),
                      const SizedBox(height: 50),
                      ElevatedButton(
                        onPressed: () {
                          _signIn();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          backgroundColor:
                              Colors.blue, // ตั้งค่าสีพื้นหลังของปุ่มเป็นสีฟ้า
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                30), // ปรับรูปร่างของปุ่มเป็นรูปวงกลม
                          ),
                        ),
                        child: Center(
                          child: _isSigning
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "เข้าสู่ระบบ",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Divider(
                                color: Colors.grey,
                                thickness: 2,
                              ),
                            ),
                          ),
                          const Text(
                            "OR",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Divider(
                                color: Colors.grey,
                                thickness: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          signInwithGoogle();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          backgroundColor:
                              const Color.fromARGB(255, 228, 216, 216),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Center(
                          child: _isSigning
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LineAwesomeIcons.gofore,
                                      size: 32,
                                    ),
                                    SizedBox(
                                        width:
                                            10), // เพิ่มระยะห่างระหว่างไอคอนและข้อความ
                                    Text(
                                      "เข้าสู่ระบบด้วย Google",
                                      style: TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _signInAnonymously();
                            },
                            child: const Text(
                              "เข้าสู่ระบบโดยบัญชี Guest",
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("คุณยังไม่มีบัญชี?",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          GestureDetector(
                              onTap: () {
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const SignUpPage()),
                                    (route) => false);
                              },
                              child: const Text(
                                "  สมัครสมาชิก",
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold),
                              ))
                        ],
                      ),
                      const SizedBox(height: 10)
                    ],
                  )
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    Text('กำลังโหลดข้อมูล เพื่อเข้าสู่ระบบ....')
                  ],
                ), // แสดงหน้าโหลด
              ),
            )
        ],
      ),
    );
  }

  void _signInAnonymously() async {
    setState(() {
      _isSigning = true;
    });

    User? user = await _authService.signInAnonymously();

    setState(() {
      _isSigning = false;
    });

    if (user != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => Navigator_Page(initialIndex: 0)),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เข้าสู่ระบบแบบไม่สมัครสมาชิกไม่สำเร็จ'),
        ),
      );
    }
  }

  // เข้าสู่ระบบ และ สมัครสมาชิกด้วย Google
  Future<void> signInwithGoogle() async {
    setState(() {
      _isSigning = true;
      _isLoading = true;
    });

    try {
      User? user = await _authService.signInWithGoogle();
      setState(() {
        _isSigning = false;
        _isLoading = false;
      });

      if (user != null) {
        try {
          QuerySnapshot getPetQuerySnapshot = await FirebaseFirestore.instance
              .collection('user')
              .where('uid', isEqualTo: user.uid)
              .where('status', isEqualTo: 'สมาชิก')
              .get();
          if (getPetQuerySnapshot.docs.isNotEmpty) {
            log(getPetQuerySnapshot.docs.isEmpty.toString());

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const LocationSelectionPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomePage()),
            );
          }
        } catch (e) {
          print('Error: $e');
        }
      } else {
        // Handle case when user is null
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sign in with Google')),
        );
      }
    } catch (e) {
      setState(() {
        _isSigning = false;
        _isLoading = false;
      });
      print("Error signing in with Google: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเข้าสู่ระบบด้วย Google')),
      );
    }
  }

  // เข้าสู่ระบบด้วย email password
  void _signIn() async {
    setState(() {
      _isSigning = true;
      _isLoading = true;
    });

    // ดึงค่าอีเมลและรหัสผ่านจากตัวควบคุม
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // ตรวจสอบว่าผู้ใช้กรอกข้อมูลทั้งสองช่องหรือไม่
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isSigning = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกอีเมลและรหัสผ่าน'),
        ),
      );
      return;
    }

    // เช็ครูปแบบของอีเมล
    RegExp emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      caseSensitive: false,
      multiLine: false,
    );

    if (!emailRegex.hasMatch(email)) {
      // หากรูปแบบของอีเมลไม่ถูกต้อง
      setState(() {
        _isSigning = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รูปแบบของอีเมลไม่ถูกต้อง'),
        ),
      );
      return;
    }

    try {
      //เข้าสู่ระบบด้วยอีเมลและรหัสผ่านที่ดึงมาจากฟอร์ม
      User? user =
          await _authService.signInWithEmailAndPassword(email, password);

      setState(() {
        _isSigning = false;
        _isLoading = false;
      });

      //ตรวจสอบการเข้าสู่ระบบ
      if (user != null) {
        // ตรวจสอบว่าอีเมลได้รับการยืนยันหรือไม่
        if (user.emailVerified) {
          print("User is Successfully sign-in");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const LocationSelectionPage()),
          );
        } else {
          // หากอีเมลยังไม่ได้รับการยืนยัน
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('โปรดยืนยันอีเมลก่อนเข้าสู่ระบบ'),
            ),
          );
        }
      } else {
        // หากไม่สามารถเข้าสู่ระบบได้ เช่นรหัสผ่านไม่ถูกต้อง
        setState(() {
          _isSigning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง'),
          ),
        );
      }
    } catch (error) {
      print("Error signing in: $error");
      setState(() {
        _isSigning = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเข้าสู่ระบบ'),
        ),
      );
    }
  }

  Widget forgetPassword(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 35,
      alignment: Alignment.bottomRight,
      child: TextButton(
        child: const Text(
          "ลืมรหัสผ่าน?",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        onPressed: () {
          Get.to(() => const ResetPwd());
        },
      ),
    );
  }
}

class AppColor {
  static Color textColor = const Color(0xff9C9C9D);
  static Color textColorDark = const Color(0xffffffff);

  static Color bodyColor = const Color(0xffffffff);
  static Color bodyColorDark = const Color(0xff0E0E0F);

  static Color buttonBackgroundColor = const Color(0xffF7F7F7);
  static Color buttonBackgroundColorDark =
      const Color.fromARGB(255, 39, 36, 36);
}
