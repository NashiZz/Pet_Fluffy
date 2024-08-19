import 'dart:convert';
import 'package:Pet_Fluffy/features/page/edit_pwd.dart';
import 'package:Pet_Fluffy/features/page/faverite_page.dart';
<<<<<<< HEAD
<<<<<<< HEAD
import 'package:Pet_Fluffy/features/page/navigator_page.dart';
import 'package:Pet_Fluffy/features/page/owner_pet/profile_user.dart';
import 'package:Pet_Fluffy/features/page/login_page.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
import 'package:Pet_Fluffy/features/page/pet_all_two.dart';
=======
import 'package:Pet_Fluffy/features/page/owner_pet/profile_user.dart';
import 'package:Pet_Fluffy/features/page/login_page.dart';
import 'package:Pet_Fluffy/features/page/navigator_page.dart';
// import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
=======
import 'package:Pet_Fluffy/features/page/navigator_page.dart';
import 'package:Pet_Fluffy/features/page/owner_pet/profile_user.dart';
import 'package:Pet_Fluffy/features/page/login_page.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
import 'package:Pet_Fluffy/features/page/pet_all_two.dart';
>>>>>>> 2a5cb27f872fa17288e57765bbe50a931c73953a
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

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
  late String petId;
  bool isLoading = true;
  bool isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _getUserDataFromFirestore();
  }

  Future<void> _getUserDataFromFirestore() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      userId = userData.uid;
