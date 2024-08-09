import 'package:Pet_Fluffy/features/page/login_page.dart';
import 'package:Pet_Fluffy/features/widgets/form_container_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//หน้าลืมรหัสผ่าน Login
class ResetPwd extends StatefulWidget {
  const ResetPwd({Key? key}) : super(key: key);

  @override
  State<ResetPwd> createState() => _ResetPwdState();
}

class _ResetPwdState extends State<ResetPwd> {
  final TextEditingController _emailController = TextEditingController();

  bool isSigningUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future passwordReset() async {
    try {
      //ส่งอีเมลการรีเซ็ตรหัสผ่านไปยังอีเมลที่ผู้ใช้ป้อน
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      showDialog(
        context: context,
        builder: (BuildContext context) {
          Future.delayed(const Duration(seconds: 5), () {
            Navigator.of(context).pop(true); // ปิดไดอะล็อกหลังจาก 2 วินาที
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          });
          return const AlertDialog(
            title: Text('Success'),
            content: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                  'ส่งลิงค์เปลี่ยนรหัสผ่านไปให้คุณแล้ว กรุณาเข้าไปตรวจสอบที่อีเมลของคุณ'),
            ),
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      print(e);
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(content: Text(e.message.toString()));
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("รีเซ็ตรหัสผ่าน"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false);
          },
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0),
                child: Text(
                  "กู้คืนรหัสผ่าน",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              FormContainerWidget(
                controller: _emailController,
                hintText: "อีเมล",
                isPasswordField: false,
              ),
              const SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () {
                  passwordReset();
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
                              "ลืมรหัสผ่าน",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            )),
                ),
              ),
               const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("คุณจำรหัสผ่านได้แล้ว ?",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                            (route) => false);
                      },
                      child: const Text(
                        "  เข้าสู่ระบบ",
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold),
                      ))
                ],
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
