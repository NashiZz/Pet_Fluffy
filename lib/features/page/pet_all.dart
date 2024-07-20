// ignore_for_file: camel_case_types, avoid_print

import 'dart:convert';
import 'dart:developer';

import 'package:Pet_Fluffy/features/page/pages_widgets/edit_Profile_Pet.dart';
import 'package:Pet_Fluffy/features/page/pet_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
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
  late User? user;
  late List<Map<String, dynamic>> petUserDataList = [];
  bool isLoading = true;
  final TextEditingController _controller = TextEditingController();

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
    if (searchValue != '') {
      try {
        QuerySnapshot petUserQuerySnapshot = await FirebaseFirestore.instance
            .collection('Pet_User')
            .where('user_id', isEqualTo: user!.uid)
            .get();

        List<Map<String, dynamic>> allPets = petUserQuerySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        List<Map<String, dynamic>> filteredPets = allPets.where((pet) {
          bool matchesName = pet['name']
              .toString()
              .toLowerCase()
              .contains(searchValue.toLowerCase());

          DateTime birthDate = DateTime.parse(pet['birthdate']);
          DateTime now = DateTime.now();
  
          int yearsDifference = now.year - birthDate.year;
          if (now.month < birthDate.month ||
              (now.month == birthDate.month && now.day < birthDate.day)) {
            yearsDifference--;
          }
          bool matchesAge = yearsDifference
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
      } catch (e) {
        print('Error getting pet user data from Firestore: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      try {
        QuerySnapshot petUserQuerySnapshot = await FirebaseFirestore.instance
            .collection('Pet_User')
            .where('user_id', isEqualTo: user!.uid)
            .get();

        setState(() {
          petUserDataList = petUserQuerySnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
          isLoading = false;
        });
      } catch (e) {
        print('Error getting pet user data from Firestore: $e');
        setState(() {
          isLoading = false;
        });
      }
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
          title: Text(
            petUserData['name'] ?? '',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'พันธุ์: ${petUserData['breed_pet'] ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'เพศ: ${petUserData['gender'] ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("ยืนยันการลบ"),
                        content:
                            const Text("คุณแน่ใจหรือไม่ที่ต้องการลบข้อมูลนี้?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("ยกเลิก"),
                          ),
                          TextButton(
                            onPressed: () {
                              _deletePetData(petUserData['pet_id']);
                              Navigator.of(context).pop();
                            },
                            child: const Text("ยืนยัน"),
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
                        title: const Text("ยืนยันการเปลี่ยนตัวหลัก"),
                        content: const Text(
                            "คุณแน่ใจหรือไม่ที่ต้องเปลี่ยนตัวหลักเป็นตัวนี้?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("ยกเลิก"),
                          ),
                          TextButton(
                            onPressed: () {
                              _shufflePet(petUserData['pet_id']);
                              Navigator.of(context).pop();
                            },
                            child: const Text("ยืนยัน"),
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

    // ตรวจสอบว่าเอกสารที่ต้องการมีอยู่หรือไม่
    DocumentSnapshot docSnapshot = await usagePet.doc(user!.uid).get();

    if (docSnapshot.exists) {
      // ถ้ามีเอกสารอยู่แล้ว ให้ทำการอัปเดต
      try {
        await usagePet.doc(user!.uid).update({
          'pet_id': petId,
        });
      } catch (e) {
        print('Error updating pet data: $e');
      }
    } else {
      // ถ้าไม่มีเอกสารอยู่ ให้สร้างเอกสารใหม่
      try {
        await usagePet.doc(user!.uid).set({
          'pet_id': petId,
          'user_id': user!.uid, // เพิ่มข้อมูล user_id เพื่อสร้างเอกสารใหม่
        });
      } catch (e) {
        print('Error creating new pet data: $e');
      }
    }
  }

  //ปุ่มลบข้อมูลสัตว์เลี้ยง
  void _deletePetData(String petId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Pet_User')
          .doc(petId)
          .delete();
      // ลบข้อมูลสัตว์เลี้ยงสำเร็จ ให้รีเฟรชหน้าเพื่อแสดงข้อมูลใหม่
      _getPetUserDataFromFirestore('');
    } catch (e) {
      print('Error deleting pet data: $e');
    }
  }
}
