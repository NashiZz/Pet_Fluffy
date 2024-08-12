import 'dart:convert';
import 'package:Pet_Fluffy/features/page/Profile_Pet_All.dart';
import 'package:Pet_Fluffy/features/page/historyMatch.dart';
import 'package:Pet_Fluffy/features/page/matchSuccess.dart';
import 'package:Pet_Fluffy/features/services/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class Notification_Page extends StatefulWidget {
  final String idPet;
  const Notification_Page({Key? key, required this.idPet}) : super(key: key);

  @override
  State<Notification_Page> createState() => _Notification_PageState();
}

class _Notification_PageState extends State<Notification_Page>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> petUserDataList_wait = [];
  late List<Map<String, dynamic>> petUserDataList_pair = [];
  late List<Map<String, dynamic>> getPetDataList = [];
  User? user = FirebaseAuth.instance.currentUser;
  late String userId;
  late String id_fav;
  bool isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late List<Offset> _randomOffsets;
  bool _isAnimating = false;

  FirebaseAccessToken firebaseAccessToken = FirebaseAccessToken();

  @override
  void initState() {
    super.initState();
    _getPetUserDataFromMatch_wait();
    _setTokenfirebaseMassag();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // กำหนด Animation สำหรับ opacity
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  //สร้าง fcm_token
  Future<void> _setTokenfirebaseMassag() async {
    userId = user!.uid;
    final userDocRef =
        FirebaseFirestore.instance.collection('user').doc(userId);
    final userData = await userDocRef.get();
    if (userData.exists) {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('user').doc(userId).update({
          'fcm_token': token,
        });
      }
    }
  }

  Future<Map<String, dynamic>?> getPetDetails(String petId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Pet_User')
          .where('pet_id', isEqualTo: petId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final petData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        return {
          'name': petData['name'], // หรือชื่อฟิลด์ที่ใช้เก็บชื่อสัตว์เลี้ยง
          'img_profile':
              petData['img_profile'] // หรือชื่อฟิลด์ที่ใช้เก็บ URL ของรูปภาพ
        };
      }
    } catch (error) {
      print("Failed to get pet details: $error");
    }
    return null;
  }

  Future<String?> getPetName(String petId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Pet_User')
          .where('pet_id', isEqualTo: petId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final petData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        return petData['name']; // หรือชื่อฟิลด์ที่ใช้เก็บชื่อสัตว์เลี้ยง
      }
    } catch (error) {
      print("Failed to get pet name: $error");
    }
    return null;
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => Historymatch_Page(
                        idPet: widget.idPet,
                        idUser: userId,
                      )),
            );
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
      floatingActionButton: _isAnimating
          ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  children: List.generate(30, (index) {
                    return Positioned(
                      top: _randomOffsets[index].dy,
                      right: _randomOffsets[index].dx,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, -50 * _opacityAnimation.value),
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            )
          : null,
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
                            onPressed: () {
                              String petIdd = petUserData['pet_id'] as String;
                              String userIdd = petUserData['user_id'] as String;
                              String img_profile =
                                  petUserData['img_profile'] as String;
                              String name_petrep =
                                  petUserData['name'] as String;
                              String des = petUserData['description'] as String;

                              add_match(petIdd, userIdd, img_profile,
                                  name_petrep, des);
                              Navigator.of(context).pop();
                            },
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

  void _showHeartAnimation() {
    setState(() {
      _isAnimating = true;
      _animationController.forward().then((_) {
        Future.delayed(const Duration(seconds: 1), () {
          _animationController.reverse();
          setState(() {
            _isAnimating = false;
          });
        });
      });
    });
  }

  Future<void> add_match(String petIdd, String userIdd, String img_profile,
      String name_petrep, String des) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? petId = prefs.getString(userId.toString());
    String pet_request = petId.toString();
    String pet_respone = petIdd.toString();

    print(pet_request);
    print(pet_respone);

    // รับวันและเวลาปัจจุบันในโซนเวลาไทย
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formatted =
        formatter.format(now.toUtc().add(Duration(hours: 7)));

    CollectionReference petMatchRef =
        FirebaseFirestore.instance.collection('match');
    try {
      // ตรวจสอบว่ามีเอกสารที่มี pet_request และ pet_respone เดียวกันอยู่หรือไม่
      QuerySnapshot querySnapshot = await petMatchRef
          .where('pet_request', isEqualTo: pet_respone)
          .where('pet_respone', isEqualTo: pet_request)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // ถ้ามีเอกสารที่ซ้ำกันอยู่แล้ว ให้ทำการอัพเดตเอกสารนั้น
        querySnapshot.docs.forEach((doc) async {
          await doc.reference
              .update({'status': 'จับคู่แล้ว', 'updates_at': formatted});
        });

        try {
          // ตรวจสอบว่ามีเอกสารที่มี pet_request และ pet_respone เดียวกันอยู่หรือไม่
          QuerySnapshot querySnapshot = await petMatchRef
              .where('pet_request', isEqualTo: pet_request)
              .where('pet_respone', isEqualTo: pet_respone)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            // ถ้ามีเอกสารที่ซ้ำกันอยู่แล้ว
            setState(() {
              isLoading = false;
            });

            showDialog(
              context: context,
              builder: (BuildContext context) {
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.of(context)
                      .pop(true); // ปิดไดอะล็อกหลังจาก 1 วินาที
                });
                return const AlertDialog(
                  title: Text('Error'),
                  content: Text('สัตว์เลี้ยงนี้มีอยู่ในรายการแล้ว'),
                );
              },
            );
          } else {
            // ดึงข้อมูลของ pet_request
            Map<String, dynamic>? petRequestDetails =
                await getPetDetails(pet_request);

            // ถ้าไม่สามารถดึงข้อมูลได้ ให้ตั้งค่าค่าพื้นฐาน
            String petName = petRequestDetails?['name'] ?? 'Unknown';
            String petImg = petRequestDetails?['img_profile'] ?? '';

            // ถ้าไม่มีเอกสารที่ซ้ำกันอยู่
            DocumentReference newPetMatch = await petMatchRef.add({
              'created_at': formatted,
              'description': des,
              'pet_request': pet_request,
              'pet_respone': pet_respone,
              'status': 'จับคู่แล้ว',
              'updates_at': formatted
            });

            String docId = newPetMatch.id;

            await newPetMatch.update({'id_match': docId});

            sendNotificationToUser(
                userIdd, 'Pet fluffy', 'You have a new pet match!');
            // match success จะให้ไปที่หน้า match
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Matchsuccess_Page(
                    pet_request: petImg, // รูปสัตว์คนที่กด หัวใจ
                    pet_respone: img_profile, // รูปสัตว์คนที่โดนกด
                    idUser_pet: userIdd, // id user ที่โดนกดหัวใจ
                    pet_request_name: petName,
                    pet_respone_name: name_petrep,
                    idUser_petReq: userId.toString()), // id user ที่กดหัวใจ
              ),
            );
          }
        } catch (error) {
          print("Failed to add pet: $error");

          setState(() {
            isLoading = false;
          });
        }
      } else {
        try {
          // ตรวจสอบว่ามีเอกสารที่มี pet_request และ pet_respone เดียวกันอยู่หรือไม่
          QuerySnapshot querySnapshot = await petMatchRef
              .where('pet_request', isEqualTo: pet_request)
              .where('pet_respone', isEqualTo: pet_respone)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            // ถ้ามีเอกสารที่ซ้ำกันอยู่แล้ว
            setState(() {
              isLoading = false;
            });

            showDialog(
              context: context,
              builder: (BuildContext context) {
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.of(context)
                      .pop(true); // ปิดไดอะล็อกหลังจาก 1 วินาที
                });
                return const AlertDialog(
                  title: Text('Error'),
                  content: Text('สัตว์เลี้ยงนี้มีอยู่ในรายการแล้ว'),
                );
              },
            );
          } else {
            // ถ้าไม่มีเอกสารที่ซ้ำกันอยู่
            DocumentReference newPetMatch = await petMatchRef.add({
              'created_at': formatted,
              'description': des,
              'pet_request': pet_request,
              'pet_respone': pet_respone,
              'status': 'กำลังรอ',
              'updates_at': formatted
            });

            String docId = newPetMatch.id;

            await newPetMatch.update({'id_match': docId});

            setState(() {
              isLoading = false;
            });
            _showHeartAnimation();
          }

          _getPetUserDataFromMatch_wait();
        } catch (error) {
          print("Failed to add pet: $error");

          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (error) {
      print("Failed to add pet: $error");

      setState(() {
        isLoading = false;
      });
    }
  }

  void sendNotificationToUser(String userIdd, String title, String body) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('user').doc(userIdd).get();
    String? fcmToken = userDoc['fcm_token'];

    if (fcmToken != null) {
      await sendPushMessage(fcmToken, title, body);
    }
  }

  Future<void> sendPushMessage(
      String token_user, String title, String body) async {
    print(token_user);
    String token = await firebaseAccessToken.getToken();
    final data = {
      "message": {
        "token": token_user,
        "notification": {
          "body": "Pet Fluffy",
          "title": "มีการตอบรับจากสัตว์เลี้ยงที่คุณร้องขอแล้วไปดูเร็ว!!!"
        }
      }
    };
    try {
      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/login-3c8fb/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + token, // ใส่ Server Key ที่ถูกต้องที่นี่
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print("Notification sent successfully");
      } else {
        print("Failed to send notification");
        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (error) {
      print("Error sending notification: $error");
    }
  }
}
