// ignore_for_file: use_build_context_synchronously, avoid_print
import 'package:Pet_Fluffy/features/page/addData_Google.dart';
import 'package:Pet_Fluffy/features/page/adminFile/admin_home.dart';
import 'package:Pet_Fluffy/features/page/home.dart';
import 'package:Pet_Fluffy/features/page/navigator_page.dart';
import 'package:Pet_Fluffy/features/page/reset_password.dart';
import 'package:Pet_Fluffy/features/page/sign_up_page.dart';
import 'package:Pet_Fluffy/features/services/auth.dart';
import 'package:Pet_Fluffy/features/splash_screen/setting_position.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//หน้า Login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSigning = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false; // สถานะการมองเห็นรหัสผ่าน

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
              (route) => false,
            );
          },
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: 15, vertical: size.height * 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "เข้าสู่ระบบ",
                  style: TextStyle(fontSize: 40, color: Colors.black),
                ),
                const SizedBox(height: 30),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "อีเมล/ชื่อผู้ใช้",
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 15),
                      prefixIcon:
                          Icon(Icons.email_outlined, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible, // ซ่อนรหัสผ่านตามสถานะ
                    decoration: InputDecoration(
                      labelText: "รหัสผ่าน",
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 15),
                      prefixIcon:
                          Icon(Icons.lock_outline_rounded, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible =
                                !_isPasswordVisible; // สลับสถานะการมองเห็นรหัสผ่าน
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                forgetPassword(context),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    _signIn();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    backgroundColor:
                        Colors.blue, // ตั้งค่าสีพื้นหลังของปุ่มเป็นสีฟ้า
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          20), // ปรับรูปร่างของปุ่มเป็นรูปวงกลม
                    ),
                  ),
                  child: Center(
                    child: _isSigning
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "เข้าสู่ระบบ",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Divider(color: Colors.grey, thickness: 2),
                      ),
                    ),
                    const Text("OR",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Divider(color: Colors.grey, thickness: 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    signInwithGoogle();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: _isSigning
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/icon/google.svg', // เปลี่ยนเป็นที่อยู่ไฟล์ SVG ของคุณ
                                color: Colors.white,
                                height: 32,
                              ),
                              const SizedBox(
                                  width: 10), // ระยะห่างระหว่างไอคอนและข้อความ
                              const Text(
                                "เข้าสู่ระบบด้วย Google",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _signInAnonymously();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    backgroundColor:
                        Colors.deepPurple, // ตั้งค่าสีพื้นหลังของปุ่มเป็นสีฟ้า
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          20), // ปรับรูปร่างของปุ่มเป็นรูปวงกลม
                    ),
                  ),
                  child: Center(
                    child: _isSigning
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/icon/incognito-circle.svg', // เปลี่ยนเป็นที่อยู่ไฟล์ SVG ของคุณ
                                color: Colors.white,
                                height: 32,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "เข้าสู่ระบบด้วยบัญชีผู้เยี่ยมชม",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("คุณยังไม่มีบัญชี?",
                        style: TextStyle(fontSize: 16)),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "  สมัครสมาชิก",
                        style: TextStyle(color: Colors.blue, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
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
            ),
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
          // เช็คว่าผู้ใช้มีข้อมูลในระบบหรือไม่
          QuerySnapshot getPetQuerySnapshot = await FirebaseFirestore.instance
              .collection('user')
              .where('uid', isEqualTo: user.uid)
              .get();

          if (getPetQuerySnapshot.docs.isNotEmpty) {
            // ตรวจสอบสถานะของผู้ใช้
            DocumentSnapshot userDoc = getPetQuerySnapshot.docs.first;
            String status = userDoc['status'] ?? '';

            if (status == 'แอดมิน') {
              // หากเป็นผู้ดูแลระบบ
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('เข้าสู่ระบบ แอดมิน สำเร็จ')),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AdminHomePage(), // หน้าแรกสำหรับผู้ดูแลระบบ
                ),
              );
            } else if (status == 'สมาชิก') {
              // หากเป็นสมาชิก
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('เข้าสู่ระบบด้วย Google สำเร็จ')),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationSelectionPage(),
                ),
              );
            } else {
              // หากไม่มีข้อมูลในระบบ
              Map<String, dynamic> userData = {
                'uid': user.uid,
                'email': user.email,
                'password': '', // คุณอาจต้องเพิ่มข้อมูลนี้ตามที่ต้องการ
                'username': user.displayName,
                'fullname': '', // คุณอาจต้องเพิ่มข้อมูลนี้ตามที่ต้องการ
                'image': user.photoURL != null
                    ? await _authService.convertImageToBase64(user.photoURL!)
                    : null,
              };

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('สมัครสมาชิกด้วย Google สำเร็จ')),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => addDataGoogle_Page(userData: userData),
                ),
              );
            }
          } else {
            // หากไม่มีข้อมูลในระบบ
            Map<String, dynamic> userData = {
              'uid': user.uid,
              'email': user.email,
              'password': '', // คุณอาจต้องเพิ่มข้อมูลนี้ตามที่ต้องการ
              'username': user.displayName,
              'fullname': '', // คุณอาจต้องเพิ่มข้อมูลนี้ตามที่ต้องการ
              'image': user.photoURL != null
                  ? await _authService.convertImageToBase64(user.photoURL!)
                  : null,
            };

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('สมัครสมาชิกด้วย Google สำเร็จ')),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => addDataGoogle_Page(userData: userData),
              ),
            );
          }
        } catch (e) {
          print('Error: $e');
        }
      } else {
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

    // ดึงค่าอีเมลหรือชื่อผู้ใช้ และรหัสผ่านจากตัวควบคุม
    String emailOrUsername = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // ตรวจสอบว่าผู้ใช้กรอกข้อมูลทั้งสองช่องหรือไม่
    if (emailOrUsername.isEmpty || password.isEmpty) {
      setState(() {
        _isSigning = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกอีเมล/ชื่อผู้ใช้และรหัสผ่าน'),
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

    bool isEmail = emailRegex.hasMatch(emailOrUsername);

    try {
      User? user;
      if (isEmail) {
        // เข้าสู่ระบบด้วยอีเมลและรหัสผ่าน
        user = await _authService.signInWithEmailAndPassword(
            emailOrUsername, password);
      } else {
        // เข้าสู่ระบบด้วยชื่อผู้ใช้และรหัสผ่าน
        user = await _authService.signInWithUsernameAndPassword(
            emailOrUsername, password);
      }

      setState(() {
        _isSigning = false;
        _isLoading = false;
      });

      // ตรวจสอบการเข้าสู่ระบบ
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
            content: Text('อีเมล/ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง'),
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
          "ลืมรหัสผ่าน ?",
          style: TextStyle(fontSize: 16),
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
