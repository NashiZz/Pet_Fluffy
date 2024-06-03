// ignore_for_file: avoid_print, camel_case_types

import 'dart:convert';

import 'package:Pet_Fluffy/features/page/edit_pwd.dart';
import 'package:Pet_Fluffy/features/page/faverite_page.dart';
import 'package:Pet_Fluffy/features/page/owner_pet/profile_user.dart';
import 'package:Pet_Fluffy/features/page/login_page.dart';
import 'package:Pet_Fluffy/features/page/navigator_page.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
// import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

//หน้า Menu Setting ใน App
class Setting_Page extends StatefulWidget {
  const Setting_Page({super.key});

  @override
  State<Setting_Page> createState() => _Setting_PageState();
}

class _Setting_PageState extends State<Setting_Page> {
  late String userId;
  late String userName;
  late String userEmail;
  late String userImageBase64;
  late String? petId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // เรียกใช้เมธอดเพื่อดึงข้อมูลของผู้ใช้จาก Firestore
    _getUserDataFromFirestore();
  }

  //ดึงข้อมูลของผู้ใช้จาก Firestore
  Future<void> _getUserDataFromFirestore() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      userId = userData.uid;
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        petId = prefs.getString(userId);

        print('$petId');
        // ระบุคอลเลคชันที่จะใช้ใน Firestore
        DocumentSnapshot userDocSnapshot = await FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .get();

        // ดึงข้อมูลผู้ใช้จาก Snapshot
        userName = userDocSnapshot['username'];
        userEmail = userDocSnapshot['email'];
        userImageBase64 = userDocSnapshot['photoURL'] ?? '';

        // อัปเดตสถานะของ State
        setState(() {
          isLoading = false;
        });
      } catch (e) {
        print('Error getting user data from Firestore: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {}, icon: const Icon(LineAwesomeIcons.cog)),
        title: Text("การตั้งค่า",
            style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          IconButton(
              onPressed: () {
                // ส่งไปยังหน้า Navigator Page พร้อมกับ index ที่ 0 เพื่อไปยังหน้าแรกของ Navigator Page ที่ Set ไว้
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) =>
                        const Navigator_Page(initialIndex: 0)));
              },
              icon: const Icon(LineAwesomeIcons.times))
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(50),
          child: isLoading // ตรวจสอบสถานะการโหลดเพื่อแสดง UI ขณะโหลด
              ? const CircularProgressIndicator() // แสดง Indicator ขณะโหลด
              : Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: Image.memory(
                          base64Decode(userImageBase64),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      userEmail,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const Profile_user_Page()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 49, 42, 42),
                            side: BorderSide.none,
                            shape: const StadiumBorder()),
                        child: const Text("ข้อมูลโปรไฟล์เจ้าของ",
                            style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255))),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),
                    MenuWidget(
                      title: "โปรไฟล์สัตว์เลี้ยง",
                      icon: LineAwesomeIcons.dog,
                      onPress: () {
                        if (petId != '') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Profile_pet_Page(petId: petId.toString()),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    MenuWidget(
                      title: "สัตว์เลี้ยงของฉัน",
                      icon: LineAwesomeIcons.paw,
                      onPress: () {},
                    ),
                    const SizedBox(height: 10),
                    MenuWidget(
                      title: "สัตว์เลี้ยงรายการโปรด",
                      icon: LineAwesomeIcons.gratipay__gittip_,
                      onPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const FaveritePage()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    MenuWidget(
                      title: "ตั้งค่ารหัสผ่าน",
                      icon: LineAwesomeIcons.lock,
                      onPress: () {
                        Get.to(() => const EditPassPage());
                      },
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 30),
                    MenuWidget(
                      title: "ออกจากระบบ",
                      icon: LineAwesomeIcons.alternate_sign_out,
                      textColor: Colors.red,
                      endIcon: false,
                      onPress: () async {
                        await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("ออกจากระบบ"),
                              content:
                                  const Text("คุณต้องการออกจากระบบหรือไม่?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // ปิด Popup
                                  },
                                  child: const Text("ยกเลิก"),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await GoogleSignIn().signOut();
                                    FirebaseAuth.instance.signOut();
                                    print("Sign Out Success!!");
                                    Navigator.pushAndRemoveUntil(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage()),
                                      (Route<dynamic> route) => false,
                                    );
                                  },
                                  child: const Text("ตกลง"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class MenuWidget extends StatelessWidget {
  const MenuWidget({
    Key? key,
    required this.title,
    required this.icon,
    required this.onPress,
    this.endIcon = true,
    this.textColor,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final VoidCallback onPress;
  final bool endIcon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPress,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: const Color.fromARGB(255, 49, 42, 42).withOpacity(0.1),
        ),
        child: Icon(icon, color: const Color.fromARGB(255, 49, 42, 42)),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.apply(color: textColor),
      ),
      trailing: endIcon
          ? Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.grey.withOpacity(0.1),
              ),
              child: const Icon(LineAwesomeIcons.angle_left,
                  size: 18.0, color: Colors.grey),
            )
          : null,
    );
  }
}
