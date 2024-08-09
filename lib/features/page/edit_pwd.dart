import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditPassPage extends StatefulWidget {
  const EditPassPage({Key? key}) : super(key: key);

  @override
  State<EditPassPage> createState() => _EditPassPageState();
}

class _EditPassPageState extends State<EditPassPage> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool isSigningUp = false;

  // Future<void> _changePassword() async {
  //   String newPassword = _newPasswordController.text.trim();
  //   String confirmPassword = _confirmPasswordController.text.trim();
  //   String currentPassword = _currentPasswordController.text.trim();

  //   if (newPassword != confirmPassword) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('รหัสผ่านใหม่และการยืนยันรหัสผ่านไม่ตรงกัน'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }

  //   if (newPassword.length < 6) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('รหัสผ่านใหม่ต้องมีความยาวอย่างน้อย 6 ตัวอักษร'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }

  //   setState(() {
  //     isSigningUp = true;
  //   });

  //   try {
  //     User? user = FirebaseAuth.instance.currentUser;

  //     if (user == null || user.email == null) {
  //       throw Exception('ไม่พบข้อมูลผู้ใช้');
  //     }

  //     // รีออธิเคทผู้ใช้
  //     AuthCredential credential = EmailAuthProvider.credential(
  //       email: user.email!,
  //       password: currentPassword,
  //     );

  //     await user.reauthenticateWithCredential(credential);

  //     // เปลี่ยนรหัสผ่าน
  //     await user.updatePassword(newPassword);

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('รหัสผ่านเปลี่ยนแปลงเรียบร้อยแล้ว'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );

  //     Navigator.pop(context);
  //   } catch (e) {
  //     print('Error changing password: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('เกิดข้อผิดพลาดในการเปลี่ยนรหัสผ่าน: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }

  //   setState(() {
  //     isSigningUp = false;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("เปลี่ยนรหัสผ่าน"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
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
                  "เปลี่ยนรหัสผ่าน",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _currentPasswordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "รหัสผ่านปัจจุบัน",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _newPasswordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "รหัสผ่านใหม่",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "ยืนยันรหัสผ่านใหม่",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {},
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
                              "บันทึก",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            )),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
