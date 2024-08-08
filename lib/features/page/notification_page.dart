import 'dart:convert';
import 'package:Pet_Fluffy/features/page/Profile_Pet_All.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class Notification_Page extends StatefulWidget {
  final String idPet;
  const Notification_Page({Key? key, required this.idPet}) : super(key: key);

  @override
  State<Notification_Page> createState() => _Notification_PageState();
}

class _Notification_PageState extends State<Notification_Page> {
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
    _getPetUserDataFromMatch_wait();
  }

  //ดึงข้อมูลจาก firebase
  Future<void> _getPetUserDataFromMatch_wait() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      userId = userData.uid;
      try {
        print(widget.idPet);
        // ดึงข้อมูลจากคอลเล็กชัน match โดยใช้ pet_respone เป็น idPet
        QuerySnapshot petUserQuerySnapshot_wait = await FirebaseFirestore
            .instance
            .collection('match')
            .where('pet_respone', isEqualTo: widget.idPet)
            .where('status', isEqualTo: "กำลังรอ")
            .get();

        List<Map<String, dynamic>> petRequestWithDescription =
            petUserQuerySnapshot_wait.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'pet_request': data['pet_request'],
            'description': data['description']
          };
        }).toList();

        List<Map<String, dynamic>> allPetDataList_wait = [];

        // ลูปเพื่อดึงข้อมูล pet_request ที่ได้จากเอกสารในคอลเล็กชัน match
        for (var petResponse in petRequestWithDescription) {
          String petRequestId = petResponse['pet_request'];
          String description = petResponse['description'];

          // ดึงข้อมูลจาก Pet_User โดยใช้ pet_request
          QuerySnapshot getPetQuerySnapshot = await FirebaseFirestore.instance
              .collection('Pet_User')
              .where('pet_id', isEqualTo: petRequestId)
              .get();

          // เพิ่มข้อมูลลงใน List พร้อมกับ description
          allPetDataList_wait.addAll(getPetQuerySnapshot.docs.map((doc) {
            final petData = doc.data() as Map<String, dynamic>;
            return {
              ...petData,
              'description': description // เพิ่ม description ที่นี่
            };
          }).toList());
        }

        // กรองข้อมูลที่ไม่ต้องการแสดง
        List<Map<String, dynamic>> nonDeletedPets = allPetDataList_wait
            .where((pet) => pet['status'] != 'ถูกลบ')
            .toList();

        // อัปเดต petUserDataList ด้วยข้อมูลทั้งหมดที่ได้รับ
        setState(() {
          petUserDataList_wait = nonDeletedPets;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(LineAwesomeIcons.angle_left),
        ),
        title: Text(
          "คำขอจับคู่",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,

        automaticallyImplyLeading: false, // กำหนดให้ไม่แสดงปุ่ม Back
      ),
      body: Container(
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
            : _buildPetList(allPetDataList_wait),
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
                Profile_pet_AllPage(petId: petUserData['pet_id']),
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
              Text(
                '  (${petUserData['breed_pet'] ?? ''})',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'รายละเอียด: ${petUserData['description'] ?? 'ไม่มีรายละเอียด'}',
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
                        title: const Text("ยืนยันการจับคู่"),
                        content: const Text(
                            "คุณต้องการที่จะยืนยันการจับคู่กับสัตว์เลี้ยงตัวนี้หรือไม่"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              print_deletePetData(
                                  petUserData['pet_id'] as String,
                                  petUserData['user_id'] as String);
                              _deletePetData(petUserData['pet_id'],
                                  petUserData['user_id']);
                              Navigator.of(context).pop();
                            },
                            child: const Text("ปฏิเสธการจับคู่"),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text("ยืนยันการจับคู่"),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(
                  LineAwesomeIcons.heart_1,
                  color: Colors.pink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void print_deletePetData(String petId, String userId) {
    print('Pet ID: $petId');
    print('User ID: $userId');
  }

  void _deletePetData(String petId_res, String Userid_res) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? petId_req = prefs.getString(userId);

      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      final String formatted =
          formatter.format(now.toUtc().add(Duration(hours: 7)));

      CollectionReference petMatchRef_req =
          FirebaseFirestore.instance.collection('match');

      QuerySnapshot querySnapshot_req = await petMatchRef_req
          .where('pet_respone', isEqualTo: petId_req)
          .where('pet_resquest', isEqualTo: petId_res)
          .where('status', isEqualTo: "จับคู่แล้ว")
          .get();

      if (querySnapshot_req.docs.isNotEmpty) {
        querySnapshot_req.docs.forEach((doc) async {
          await doc.reference
              .update({'status': 'ไม่ยอมรับ', 'updates_at': formatted});
        });

        CollectionReference petMatchRef_res =
            FirebaseFirestore.instance.collection('match');

        QuerySnapshot querySnapshot_res = await petMatchRef_res
            .where('pet_respone', isEqualTo: petId_req)
            .where('pet_resquest', isEqualTo: petId_res)
            .where('status', isEqualTo: "จับคู่แล้ว")
            .get();

        if (querySnapshot_res.docs.isNotEmpty) {
          querySnapshot_res.docs.forEach((doc) async {
            await doc.reference
                .update({'status': 'ไม่ยอมรับ', 'updates_at': formatted});
          });
          _getPetUserDataFromMatch_wait();
        } else {
          print('No document found with pet_id: $petId_res');
        }
      } else {
        CollectionReference petMatchRef_req =
            FirebaseFirestore.instance.collection('match');

        QuerySnapshot querySnapshot_req = await petMatchRef_req
            .where('pet_respone', isEqualTo: petId_req)
            .where('pet_resquest', isEqualTo: petId_res)
            .where('status', isEqualTo: "กำลังรอ")
            .get();
        if (querySnapshot_req.docs.isNotEmpty) {
          DocumentSnapshot docSnapshot = querySnapshot_req.docs.first;

          String idFav = docSnapshot.get('id_match');

          DocumentReference docRef = petMatchRef_req.doc(idFav);

          DocumentSnapshot docToCheck = await docRef.get();

          if (docToCheck.exists) {
            await docRef.delete();

            _getPetUserDataFromMatch_wait();

            print('Document with id_fav $idFav deleted successfully');
          } else {
            print('No document found with id_fav: $idFav');
          }
        }
      }
    } catch (e) {
      print('Error deleting pet data: $e');
    }
  }
}
