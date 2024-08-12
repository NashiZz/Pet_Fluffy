// ignore_for_file: unnecessary_null_comparison, camel_case_types, avoid_print, no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

//หน้า แก้ไขข้อมูลผู้ใช้ปัจจุบัน
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

  String? _selectedCounty;
  String? _selectedGender;
  List<String> _county = [];
  final List<String> _gender = ['ชาย', 'หญิง', 'อื่นๆ'];

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

          _selectedGender = userDocSnapshot['gender'];
          String? countyFromFirestore = userDocSnapshot['county'];
          if (countyFromFirestore != null &&
              _county.contains(countyFromFirestore)) {
            _selectedCounty = countyFromFirestore;
          } else {
            _selectedCounty = null;
          }
        });
      } catch (e) {
        print('Error getting user data from Firestore: $e');
      }
    }
  }

  // ฟังก์ชันสำหรับโหลดข้อมูลจังหวัดจากไฟล์ JSON
  Future<void> _loadCounties() async {
    try {
      final String response =
          await rootBundle.loadString('assets/counties.json');
      final data = json.decode(response) as Map<String, dynamic>;
      List<String> countiesFromJson = List<String>.from(data['counties'] ?? []);
      // ลบค่าซ้ำจากรายการ
      _county = countiesFromJson.toSet().toList();
      setState(() {});
      print('Counties loaded: $_county'); // ตรวจสอบค่าที่โหลดได้
    } catch (e) {
      print('Error loading counties: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCounties().then((_) {
      _getUserDataFromFirestore();
      if (_county.isNotEmpty) {
        _selectedCounty =
            _county.contains(_selectedCounty) ? _selectedCounty : _county[0];
      }
    });
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
                const SizedBox(
                  height: 30,
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 15),
                    labelText: "ชื่อ - นามสกุล",
                    prefixIcon: Icon(LineAwesomeIcons
                        .identification_card), // เพิ่มไอคอนที่ต้องการ
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกชื่อ-นามสกุล';
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  style: const TextStyle(fontSize: 14),
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อเล่น',
                    prefixIcon: Icon(LineAwesomeIcons.identification_badge),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 15),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  items: _gender.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'เพศ',
                    prefixIcon: Icon(LineAwesomeIcons.venus_mars),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 15),
                  ),
                  validator: (value) {
                    if (value == null) {
                      return 'กรุณาเลือกเพศ';
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedCounty,
                  items: _county
                      .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      })
                      .toSet()
                      .toList(), // ลบค่าซ้ำใน items
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCounty = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'จังหวัด',
                    prefixIcon: Icon(LineAwesomeIcons.map_marked),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 15),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  style: const TextStyle(fontSize: 14),
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: InputDecoration(
                    labelText: 'เบอร์โทรศัพท์',
                    prefixIcon: Icon(LineAwesomeIcons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกเบอร์โทรศัพท์';
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  style: const TextStyle(fontSize: 14),
                  controller: _facebookController,
                  decoration: InputDecoration(
                    labelText: 'Facebook',
                    prefixIcon: Icon(LineAwesomeIcons.facebook),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอก Facebook';
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  style: const TextStyle(fontSize: 14),
                  controller: _lineController,
                  decoration: InputDecoration(
                    labelText: 'Line',
                    prefixIcon: Icon(LineAwesomeIcons.line),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอก Line';
                    }
                    return null;
                  },
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
