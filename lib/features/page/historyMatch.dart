import 'dart:convert';
import 'dart:math';

import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class Historymatch_Page extends StatefulWidget {
  final String idPet;
  final String idUser;
  const Historymatch_Page({Key? key, required this.idPet, required this.idUser})
      : super(key: key);

  @override
  State<Historymatch_Page> createState() => _Historymatch_PageState();
}

class _Historymatch_PageState extends State<Historymatch_Page> {
  late List<Map<String, dynamic>> petUserDataList_wait = [];
  late List<Map<String, dynamic>> petUserDataList_pair = [];
  late List<Map<String, dynamic>> getPetDataList = [];
  User? user = FirebaseAuth.instance.currentUser;
  late String userId;
  late String id_fav;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getPetUserDataFromMatch_wait(); // รอ
    _getPetUserDataFromMatch_paired(); // จับคู่แล้ว
  }

  //ดึงข้อมูลจาก firebase
  Future<void> _getPetUserDataFromMatch_wait() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      userId = userData.uid;
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? petId = prefs.getString(userId);
        // ดึงข้อมูลจากคอลเล็กชัน favorites
        QuerySnapshot petUserQuerySnapshot_wait = await FirebaseFirestore
            .instance
            .collection('match')
            .doc(userId)
            .collection('match_pet')
            .where('pet_request', isEqualTo: petId)
            .where('status', isEqualTo: "กำลังรอ")
            .get();

        // ดึงข้อมูลจากเอกสารในรูปแบบ Map<String, dynamic> และดึงเฉพาะฟิลด์ pet_respone
        List<dynamic> petResponses = petUserQuerySnapshot_wait.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        // ประกาศตัวแปร เพื่อรอรับข้อมูลใน for
        List<Map<String, dynamic>> allPetDataList_wait = [];

        // ลูปเพื่อดึงข้อมูลแต่ละรายการ
        for (var petRespone in petResponses) {
          String petResponeId = petRespone['pet_respone'];

          // ดึงข้อมูลจาก pet_user
          QuerySnapshot getPetQuerySnapshot = await FirebaseFirestore.instance
              .collection('Pet_User')
              .where('pet_id', isEqualTo: petResponeId)
              .get();

          // เพิ่มข้อมูลลงใน List
          allPetDataList_wait.addAll(getPetQuerySnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList());
        }

        // อัปเดต petUserDataList ด้วยข้อมูลทั้งหมดที่ได้รับ
        setState(() {
          petUserDataList_wait = allPetDataList_wait;
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

  Future<void> _getPetUserDataFromMatch_paired() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      userId = userData.uid;
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? petId = prefs.getString(userId);
        // ดึงข้อมูลจากคอลเล็กชัน favorites
        QuerySnapshot petUserQuerySnapshot_pair = await FirebaseFirestore
            .instance
            .collection('match')
            .doc(userId)
            .collection('match_pet')
            .where('pet_request', isEqualTo: petId)
            .where('status', isEqualTo: "จับคู่แล้ว")
            .get();

        // ดึงข้อมูลจากเอกสารในรูปแบบ Map<String, dynamic> และดึงเฉพาะฟิลด์ pet_respone
        List<dynamic> petResponses = petUserQuerySnapshot_pair.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        // ประกาศตัวแปร เพื่อรอรับข้อมูลใน for
        List<Map<String, dynamic>> allPetDataList_pair = [];

        // ลูปเพื่อดึงข้อมูลแต่ละรายการ
        for (var petRespone in petResponses) {
          String petResponeId = petRespone['pet_respone'];

          // ดึงข้อมูลจาก pet_user
          QuerySnapshot getPetQuerySnapshot = await FirebaseFirestore.instance
              .collection('Pet_User')
              .where('pet_id', isEqualTo: petResponeId)
              .get();

          // เพิ่มข้อมูลลงใน List
          allPetDataList_pair.addAll(getPetQuerySnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList());
        }

        // อัปเดต petUserDataList ด้วยข้อมูลทั้งหมดที่ได้รับ
        setState(() {
          petUserDataList_pair = allPetDataList_pair;
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

  List<Map<String, dynamic>> get allPetDataList_wait => petUserDataList_wait;
  List<Map<String, dynamic>> get allPetDataList_pair => petUserDataList_pair;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(LineAwesomeIcons.angle_left),
          ),
          title: Text(
            "การจับคู่",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          centerTitle: true,
          automaticallyImplyLeading: false, // กำหนดให้ไม่แสดงปุ่ม Back
          bottom: TabBar(
            tabs: [
              Tab(text: 'กำลังรอ'),
              Tab(text: 'จับคู่แล้ว'),
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
                  _buildPetList(allPetDataList_wait),
                  //แมว
                  _buildPetList(allPetDataList_pair),
                ],
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

  Widget _buildPetCard(Map<String, dynamic> petUserData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Profile_pet_Page(petId: petUserData['pet_id']),
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
                'ค่าผสมพันธุ์: ${petUserData['price'] ?? ''}',
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
                              _deletePetData(petUserData['pet_id'],
                                  petUserData['user_id']);
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
            ],
          ),
        ),
      ),
    );
  }

  void _deletePetData(String petId_res, String Userid_res) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? petId_req = prefs.getString(userId);

      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      final String formatted =
          formatter.format(now.toUtc().add(Duration(hours: 7)));
      // อ้างอิงถึงเอกสาร userId ในคอลเลกชัน favorites
      DocumentReference userMatchRef_req =
          FirebaseFirestore.instance.collection('match').doc(userId);

      // อ้างอิงถึงคอลเลกชันย่อย pet_favorite ในเอกสาร userId
      CollectionReference petMatchRef_req =
          userMatchRef_req.collection('match_pet');

      // ดึงเอกสารที่มี pet_respone ตรงกับ petId
      QuerySnapshot querySnapshot_req = await petMatchRef_req
          .where('pet_request', isEqualTo: petId_req)
          .where('pet_respone', isEqualTo: petId_res)
          .where('status', isEqualTo: "จับคู่แล้ว")
          .get();

      if (querySnapshot_req.docs.isNotEmpty) {
        // สมมติว่า pet_id มีค่า unique ดังนั้นจะมีเอกสารเพียงเอกสารเดียว
        querySnapshot_req.docs.forEach((doc) async {
          await doc.reference
              .update({'status': 'ไม่ยอมรับ', 'updates_at': formatted});
        });
        DocumentReference userMatchRef_res =
            FirebaseFirestore.instance.collection('match').doc(Userid_res);

        // อ้างอิงถึงคอลเลกชันย่อย pet_favorite ในเอกสาร userId
        CollectionReference petMatchRef_res =
            userMatchRef_res.collection('match_pet');

        // ดึงเอกสารที่มี pet_respone ตรงกับ petId
        QuerySnapshot querySnapshot_res = await petMatchRef_res
            .where('pet_request', isEqualTo: petId_res)
            .where('pet_respone', isEqualTo: petId_req)
            .where('status', isEqualTo: "จับคู่แล้ว")
            .get();

        if (querySnapshot_res.docs.isNotEmpty) {
          // สมมติว่า pet_id มีค่า unique ดังนั้นจะมีเอกสารเพียงเอกสารเดียว
          querySnapshot_res.docs.forEach((doc) async {
            await doc.reference
                .update({'status': 'ไม่ยอมรับ', 'updates_at': formatted});
          });
          _getPetUserDataFromMatch_wait(); 
          _getPetUserDataFromMatch_paired();
        } else {
          print('No document found with pet_id: $petId_res');
        }
      } else {
        DocumentReference userMatchRef_req =
            FirebaseFirestore.instance.collection('match').doc(userId);

        // อ้างอิงถึงคอลเลกชันย่อย pet_favorite ในเอกสาร userId
        CollectionReference petMatchRef_req =
            userMatchRef_req.collection('match_pet');

        // ดึงเอกสารที่มี pet_respone ตรงกับ petId
        QuerySnapshot querySnapshot_req = await petMatchRef_req
            .where('pet_request', isEqualTo: petId_req)
            .where('pet_respone', isEqualTo: petId_res)
            .where('status', isEqualTo: "กำลังรอ")
            .get();
        if (querySnapshot_req.docs.isNotEmpty) {
          // สมมติว่า pet_id มีค่า unique ดังนั้นจะมีเอกสารเพียงเอกสารเดียว
          querySnapshot_req.docs.forEach((doc) async {
            await doc.reference
                .update({'status': 'ไม่ยอมรับ', 'updates_at': formatted});
          });
          _getPetUserDataFromMatch_wait(); 
          _getPetUserDataFromMatch_paired();
        }
      }
    } catch (e) {
      print('Error deleting pet data: $e');
    }
  }
}
