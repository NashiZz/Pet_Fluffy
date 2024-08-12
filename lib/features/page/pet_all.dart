// ignore_for_file: camel_case_types, avoid_print

import 'dart:convert';

import 'package:Pet_Fluffy/features/page/pages_widgets/edit_Profile_Pet.dart';
import 'package:Pet_Fluffy/features/page/pet_page.dart';
import 'package:Pet_Fluffy/features/services/age_calculator_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

//หน้า แสดงสัตว์เลี้ยงของผู้ใช้ ใน menu
class Pet_All_Page extends StatefulWidget {
  const Pet_All_Page({Key? key}) : super(key: key);

  @override
  State<Pet_All_Page> createState() => _Pet_All_PageState();
}

class _Pet_All_PageState extends State<Pet_All_Page> {
  final AgeCalculatorService _ageCalculatorService = AgeCalculatorService();
  late User? user;
  late List<Map<String, dynamic>> petUserDataList = [];
  bool isLoading = true;
  final TextEditingController _controller = TextEditingController();
  String? petId_main;
  String age = '';

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _getPetUserDataFromFirestore('');
    }
  }

  //ดึงข้อมูลสัตว์เลี้ยงของผู้ใช้
  Future<void> _getPetUserDataFromFirestore(String searchValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? petId = prefs.getString(user!.uid.toString());

    try {
      // ดึงข้อมูลจากคอลเลคชัน Usage_pet เพื่อหาข้อมูล pet_id
      QuerySnapshot petIdQuerySnapshot = await FirebaseFirestore.instance
          .collection('Usage_pet')
          .where('pet_id', isEqualTo: petId)
          .get();

      if (petIdQuerySnapshot.docs.isNotEmpty) {
        // ตรวจสอบว่าเอกสารแรกไม่เป็น null และมีข้อมูล pet_id
        var firstDoc =
            petIdQuerySnapshot.docs.first.data() as Map<String, dynamic>?;
        petId_main = firstDoc?['pet_id'];
        print('Pet ID from Usage_pet: $petId_main');
      } else {
        print('No pet_id found in Usage_pet for petId: $petId');
      }

      QuerySnapshot petUserQuerySnapshot = await FirebaseFirestore.instance
          .collection('Pet_User')
          .where('user_id', isEqualTo: user!.uid)
          .get();

      List<Map<String, dynamic>> allPets = petUserQuerySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      List<Map<String, dynamic>> nonDeletedPets =
          allPets.where((pet) => pet['status'] != 'ถูกลบ').toList();

      if (searchValue.isNotEmpty) {
        List<Map<String, dynamic>> filteredPets = nonDeletedPets.where((pet) {
          bool matchesName = pet['name']
              .toString()
              .toLowerCase()
              .contains(searchValue.toLowerCase());

          DateTime birthDate = DateTime.parse(pet['birthdate']);
          DateTime now = DateTime.now();
          // คำนวณความแตกต่างของปีและเดือน
          int yearsDifference = now.year - birthDate.year;
          int monthsDifference = now.month - birthDate.month;

// ถ้าความแตกต่างของวันทำให้ต้องลดจำนวนเดือนลงหนึ่งเดือน
          if (now.day < birthDate.day) {
            monthsDifference--;
          }

// แปลงจำนวนปีเป็นเดือนแล้วรวมกับจำนวนเดือนที่เหลือ
          int totalMonths = yearsDifference * 12 + monthsDifference;

          if (totalMonths > 12) {
            totalMonths = totalMonths % 12;
          }

// ตรวจสอบว่า totalMonths มีค่าเหมือนกับ searchValue หรือไม่
          bool matchesAge = totalMonths
              .toString()
              .toLowerCase()
              .contains(searchValue.toLowerCase());

          bool matchesBreed = pet['breed_pet']
              .toString()
              .toLowerCase()
              .contains(searchValue.toLowerCase());

          bool matchesGender = pet['gender']
              .toString()
              .toLowerCase()
              .contains(searchValue.toLowerCase());

          bool matchesColor = pet['color']
              .toString()
              .toLowerCase()
              .contains(searchValue.toLowerCase());

          return matchesName ||
              matchesAge ||
              matchesBreed ||
              matchesGender ||
              matchesColor;
        }).toList();

        setState(() {
          petUserDataList = filteredPets;
          isLoading = false;
        });
      } else {
        setState(() {
          petUserDataList = nonDeletedPets;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error getting pet user data from Firestore: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _logSearchValue() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchValue = _controller.text;
      // log(searchValue.toString());
      _getPetUserDataFromFirestore(searchValue);
    });
  }

  //กรองข้อมูลสัตว์เลี้ยงโดยแยกตามประเภทของสัตว์เลี้ยง (สุนัข และ แมว)
  List<Map<String, dynamic>> get filteredDogPets =>
      petUserDataList.where((pet) => pet['type_pet'] == 'สุนัข').toList();

  List<Map<String, dynamic>> get filteredCatPets =>
      petUserDataList.where((pet) => pet['type_pet'] == 'แมว').toList();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Scaffold(
          appBar: AppBar(
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "สัตว์เลี้ยงของฉัน",
                style: Theme.of(context).textTheme.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            centerTitle: true,
            automaticallyImplyLeading: false, // กำหนดให้ไม่แสดงปุ่ม Back
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(
                  kToolbarHeight + 60), // ปรับขนาด preferredSize
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50.0, vertical: 14.0),
                    child: Container(
                      height: MediaQuery.of(context).size.height / 17,
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'ค้นหา',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _logSearchValue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const TabBar(
                    tabs: [
                      Tab(text: 'สุนัข'),
                      Tab(text: 'แมว'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(
                          height:
                              16), // เพิ่มระยะห่างระหว่าง CircularProgressIndicator กับข้อความ
                      Text('กำลังโหลดข้อมูล'),
                    ],
                  ),
                )
              : TabBarView(
                  children: [
                    //สุนัข
                    _buildPetList(filteredDogPets),
                    //แมว
                    _buildPetList(filteredCatPets),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Pet_Page()),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildPetList(List<Map<String, dynamic>> petList) {
    return petList.isEmpty
        ? const Center(
            child: Text(
              'ไม่มีข้อมูลสัตว์เลี้ยง',
              style: TextStyle(fontSize: 16),
            ),
          )
        : SingleChildScrollView(
            // แสดงรายการสัตว์เลี้ยงเมื่อข้อมูลถูกโหลดเสร็จสิ้น
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: petList.length,
                  itemBuilder: (context, index) {
                    return _buildPetCard(petList[index]);
                  },
                ),
              ],
            ),
          );
  }

  // ข้อมูลสัตว์เลี้ยงที่แสดงผล
  Widget _buildPetCard(Map<String, dynamic> petUserData) {
    DateTime birthDate = DateTime.parse(petUserData['birthdate']);
    age = _ageCalculatorService.calculateAge(birthDate); // คำนวณอายุที่นี่
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Edit_Pet_Page(petUserData: petUserData),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 30,
            backgroundImage: petUserData['img_profile'] != null
                ? MemoryImage(
                    base64Decode(petUserData['img_profile'] as String))
                : null,
            child: petUserData['img_profile'] == null
                ? const ImageIcon(AssetImage('assets/default_pet_image.png'))
                : null,
          ),
          title: Row(
            children: [
              Text(
                petUserData['name'] ?? '',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              petUserData['gender'] == 'ตัวผู้'
                  ? const Icon(Icons.male, size: 20, color: Colors.purple)
                  : petUserData['gender'] == 'ตัวเมีย'
                      ? const Icon(Icons.female, size: 20, color: Colors.pink)
                      : const Icon(Icons.help_outline,
                          size: 20, color: Colors.black),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${petUserData['breed_pet'] ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '$age',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: petId_main == petUserData['pet_id']
                ? [
                    IconButton(
                      onPressed: () {
                        // แสดงไอคอนของสัตว์เลี้ยงเมื่อเป็นตัวหลัก
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Column(
                                children: [
                                  Icon(Icons.pets,
                                      color: Colors.blue.shade800, size: 50),
                                  SizedBox(height: 20),
                                  Text('${petUserData['name']}',
                                      style: TextStyle(fontSize: 25)),
                                ],
                              ),
                              content: Text(
                                "สัตว์เลี้ยงตัวนี้เป็นตัวหลักของคุณ",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18),
                              ),
                              actions: <Widget>[
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("ปิด"),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: Icon(Icons.pets, color: Colors.blue.shade800),
                    ),
                  ]
                : [
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Column(
                                children: [
                                  const Icon(Icons.delete,
                                      color: Colors.deepPurple, size: 50),
                                  SizedBox(height: 20),
                                  Text('คุณต้องการลบลบสัตว์เลี้ยง',
                                      style: TextStyle(fontSize: 18)),
                                ],
                              ),
                              content: Text(
                                "${petUserData['name']}?",
                                style: TextStyle(fontSize: 25),
                                textAlign: TextAlign.center,
                              ),
                              actions: <Widget>[
                                Center(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      SizedBox(
                                        height: 40,
                                        width: 90,
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text("ยกเลิก"),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.blue,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 40,
                                        width: 90,
                                        child: TextButton(
                                          onPressed: () {
                                            _deletePetData(
                                                petUserData['pet_id']);
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text("ยืนยัน"),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(LineAwesomeIcons.minus),
                    ),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Column(
                                children: [
                                  const Icon(Icons.swap_horiz,
                                      color: Colors.green, size: 50),
                                  SizedBox(height: 20),
                                  Text('คุณต้องการเปลี่ยนตัวหลักเป็น',
                                      style: TextStyle(fontSize: 18)),
                                ],
                              ),
                              content: Text(
                                "${petUserData['name']}?",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 25),
                              ),
                              actions: <Widget>[
                                Center(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      SizedBox(
                                        height: 40,
                                        width: 90,
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text("ยกเลิก"),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.blue,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 40,
                                        width: 90,
                                        child: TextButton(
                                          onPressed: () {
                                            _shufflePet(petUserData['pet_id']);
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text("ยืนยัน"),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(LineAwesomeIcons.alternate_exchange),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  void _shufflePet(String petId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(user!.uid, petId);

    CollectionReference usagePet =
        FirebaseFirestore.instance.collection('Usage_pet');

    try {
      DocumentSnapshot docSnapshot = await usagePet.doc(user!.uid).get();

      if (docSnapshot.exists) {
        await usagePet.doc(user!.uid).update({'pet_id': petId});
      } else {
        await usagePet.doc(user!.uid).set({
          'pet_id': petId,
          'user_id': user!.uid,
        });
      }

      _getPetUserDataFromFirestore('');

      // แสดงแจ้งเตือนเมื่อสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เปลี่ยนสัตว์เลี้ยงตัวหลักแล้ว'),
          duration: Duration(seconds: 2), // กำหนดระยะเวลาแสดง
        ),
      );
    } catch (e) {
      print('Error updating or creating pet data: $e');
      // แสดงแจ้งเตือนเมื่อเกิดข้อผิดพลาด (ถ้าต้องการ)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเปลี่ยนสัตว์เลี้ยง'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  //ปุ่มลบข้อมูลสัตว์เลี้ยง
  void _deletePetData(String petId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Pet_User')
          .doc(petId)
          .update({'status': 'ถูกลบ'});
      // ลบข้อมูลสัตว์เลี้ยงสำเร็จ ให้รีเฟรชหน้าเพื่อแสดงข้อมูลใหม่
      _getPetUserDataFromFirestore('');
    } catch (e) {
      print('Error deleting pet data: $e');
    }
  }
}
