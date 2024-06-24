import 'dart:convert';

import 'package:Pet_Fluffy/features/page/pages_widgets/edit_Profile_Pet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PetAllTwo extends StatefulWidget {
  const PetAllTwo({super.key});

  @override
  State<PetAllTwo> createState() => _PetAllTwoState();
}

class _PetAllTwoState extends State<PetAllTwo> {
  late User? user;
  late List<Map<String, dynamic>> petUserDataList = [];
  bool isLoading = true;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController(viewportFraction: 0.8);
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _getPetUserDataFromFirestore();
    }
  }

  Future<void> _getPetUserDataFromFirestore() async {
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

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredDogPets =>
      petUserDataList.where((pet) => pet['type_pet'] == 'สุนัข').toList();

  List<Map<String, dynamic>> get filteredCatPets =>
      petUserDataList.where((pet) => pet['type_pet'] == 'แมว').toList();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: NetworkImage(
                  'https://i.pinimg.com/236x/ca/e6/42/cae6422233c711a56f03430aa57e9e0e.jpg'),
              fit: BoxFit.fill),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(LineAwesomeIcons.angle_left),
            ),
            title: Text(
              "สัตว์เลี้ยงของฉัน",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,
            bottom: TabBar(
              tabs: [
                Tab(text: 'สุนัข'),
                Tab(text: 'แมว'),
              ],
              labelColor: Color.fromARGB(255, 187, 3, 243),
              unselectedLabelColor: Colors.black54,
            ),
          ),
          body: isLoading
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
              : TabBarView(
                  children: [
                    //สุนัข
                    _buildPetList(filteredDogPets),
                    //แมว
                    _buildPetList(filteredCatPets),
                  ],
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
                // SizedBox(height: 30,),
                Stack(children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: petList.length,
                    itemBuilder: (context, index) {
                      return _buildPetCard(petList[index]);
                    },
                  ),
                ]),
              ],
            ),
          );
  }

  Widget _buildPetCard(Map<String, dynamic> petUserData) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 300,
                  child: Image.memory(
                    base64Decode(petUserData['img_profile']),
                    fit: BoxFit.cover,
                  ),
                ),

                Positioned(
                  top: 0, // ปรับตำแหน่งให้มันเป็นบวก
                  left: 0,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height / 2.55,
                    width: MediaQuery.of(context).size.width,
                    child: Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: [
                            Color.fromARGB(255, 0, 0, 0),
                            Color.fromARGB(132, 0, 0, 0),
                            Color.fromARGB(131, 245, 240, 240)
                          ])),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                petUserData['name'],
                                style: TextStyle(
                                  fontSize: 45.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Padding(padding: EdgeInsets.only(top: 170)),
                              SizedBox(
                                child: Row(
                                  children: [
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                2.955),
                                    IconButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text(
                                                    "ยืนยันการเปลี่ยนตัวหลัก"),
                                                content: const Text(
                                                    "คุณแน่ใจหรือไม่ที่ต้องเปลี่ยนตัวหลักเป็นตัวนี้?"),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text("ยกเลิก"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      _shufflePet(petUserData[
                                                          'pet_id']);
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text("ยืนยัน"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        icon: Icon(
                                          LineAwesomeIcons.alternate_exchange,
                                          size: 40.0,
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                        )),
                                    SizedBox(width: 20),
                                    IconButton(
                                        color:
                                            Color.fromARGB(255, 255, 255, 255),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  Edit_Pet_Page(
                                                      petUserData: petUserData),
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          LineAwesomeIcons.edit,
                                          size: 40.0,
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Positioned(
                //   top: 200, // ปรับตำแหน่งให้มันเป็นบวก
                //   right: 0,
                //   child: SizedBox(
                //     height: 90,
                //     child: Image.asset('assets/images/1fbe1ac2cb61c7be91c369dc868d2786-removebg-preview (1).png')
                //   ),
                // ),
              ],
            )
          ],
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
}
