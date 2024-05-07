// ignore_for_file: unnecessary_null_comparison, camel_case_types, avoid_print, no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class Edit_Profile_Page extends StatefulWidget {
  const Edit_Profile_Page({super.key});

  @override
  State<Edit_Profile_Page> createState() => _Edit_Profile_PageState();
}

class _Edit_Profile_PageState extends State<Edit_Profile_Page> {
  static const String tempUserImageUrl =
      "https://i.pinimg.com/564x/51/f6/fb/51f6fb256629fc755b8870c801092942.jpg";
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _lineController = TextEditingController();

  bool isSigningUp = false;

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

  Future<void> _getUserDataFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDocSnapshot = await FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .get();

        // ดึงข้อมูลจาก Firestore และกำหนดค่าใน TextField Controllers
        setState(() {
          _nameController.text = userDocSnapshot['fullname'] ?? '';
          _nicknameController.text = userDocSnapshot['nickname'] ?? '';
          _genderController.text = userDocSnapshot['gender'] ?? '';
          _phoneController.text = userDocSnapshot['phone'] ?? '';
          _facebookController.text = userDocSnapshot['facebook'] ?? '';
          _lineController.text = userDocSnapshot['line'] ?? '';
          // หากมีภาพโปรไฟล์ใน Firestore ก็สามารถดึงมาแสดงได้ด้วยการ decode base64
          String? photoURL = userDocSnapshot['photoURL'];
          if (photoURL != null && photoURL.isNotEmpty) {
            _image = base64Decode(photoURL);
          }
        });
      } catch (e) {
        print('Error getting user data from Firestore: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserDataFromFirestore();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    _facebookController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("แก้ไขข้อมูลโปรไฟล์"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menu Icon',
          onPressed: () {
            Navigator.pop(context);
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
                      // ignore: sort_child_properties_last
                      child: IconButton(
                        onPressed: selectImage,
                        icon: const Icon(Icons.add_a_photo),
                      ),
                      bottom: -10,
                      left: 80,
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
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "ชื่อ-นามสกุล",
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
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "ชื่อเล่น",
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
                    controller: _genderController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "เพศ",
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
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "เบอร์มือถือ",
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
                    controller: _facebookController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Facebook",
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
                    controller: _lineController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Line",
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isSigningUp = true;
                    });
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      saveUserDataToFirestore(user.uid);
                    }
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
                                "บันทึก",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> saveUserDataToFirestore(String userId) async {
    String name = _nameController.text;
    String nickname = _nicknameController.text;
    String gender = _genderController.text;
    String phone = _phoneController.text;
    String facebook = _facebookController.text;
    String line = _lineController.text;

    String img = _image != null ? uint8ListToBase64(_image!) : '';

    DocumentReference userRef =
        FirebaseFirestore.instance.collection('user').doc(userId);

    await userRef.update({
      'fullname': name,
      'nickname': nickname,
      'gender': gender,
      'phone': phone,
      'facebook': facebook,
      'line': line,
      'photoURL': img,
    }).then((_) {
      setState(() {
        isSigningUp = false;
      });
      print("User data updated in Firestore");
      showDialog(
        context: context,
        builder: (context) {
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(); // ปิดหน้าแก้ไขโปรไฟล์
            Navigator.of(context).pop(); // กลับไปที่หน้า Profile User
          });
          return const AlertDialog(
            title: Text('Success'),
            content: Text('บันทึกข้อมูลสำเร็จ'),
          );
        },
      );
    }).catchError((error) {
      setState(() {
        isSigningUp = false;
      });
      print("Failed to update user data: $error");
      // Handle error
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
