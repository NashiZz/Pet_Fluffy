// ignore_for_file: unnecessary_null_comparison, avoid_print, use_build_context_synchronously, no_leading_underscores_for_local_identifiers

import 'package:Pet_Fluffy/features/page/addDataUser.dart';
import 'package:Pet_Fluffy/features/page/home.dart';
import 'package:Pet_Fluffy/features/page/login_page.dart';
import 'package:Pet_Fluffy/features/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

//หน้า การสมัครสมาชิก
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  static const String tempUserImageUrl =
      "https://i.pinimg.com/564x/51/f6/fb/51f6fb256629fc755b8870c801092942.jpg";
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _compasswordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool isSigningUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "สมัครสมาชิก",
                    style: TextStyle(fontSize: 30),
                  ),
                  SizedBox(height: 40),
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
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: selectImage,
                              icon: const Icon(Icons.add_a_photo,
                                  color: Colors.white),
                              iconSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(
                    height: 30,
                  ),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: "ชื่อผู้ใช้",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 15),
                      counterText: '',
                      prefixIcon: Icon(
                          LineAwesomeIcons.user_circle), // เพิ่มไอคอนที่ต้องการ
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกชื่อผู้ใช้';
                      }
                      return null;
                    },
                    maxLength: 30,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 15),
                      labelText: "ชื่อ - นามสกุล",
                      counterText: '',
                      prefixIcon: Icon(LineAwesomeIcons
                          .identification_card), // เพิ่มไอคอนที่ต้องการ
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกชื่อ-นามสกุล';
                      }
                      return null;
                    },
                    maxLength: 50,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 15),
                      labelText: "อีเมล",
                      counterText: '',
                      prefixIcon: Icon(
                          LineAwesomeIcons.envelope), // เพิ่มไอคอนที่ต้องการ
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณาอีเมล';
                      }
                      return null;
                    },
                    maxLength: 40,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 15),
                      labelText: "รหัสผ่าน",
                      counterText: '',
                      prefixIcon: Icon(LineAwesomeIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรหัสผ่าน';
                      }
                      return null;
                    },
                    maxLength: 30,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: _compasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 15),
                      labelText: "ยืนยันรหัสผ่าน",
                      counterText: '',
                      prefixIcon: Icon(LineAwesomeIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: _toggleConfirmPasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกยืนยันรหัสผ่าน';
                      }
                      return null;
                    },
                    maxLength: 30,
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
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                          child: isSigningUp
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "ถัดไป",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18),
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
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          ))
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isSigningUp = true;
      });

      // ใช้ trim() เพื่อกำจัดช่องว่างที่ไม่ต้องการ
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String compass = _compasswordController.text.trim();

      // ตรวจสอบความยาวรหัสผ่านและการยืนยันรหัสผ่าน
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

      // ตรวจสอบว่าอีเมลมีการใช้งานแล้วหรือไม่
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

      // ตรวจสอบว่าผู้ใช้ได้เพิ่มรูปภาพหรือไม่
      if (_image == null) {
        setState(() {
          isSigningUp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเพิ่มรูปภาพ'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // เก็บข้อมูลที่กรอกไว้ใน shared preferences หรือ pass parameter ไปที่ addDataUser_Page
      final Map<String, dynamic> userData = {
        'email': email,
        'password': password,
        'username': _usernameController.text.trim(),
        'fullname': _nameController.text.trim(),
        'image': _image ?? '',
      };

      // ไปที่หน้ากรอกข้อมูลเพิ่มเติมโดยส่งข้อมูลที่เก็บไว้ไปด้วย
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => addDataUser_Page(userData: userData),
        ),
      );

      setState(() {
        isSigningUp = false;
      });
    }
  }
}