<<<<<<< HEAD
<<<<<<< HEAD
      isAnonymous = userData.isAnonymous;
      if (isAnonymous) {
=======
      try {
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
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
=======
      isAnonymous = userData.isAnonymous;
      if (isAnonymous) {
>>>>>>> 2a5cb27f872fa17288e57765bbe50a931c73953a
        setState(() {
          userName = 'บัญชีผู้เยี่ยมชม';
          userEmail = '';
          userImageBase64 = ''; // หรือคุณอาจจะใช้รูปภาพ default ที่คุณต้องการ
          isLoading = false;
        });
      } else {
        try {
          DocumentSnapshot userDocSnapshot = await FirebaseFirestore.instance
              .collection('user')
              .doc(userId)
              .get();

          userName = userDocSnapshot['username'];
          userEmail = userDocSnapshot['email'];
          userImageBase64 = userDocSnapshot['photoURL'] ?? '';

          DocumentSnapshot petDocSnapshot = await FirebaseFirestore.instance
              .collection('Usage_pet')
              .doc(userId)
              .get();

          petId = petDocSnapshot['pet_id'];

          setState(() {
            isLoading = false;
          });
        } catch (e) {
          print('Error getting user data from Firestore: $e');
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: Icon(
          LineAwesomeIcons.cog,
          color: Colors.black, // ตั้งสีของไอคอนได้ที่นี่
        ),
        title: Text("การตั้งค่า",
            style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => Navigator_Page(initialIndex: 0)),
                (route) => false,
              );
            },
            icon: const Icon(LineAwesomeIcons.times),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(35),
          child: isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('กำลังโหลดข้อมูล'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    CircleAvatar(
                      radius: size.width * 0.15,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: isAnonymous
                            ? Image.asset(
                                'assets/images/user-286-512.png',
                                width: size.width * 0.3,
                                height: size.width * 0.3,
                                fit: BoxFit.cover,
                              )
                            : Image.memory(
                                base64Decode(userImageBase64),
                                width: size.width * 0.3,
                                height: size.width * 0.3,
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
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 2a5cb27f872fa17288e57765bbe50a931c73953a
                    if (!isAnonymous)
                      Column(
                        children: [
                          SizedBox(
                            width: size.width * 0.5,
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
                              child: const Text(
                                "ข้อมูลโปรไฟล์เจ้าของ",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
<<<<<<< HEAD
=======
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Profile_user_Page()),
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
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
=======
>>>>>>> 2a5cb27f872fa17288e57765bbe50a931c73953a
                      ),
                    const Divider(),
                    const SizedBox(height: 10),
                    MenuWidget(
                      title: "โปรไฟล์สัตว์เลี้ยง",
                      icon: LineAwesomeIcons.dog,
                      onPress: () {
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 2a5cb27f872fa17288e57765bbe50a931c73953a
                        if (petId.isEmpty) {
                          // แสดงข้อความเตือนเมื่อ petId เป็นค่าว่าง
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              Future.delayed(const Duration(seconds: 3), () {
                                Navigator.of(context)
                                    .pop(true); // ปิดไดอะล็อกหลังจาก 1 วินาที
                              });
                              return AlertDialog(
                                title: Column(
                                  children: [
                                    const Icon(Icons.pets_rounded,
                                        color: Colors.deepPurple, size: 50),
                                    SizedBox(height: 20),
                                    Text(
                                      'กรุณาเลือกสัตว์เลี้ยงตัวหลักก่อนที่จะเข้าถึงโปรไฟล์สัตว์เลี้ยง',
                                      style: TextStyle(fontSize: 18),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Profile_pet_Page(petId: petId),
                            ),
                          );
                        }
<<<<<<< HEAD
=======
                        
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
=======
>>>>>>> 2a5cb27f872fa17288e57765bbe50a931c73953a
                      },
                      isAnonymous: isAnonymous,
                    ),
                    const SizedBox(height: 10),
                    MenuWidget(
                      title: "สัตว์เลี้ยงของฉัน",
                      icon: LineAwesomeIcons.paw,
                      onPress: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PetAllTwo()));
                      },
                      isAnonymous: isAnonymous,
                    ),
                    const SizedBox(height: 10),
                    MenuWidget(
                      title: "สัตว์เลี้ยงรายการโปรด",
<<<<<<< HEAD
<<<<<<< HEAD
                      icon: LineAwesomeIcons.star,
=======
                      icon: LineAwesomeIcons.gratipay__gittip_,
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
=======
                      icon: LineAwesomeIcons.star,
>>>>>>> 2a5cb27f872fa17288e57765bbe50a931c73953a
                      onPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const FaveritePage()),
                        );
                      },
<<<<<<< HEAD
<<<<<<< HEAD
                      isAnonymous: isAnonymous,
=======
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
=======
                      isAnonymous: isAnonymous,
>>>>>>> 2a5cb27f872fa17288e57765bbe50a931c73953a
                    ),
                    const SizedBox(height: 10),
                    MenuWidget(
                      title: "ตั้งค่ารหัสผ่าน",
                      icon: LineAwesomeIcons.lock,
                      onPress: () {
                        Get.to(() => const EditPassPage());
                      },
                      isAnonymous: isAnonymous,
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),
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
                                    User? user =
                                        FirebaseAuth.instance.currentUser;
                                    if (user != null && user.isAnonymous) {
                                      // ลบบัญชี anonymous
                                      try {
                                        await user.delete();
                                        print("Anonymous account deleted");
                                      } catch (e) {
                                        print(
                                            "Error deleting anonymous account: $e");
                                      }
                                    } else {
                                      await GoogleSignIn().signOut();
                                    }
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
    this.isAnonymous = false,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final VoidCallback onPress;
  final bool endIcon;
  final Color? textColor;
  final bool isAnonymous;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: isAnonymous
          ? () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("ต้องสมัครสมาชิกก่อน"),
                    content:
                        const Text("กรุณาสมัครสมาชิกก่อนเพื่อเข้าถึงเมนูนี้"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // ปิด Popup
                        },
                        child: const Text("ตกลง"),
                      ),
                    ],
                  );
                },
              );
            }
          : onPress,
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
              child: const Icon(LineAwesomeIcons.angle_right,
                  size: 18.0, color: Colors.grey),
            )
          : null,
    );
  }
}
