// ignore_for_file: unnecessary_null_comparison, avoid_print, use_build_context_synchronously, no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:io';

import 'package:Pet_Fluffy/features/page/email_verifly.dart';
import 'package:Pet_Fluffy/features/page/home.dart';
import 'package:Pet_Fluffy/features/page/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  static const String tempUserImageUrl =
      "https://i.pinimg.com/564x/51/f6/fb/51f6fb256629fc755b8870c801092942.jpg";
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _compasswordController = TextEditingController();

  bool isSigningUp = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _compasswordController.dispose();
    super.dispose();
  }

  Uint8List? _image;

  void selectImage() async {
    Uint8List? img = await pickImage(ImageSource.gallery);
    setState(() {
      _image = img;
    });
  }

  String uint8ListToBase64(Uint8List data) {
    return base64Encode(data);
  }

  Future<bool> _checkDuplicateEmail(String email) async {
    try {
      // เรียกใช้งานเมธอด fetchSignInMethodsForEmail() เพื่อตรวจสอบว่ามีวิธีการเข้าสู่ระบบที่เชื่อมโยงกับอีเมลที่ให้ไว้หรือไม่
      List<String> signInMethods =
          // ignore: deprecated_member_use
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty;
    } catch (e) {
      print('Error checking duplicate email: $e');
      return false;
    }
  }

  bool _isPasswordMatched() {
    return _passwordController.text == _compasswordController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("สมัครสมาชิก"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menu Icon',
          onPressed: () {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Home_Page()),
                (route) => false);
          },
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    _image != null
                        ? CircleAvatar(
                            radius: 64,
                            backgroundImage: MemoryImage(_image!),
                          )
                        : const CircleAvatar(
                            radius: 64,
                            backgroundImage: NetworkImage(tempUserImageUrl),
                          ),
                    Positioned(
                      bottom: -10,
                      left: 80,
                      child: IconButton(
                        onPressed: selectImage,
                        icon: const Icon(Icons.add_a_photo),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColorLight,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(20))),
                  child: TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "ชื่อผู้ใช้",
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColorLight,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(20))),
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "ชื่อ - นามสกุล",
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColorLight,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(20))),
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "อีเมล",
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColorLight,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(20))),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "รหัสผ่าน",
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColorLight,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(20))),
                  child: TextField(
                    controller: _compasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "ยืนยันรหัสผ่าน",
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                GestureDetector(
                  onTap: () {
                    _signUp();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                        child: isSigningUp
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "สมัครสมาชิก",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              )),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("คุณมีบัญชีอยู่แล้ว?"),
                    const SizedBox(
                      width: 5,
                    ),
                    GestureDetector(
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                              (route) => false);
                        },
                        child: const Text(
                          "เข้าสู่ระบบ",
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
                        ))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    setState(() {
      isSigningUp = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    if (password.length < 6) {
      setState(() {
        isSigningUp = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัว'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // สร้างบัญชีผู้ใช้ใหม่ด้วยอีเมลและรหัสผ่านที่ดึงมาจากฟอร์ม
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // ส่งอีเมลยืนยันไปยังผู้ใช้
      await userCredential.user?.sendEmailVerification();

      setState(() {
        isSigningUp = false;
      });

      // แสดงข้อความหรือ UI ที่เตือนผู้ใช้ให้ยืนยันอีเมล
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('กรุณายืนยันอีเมลของคุณโดยเปิดอีเมลและคลิกที่ลิงก์ยืนยัน'),
          backgroundColor: Colors.green,
        ),
      );
      
      // คุณสามารถบันทึกข้อมูลลงใน Firestore ตามปกติได้
      await saveUserDataToFirestore(userCredential.user!.uid);

      // เช็คการสร้างบัญชีผู้ใช้
      if (userCredential.user != null) {
        print("User is Successfully created");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EmailVerifly_Page()),
        );
      }
    } catch (error) {
      print("Error creating user: $error");
      setState(() {
        isSigningUp = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการสร้างบัญชีผู้ใช้'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> saveUserDataToFirestore(String userId) async {
    String username = _usernameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;
    String name = _nameController.text;
    String img = uint8ListToBase64(_image!);

    DocumentReference userRef =
        FirebaseFirestore.instance.collection('user').doc(userId);

    await userRef.set({
      'uid': userId,
      'username': username,
      'fullname': name,
      'email': email,
      'password': password,
      'photoURL': img,
      'phone': '',
      'nickname': '',
      'gender': '',
      'birtdate': '',
      'country': '',
      'facebook': '',
      'line': ''
    }).then((_) {
      print("User data added to Firestore");
    }).catchError((error) {
      print("Failed to add user data: $error");
    });
  }

  Future<Uint8List?> pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      return await file.readAsBytes();
    } else {
      return null;
    }
  }
}
