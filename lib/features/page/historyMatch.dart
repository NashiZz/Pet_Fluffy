import 'dart:convert';
import 'package:Pet_Fluffy/features/page/Profile_Pet_All.dart';
import 'package:Pet_Fluffy/features/page/navigator_page.dart';
import 'package:Pet_Fluffy/features/page/notification_page.dart';
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
  late String petId;
  bool isLoading = true;
  int _currentIndex = 0; // ตัวแปรสถานะของแถบที่ถูกเลือก

  @override
  void initState() {
    super.initState();
    userId = user?.uid ?? '';
    _getPetUserDataFromMatch_wait(); // รอ
    _getPetUserDataFromMatch_paired(); // จับคู่แล้ว
    _initializePetId(); // กำหนดค่า petId
  }

  Future<void> _initializePetId() async {
    await getPetId();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> getPetId() async {
    try {
      // ดึงข้อมูลจาก Firestore
      DocumentSnapshot petDocSnapshot = await FirebaseFirestore.instance
          .collection('Usage_pet')
          .doc(userId)
          .get();

      // ตรวจสอบว่าข้อมูลผู้ใช้มีอยู่
      if (petDocSnapshot.exists) {
        // ดึง petId จาก Firestore
        petId = petDocSnapshot['pet_id'] ?? '';
        print('Pet ID from Firestore: $petId');
      } else {
        // หากเอกสารไม่พบ ตั้งค่า petId เป็นค่าเริ่มต้น
        petId = '';
        print('No document found for userId: $userId');
      }
    } catch (e) {
      // จัดการข้อผิดพลาด
      print('Error getting pet ID from Firestore: $e');
      petId = ''; // ตั้งค่า petId เป็นค่าเริ่มต้นในกรณีเกิดข้อผิดพลาด
    }
  }

  //ดึงข้อมูลจาก firebase
  Future<void> _getPetUserDataFromMatch_wait() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      userId = userData.uid;
      if (userId.isEmpty) {
        print('User ID is empty');
        return;
      }

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? petId = prefs.getString(userId);
        if (petId == null || petId.isEmpty) {
          print('Pet ID is empty');
          return;
        }

        // ดึงข้อมูลจากคอลเล็กชัน match_pet
        QuerySnapshot petUserQuerySnapshot_wait = await FirebaseFirestore
            .instance
            .collection('match')
            .where('pet_request', isEqualTo: petId)
            .where('status', isEqualTo: "กำลังรอ")
            .get();

        // ดึงข้อมูลจากเอกสารในรูปแบบ Map<String, dynamic> และดึงเฉพาะฟิลด์ pet_respone และ description
        List<Map<String, dynamic>> petResponsesWithDescription =
            petUserQuerySnapshot_wait.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'pet_respone': data['pet_respone'],
            'description': data['description']
          };
        }).toList();

        // ประกาศตัวแปร เพื่อรอรับข้อมูลใน for
        List<Map<String, dynamic>> allPetDataList_wait = [];

        // ลูปเพื่อดึงข้อมูลแต่ละรายการ
        for (var petResponse in petResponsesWithDescription) {
          String petResponseId = petResponse['pet_respone'];
          String description = petResponse['description'];

          // เก็บค่า petIdResponse ใน SharedPreferences
          prefs.setString('pet_id_respone', petResponseId);

          // ดึงข้อมูลจาก Pet_User
          QuerySnapshot getPetQuerySnapshot = await FirebaseFirestore.instance
              .collection('Pet_User')
              .where('pet_id', isEqualTo: petResponseId)
              .get();

          // เพิ่มข้อมูลลงใน List พร้อมกับ description และ user_id
          allPetDataList_wait.addAll(getPetQuerySnapshot.docs.map((doc) {
            final petData = doc.data() as Map<String, dynamic>;
            String userId = petData['user_id'];
            prefs.setString('pet_user_id_respone', userId);
            // ปริ้นค่า user_id
            print('User ID: $userId');
            return {
              ...petData,
              'description': description, // เพิ่ม description ที่นี่
            };
          }).toList());
        }

        // ส่วนที่ถูกนำไปแสดง
        List<Map<String, dynamic>> nonDeletedPets = allPetDataList_wait
            .where((pet) => pet['status'] != 'ถูกลบ')
            .toList();

        // ส่วนที่ถูกนำไปลบใน favorites
        List<Map<String, dynamic>> pet_Deleted = allPetDataList_wait
            .where((pet) => pet['status'] == 'ถูกลบ')
            .toList();

        for (var idpet_res in pet_Deleted) {
          String petResId = idpet_res['pet_id'];

          DocumentReference userFavoritesRef =
              FirebaseFirestore.instance.collection('match').doc(userId);
          CollectionReference petFavoriteRef =
              userFavoritesRef.collection('match_pet');
          // ดึงเอกสารที่มี pet_respone ตรงกับ petId
          QuerySnapshot querySnapshot = await petFavoriteRef
              .where('pet_respone', isEqualTo: petResId)
              .get();
          if (querySnapshot.docs.isNotEmpty) {
            // สมมติว่า pet_id มีค่า unique ดังนั้นจะมีเอกสารเพียงเอกสารเดียว
            DocumentSnapshot docSnapshot = querySnapshot.docs.first;

            String id_match = docSnapshot.get('id_match');

            DocumentReference docRef = petFavoriteRef.doc(id_match);

            // ตรวจสอบเอกสารก่อนที่จะลบ
            DocumentSnapshot docToCheck = await docRef.get();

            if (docToCheck.exists) {
              // ลบเอกสารโดยใช้ id_fav
              await docRef.delete();

              // ดึงข้อมูลใหม่หลังจากลบสำเร็จ (ถ้าต้องการ)
              _getPetUserDataFromMatch_wait(); // รอ
              _getPetUserDataFromMatch_paired();

              print('Document with id_match $id_match deleted successfully');
            } else {
              print('No document found with id_match: $id_match');
            }
          } else {
            print('No document found with pet_id: $petId');
          }
        }

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

  Future<void> _getPetUserDataFromMatch_paired() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      userId = userData.uid;
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? petId = prefs.getString(userId);
        print('petID: $petId');

        // ดึงข้อมูลจากคอลเล็กชัน match สำหรับ pet_request
        QuerySnapshot petUserQuerySnapshot_pair = await FirebaseFirestore
            .instance
            .collection('match')
            .where('pet_request', isEqualTo: petId)
            .where('status', isEqualTo: "จับคู่แล้ว")
            .get();

        // ดึงข้อมูลจากคอลเล็กชัน match สำหรับ pet_respone
        QuerySnapshot petUserQuerySnapshot_resp = await FirebaseFirestore
            .instance
            .collection('match')
            .where('pet_respone', isEqualTo: petId)
            .where('status', isEqualTo: "จับคู่แล้ว")
            .get();

        // รวมผลลัพธ์ของทั้งสอง query
        List<dynamic> petResponses = petUserQuerySnapshot_pair.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            
            .toList();
        petResponses.addAll(petUserQuerySnapshot_resp.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());

        List<Map<String, dynamic>> allPetDataList_pair = [];

        // ลูปเพื่อดึงข้อมูลแต่ละรายการจาก pet_request และ pet_respone
        for (var petRespone in petResponses) {
          String petResponeId = '';
          if (petId == petRespone['pet_respone']) {
            petResponeId = petRespone['pet_request'];
          } else if (petId == petRespone['pet_request']) {
            petResponeId = petRespone['pet_respone'];
          }

          print('petRespone: $petResponeId');
          print(petRespone['pet_request']);
          print(petRespone['pet_respone']);

          QuerySnapshot getPetQuerySnapshot = await FirebaseFirestore.instance
              .collection('Pet_User')
              .where('pet_id', isEqualTo: petResponeId)
              .get();

          allPetDataList_pair.addAll(getPetQuerySnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList());
        }

        // ส่วนที่ถูกนำไปแสดง
        List<Map<String, dynamic>> nonDeletedPets = allPetDataList_pair
            .where((pet) => pet['status'] != 'ถูกลบ')
            .toList();

        // ส่วนที่ถูกนำไปลบใน favorites
        List<Map<String, dynamic>> pet_Deleted = allPetDataList_pair
            .where((pet) => pet['status'] == 'ถูกลบ')
            .toList();

        for (var idpet_res in pet_Deleted) {
          String petResId = idpet_res['pet_id'];

          DocumentReference userFavoritesRef =
              FirebaseFirestore.instance.collection('match').doc(userId);
          CollectionReference petFavoriteRef =
              userFavoritesRef.collection('match_pet');

          QuerySnapshot querySnapshot = await petFavoriteRef
              .where('pet_respone', isEqualTo: petResId)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            DocumentSnapshot docSnapshot = querySnapshot.docs.first;
            String id_match = docSnapshot.get('id_match');
            DocumentReference docRef = petFavoriteRef.doc(id_match);

            DocumentSnapshot docToCheck = await docRef.get();

            if (docToCheck.exists) {
              await docRef.delete();
              _getPetUserDataFromMatch_wait();
              _getPetUserDataFromMatch_paired();

              print('Document with id_fav $id_match deleted successfully');
            } else {
              print('No document found with id_fav: $id_match');
            }
          } else {
            print('No document found with pet_id: $petId');
          }
        }

        setState(() {
          petUserDataList_pair = nonDeletedPets;
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
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      Navigator_Page(initialIndex: 0),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(-1.0, 0.0); // เริ่มต้นจากขวา
                    const end = Offset.zero; // สิ้นสุดที่ศูนย์กลาง (0.0, 0.0)
                    const curve = Curves.ease;

                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
                (route) => false, // ลบทุกเส้นทางก่อนหน้าออก
              );
            },
            icon: const Icon(LineAwesomeIcons.angle_left),
          ),
          title: Text(
            "การจับคู่",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                notification_Page();
              },
              icon: Icon(
                Icons.notifications_rounded,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          automaticallyImplyLeading: false, // กำหนดให้ไม่แสดงปุ่ม Back
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
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
            : (petId == null || petId.isEmpty)
                ? Center(
                    child: Text('คุณยังไม่มีข้อมูลสัตว์เลี้ยง'),
                  )
                : TabBarView(
                    children: [
                      _buildPetList(allPetDataList_wait),
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
              // แสดง description ที่ดึงมาจาก Firestore
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
                      bool isMatching =
                          _currentIndex == 1; // 1 สำหรับ "จับคู่แล้ว"

                      return AlertDialog(
                        title: Column(
                          children: [
                            const Icon(LineAwesomeIcons.heart_1,
                                color: Colors.pink, size: 50),
                            SizedBox(height: 20),
                            Text(
                              isMatching
                                  ? 'คุณต้องการที่จะลบการจับคู่กับ'
                                  : 'คุณต้องการลบคำร้องขอการจับคู่กับ',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                        content: Text(
                          "${petUserData['name']} ?",
                          style:
                              TextStyle(fontSize: 30, color: Colors.deepPurple),
                          textAlign: TextAlign.center,
                        ),
                        actions: <Widget>[
                          SizedBox(height: 20),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                      _deletePetData(petUserData['pet_id'],
                                          petUserData['user_id']);
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

      // ฟังก์ชันอัปเดตสถานะ
      Future<void> updateMatchStatus(QuerySnapshot querySnapshot) async {
        if (querySnapshot.docs.isNotEmpty) {
          for (var doc in querySnapshot.docs) {
            await doc.reference
                .update({'status': 'ไม่ยอมรับ', 'updates_at': formatted});
          }
          _getPetUserDataFromMatch_wait();
          _getPetUserDataFromMatch_paired();
        } else {
          print('No document found with pet_id: $petId_res');
        }
      }

      // ดึงข้อมูลจาก match สำหรับ pet_request
      QuerySnapshot querySnapshot_req = await FirebaseFirestore.instance
          .collection('match')
          .where('pet_request', isEqualTo: petId_req)
          .where('pet_respone', isEqualTo: petId_res)
          .where('status', isEqualTo: "จับคู่แล้ว")
          .get();

      // อัปเดตสถานะสำหรับ pet_request
      await updateMatchStatus(querySnapshot_req);

      // ดึงข้อมูลจาก match สำหรับ pet_respone
      QuerySnapshot querySnapshot_res = await FirebaseFirestore.instance
          .collection('match')
          .where('pet_request', isEqualTo: petId_res)
          .where('pet_respone', isEqualTo: petId_req)
          .where('status', isEqualTo: "จับคู่แล้ว")
          .get();

      // อัปเดตสถานะสำหรับ pet_respone
      await updateMatchStatus(querySnapshot_res);

      // ตรวจสอบสถานะ 'กำลังรอ' สำหรับ pet_request
      QuerySnapshot querySnapshot_wait_req = await FirebaseFirestore.instance
          .collection('match')
          .where('pet_request', isEqualTo: petId_req)
          .where('pet_respone', isEqualTo: petId_res)
          .where('status', isEqualTo: "กำลังรอ")
          .get();

      if (querySnapshot_wait_req.docs.isNotEmpty) {
        DocumentSnapshot docSnapshot = querySnapshot_wait_req.docs.first;
        String idFav = docSnapshot.get('id_match');
        DocumentReference docRef =
            FirebaseFirestore.instance.collection('match').doc(idFav);

        DocumentSnapshot docToCheck = await docRef.get();

        if (docToCheck.exists) {
          await docRef.delete();
          _getPetUserDataFromMatch_wait();
          _getPetUserDataFromMatch_paired();
          print('Document with id_fav $idFav deleted successfully');
        } else {
          print('No document found with id_fav: $idFav');
        }
      }
    } catch (e) {
      print('Error deleting pet data: $e');
    }
  }

  void notification_Page() async {
    // ตรวจสอบให้แน่ใจว่า petId ได้รับค่าแล้ว
    if (petId.isNotEmpty) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              Notification_Page(idPet: petId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    } else {
      print('Pet ID is not available');
    }
  }
}
