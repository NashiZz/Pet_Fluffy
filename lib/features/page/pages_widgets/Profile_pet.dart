// ignore_for_file: camel_case_types, file_names, avoid_print

import 'dart:convert';

import 'package:Pet_Fluffy/features/api/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

//หน้า Profile ของ สัตว์เลี้ยง
class Profile_pet_Page extends StatefulWidget {
  final String petId;
  const Profile_pet_Page({super.key, required this.petId});

  @override
  State<Profile_pet_Page> createState() => _Profile_pet_PageState();
}

class _Profile_pet_PageState extends State<Profile_pet_Page> {
  User? user = FirebaseAuth.instance.currentUser;

  String pet_user = '';
  String petName = '';
  String type = '';
  String petImageBase64 = '';
  String weight = '';
  String color = '';
  String gender = '';
  String des = '';
  String birthdateStr = '';
  String age = '';
  String price = '';
  String userPhotoURL = '';

  String? userId;
  String? userImageBase64;

  bool isLoading = true;
  late List<Map<String, dynamic>> petUserDataList = [];

  final double coverHeight = 180;
  final double profileHeight = 90;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _loadAllPet(widget.petId);
      _getUserDataFromFirestore();
    }
    isLoading = true;
  }

  String calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    int years = now.year - birthdate.year;
    int months = now.month - birthdate.month;

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

    return ageString;
  }

  //ดึงข้อมูลสัตว์เลี้ยงของผู้ใช้ทั้งหมด
  Future<void> _loadAllPet(String petId) async {
    try {
      DocumentSnapshot petDocSnapshot = await FirebaseFirestore.instance
          .collection('Pet_User')
          .doc(petId)
          .get();

      if (petDocSnapshot.exists) {
        Map<String, dynamic> petData =
            petDocSnapshot.data() as Map<String, dynamic>;
        setState(() {
          // ดึงข้อมูลจาก Firestore และกำหนดค่าให้กับตัวแปรที่ใช้เก็บข้อมูล
          pet_user = petData['user_id'] ?? '';
          petName = petData['name'] ?? '';
          type = petData['breed_pet'] ?? '';
          petImageBase64 = petData['img_profile'] ?? '';
          color = petData['color'] ?? '';
          weight = petData['weight'] ?? '0.0';
          gender = petData['gender'] ?? '';
          des = petData['description'] ?? '';
          price = petData['price'] ?? '';
          birthdateStr = petData['birthdate'] ?? '';
          DateTime birthdate = DateTime.parse(birthdateStr);
          age = calculateAge(birthdate);

          isLoading = false;
        });
        print(price);
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error getting pet user data from Firestore: $e');
    }
  }

  //ดึงข้อมูลรูปภาพผู้ใช้ทั้งหมด
  void _getUserDataFromFirestore() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      userId = userData.uid;
      Map<String, dynamic>? userDataFromFirestore =
          await ApiUserService.getUserDataFromFirestore(userId!);
      if (userDataFromFirestore != null) {
        userImageBase64 = userDataFromFirestore['photoURL'] ?? '';
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Future<void> _getPetUserDataFromFirestore() async {
  //   try {
  //     QuerySnapshot petUserQuerySnapshot = await FirebaseFirestore.instance
  //         .collection('Pet_User')
  //         .where('user_id', isEqualTo: user!.uid)
  //         .get();

  //     setState(() {
  //       petUserDataList = petUserQuerySnapshot.docs
  //           .map((doc) => doc.data() as Map<String, dynamic>)
  //           .toList();
  //     });
  //   } catch (e) {
  //     print('Error getting pet user data from Firestore: $e');
  //   }
  // }

  // List<Map<String, dynamic>> get filteredDogPets =>
  //     petUserDataList.where((pet) => pet['type_pet'] == 'สุนัข').toList();

  // List<Map<String, dynamic>> get filteredCatPets =>
  //     petUserDataList.where((pet) => pet['type_pet'] == 'แมว').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "โปรไฟล์สัตว์เลี้ยง",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(LineAwesomeIcons.info_circle),
          )
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                buildTop(),
                const SizedBox(height: 30),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.0),
                  child: Text(
                    'คำอธิบาย',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Container(
                    width: 360,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              des,
                              style: const TextStyle(fontSize: 16),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: DefaultTabController(
                    length: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          const TabBar(
                            tabs: [
                              Tab(text: 'ข้อมูลทั่วไป'),
                              Tab(text: 'ประจำเดือน'),
                              Tab(text: 'ประวัติสุขภาพ'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                SingleChildScrollView(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        const SizedBox(height: 15),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 40.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'สี',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(color),
                                              const Text(
                                                'น้ำหนัก',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text('$weight Kg')
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 40.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'เพศ',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Center(
                                                child: gender == 'ตัวผู้'
                                                    ? const Icon(Icons.male,
                                                        size: 30,
                                                        color: Colors.purple)
                                                    : gender == 'ตัวเมีย'
                                                        ? const Icon(
                                                            Icons.female,
                                                            size: 30,
                                                            color: Colors.pink)
                                                        : const Icon(
                                                            Icons.help_outline,
                                                            size: 30,
                                                            color:
                                                                Colors.black),
                                              ),
                                              const Text(
                                                'อายุ',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(age)
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20.0),
                                          child: Column(
                                            children: [
                                              MenuPetWidget(
                                                title: "ประวัติการจับคู่",
                                                icon: LineAwesomeIcons.history,
                                                onPress: () {},
                                              ),
                                              MenuPetWidget(
                                                title: "การประกวด",
                                                icon: LineAwesomeIcons
                                                    .certificate,
                                                onPress: () {},
                                              ),
                                              MenuPetWidget(
                                                title: "ใบเพ็ดดีกรี",
                                                icon: LineAwesomeIcons.dna,
                                                onPress: () {},
                                              ),
                                              MenuPetWidget(
                                                title: "ค่าการผสมพันธุ์",
                                                icon: LineAwesomeIcons.coins,
                                                trailingText: price.isNotEmpty
                                                    ? '$price บาท'
                                                    : 'ไม่มีค่าใช้จ่าย',
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Row(
                                          children: [
                                            Row(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.only(right: 5),
                                                  child: Icon(LineAwesomeIcons.image),
                                                ),
                                                Text(
                                                  'รูปภาพ',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.start,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        
                                        //ดึงข้อมูลรูปภาพ 9 รูปของสัตว์เลี้ยง
                                        FutureBuilder<QuerySnapshot>(
                                          future: FirebaseFirestore.instance
                                              .collection('imgs_pet')
                                              .where('pet_id', isEqualTo: widget.petId)
                                              .get(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const CircularProgressIndicator();
                                            }
                                            if (snapshot.hasError) {
                                              return Text('Error: ${snapshot.error}');
                                            }
                                            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                              // ดึงข้อมูลและแสดงผลใน GridView.builder
                                              return GridView.builder(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 1,
                                                  crossAxisSpacing: 10.0,
                                                  mainAxisSpacing: 10.0,
                                                ),
                                                itemCount: snapshot.data!.docs.length,
                                                itemBuilder: (context, index) {
                                                  // ดึงข้อมูลทั้งหมดในเอกสารแต่ละเอกสาร
                                                  DocumentSnapshot imgDoc = snapshot.data!.docs[index];
                                                  Map<String, dynamic>? data = imgDoc.data() as Map<String, dynamic>?;

                                                  if (data != null && data.isNotEmpty) {
                                                    List<String> imageUrls = [];
                                                    for (int i = 1; i <= 9; i++) {
                                                      String? imageUrl = data['img_$i'] as String?;
                                                      if (imageUrl != null && imageUrl.isNotEmpty) {
                                                        imageUrls.add(imageUrl);
                                                      }
                                                    }
                                                    return GridView.builder(
                                                      physics: const NeverScrollableScrollPhysics(),
                                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: 3,
                                                        crossAxisSpacing: 8.0,
                                                        mainAxisSpacing: 8.0,
                                                      ),
                                                      itemCount: imageUrls.length,
                                                      itemBuilder: (context, index) {
                                                        return ClipRRect(
                                                          borderRadius: BorderRadius.circular(8.0),
                                                          child: Image.memory(
                                                            base64Decode(imageUrls[index]),
                                                            fit: BoxFit.cover,
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  } else {
                                                    return Text('ไม่มีข้อมูล');
                                                  }
                                                },
                                              );
                                            } 
                                            return Text('ไม่มีรูปภาพ');
                                          },
                                        ),
                                        const SizedBox(height: 5)
                                      ]),
                                ),
                                SingleChildScrollView(
                                  child: Column(children: [Text('data')]),
                                ),
                                SingleChildScrollView(
                                  child: Column(children: [Text('data')]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildTop() {
    final top = coverHeight - profileHeight / 2;
    final bottom = profileHeight / 2;

    return FutureBuilder<DocumentSnapshot>(
        future: ApiUserService.getUserData(pet_user),
        builder: (BuildContext context,
            AsyncSnapshot<DocumentSnapshot> userSnapshot) {
          if (userSnapshot.hasError) {
            return Text('Error: ${userSnapshot.error}');
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const SizedBox(); // ถ้าไม่มีข้อมูลผู้ใช้ ให้แสดง Widget ว่าง
          }
          Map<String, dynamic> userData =
              userSnapshot.data!.data() as Map<String, dynamic>;
          String? userImageURL = userData['photoURL'];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                  margin: EdgeInsets.only(bottom: bottom),
                  child: buildCoverImage()),
              Positioned(
                top: top,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                      child: Stack(
                        children: [
                          buildProfileImage(),
                          Positioned(
                            top: 80,
                            right: 5,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            petName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            type,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 0, 0),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade500.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.transparent,
                            child: ClipOval(
                              child: userImageURL != null
                                  ? Image.memory(
                                      base64Decode(userImageURL),
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }

  // รูป Banner
  Widget buildCoverImage() => Container(
        color: Colors.grey,
        child: petImageBase64.isNotEmpty
            ? Image.memory(
                base64Decode(petImageBase64),
                width: double.infinity,
                height: coverHeight,
                fit: BoxFit.cover,
              )
            : const CircularProgressIndicator(), // กรณีที่ไม่มีข้อมูลภาพ
      );

  // รูป Profile
  Widget buildProfileImage() => Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(55),
        ),
        child: CircleAvatar(
          radius: 50,
          backgroundColor: Colors.transparent,
          child: ClipOval(
            child: petImageBase64.isNotEmpty
                ? Image.memory(
                    base64Decode(petImageBase64),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );

  // Widget _buildPetCard(Map<String, dynamic> petUserData) {
  //   return Card(
  //     margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //     child: ListTile(
  //       leading: CircleAvatar(
  //         backgroundColor: Colors.transparent,
  //         backgroundImage: petUserData['img_profile'] != null
  //             ? MemoryImage(base64Decode(petUserData['img_profile'] as String))
  //             : null,
  //         child: petUserData['img_profile'] == null
  //             ? const ImageIcon(AssetImage('assets/default_pet_image.png'))
  //             : null,
  //       ),
  //       title: Text(
  //         petUserData['name'] ?? '',
  //         style: Theme.of(context).textTheme.titleLarge,
  //       ),
  //       subtitle: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'ประเภท: ${petUserData['type_pet'] ?? ''}',
  //             style: Theme.of(context).textTheme.bodyMedium,
  //           ),
  //           Text(
  //             'พันธุ์: ${petUserData['breed_pet'] ?? ''}',
  //             style: Theme.of(context).textTheme.bodyMedium,
  //           ),
  //           Text(
  //             'เพศ: ${petUserData['gender'] ?? ''}',
  //             style: Theme.of(context).textTheme.bodyMedium,
  //           ),
  //         ],
  //       ),
  //       onTap: () {
  //         // ทำสิ่งที่ต้องการเมื่อคลิกที่รายการสัตว์เลี้ยง
  //       },
  //     ),
  //   );
  // }
}

class MenuPetWidget extends StatelessWidget {
  const MenuPetWidget({
    Key? key,
    required this.title,
    required this.icon,
    this.trailingText,
    this.onPress,
    this.endIcon = true,
    this.textColor,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final String? trailingText;
  final VoidCallback? onPress;
  final bool endIcon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPress,
      leading: Icon(icon, color: const Color.fromARGB(255, 49, 42, 42)),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.apply(color: textColor),
      ),
      trailing: endIcon
          ? trailingText !=
                  null // ตรวจสอบว่ามีข้อความที่จะแสดงใน trailing หรือไม่
              ? Text(
                  trailingText!,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                )
              : const Icon(LineAwesomeIcons.angle_right,
                  size: 18.0, color: Colors.grey)
          : null,
    );
  }
}
