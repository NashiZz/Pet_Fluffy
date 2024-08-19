// ignore_for_file: camel_case_types, file_names, avoid_print
import 'dart:math';

import 'package:Pet_Fluffy/features/page/login_page.dart';
import 'package:Pet_Fluffy/features/page/navigator_page.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/PetDegreeDetail.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/showDialogContest.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/showDialogHistory_Match.dart';
import 'package:Pet_Fluffy/features/page/profile_all_user.dart';
import 'package:Pet_Fluffy/features/services/auth.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:Pet_Fluffy/features/api/user_data.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/table_dataVac.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/periodDetail_Page.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/vacDetail_Page.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/vac_More.dart';
import 'package:Pet_Fluffy/features/services/age_calculator_service.dart';
import 'package:Pet_Fluffy/features/services/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

//หน้า Profile ของ สัตว์เลี้ยง
class Profile_pet_AllPage extends StatefulWidget {
  final String petId;
  const Profile_pet_AllPage({super.key, required this.petId});

  @override
  State<Profile_pet_AllPage> createState() => _Profile_pet_AllPageState();
}

class _Profile_pet_AllPageState extends State<Profile_pet_AllPage>
    with TickerProviderStateMixin {
  FirebaseAccessToken firebaseAccessToken = FirebaseAccessToken();
  final ProfileService _profileService = ProfileService();
  final AgeCalculatorService _ageCalculatorService = AgeCalculatorService();
  late AnimationController _animationController;
  bool _isAnimating = false;
  bool _offsetsInitialized = false;
  late List<Offset> _randomOffsets;
  late Animation<double> _opacityAnimation;
  bool hasPrimaryPet = false;
  bool _isPetMatching = false;

  User? user = FirebaseAuth.instance.currentUser;

  String pet_user = '';
  String pet_id = '';
  String petName = '';
  String type = '';
  String petImageBase64 = '';
  String petImageBanner = '';
  String weight = '';
  String color = '';
  String gender = '';
  String des = '';
  String birthdateStr = '';
  String age = '';
  String price = '';
  String userPhotoURL = '';
  String pet_type = '';
  String status = '';

  String? petId_main;
  String? petType;
  String? petGender;
  String? namePet;

  String? userId;
  String? userImageBase64;

  bool isLoading = true;
  late List<Map<String, dynamic>> petUserDataList = [];
  List<Map<String, dynamic>> vaccinationSchedule = [];
  List<Map<String, dynamic>> vaccination_Table = [];
  List<Map<String, dynamic>> vaccinationDataFromFirestore = [];

  final double coverHeight = 180;
  final double profileHeight = 90;

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.petId.isNotEmpty) {
      _checkPetMatchStatus();
      _getUsage_pet();
      _loadAllPet(widget.petId);
      _getUserDataFromFirestore();
      _fetchVaccinationData();
    }
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // กำหนด Animation สำหรับ opacity
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    isLoading = true;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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

  void _initializeOffsets(BuildContext context) {
    if (!_offsetsInitialized) {
      final Random _random = Random();
      final double screenWidth = MediaQuery.of(context).size.width;
      final double screenHeight = MediaQuery.of(context).size.height;
      final double iconSize = 100.0; // ขนาดของไอคอน
      _randomOffsets = List.generate(30, (index) {
        return Offset(
          _random.nextDouble() *
              (screenWidth - iconSize), // ปรับตำแหน่งให้อยู่ภายในหน้าจอ
          _random.nextDouble() * (screenHeight - iconSize),
        );
      });
      _offsetsInitialized = true;
    }
  }

  Future<bool> _isPetInMatch(String petId) async {
    try {
      // ตรวจสอบว่า `petId` กำลังจับคู่หรือกำลังรอ
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('match')
          .where('pet_request', isEqualTo: petId)
          .where('status', whereIn: ["จับคู่แล้ว", "กำลังรอ"]).get();

      // ตรวจสอบอีกครั้งสำหรับ pet_respone
      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('match')
            .where('pet_respone', isEqualTo: petId)
            .where('status', whereIn: ["จับคู่แล้ว", "กำลังรอ"]).get();
      }

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking match status: $e');
      return false;
    }
  }

  Future<void> _checkPetMatchStatus() async {
    final petId = widget.petId;
    bool isMatching = await _isPetInMatch(petId);

    setState(() {
      _isPetMatching = isMatching;
    });
  }

  // ดึงข้อมูล User
  void _getUserDataFromFirestore() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      userId = userData.uid;
      Map<String, dynamic>? userDataFromFirestore =
          await _profileService.getUserData(userId!);
      if (userDataFromFirestore != null) {
        userImageBase64 = userDataFromFirestore['photoURL'] ?? '';
        setState(() {
          isLoading = false;
        });
      }
    }
    print(userId);
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
          petId_main = userDocSnapshot['pet_id'] as String?;

          // ตรวจสอบว่าค่าของ petId ไม่เป็น null และไม่ว่าง
          if (petId_main != null && petId_main!.isNotEmpty) {
            hasPrimaryPet = true;

            // ค้นหาข้อมูลในคอลเลคชัน Pet_user เพื่อดึงประเภทสัตว์เลี้ยงและเพศ
            DocumentSnapshot petDocSnapshot = await FirebaseFirestore.instance
                .collection('Pet_User')
                .doc(petId_main)
                .get();

            if (petDocSnapshot.exists) {
              setState(() {
                namePet = petDocSnapshot['name'] as String?;
                petType = petDocSnapshot['type_pet'] as String?;
                petGender = petDocSnapshot['gender'] as String?;
                isLoading = false;
              });

              print('Type : $petType, Gender : $petGender');
            } else {
              print('No pet data found with pet_id: $petId_main');
            }
          } else {
            print('No primary pet assigned.');
            hasPrimaryPet = false;
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

  Future<void> _loadAllPet(String petId) async {
    try {
      Map<String, dynamic> petData = await _profileService.loadPetData(petId);
      setState(() {
        pet_user = petData['user_id'] ?? '';
        pet_id = petId;
        petName = petData['name'] ?? '';
        type = petData['breed_pet'] ?? '';
        petImageBase64 = petData['img_profile'] ?? '';
        petImageBanner = petData['img_Banner'] ?? '';
        color = petData['color'] ?? '';
        weight = petData['weight'] ?? '0.0';
        gender = petData['gender'] ?? '';
        des = petData['description'] ?? '';
        price = petData['price'] ?? '';
        birthdateStr = petData['birthdate'] ?? '';
        pet_type = petData['type_pet'] ?? '';
        DateTime birthdate = DateTime.parse(birthdateStr);
        age = _ageCalculatorService.calculateAge(birthdate);
        status = petData['status'] ?? 'มีชีวิต';

        vaccinationSchedule =
            (pet_type == 'สุนัข') ? vaccinationDog : vaccinationCat;

        vaccination_Table =
            (pet_type == 'สุนัข') ? vaccinationDog_Table : vaccinationCat_Table;

        _fetchVaccinationData();

        isLoading = false;
      });
      print(
          'Pet user ID: $pet_user'); // เพิ่มเพื่อดูค่า pet_user ว่าถูกต้องหรือไม่
    } catch (e) {
      print('Error getting pet user data from Firestore: $e');
    }
  }

  void showImageDialog(BuildContext context, String imageUrl) {
    try {
      final decodedImage = base64Decode(imageUrl);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  child: Image.memory(
                    decodedImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('Error decoding base64 image: $e');
      // แสดงภาพพื้นฐานหรือข้อความข้อผิดพลาด
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Could not decode image.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
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

  // ดึงข้อมูล Vac_table ที่บันทึกลงไป
  Future<void> _fetchVaccinationData() async {
    if (pet_user.isEmpty || pet_id.isEmpty) {
      print('Pet user or Pet ID is empty.');
      return;
    }

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('vac_history')
          .doc(pet_user)
          .collection('vac_pet')
          .where('pet_id', isEqualTo: pet_id)
          .get();

      setState(() {
        vaccinationDataFromFirestore = querySnapshot.docs.map((doc) {
          return {
            'status': doc['status'] ?? 'ไม่ระบุ',
            'vaccine': doc['vacName'] ?? 'ไม่ระบุ',
            'date': doc['date'] ?? 'ไม่ระบุ',
            'weight': doc['weight'] ?? 'ไม่ระบุ',
            'price': doc['price'] ?? 'ไม่ระบุ',
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching vaccination data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeOffsets(context);
    List<Tab> myTabs = [];
    List<Widget> myTabViews = [];

    if (gender == 'ตัวผู้') {
      myTabs = [
        Tab(text: 'ข้อมูลทั่วไป'),
        Tab(text: 'ประวัติสุขภาพ'),
      ];
      myTabViews = [
        _buildGeneralInfoTab(),
        _buildHealthHistoryTab(),
      ];
    } else {
      myTabs = [
        Tab(text: 'ข้อมูลทั่วไป'),
        Tab(text: 'ประจำเดือน'),
        Tab(text: 'ประวัติสุขภาพ'),
      ];
      myTabViews = [
        _buildGeneralInfoTab(),
        _buildMonthlyInfoTab(),
        _buildHealthHistoryTab(),
      ];
    }

    if (_tabController == null) {
      if (gender == 'ตัวเมีย') {
        _tabController = TabController(length: 3, vsync: this);
      } else if (gender == 'ตัวผู้') {
        _tabController = TabController(length: 2, vsync: this);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "โปรไฟล์สัตว์เลี้ยง",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                des,
                                style: const TextStyle(fontSize: 16),
                              ),
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
                    length: myTabs.length,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            tabs: myTabs,
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: myTabViews,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
          : Visibility(
              visible: !_isPetMatching, // Hide SpeedDial if pet is matching
              child: SpeedDial(
                icon: Icons.menu,
                foregroundColor: Colors.white,
                activeIcon: Icons.close,
                backgroundColor: Colors.blue,
                overlayColor: Colors.black,
                overlayOpacity: 0.5,
                children: [
                  SpeedDialChild(
                    child: Icon(Icons.star, color: Colors.yellow.shade700),
                    label: 'ถูกใจ',
                    onTap: (hasPrimaryPet && !user!.isAnonymous)
                        ? () {
                            add_Faverite(pet_id);
                          }
                        : () {
                            if (user!.isAnonymous) {
                              _showSignInDialog(context);
                            } else {
                              _showNoPrimaryPetDialog(context);
                            }
                          },
                  ),
                  SpeedDialChild(
                    child: Icon(
                      Icons.favorite,
                      color: Colors.pinkAccent,
                    ),
                    label: 'ขอจับคู่',
                    onTap: (hasPrimaryPet && !user!.isAnonymous)
                        ? () {
                            _showRequestDialog(
                              context,
                              petName,
                              pet_id,
                              pet_user,
                              petImageBase64,
                            );
                          }
                        : () {
                            if (user!.isAnonymous) {
                              _showSignInDialog(context);
                            } else {
                              _showNoPrimaryPetDialog(context);
                            }
                          },
                  ),
                ],
              ),
            ),
    );
  }

  // Tab ข้อมูลทั่วไป
  Widget _buildGeneralInfoTab() {
    return SingleChildScrollView(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        ? const Icon(Icons.male, size: 30, color: Colors.purple)
                        : gender == 'ตัวเมีย'
                            ? const Icon(Icons.female,
                                size: 30, color: Colors.pink)
                            : const Icon(Icons.help_outline,
                                size: 30, color: Colors.black),
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  MenuPetWidget(
                      title: "ประวัติการจับคู่",
                      icon: LineAwesomeIcons.history,
                      onPress: () => showHistoryDialog(
                          context: context, userId: pet_user, petId: pet_id)),
                  MenuPetWidget(
                      title: "การประกวด",
                      icon: LineAwesomeIcons.certificate,
                      onPress: () => showContestDialog(
                          context: context,
                          userId: pet_user,
                          petId: pet_id,
                          userPet: userId ?? '')),
                  MenuPetWidget(
                    title: "ใบเพ็ดดีกรี",
                    icon: LineAwesomeIcons.dna,
                    onPress: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  PetdigreeDetailPage(
                            userId: pet_user,
                            petId: pet_id,
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.ease;

                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  MenuPetWidget(
                    title: "ค่าการผสมพันธุ์",
                    icon: LineAwesomeIcons.coins,
                    trailingText:
                        price.isNotEmpty ? '$price บาท' : 'ไม่มีค่าใช้จ่าย',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
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
                Spacer(),
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
                  List<String> imageUrls = [];

                  // รวมรูปภาพทั้งหมดที่มีในเอกสารที่เกี่ยวข้องกับ pet_id
                  for (var imgDoc in snapshot.data!.docs) {
                    Map<String, dynamic>? data =
                        imgDoc.data() as Map<String, dynamic>?;
                    if (data != null && data.isNotEmpty) {
                      for (int i = 1; i <= 9; i++) {
                        String? imageUrl = data['img_$i'] as String?;
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          imageUrls.add(imageUrl);
                        }
                      }
                    }
                  }

                  if (imageUrls.isNotEmpty) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            showImageDialog(context, imageUrls[index]);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: Image.memory(
                              base64Decode(imageUrls[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return const Text('ไม่มีรูปภาพ');
                  }
                }

                // กรณีไม่มีเอกสารที่ตรงกับ pet_id
                return const Text('ไม่มีรูปภาพ');
              },
            ),

            const SizedBox(height: 5),
          ]),
    );
  }

  // Tab ข้อมูลประจำเดือน เฉพาะตัวเมีย
  Widget _buildMonthlyInfoTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 15),
          Row(
            children: [
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 5),
                    child: Icon(LineAwesomeIcons.calendar_with_day_focus),
                  ),
                  Text(
                    'บันทึกประจำเดือน',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
              Spacer(),
            ],
          ),
          SizedBox(height: 10),
          // แสดงข้อมูลบันทึกประจำเดือน
          FutureBuilder<QuerySnapshot>(
            future: (pet_user.isNotEmpty)
                ? FirebaseFirestore.instance
                    .collection('report_period')
                    .doc(pet_user)
                    .collection('period_pet')
                    .where('pet_id', isEqualTo: widget.petId)
                    .orderBy('date', descending: true)
                    .get()
                : null,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot reportDoc = snapshot.data!.docs[index];
                    Map<String, dynamic> report =
                        reportDoc.data() as Map<String, dynamic>;
                    final date = DateTime.parse(report['date']);

                    // Create a DateFormat with the Thai locale
                    final formattedDate =
                        DateFormat('d MMM yyyy', 'th_TH').format(date);
                    final idPeriod = reportDoc.id;

                    return GestureDetector(
                      onTap: () {
                        // แสดงข้อมูลทั้งหมดใน BottomSheet เมื่อคลิกที่ Card
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    PeriodDetailPage(
                              report: report,
                              userId: pet_user,
                              idPeriod: idPeriod,
                            ),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.ease;

                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));

                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.pinkAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  LineAwesomeIcons.calendar_with_day_focus,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'รายละเอียดการบันทึกประจำเดือน',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      report['des'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              return Text('ไม่มีบันทึกประจำเดือน');
            },
          )
        ],
      ),
    );
  }

  // Tab ข้อมูลประวัติสุขภาพ
  Widget _buildHealthHistoryTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 15),
          Row(
            children: [
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 5),
                    child: Icon(LineAwesomeIcons.syringe),
                  ),
                  Text(
                    'การฉีดวัคซีน (ตามเกณฑ์)',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
              Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                MenuPetWidget(
                  title: "ดูตารางการฉีดวัคซีน",
                  icon: LineAwesomeIcons.table,
                  onPress: () {
                    _showVaccinationScheduleDialog(context, pet_type);
                  },
                ),
              ],
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.33,
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Table(
                        border: TableBorder.all(),
                        columnWidths: const <int, TableColumnWidth>{
                          0: FixedColumnWidth(80),
                          1: FixedColumnWidth(180),
                          2: FixedColumnWidth(100),
                          3: FixedColumnWidth(80),
                          4: FixedColumnWidth(80),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: <TableRow>[
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                            ),
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'สถานะ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'วัคซีน (เข็มที่)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'วัน/เดือน/ปี',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'น้ำหนัก',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'ราคา',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          ..._buildTableRows(vaccination_Table),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: Icon(LineAwesomeIcons.syringe),
                      ),
                      Text(
                        'การฉีดวัคซีน (เพิ่มเติม)',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                  Spacer(),
                ],
              ),
              const SizedBox(height: 5),
              // แสดงข้อมูลบันทึกวัคซีน
              FutureBuilder<QuerySnapshot>(
                future: (pet_user.isNotEmpty)
                    ? FirebaseFirestore.instance
                        .collection('vac_more')
                        .doc(pet_user)
                        .collection('vac_pet')
                        .where('pet_id', isEqualTo: widget.petId)
                        .orderBy('date', descending: true)
                        .get()
                    : null,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot reportDoc = snapshot.data!.docs[index];
                        Map<String, dynamic> report =
                            reportDoc.data() as Map<String, dynamic>;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        VaccineDetailPage(
                                  report: report,
                                  userId: pet_user,
                                  pet_type: pet_type,
                                ),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.ease;

                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));

                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          child: VaccineCard(report: report),
                        );
                      },
                    );
                  }
                  return Text('ไม่มีบันทึกการฉีดวัคซีนเพิ่มเติม');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTop() {
    final top = coverHeight - profileHeight / 2;
    final bottom = profileHeight / 2;

    Color getStatusColor(String status) {
      switch (status) {
        case 'เสียชีวิต':
          return Colors.red;
        case 'พร้อมผสมพันธุ์':
          return Colors.pinkAccent;
        case 'ไม่พร้อมผสมพันธุ์':
          return Colors.grey;
        default:
          return Colors.green;
      }
    }

    return FutureBuilder<DocumentSnapshot>(
      future: ApiUserService.getUserData(pet_user),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
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
              child: buildCoverImage(),
            ),
            Positioned(
              top: top,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                    child: Stack(
                      children: [
                        buildProfileImage(context, status),
                        Positioned(
                          top: 80,
                          right: 5,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: getStatusColor(status),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 55, 0, 0),
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
                        ),
                        Text(
                          '($status)',
                          style: TextStyle(
                            color: getStatusColor(status),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                      child: GestureDetector(
                        onTap: () {
                          print(pet_user);
                          print(pet_user);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileAllUserPage(
                                userId: pet_user,
                                userId_req: pet_user,
                              ),
                            ),
                          );
                        },
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
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // รูป Banner
  Widget buildCoverImage() => Stack(
        children: [
          Container(
            width: double.infinity,
            height: coverHeight,
            color: Colors.grey,
            child: petImageBanner.isNotEmpty
                ? Image.memory(
                    base64Decode(petImageBanner),
                    width: double.infinity,
                    height: coverHeight,
                    fit: BoxFit.cover,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );

  // รูป Profile
  Widget buildProfileImage(BuildContext context, String status) {
    return GestureDetector(
      onTap: () => showImageDialog(context, petImageBase64),
      child: Container(
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
      ),
    );
  }

  // แสดงตารางการฉีดวัคซีนตามเกณฑ์
  void _showVaccinationScheduleDialog(BuildContext context, String petType) {
    List<Map<String, String>> vaccinationSchedule =
        (petType == 'สุนัข') ? vaccinationDog : vaccinationCat;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.65,
            padding: EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Spacer(), // ใช้ Spacer เพื่อดัน IconButton ไปทางขวา
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                Center(
                  child: Text(
                    'ตารางการฉีดวัคซีน',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Table(
                        border: TableBorder.all(),
                        columnWidths: const <int, TableColumnWidth>{
                          0: FixedColumnWidth(70),
                          1: FixedColumnWidth(160),
                          2: FixedColumnWidth(70),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: <TableRow>[
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                            ),
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'อายุ/สัปดาห์',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'วัคซีน (เข็มที่)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'โปรแกรมการฉีด',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          ..._buildTableVac(vaccinationSchedule),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRequestDialog(BuildContext context, petName, petId, petUser, Img) {
    TextEditingController des = TextEditingController();
    print(
        'petrequest: $petId_main ,petrespone: $petId, userid: $petUser, name: $namePet');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      'ส่งคำขอจับคู่ไปหา ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      petName,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade600),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 150,
                height: 120,
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.memory(
                      base64Decode(Img),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: des,
                decoration: InputDecoration(
                  hintText: 'พิมพ์ข้อความที่ต้องการส่งไปหา....',
                ),
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.deepPurpleAccent, // เปลี่ยนสีพื้นหลังของปุ่ม
                    ),
                    child: Text('ยกเลิกการส่งคำขอ',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      add_match(petId, petUser, Img, petName, des.text);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                Navigator_Page(initialIndex: 0)),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.pinkAccent, // เปลี่ยนสีพื้นหลังของปุ่ม
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            LineAwesomeIcons.paper_plane_1,
                            color: Colors.white,
                          ),
                        ),
                        Text('ส่งคำขอ', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showSignInDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('กรุณาลงทะเบียน'),
          content: const Text(
            'คุณต้องลงทะเบียนเพื่อใช้ฟังก์ชันนี้',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
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
                onPressed: () async {
                  try {
                    await user?.delete();
                    print("Anonymous account deleted");
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                    );
                  } catch (e) {
                    print("Error deleting anonymous account: $e");
                  }
                },
                child: const Text("ลงทะเบียน"),
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
  }

  void _showNoPrimaryPetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop(true); // ปิดไดอะล็อกหลังจาก 1 วินาที
        });
        return AlertDialog(
          title: Column(
            children: [
              const Icon(Icons.pets_rounded,
                  color: Colors.deepPurple, size: 50),
              SizedBox(height: 20),
              Text(
                'กรุณาเลือกสัตว์เลี้ยงตัวหลัก',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'ที่จะใช้ในการจับคู่และกดถูกใจก่อน',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  void add_Faverite(String petIdd) async {
    // setState(() {
    //   isLoading = true;
    // });
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

    try {
      // ตรวจสอบว่ามีเอกสารที่มี pet_request และ pet_respone เดียวกันอยู่หรือไม่
      QuerySnapshot querySnapshot = await petFavoriteRef
          .where('pet_request', isEqualTo: pet_request)
          .where('pet_respone', isEqualTo: pet_respone)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // ถ้ามีเอกสารที่ซ้ำกันอยู่แล้ว
        // setState(() {
        //   isLoading = false;
        // });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.of(context).pop(true); // ปิดไดอะล็อกหลังจาก 1 วินาที
            });
            return AlertDialog(
              title: Column(
                children: [
                  Icon(LineAwesomeIcons.star_1,
                      color: Colors.yellow.shade800, size: 50),
                  SizedBox(height: 20),
                  Text('คุณมีการกดถูกใจนี้อยู่แล้ว',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          },
        );
      } else {
        // ถ้าไม่มีเอกสารที่ซ้ำกันอยู่
        DocumentReference newPetfav = await petFavoriteRef.add({
          'created_at': formatted,
          'pet_request': pet_request,
          'pet_respone': pet_respone,
        });

        String docId = newPetfav.id;

        await newPetfav.update({'id_fav': docId});

        showDialog(
          context: context,
          builder: (BuildContext context) {
            Future.delayed(const Duration(seconds: 1), () {
              Navigator.of(context).pop(true); // ปิดไดอะล็อกหลังจาก 1 วินาที
            });
            return AlertDialog(
              title: Column(
                children: [
                  Icon(LineAwesomeIcons.star_1,
                      color: Colors.yellow.shade800, size: 50),
                  SizedBox(height: 20),
                  Text('เพิ่มการกดถูกใจเรียบร้อย',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          },
        );
      }
    } catch (error) {
      print("Failed to add pet: $error");

      setState(() {
        isLoading = false;
      });
    }
  }

  void add_match(String petIdd, String userIdd, String img_profile,
      String name_petrep, String des) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    petId_main = prefs.getString(userId.toString());
    String pet_request = petId_main.toString();
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
        setState(() {
          isLoading = false;
        });

        // แจ้งเตือนว่ามีคำขอจับคู่อยู่แล้ว
        showDialog(
          context: context,
          builder: (BuildContext context) {
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.of(context).pop(true); // ปิดไดอะล็อกหลังจาก 1 วินาที
            });
            return AlertDialog(
              title: Column(
                children: [
                  Icon(LineAwesomeIcons.heart_1,
                      color: Colors.pinkAccent, size: 50),
                  SizedBox(height: 20),
                  Text('สัตว์เลี้ยงตัวนี้กำลังขอจับคู่กับคุณอยู่',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
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
          'updates_at': formatted,
          'user_req': userId,
          'user_res': userIdd
        });

        String docId = newPetMatch.id;

        await newPetMatch.update({'id_match': docId});

        sendNotificationToUser(
            userIdd, // ผู้ใช้เป้าหมายที่จะได้รับแจ้งเตือน
            pet_respone,
            "คุณมีคำขอใหม่!",
            "สัตว์เลี้ยง $name_petrep ของคุณได้รับคำขอจาก $namePet ไปดูรายละเอียดได้เลย!");
        setState(() {
          isLoading = false;
        });
        _showHeartAnimation();
      }
    } catch (error) {
      print("Failed to add pet: $error");

      setState(() {
        isLoading = false;
      });
    }
  }

  void sendNotificationToUser(
      String userIdd, String petRespone, String title, String body) async {
    try {
      // ตรวจสอบว่า userIdd ไม่ตรงกับผู้ใช้ปัจจุบัน (หมายถึงผู้ใช้ที่ถูกส่งคำขอ)
      if (userIdd != FirebaseAuth.instance.currentUser!.uid) {
        // ดึงข้อมูลผู้ใช้จาก Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('user')
            .doc(userIdd)
            .get();

        // ดึง FCM Token ของผู้ใช้จากข้อมูลที่ได้มา
        String? fcmToken = userDoc['fcm_token'];

        if (fcmToken != null) {
          // ส่งการแจ้งเตือนโดยเรียกใช้ฟังก์ชัน sendPushMessage
          await sendPushMessage(fcmToken, title, body);

          // บันทึกข้อมูลการแจ้งเตือนลงใน Firestore
          await _saveNotificationToFirestore(userIdd, petRespone, title, body);
        } else {
          print("FCM Token is null, unable to send notification");
        }
      } else {
        print(
            "No notification sent because the user is the one who made the request.");
      }
    } catch (error) {
      print("Error sending notification to user: $error");
    }
  }

  Future<void> _saveNotificationToFirestore(
      String userId, String petId, String title, String body) async {
    try {
      // รับวันและเวลาปัจจุบันในโซนเวลาไทย
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      final String formattedDate =
          formatter.format(now.toUtc().add(Duration(hours: 7)));

      // อ้างอิงถึงคอลเลกชัน notifications ในเอกสาร userId
      CollectionReference notificationsRef = FirebaseFirestore.instance
          .collection('notification')
          .doc(userId)
          .collection('pet_notification');

      // เพิ่มเอกสารใหม่ลงในคอลเลกชัน notifications
      await notificationsRef.add({
        'pet_id': petId, // เพิ่มข้อมูล pet_id
        'title': title,
        'body': body,
        'status': 'unread', // สถานะเริ่มต้นเป็น 'unread'
        'created_at': formattedDate,
        'scheduled_at': formattedDate, // เวลาที่การแจ้งเตือนถูกตั้งค่า
      });

      print("Notification saved to Firestore successfully");
    } catch (error) {
      print("Error saving notification to Firestore: $error");
    }
  }

  Future<void> sendPushMessage(
      String token_user, String title, String body) async {
    try {
      print("Sending notification to token: $token_user");

      // ดึง Firebase Access Token
      String token = await firebaseAccessToken.getToken();

      final data = {
        "message": {
          "token": token_user,
          "notification": {"title": title, "body": body}
        }
      };

      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/login-3c8fb/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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

  // ดึงข้อมูลที่บันทึกมาใส่ตารางการฉีดวัคซีนตามเกณฑ์
  List<TableRow> _buildTableRows(List<Map<String, dynamic>> vaccination_Table) {
    return vaccination_Table.map((schedule_table) {
      // รวม vaccine และ dose เป็นค่าเดียวเพื่อใช้ในการค้นหา
      String vaccineWithDose =
          "${schedule_table['vaccine']} ${schedule_table['dose']}";

      // ค้นหาข้อมูลการฉีดวัคซีนที่ตรงกับ vaccine + dose จาก Firestore
      var firestoreData = vaccinationDataFromFirestore.firstWhere(
        (data) => data['vaccine'] == vaccineWithDose,
        orElse: () => {},
      );

      return TableRow(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                Text(firestoreData.isNotEmpty ? firestoreData['status'] : ''),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(vaccineWithDose),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(firestoreData.isNotEmpty ? firestoreData['date'] : ''),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                Text(firestoreData.isNotEmpty ? firestoreData['weight'] : ''),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(firestoreData.isNotEmpty ? firestoreData['price'] : ''),
          ),
        ],
      );
    }).toList();
  }

  // ดึงข้อมูลตารางการฉีดวัคซีนตามเกณฑ์
  List<TableRow> _buildTableVac(List<Map<String, String>> vaccinationSchedule) {
    return vaccinationSchedule.map((schedule) {
      return TableRow(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              schedule['age']!,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              schedule['vaccine']!,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              schedule['dose']!,
            ),
          ),
        ],
      );
    }).toList();
  }
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
