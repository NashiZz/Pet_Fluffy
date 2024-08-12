import 'dart:convert';

import 'package:Pet_Fluffy/features/page/email_verifly.dart';
import 'package:Pet_Fluffy/features/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class addDataUser_Page extends StatefulWidget {
  final Map<String, dynamic> userData;

  const addDataUser_Page({Key? key, required this.userData}) : super(key: key);

  @override
  State<addDataUser_Page> createState() => _addDataUser_PageState();
}

class _addDataUser_PageState extends State<addDataUser_Page> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController lineController = TextEditingController();

  String? _selectedCounty;
  String? _selectedGender;
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();
  List<String> _county = []; // เริ่มต้นด้วย List เปล่า
  final List<String> _gender = ['ชาย', 'หญิง', 'อื่นๆ'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCounties(); // เรียกใช้ฟังก์ชันโหลดข้อมูลจังหวัด
  }

  // ฟังก์ชันสำหรับโหลดข้อมูลจังหวัดจากไฟล์ JSON
  Future<void> _loadCounties() async {
    try {
      // อ่านไฟล์ JSON
      final String response =
          await rootBundle.loadString('assets/counties.json');
      final data = json.decode(response);
      setState(() {
        _county = List<String>.from(data['counties']);
      });
    } catch (e) {
      print('Error loading counties: $e');
    }
  }

  // ฟังก์ชันสำหรับแสดงหน้าต่างเลือกวันที่
  void selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose(); // ล้างทรัพยากร
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "เพิ่มข้อมูลส่วนตัวผู้ใช้",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(), // แสดงสัญลักษณ์การโหลดข้อมูล
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "ข้อมูลส่วนตัว",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800]),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        style: const TextStyle(fontSize: 14),
                        controller: nicknameController,
                        decoration: InputDecoration(
                          labelText: 'ชื่อเล่น',
                          prefixIcon:
                              Icon(LineAwesomeIcons.identification_badge),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0)),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 15),
                        ),
                      ),
                      const SizedBox(height: 15),
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
                      const SizedBox(height: 15),
                      TextFormField(
                        readOnly: true,
                        controller: _dateController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'วันเกิด',
                          prefixIcon: Icon(LineAwesomeIcons.birthday_cake),
                          suffixIcon: IconButton(
                            icon: Icon(
                              LineAwesomeIcons.calendar,
                            ),
                            onPressed: () => selectDate(context),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 15,
                          ),
                        ),
                        onTap: () => selectDate(context),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณาเลือกวันเกิด';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedCounty,
                        items: _county.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
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
                      const SizedBox(height: 25),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "ข้อมูลติดต่อ",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800]),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        style: const TextStyle(fontSize: 14),
                        controller: phoneController,
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
                      const SizedBox(height: 15),
                      TextFormField(
                        style: const TextStyle(fontSize: 14),
                        controller: facebookController,
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
                      const SizedBox(height: 15),
                      TextFormField(
                        style: const TextStyle(fontSize: 14),
                        controller: lineController,
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
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () {
                          if (_formKey.currentState!.validate()) {
                            saveUserAdditionalData();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "เพิ่มข้อมูล",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18),
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

  Future<void> saveUserAdditionalData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // ดึงข้อมูลที่ส่งมาจากหน้าก่อน
      String email = widget.userData['email'];
      String password = widget.userData['password'];
      String username = widget.userData['username'];
      String fullname = widget.userData['fullname'];
      String image = widget.userData['image'] != null
          ? base64Encode(widget.userData['image'])
          : '';

      // สร้างบัญชีผู้ใช้ใน Firebase Authentication
      UserCredential? userCredential =
          await _authService.signUp(email, password);

      if (userCredential == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการสร้างบัญชีผู้ใช้'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // เรียกใช้ฟังก์ชัน saveUserDataToFirestore
      await _authService.saveUserDataToFirestore(
        userCredential.user!.uid,
        username,
        fullname,
        email,
        password,
        image,
        nicknameController.text,
        phoneController.text,
        facebookController.text,
        lineController.text,
        _selectedGender,
        _dateController.text,
        _selectedCounty,
      );

      // แสดงข้อความที่สำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ข้อมูลส่วนตัวถูกบันทึกเรียบร้อยแล้ว!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EmailVerifly_Page()),
      );
    } catch (error) {
      print("Error saving user additional data: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
