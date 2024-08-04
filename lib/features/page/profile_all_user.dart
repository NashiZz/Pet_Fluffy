import 'dart:convert';
import 'dart:developer';

import 'package:Pet_Fluffy/features/page/navigator_page.dart';
import 'package:Pet_Fluffy/features/page/randomMatch.dart';
import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

//หน้า Profile ของ ผู้ใช้ทั้งหมด
class ProfileAllUserPage extends StatefulWidget {
  final String userId;
  final String userId_req;
  const ProfileAllUserPage(
      {Key? key, required this.userId, required this.userId_req})
      : super(key: key);

  @override
  State<ProfileAllUserPage> createState() => _ProfileAllUserPageState();
}

class _ProfileAllUserPageState extends State<ProfileAllUserPage> {
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  late int numPet = 0;
  late Map<String, dynamic> userData = {};
  late User? user;
  late List<Map<String, dynamic>> petUserDataList = [];
  late String userImageBase64 = '';
  late String username = '';
  int dogCount = 0;
  int catCount = 0;
  bool isCheckMatch = false;

  @override
  void initState() {
    super.initState();
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _getUserDataFromFirestore(widget.userId);
      _getPetUserDataFromFirestore(widget.userId);
      _getIsCheckMatchSuccess();
    }
  }

  Future<void> _getIsCheckMatchSuccess() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? petId = prefs.getString(widget.userId_req);
    String pet_respone = petId.toString();
    
    DocumentReference matchRef =
        FirebaseFirestore.instance.collection('match').doc(widget.userId);

    CollectionReference petMatchRef = matchRef.collection('match_pet');
    try {
      QuerySnapshot querySnapshot = await petMatchRef
          .where('pet_respone', isEqualTo: pet_respone)
          .where('status', isEqualTo: 'จับคู่แล้ว')
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          isCheckMatch = true;
        }); 
      }

    } catch (e) {}
  }

  // Future<void> _showNotification() async {
  //   const AndroidNotificationDetails androidNotificationDetails =
  //       AndroidNotificationDetails('Pet_Fluffy', 'แจ้งเตือนทั่วไป',
  //           importance: Importance.max,
  //           priority: Priority.high,
  //           ticker: 'ticker');

  //   const NotificationDetails platformChannelDetail = NotificationDetails(
  //     android: androidNotificationDetails,
  //   );

  //   await _flutterLocalNotificationsPlugin.show(
  //       0,
  //       'ใกล้ถึงเวลาการผสมพันธุ์แล้วนะ',
  //       'น้องสุนัข: ชินโนะสุเกะ ใกล้ถึงเวลาการผสมพันธุ์ในอีก 9 วัน',
  //       platformChannelDetail);
  // }

  Future<void> _getPetUserDataFromFirestore(String userId) async {
    try {
      QuerySnapshot petUserQuerySnapshot = await FirebaseFirestore.instance
          .collection('Pet_User')
          .where('user_id', isEqualTo: userId)
          .get();

      //นับจำนวนสัตว์เลี้ยงทั้งหมด
      numPet = petUserQuerySnapshot.docs.length;

      // นับจำนวนสัตว์เลี้ยงแต่ละชนิด
      petUserQuerySnapshot.docs.forEach((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String petType = data['type_pet'];

        if (petType == 'สุนัข') {
          dogCount++;
        } else if (petType == 'แมว') {
          catCount++;
        }
      });

      setState(() {
        petUserDataList = petUserQuerySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print('Error getting pet user data from Firestore: $e');
    }
  }

  Future<void> _getUserDataFromFirestore(String userId) async {
    try {
      DocumentSnapshot userDocSnapshot =
          await FirebaseFirestore.instance.collection('user').doc(userId).get();

      setState(() {
        userData = userDocSnapshot.data() as Map<String, dynamic>;
        userImageBase64 = userData['photoURL'] ?? '';
        username = userData['username'] ?? '';
      });
    } catch (e) {
      print('Error getting user data from Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final RouteSettings settings = ModalRoute.of(context)!.settings;
    final String? previousPage = settings.name;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              // Navigator.pop(context);

              if (previousPage.toString() == 'matchSuccess') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => Navigator_Page(initialIndex: 0)),
                  (Route<dynamic> route) => false,
                );
              }
              else {
                Navigator.pop(context);
              }
            },
            icon: const Icon(LineAwesomeIcons.angle_left)),
        title: Text(
          "โปรไฟล์ $username",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: userImageBase64.isNotEmpty
                            ? Image.memory(
                                base64Decode(userImageBase64),
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                              )
                            : const CircularProgressIndicator(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userData['username'] ?? '',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 20, 0),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          numPet.toString(),
                          style: TextStyle(
                            fontSize: 24,
                          ),
                        ),
                        const Text(
                          'สัตว์เลี้ยง',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Text(
                                'สุนัข: $dogCount แมว: $catCount',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey.shade600),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ButtonsTabBar(
                      backgroundColor: const Color.fromARGB(255, 65, 65, 65),
                      unselectedBackgroundColor: Colors.grey[300],
                      labelStyle: GoogleFonts.kanit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: GoogleFonts.kanit(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      radius: 100,
                      buttonMargin: const EdgeInsets.fromLTRB(0, 5, 30, 5),
                      tabs: const [
                        Tab(
                          text: "ข้อมูลของผู้ใช้",
                        ),
                        Tab(
                          text: "ข้อมูลติดต่อ",
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: <Widget>[
                          Column(
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 20, 50, 20),
                                    child: Text(
                                        'ชื่อเล่น : ${userData['nickname'] ?? ''}',
                                        style: const TextStyle(fontSize: 16)),
                                  ),
                                  Text('เพศ : ${userData['gender'] ?? ''}',
                                      style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                              const Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(20, 0, 50, 0),
                                    child: Text('อายุ : 21',
                                        style: TextStyle(fontSize: 16)),
                                  ),
                                  Text('จังหวัด : อุดรธานี',
                                      style: TextStyle(fontSize: 16)),
                                ],
                              )
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 20, 80, 10),
                                child: isCheckMatch == false
                                    ? Text('เบอร์โทรศัพท์ : ',
                                        style: const TextStyle(fontSize: 16))
                                    : Text(
                                        'เบอร์โทรศัพท์ : ${userData['phone'] }',
                                        style: const TextStyle(fontSize: 16)),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 10, 80, 10),
                                child: isCheckMatch == false
                                    ? Text('Facebook : ',
                                        style: const TextStyle(fontSize: 16))
                                    : Text(
                                        'Facebook : ${userData['facebook']}',
                                        style: const TextStyle(fontSize: 16)),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 10, 80, 10),
                                child: isCheckMatch == false
                                    ? Text('Line : ',
                                        style: const TextStyle(fontSize: 16))
                                    : Text('Line : ${userData['line']}',
                                        style: const TextStyle(fontSize: 16)),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: DefaultTabController(
                length: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ButtonsTabBar(
                      backgroundColor: const Color.fromARGB(255, 65, 65, 65),
                      unselectedBackgroundColor: Colors.white,
                      labelStyle: GoogleFonts.kanit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: GoogleFonts.kanit(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      radius: 100,
                      tabs: const [
                        Tab(
                          text: "สัตว์เลี้ยงของผู้ใช้",
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        children: <Widget>[
                          GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: petUserDataList.length,
                            itemBuilder: (context, index) {
                              Map<String, dynamic> petData =
                                  petUserDataList[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(8.0),
                                        bottom: Radius.circular(8.0),
                                      ),
                                      child: Image.memory(
                                        base64Decode(petData['img_profile']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      petData['name'],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
