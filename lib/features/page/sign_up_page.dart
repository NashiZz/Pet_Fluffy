// ignore_for_file: unnecessary_null_comparison, avoid_print, use_build_context_synchronously, no_leading_underscores_for_local_identifiers

import 'package:Pet_Fluffy/features/page/email_verifly.dart';
import 'package:Pet_Fluffy/features/page/home.dart';
import 'package:Pet_Fluffy/features/page/login_page.dart';
import 'package:Pet_Fluffy/features/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';

//หน้า การสมัครสมาชิก
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

  final AuthService _authService = AuthService();
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

  //Select Img
  Uint8List? _image;

  void selectImage() async {
    Uint8List? img = await _authService.pickImage(ImageSource.gallery);
    setState(() {
      _image = img;
    });
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
    String compass = _compasswordController.text;

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

    if (password != compass) {
      setState(() {
        isSigningUp = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสผ่านและการยืนยันรหัสผ่านไม่ตรงกัน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool emailExists = await _authService.checkDuplicateEmail(email);
    if (emailExists) {
      setState(() {
        isSigningUp = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อีเมลนี้มีผู้ใช้งานแล้ว'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // สร้างบัญชีผู้ใช้ใหม่ด้วยอีเมลและรหัสผ่านที่ดึงมาจากฟอร์ม
      UserCredential? userCredential =
          await _authService.signUp(email, password);

      if (userCredential == null) {
        setState(() {
          isSigningUp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการสร้างบัญชีผู้ใช้'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _authService.saveUserDataToFirestore(
        userCredential.user!.uid,
        _usernameController.text,
        _nameController.text,
        email,
        password,
        _image,
      );

      setState(() {
        isSigningUp = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('กรุณายืนยันอีเมลของคุณโดยเปิดอีเมลและคลิกที่ลิงก์ยืนยัน'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EmailVerifly_Page()),
      );
    } catch (error) {
      print("Error creating user: $error");
      setState(() {
        isSigningUp = false;
      });
    }
  }
}
