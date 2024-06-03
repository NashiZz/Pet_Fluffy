// ignore_for_file: camel_case_types, file_names

import 'dart:convert';

import 'package:Pet_Fluffy/features/api/pet_data.dart';
import 'package:Pet_Fluffy/features/api/user_data.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
import 'package:Pet_Fluffy/features/page/profile_all_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

//หน้า Menu Home ของ App
class randomMathch_Page extends StatefulWidget {
  const randomMathch_Page({super.key});

  @override
  State<randomMathch_Page> createState() => _randomMathch_PageState();
}

class _randomMathch_PageState extends State<randomMathch_Page> {
  User? user = FirebaseAuth.instance.currentUser;
  String? userId;
  String? petId;
  String? petType;
  String? petGender;
  String? petImg;
  String? userImageBase64;

  bool isLoading = true;

  //ดึงข้อมูลของผู้ใช้
  void _getUserDataFromFirestore() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      userId = userData.uid;
      Map<String, dynamic>? userDataFromFirestore =
          await ApiUserService.getUserDataFromFirestore(userId!);
      if (userDataFromFirestore != null && mounted) {
        setState(() {
          userImageBase64 = userDataFromFirestore['photoURL'] ?? '';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _getUsage_pet() async {
    if (user != null) {
      userId = user!.uid;
      try {
        // ระบุคอลเลคชันที่จะใช้ใน Firestore
        DocumentSnapshot userDocSnapshot = await FirebaseFirestore.instance
            .collection('Usage_pet')
            .doc(userId)
            .get();

        if (userDocSnapshot.exists) {
          // ดึงข้อมูลผู้ใช้จาก Snapshot
          petId = userDocSnapshot['pet_id'];

          // ค้นหาข้อมูลในคอลเลคชัน Pet_user เพื่อดึงประเภทสัตว์เลี้ยงและเพศ
          DocumentSnapshot petDocSnapshot = await FirebaseFirestore.instance
              .collection('Pet_User')
              .doc(petId)
              .get();

          if (petDocSnapshot.exists) {
            setState(() {
              petType = petDocSnapshot['type_pet'];
              petGender = petDocSnapshot['gender'];
              petImg = petDocSnapshot['img_profile'] ?? '';
              isLoading = false;
            });

            print('Type : $petType, Gender : $petGender');
          } else {
            print('No pet data found with pet_id: $petId');
          }
        } else {
          // หากไม่มีข้อมูลใน Usage_pet ให้สร้างเอกสารใหม่
          await FirebaseFirestore.instance
              .collection('Usage_pet')
              .doc(userId)
              .set({
            'pet_id': '',
          });
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        print('Error getting user data from Firestore: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserDataFromFirestore();
    _getUsage_pet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: GestureDetector(
                          onTap: () {
                            if (petImg != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      Profile_pet_Page(petId: petId!),
                                ),
                              );
                            } else {
                              print('User image is not available');
                            }
                          },
                          child: petImg != null
                              ? Image.memory(
                                  base64Decode(petImg!),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                )
                              : const CircularProgressIndicator(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'ค้นหา',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          // Add search functionality
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Add code for notification button
                      },
                      icon: const Icon(Icons.notifications),
                    ),
                  ],
                ),
              ),
            ),
            // ดึงข้อมูลสัตว์เลี้ยงจาก ApiPetService.loadAllPet() คืนค่าเป็น List<Map<String, dynamic>>
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Stream.fromFuture(ApiPetService.loadAllPet()),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 15),
                        Text('กำลังโหลดข้อมูล...')
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('ไม่พบข้อมูลสัตว์เลี้ยง'),
                  );
                }

                List<Map<String, dynamic>> allPetData = snapshot.data!;
                // กำหนดเพศตรงข้าม
                String oppositeGender = (petGender == 'ตัวผู้') ? 'ตัวเมีย' : 'ตัวผู้';
                List<Map<String, dynamic>> filteredPetData = snapshot.data!
                    .where((pet) =>
                        pet['type_pet'] == petType &&
                        pet['gender'] == oppositeGender)
                    .toList();

                if (filteredPetData.isEmpty) {
                  filteredPetData =
                      allPetData; // แสดงข้อมูลทั้งหมดเมื่อไม่ตรงตามเงื่อนไข
                }

                return Expanded(
                  //นำข้อมูลสัตว์เลี้ยงที่ได้มาแสดงผลใน ListView.builder โดยดึงข้อมูลเกี่ยวกับอายุของสัตว์เลี้ยงและข้อมูลของผู้ใช้ที่เป็นเจ้าของสัตว์เลี้ยงด้วย
                  child: ListView.builder(
                    itemCount: filteredPetData.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> petData = filteredPetData[index];
                      DateTime birthDate = DateTime.parse(petData['birthdate']);
                      final now = DateTime.now();
                      int years = now.year - birthDate.year;
                      int months = now.month - birthDate.month;

                      if (months < 0) {
                        years--;
                        months += 12;
                      }
                      String ageString = '';
                      if (years > 0) {
                        ageString += '$years ขวบ';
                        if (months > 0) {
                          ageString += ' ';
                        }
                      }
                      if (months > 0 || years == 0) {
                        if (years == 0 && months == 0) {
                          ageString = 'ไม่ถึง 1 เดือน';
                        } else {
                          ageString += '$months เดือน';
                        }
                      }

                      //ดึงข้อมูลผู้ใช้ทั้งหมดจาก ID ของผู้ใช้ที่เป็นเจ้าของสัตว์เลี้ยง
                      return FutureBuilder<DocumentSnapshot>(
                        future: ApiUserService.getUserData(petData['user_id']),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                          if (userSnapshot.hasError) {
                            return Text('Error: ${userSnapshot.error}');
                          }
                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return const SizedBox(); // ถ้าไม่มีข้อมูลผู้ใช้ ให้แสดง Widget ว่าง
                          }
                          //ดึงเอาข้อมูลรูปภาพโปรไฟล์ของผู้ใช้ ทั้งหมดมา
                          Map<String, dynamic> userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;
                          String? userImageURL = userData['photoURL'];

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.all(10),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              Profile_pet_Page(
                                                  petId: petData['pet_id']),
                                        ),
                                      );
                                    },
                                    child: SizedBox(
                                      width: 150,
                                      height: 120,
                                      child: AspectRatio(
                                        aspectRatio: 1.5,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image.memory(
                                            base64Decode(
                                                petData['img_profile']),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              petData['name'],
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Icon(
                                              petData['gender'] == 'ตัวผู้'
                                                  ? Icons.male
                                                  : petData['gender'] ==
                                                          'ตัวเมีย'
                                                      ? Icons.female
                                                      : Icons.help_outline,
                                              size: 20,
                                              color:
                                                  petData['gender'] == 'ตัวผู้'
                                                      ? Colors.purple
                                                      : petData['gender'] ==
                                                              'ตัวเมีย'
                                                          ? Colors.pink
                                                          : Colors.black,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          petData['breed_pet'],
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          ageString,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade600
                                                    .withOpacity(0.8),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.5),
                                                    spreadRadius: 1,
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: IconButton(
                                                onPressed: () {
                                                  add_Faverite(
                                                      petData['pet_id']);
                                                },
                                                icon: const Icon(
                                                  Icons.star_rounded,
                                                  color: Colors.yellow,
                                                ),
                                                iconSize: 20,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ProfileAllUserPage(
                                                            userId: petData[
                                                                'user_id']),
                                                  ),
                                                )
                                              },
                                              child: Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade500
                                                      .withOpacity(0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(40),
                                                ),
                                                child: Center(
                                                  child: CircleAvatar(
                                                    radius: 40,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    child: ClipOval(
                                                      child: Image.memory(
                                                        base64Decode(
                                                            userImageURL!),
                                                        width: 40,
                                                        height: 40,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.5),
                                                    spreadRadius: 1,
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: IconButton(
                                                onPressed: () {
                                                  // Add your code to handle the "heart" action here
                                                },
                                                icon: const Icon(
                                                  Icons.favorite,
                                                  color: Colors.pinkAccent,
                                                ),
                                                iconSize: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void add_Faverite(String petIdd) async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? petId = prefs.getString(userId.toString());
    String pet_request = petId.toString();
    String pet_respone = petIdd.toString();

    // รับวันและเวลาปัจจุบันในโซนเวลาไทย
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formatted =
        formatter.format(now.toUtc().add(Duration(hours: 7)));

    // อ้างอิงถึงเอกสาร userId ในคอลเลกชัน favorites
    DocumentReference userFavoritesRef =
        FirebaseFirestore.instance.collection('favorites').doc(userId);

    // อ้างอิงถึงคอลเลกชันย่อย pet_favorite ในเอกสาร userId
    CollectionReference petFavoriteRef =
        userFavoritesRef.collection('pet_favorite');

    // เพิ่มเอกสารใหม่ในคอลเลกชันย่อย pet_favorite
    try {
      DocumentReference newPetfav = await petFavoriteRef.add({
        'created_at': formatted,
        'pet_request': pet_request,
        'pet_respone': pet_respone,
      });

      String docId = newPetfav.id;

      await newPetfav.update({'id_fav': docId});

      setState(() {
        isLoading = false;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.of(context).pop(true); // ปิดไดอะล็อกหลังจาก 2 วินาที
          });
          return const AlertDialog(
            title: Text('Success'),
            content: Text('เพิ่มสัตว์เลี้ยงสำเร็จ'),
          );
        },
      );
    } catch (error) {
      print("Failed to add pet: $error");

      setState(() {
        isLoading = false;
      });
    }
  }
}
