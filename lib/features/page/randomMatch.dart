// ignore_for_file: camel_case_types, file_names

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:Pet_Fluffy/features/page/Profile_Pet_All.dart';
import 'package:Pet_Fluffy/features/page/login_page.dart';
import 'package:Pet_Fluffy/features/page/notification_more.dart';
import 'package:Pet_Fluffy/features/services/auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:Pet_Fluffy/features/api/user_data.dart';
import 'package:Pet_Fluffy/features/page/historyMatch.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
import 'package:Pet_Fluffy/features/page/profile_all_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

//หน้า Menu Home ของ App
class randomMathch_Page extends StatefulWidget {
  const randomMathch_Page({super.key});

  @override
  State<randomMathch_Page> createState() => _randomMathch_PageState();
}

class _randomMathch_PageState extends State<randomMathch_Page>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool isAnonymousUser = false;
  User? user = FirebaseAuth.instance.currentUser;
  String distanceStr = '';
  String? userId;
  String? petId;
  String? petType;
  String? petGender;
  String? petImg;
  String? userImageBase64;
  String? petName;
  bool isLoading = true;
  String? _selectedDistance;
  String? _selectedAge;
  String? _selectedPrice;
  LatLng? petLocation;
  LocationData? _locationData;
  Location location = Location();

  late Map<String, String> petPosition_ = {};
  late Map<String, String> userLocation_get = {};
  late List<Map<String, dynamic>> petDataMatchList = [];
  late List<Map<String, dynamic>> petDataFavoriteList = [];
  late List<Map<String, dynamic>> petUserDataList = [];
  List<Map<String, String>> petPositions = [];
  String? search;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late List<Offset> _randomOffsets;
  late Future<List<Map<String, dynamic>>> _futurePets;
  bool _offsetsInitialized = false;
  bool hasPrimaryPet = false;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToTop = false;

  bool _isAnimating = false;
  FirebaseAccessToken firebaseAccessToken = FirebaseAccessToken();
  int unreadNotifications = 0;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _otherBreedController = TextEditingController();
  final TextEditingController _otherColor = TextEditingController();
  final List<String> _Distance = [
    '0 - 500 เมตร',
    '500 - 1000 เมตร ',
    '1 - 5 กิโลเมตร',
    '5 - 20 กิโลเมตร',
    '20 - 100 กิโลเมตร',
    'มากกว่า 100 กิโลเมตร'
  ];
  final List<String> _Age = [
    '6 เดือน - 1 ปี',
    '1 ปี - 1 ปี 6 เดือน',
    '1 ปี 6 เดือน - 2 ปี',
    'มากกว่า 2 ปี'
  ];
  final List<String> _Price = [
    'น้อยกว่า 1000 บาท',
    '1000-5000 บาท',
    '5000-10000 บาท',
    '10000-30000 บาท',
    'มากกว่า 30000 บาท'
  ];
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

  Future<void> _fetchUnreadNotifications() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('notification')
            .doc(userId)
            .collection('pet_notification')
            .where('status',
                isEqualTo: 'unread') // ดึงการแจ้งเตือนที่ยังไม่ได้อ่าน
            .get();

        setState(() {
          unreadNotifications = querySnapshot.docs.length;
        });
      } catch (e) {
        print('Error fetching unread notifications: $e');
      }
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      try {
        // ดึงการแจ้งเตือนที่ยังไม่ได้อ่าน
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('notification')
            .doc(userId)
            .collection('pet_notification')
            .where('status', isEqualTo: 'unread')
            .get();

        for (var doc in querySnapshot.docs) {
          // เปลี่ยนสถานะของการแจ้งเตือนเป็น "อ่านแล้ว"
          await doc.reference.update({'status': 'read'});
        }

        // อัปเดตจำนวนการแจ้งเตือนที่ยังไม่ได้อ่าน
        setState(() {
          unreadNotifications =
              0; // จำนวนการแจ้งเตือนหลังจากทำการอ่านทั้งหมดแล้ว
        });
      } catch (e) {
        print('Error marking all notifications as read: $e');
      }
    }
  }

  Future<void> _printStoredPetId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? storedPetId = prefs.getString(userId.toString());

      if (storedPetId != null && storedPetId.isNotEmpty) {
        // พิมพ์ค่า storedPetId ลงในคอนโซล
        print('Stored Pet ID: $storedPetId');

        // ต่อไปให้ใช้ storedPetId ในการค้นหาข้อมูล
        QuerySnapshot petUserQuerySnapshot = await FirebaseFirestore.instance
            .collection('match')
            .where('pet_request', isEqualTo: storedPetId)
            .get();

        // แสดงจำนวนเอกสารที่ได้รับ
        print('Number of documents found: ${petUserQuerySnapshot.docs.length}');
      } else {
        print('Stored Pet ID is null or empty.');
      }
    } catch (e) {
      print('Error retrieving stored pet ID: $e');
    }
  }

  void getLocation() async {
    try {
      _locationData = await location.getLocation();
      if (_locationData != null) {
        print(LatLng(_locationData!.latitude!, _locationData!.longitude!));
      } else {
        print('Location data is null.');
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _getUsage_pet(String searchValue) async {
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
          petId = userDocSnapshot['pet_id'] as String?;

          // ตรวจสอบว่าค่าของ petId ไม่เป็น null และไม่ว่าง
          if (petId != null && petId!.isNotEmpty) {
            hasPrimaryPet = true;

            // ค้นหาข้อมูลในคอลเลคชัน Pet_user เพื่อดึงประเภทสัตว์เลี้ยงและเพศ
            DocumentSnapshot petDocSnapshot = await FirebaseFirestore.instance
                .collection('Pet_User')
                .doc(petId)
                .get();

            if (petDocSnapshot.exists) {
              setState(() {
                petName = petDocSnapshot['name'] as String?;
                petType = petDocSnapshot['type_pet'] as String?;
                petGender = petDocSnapshot['gender'] as String?;
                petImg = petDocSnapshot['img_profile'] as String? ?? '';
                isLoading = false;
              });

              print('Type : $petType, Gender : $petGender');
            } else {
              print('No pet data found with pet_id: $petId');
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

        // เรียกเก็บข้อมูลจากตัวที่เคย match
        User? userData = FirebaseAuth.instance.currentUser;
        if (userData != null) {
          userId = userData.uid;

          // ดึงข้อมูลจากคอลเล็กชัน match
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? storedPetId = prefs.getString(userId.toString());

          // ตรวจสอบว่าค่าของ storedPetId ไม่เป็น null ก่อนที่จะทำการใช้งาน
          if (storedPetId != null && storedPetId.isNotEmpty) {
            QuerySnapshot petUserQuerySnapshot = await FirebaseFirestore
                .instance
                .collection('match')
                .where('pet_request', isEqualTo: storedPetId)
                .get();

            List<dynamic> petResponses = petUserQuerySnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();

            List<Map<String, dynamic>> allPetDataList = [];

            for (var petRespone in petResponses) {
              String? petResponeId = petRespone['pet_respone'] as String?;

              if (petResponeId != null) {
                // ดึงข้อมูลจาก Pet_User
                QuerySnapshot getPetQuerySnapshot = await FirebaseFirestore
                    .instance
                    .collection('Pet_User')
                    .where('pet_id', isEqualTo: petResponeId)
                    .where('type_pet', isEqualTo: petType)
                    .get();

                List<Map<String, dynamic>> petDataList = getPetQuerySnapshot
                    .docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList();

                // กรองสัตว์เลี้ยงที่ไม่ใช่ตัวที่กำลังขอจับคู่
                petDataList
                    .removeWhere((petData) => petData['pet_id'] == storedPetId);

                allPetDataList.addAll(petDataList);
              }
            }

            // อัปเดต petUserDataList ด้วยข้อมูลทั้งหมดที่ได้รับ
            print(allPetDataList.length);
            setState(() {
              petDataMatchList = allPetDataList;
              isLoading = false;
            });

            // ส่วน Favorite
            try {
              QuerySnapshot petUserQuerySnapshot = await FirebaseFirestore
                  .instance
                  .collection('favorites')
                  .doc(userId)
                  .collection('pet_favorite')
                  .where('pet_request', isEqualTo: storedPetId)
                  .get();

              List<dynamic> petResponses = petUserQuerySnapshot.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();

              List<Map<String, dynamic>> allPetDataList = [];

              for (var petRespone in petResponses) {
                String? petResponeId = petRespone['pet_respone'] as String?;

                if (petResponeId != null) {
                  // ดึงข้อมูลจาก Pet_User
                  QuerySnapshot getPetQuerySnapshot = await FirebaseFirestore
                      .instance
                      .collection('Pet_User')
                      .where('pet_id', isEqualTo: petResponeId)
                      .where('type_pet', isEqualTo: petType)
                      .get();

                  List<Map<String, dynamic>> petDataList = getPetQuerySnapshot
                      .docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .toList();

                  // กรองสัตว์เลี้ยงที่ไม่ใช่ตัวที่กำลังขอจับคู่
                  petDataList.removeWhere(
                      (petData) => petData['pet_id'] == storedPetId);

                  allPetDataList.addAll(petDataList);
                }
              }

              // อัปเดต petUserDataList ด้วยข้อมูลทั้งหมดที่ได้รับ
              setState(() {
                petDataFavoriteList = allPetDataList;
                isLoading = false;
              });
            } catch (e) {
              print('Error getting pet user data from Firestore: $e');
              setState(() {
                isLoading = false;
              });
            }
          } else {
            print('Stored Pet ID is null or empty.');
          }
        }
      } catch (e) {
        print('Error getting user data from Firestore: $e');
      }
    }
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

  Future<List<Map<String, dynamic>>> _getPets() async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot<Map<String, dynamic>> petUserDocsSnapshot =
          await FirebaseFirestore.instance
              .collection('Pet_User')
              .where('user_id', isNotEqualTo: currentUserId)
              .get();
      List<Map<String, dynamic>> petList = [];
      for (var doc in petUserDocsSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        DocumentSnapshot userSnapshot =
            await ApiUserService.getUserData(data['user_id']);
        double lat = userSnapshot['lat'] ?? 0.0;
        double lng = userSnapshot['lng'] ?? 0.0;
        lat += Random().nextDouble() * 0.0002;
        lng += Random().nextDouble() * 0.0002;
        Map<String, String> petPosition_ = {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'user_id': data['user_id'] as String,
          'pet_id': data['pet_id'] as String,
        };
        petPositions.add(petPosition_);
        petList.add(data);
      }
      petList.shuffle();
      if (mounted) {
        setState(() {
        });
      }
      return petList;
    } catch (e) {
      print('Error loading pet locations from Firestore: $e');
      return [];
    }
  }

  void _logSearchValue() {
    setState(() {
      _selectedDistance = null;
      _selectedAge = null;
      _otherBreedController.text = '';
      _otherColor.text = '';
      _selectedPrice = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchValue = _controller.text;
      search = searchValue.toString();
      _getUsage_pet(searchValue);
    });
  }

  Future<List<Map<String, dynamic>>> filterUniquePetsAsync(
      List<Map<String, dynamic>> sourceList,
      List<Map<String, dynamic>> filterList,
      bool Function(Map<String, dynamic>, Map<String, dynamic>)
          comparator) async {
    return sourceList.where((item) {
      return !filterList.any((filterItem) => comparator(item, filterItem));
    }).toList();
  }

  bool isSamePet(Map<String, dynamic> pet1, Map<String, dynamic> pet2) {
    return pet1['pet_id'] == pet2['pet_id'];
  }

  @override
  void initState() {
    super.initState();
    isAnonymousUser = _authService.isAnonymous();
    _setTokenfirebaseMassag();
    _getUserDataFromFirestore();
    _getUsage_pet('');
    getLocation();
    _printStoredPetId();
    _fetchUnreadNotifications();
    _futurePets = _getPets();
    // กำหนด AnimationController
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // กำหนด Animation สำหรับ opacity
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasScrolledToTop) {
        if (_scrollController.hasClients) {
          _scrollToTop();
        }
        setState(() {
          _hasScrolledToTop = true;
        });
      }
    });
  }

  void _scrollToTop() {
    // การเลื่อนที่นุ่มนวล
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 500), // ระยะเวลาในการเลื่อน
      curve: Curves.easeInOut, // รูปแบบการเคลื่อนไหว
    );
  }

  @override
  void dispose() {
    _animationController.dispose(); // หรือหยุด Timer หรือ Animation อื่นๆ
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

  int convertToMonths(String ageString) {
    int months = 0;
    RegExp regExp = RegExp(r'(\d+)\s*ปี');
    Match? match = regExp.firstMatch(ageString);
    if (match != null) {
      int years = int.parse(match.group(1)!);
      months += years * 12;
    }
    regExp = RegExp(r'(\d+)\s*เดือน');
    match = regExp.firstMatch(ageString);
    if (match != null) {
      int extraMonths = int.parse(match.group(1)!);
      months += extraMonths;
    }
    return months;
  }

  bool isAgeInRange(String ageRange, DateTime birthDate) {
    DateTime now = DateTime.now();
    int yearsDifference = now.year - birthDate.year;
    int monthsDifference = now.month - birthDate.month;

    if (now.day < birthDate.day) {
      monthsDifference--;
    }

    if (monthsDifference < 0) {
      yearsDifference--;
      monthsDifference += 12;
    }

    // แปลงอายุเป็นเดือน
    int totalMonths = yearsDifference * 12 + monthsDifference;

    // แปลงช่วงอายุเป็นเดือน
    List<String> parts = ageRange.split(' - ');
    if (parts.length == 2) {
      int minMonths = convertToMonths(parts[0]);
      int maxMonths = convertToMonths(parts[1]);

      // ตรวจสอบช่วงอายุ
      return totalMonths >= minMonths && totalMonths <= maxMonths;
    } else {
      // กรณีไม่มีการระบุช่วง เช่น 'มากกว่า 2 ปี'
      if (ageRange == 'มากกว่า 2 ปี') {
        return totalMonths > 24; // มากกว่า 24 เดือน
      }
    }

    return false;
  }

  bool isPriceInRange(String priceString, String selectedPrice) {
    // แปลงราคาที่เป็นข้อความเป็นตัวเลข
    double price = double.tryParse(priceString.replaceAll(',', '')) ?? 0.0;

    // แปลงช่วงราคาที่เลือก
    double? minPrice;
    double? maxPrice;

    // ตรวจสอบช่วงราคาที่เลือก
    if (selectedPrice.contains('น้อยกว่า')) {
      maxPrice = double.parse(selectedPrice
          .replaceAll('น้อยกว่า', '')
          .replaceAll(' บาท', '')
          .trim());
    } else if (selectedPrice.contains('มากกว่า')) {
      minPrice = double.parse(selectedPrice
          .replaceAll('มากกว่า', '')
          .replaceAll(' บาท', '')
          .trim());
    } else if (selectedPrice.contains('-')) {
      List<String> parts = selectedPrice.split('-');
      minPrice = double.parse(parts[0].replaceAll(' บาท', '').trim());
      maxPrice = double.parse(parts[1].replaceAll(' บาท', '').trim());
    }

    // ตรวจสอบว่าราคาอยู่ในช่วงที่เลือกหรือไม่
    if (minPrice != null && maxPrice != null) {
      return price >= minPrice && price <= maxPrice;
    } else if (minPrice != null) {
      return price > minPrice;
    } else if (maxPrice != null) {
      return price < maxPrice;
    } else {
      return false; // ไม่มีช่วงราคาที่กำหนด
    }
  }

  bool isDistanceRange(String distanceStr, String selectedRange) {
    // แปลง distanceStr เป็นค่าตัวเลข
    double distance = _parseDistance(distanceStr);

    // แปลง selectedRange เป็นช่วงระยะทาง
    List<double> range = _parseRange(selectedRange);

    // ตรวจสอบว่าระยะทางอยู่ในช่วงหรือไม่
    return distance >= range[0] && distance <= range[1];
  }

  double _parseDistance(String distanceStr) {
    final RegExp regex = RegExp(r'(\d+\.?\d*)\s*(กิโลเมตร|เมตร)');
    final match = regex.firstMatch(distanceStr);
    if (match != null) {
      double value = double.parse(match.group(1)!);
      String unit = match.group(2)!;

      // แปลงหน่วยเป็นเมตร
      if (unit == 'กิโลเมตร') {
        return value * 1000;
      } else {
        return value;
      }
    }
    return 0.0;
  }

  List<double> _parseRange(String rangeStr) {
    final RegExp regexRange = RegExp(r'(\d+)\s*-\s*(\d+)\s*(เมตร|กิโลเมตร)');
    final RegExp regexMoreThan = RegExp(r'มากกว่า\s*(\d+)\s*(เมตร|กิโลเมตร)');
    final matchRange = regexRange.firstMatch(rangeStr);
    final matchMoreThan = regexMoreThan.firstMatch(rangeStr);

    if (matchRange != null) {
      double start = double.parse(matchRange.group(1)!);
      double end = double.parse(matchRange.group(2)!);
      String unit = matchRange.group(3)!;

      // แปลงหน่วยเป็นเมตร
      if (unit == 'กิโลเมตร') {
        start *= 1000;
        end *= 1000;
      }

      return [start, end];
    } else if (matchMoreThan != null) {
      double start = double.parse(matchMoreThan.group(1)!);
      String unit = matchMoreThan.group(2)!;

      // แปลงหน่วยเป็นเมตร
      if (unit == 'กิโลเมตร') {
        start *= 1000;
      }

      return [
        start,
        double.infinity
      ]; // ใช้ double.infinity สำหรับค่าที่ไม่จำกัด
    }

    return [0.0, 0.0];
  }

  String calculateDistance(LatLng start, LatLng end) {
    // คำนวณระยะทางในหน่วยเมตร
    double distanceInMeters = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );

    // ตรวจสอบและแปลงหน่วย
    if (distanceInMeters >= 1000) {
      // แปลงเป็นกิโลเมตรและคืนค่าเป็นสตริง
      double distanceInKilometers = distanceInMeters / 1000;
      return '${distanceInKilometers.toStringAsFixed(2)} กิโลเมตร';
    } else {
      // คืนค่าเป็นเมตร
      return '${distanceInMeters.toStringAsFixed(0)} เมตร';
    }
  }

  Future<LatLng> position_pet(String user_id) async {
    DocumentSnapshot userSnapshot = await ApiUserService.getUserData(user_id);

    double lat = userSnapshot['lat'] ?? 0.0;
    double lng = userSnapshot['lng'] ?? 0.0;
    lat += Random().nextDouble() * 0.0002;
    lng += Random().nextDouble() * 0.0002;
    LatLng petLocation = LatLng(lat, lng);
    return petLocation;
  }

  Future<Widget> _getImage() async {
    if (user != null && user!.isAnonymous) {
      return Image.asset(
        'assets/images/user-286-512.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    } else if (petImg == null || petImg!.isEmpty) {
      if (userImageBase64 != null && userImageBase64!.isNotEmpty) {
        return Image.memory(
          base64Decode(userImageBase64!),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        );
      } else {
        return Image.asset(
          'assets/images/user-286-512.png',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        );
      }
    } else {
      return Image.memory(
        base64Decode(petImg!),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    }
  }

  Future<void> _refreshData() async {
    // ทำการดึงข้อมูลใหม่
    setState(() {
      // รีเซ็ตข้อมูล หรือทำการเรียก Future ใหม่เพื่อดึงข้อมูลใหม่
      // สมมติว่า _getPets() เป็น Future ที่ดึงข้อมูลใหม่
      // ทำให้ FutureBuilder เรียก Future ใหม่เมื่อรีเฟรช
      _futurePets = _getPets();
    });
  }

  @override
  Widget build(BuildContext context) {
    _initializeOffsets(context);
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
                child: Column(
                  children: [
                    Row(
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
                              child: FutureBuilder(
                                future:
                                    _getImage(), // Future function to get the image
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    // Show a loading indicator while waiting
                                    return Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    // Handle errors, e.g., image not found
                                    return Icon(Icons.error, size: 40);
                                  } else {
                                    // Show the image when done
                                    return snapshot.data as Widget;
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'ค้นหา',
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: _logSearchValue,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: isAnonymousUser
                              ? null
                              : () {
                                  historyMatch();
                                },
                          icon: const Icon(
                            Icons.favorite,
                            color: Colors.pinkAccent,
                          ),
                        ),
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (petId != null && petId!.isNotEmpty) {
                                  // นำทางไปยังหน้าการแจ้งเตือน
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          NotificationMore_Page(
                                        idPet: petId!,
                                      ),
                                    ),
                                  ).then((_) async {
                                    // เปลี่ยนสถานะการแจ้งเตือนเป็น "อ่านแล้ว" หลังจากกลับมาที่หน้าเดิม
                                    await _markAllNotificationsAsRead();
                                    // อัปเดตจำนวนการแจ้งเตือนที่ยังไม่ได้อ่าน
                                    await _fetchUnreadNotifications();
                                  });
                                } else {
                                  print('Pet ID is null or empty.');
                                }
                              },
                              icon: Icon(
                                Icons.notifications_rounded,
                                color: Colors.yellow.shade800,
                              ),
                            ),
                            if (unreadNotifications > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(0),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$unreadNotifications',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled:
                              true, // เพิ่มการตั้งค่านี้เพื่อให้สามารถเลื่อนขึ้นลงได้
                          builder: (BuildContext context) {
                            return SizedBox(
                              height: MediaQuery.of(context).size.height *
                                  0.8, // ปรับขนาดความสูงตามต้องการ
                              child: SingleChildScrollView(
                                // เพิ่ม SingleChildScrollView เพื่อให้สามารถเลื่อนขึ้นลงได้
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Text('การค้นหาขั้นสูง',
                                          style: TextStyle(fontSize: 20)),
                                      const SizedBox(height: 15),
                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value: _selectedDistance,
                                              items:
                                                  _Distance.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  _selectedDistance = newValue;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'ระยะความห่าง',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          30.0),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value: _selectedAge,
                                              items: _Age.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  _selectedAge = newValue;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'ช่วงอายุ',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          30.0),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              style:
                                                  const TextStyle(fontSize: 15),
                                              controller: _otherBreedController,
                                              decoration: InputDecoration(
                                                labelText: 'สายพันธุ์',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          30.0),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              style:
                                                  const TextStyle(fontSize: 15),
                                              controller: _otherColor,
                                              decoration: InputDecoration(
                                                labelText: 'สี',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          30.0),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              value: _selectedPrice,
                                              items: _Price.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  _selectedPrice = newValue;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                labelText:
                                                    'ราคา (ค่าผสมพันธุ์)',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          30.0),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedDistance =
                                                _selectedDistance;
                                            _selectedAge = _selectedAge;
                                            _otherBreedController.text =
                                                _otherBreedController.text;
                                            _otherColor.text = _otherColor.text;
                                            _selectedPrice = _selectedPrice;
                                          });
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                        ),
                                        child: const Text('ค้นหา',
                                            style: TextStyle(fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        // ใช้ขนาดที่จำเป็นเท่านั้น
                        children: [
                          Text(
                            'ค้นหาขั้นสูง',
                            style: TextStyle(
                              fontSize: 16,
                              color: const Color.fromARGB(
                                  255, 110, 110, 110), // สีของตัวอักษร
                            ),
                          ),
                          const SizedBox(
                              width: 8.0), // ระยะห่างระหว่าง Text และ Icon
                          Icon(
                            Icons.keyboard_arrow_down_sharp,
                            color: const Color.fromARGB(
                                255, 110, 110, 110), // สีของไอคอน
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            // ดึงข้อมูลสัตว์เลี้ยงจาก ApiPetService.loadAllPet() คืนค่าเป็น List<Map<String, dynamic>>
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _futurePets, // ใช้ Future ที่คงที่
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

                // ตรวจสอบว่าเป็นผู้ใช้ Anonymous หรือไม่
                bool isAnonymousUser =
                    FirebaseAuth.instance.currentUser?.isAnonymous ?? false;

                // กำหนดเพศตรงข้าม
                List<Map<String, dynamic>> filteredPetData;
                if (isAnonymousUser) {
                  // หากเป็นผู้ใช้ Anonymous ให้แสดงข้อมูลสัตว์เลี้ยงทั้งหมด
                  filteredPetData = snapshot.data!;
                } else {
                  // กรองข้อมูลสัตว์เลี้ยงตามเงื่อนไขที่กำหนด
                  String oppositeGender =
                      (petGender == 'ตัวผู้') ? 'ตัวเมีย' : 'ตัวผู้';
                  filteredPetData = snapshot.data!
                      .where((pet) =>
                          pet['type_pet'] == petType &&
                          pet['gender'] == oppositeGender &&
                          pet['status'] == 'พร้อมผสมพันธุ์')
                      .toList();
                }

                // ตรวจสอบว่า filteredPetData ว่างเปล่าหรือไม่
                if (filteredPetData.isEmpty) {
                  // หากว่างเปล่า ให้แสดงสัตว์เลี้ยงทั้งหมด
                  filteredPetData = snapshot.data!;
                }

                return FutureBuilder<List<Map<String, dynamic>>>(
                    future: () async {
                  List<Map<String, dynamic>> uniquePetDataMatch =
                      await filterUniquePetsAsync(
                          filteredPetData, petDataMatchList, isSamePet);
                  return await filterUniquePetsAsync(
                      uniquePetDataMatch, petDataFavoriteList, isSamePet);
                }(), builder: (context,
                        AsyncSnapshot<List<Map<String, dynamic>>>
                            filteredSnapshot) {
                  if (filteredSnapshot.connectionState ==
                      ConnectionState.waiting) {
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
                  if (filteredSnapshot.hasError) {
                    return Text('Error: ${filteredSnapshot.error}');
                  }
                  if (filteredSnapshot.data == null ||
                      filteredSnapshot.data!.isEmpty) {
                    return Center(
                      child: Text('คุณได้จับคู่หมดแล้ว'),
                    );
                  }

                  List<Map<String, dynamic>> filteredData =
                      filteredSnapshot.data!;
                  if (_selectedDistance == null &&
                      _selectedAge == null &&
                      _otherBreedController.text == '' &&
                      _otherColor.text == '' &&
                      _selectedPrice == null) {
                    if (search.toString() != 'null') {
                      List<Map<String, dynamic>> filteredPets =
                          filteredData.where((pet) {
                        // log(search.toString().toLowerCase());
                        bool matchesName = pet['name']
                            .toString()
                            .toLowerCase()
                            .contains(search.toString().toLowerCase());

                        DateTime birthDate = DateTime.parse(pet['birthdate']);
                        DateTime now = DateTime.now();
                        int yearsDifference = now.year - birthDate.year;
                        int monthsDifference = now.month - birthDate.month;

                        if (now.day < birthDate.day) {
                          monthsDifference--;
                        }

                        if (monthsDifference < 0) {
                          yearsDifference--;
                          monthsDifference += 12;
                        }

                        String ageDifference =
                            '$yearsDifferenceปี$monthsDifferenceเดือน';

                        bool matchesAge = ageDifference
                            .toLowerCase()
                            .contains(search.toString().toLowerCase());

                        bool matchesBreed = pet['breed_pet']
                            .toString()
                            .toLowerCase()
                            .contains(search.toString().toLowerCase());

                        bool matchesGender = pet['gender']
                            .toString()
                            .toLowerCase()
                            .contains(search.toString().toLowerCase());

                        bool matchesColor = pet['color']
                            .toString()
                            .toLowerCase()
                            .contains(search.toString().toLowerCase());

                        return matchesName ||
                            matchesAge ||
                            matchesBreed ||
                            matchesGender ||
                            matchesColor;
                      }).toList();
                      petUserDataList = filteredPets;
                    } else {
                      petUserDataList = filteredData;
                    }
                  } else {
                    List<Map<String, dynamic>> filteredPets =
                        filteredData.where((pet) {
                      LatLng userLocation = LatLng(
                        _locationData?.latitude ?? 0.0,
                        _locationData?.longitude ?? 0.0,
                      );

                      bool matchDistance = false;
                      for (var doc in petPositions) {
                        if (doc['pet_id'] == pet['pet_id']) {
                          double lat =
                              double.tryParse(doc['lat'].toString()) ?? 0.0;
                          double lng =
                              double.tryParse(doc['lng'].toString()) ?? 0.0;
                          LatLng petLocation = LatLng(lat, lng);
                          distanceStr =
                              calculateDistance(userLocation, petLocation);
                          print(pet['name']);
                          print(pet['pet_id']);
                          print(distanceStr);
                          print(_selectedDistance);
                          matchDistance = isDistanceRange(
                              distanceStr, _selectedDistance.toString());
                          print(matchDistance);
                          break;
                        }
                      }

                      bool matchesBreed = pet['breed_pet']
                          .toString()
                          .toLowerCase()
                          .contains(_otherBreedController.text.toLowerCase());

                      DateTime birthDate = DateTime.parse(pet['birthdate']);
                      bool matchesAge =
                          isAgeInRange(_selectedAge.toString(), birthDate);

                      bool matchesColor = pet['color']
                          .toString()
                          .toLowerCase()
                          .contains(_otherColor.text.toLowerCase());

                      bool matchesPrice = isPriceInRange(
                          pet['price'].toString(), _selectedPrice.toString());

                      // return matchesPrice;
                      if (_otherBreedController.text != '' &&
                          _selectedAge != null &&
                          _otherColor.text != '' &&
                          _selectedPrice != null &&
                          _selectedDistance != null) {
                        return matchesBreed &&
                            matchesAge &&
                            matchesColor &&
                            matchesPrice &&
                            matchDistance;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge != null &&
                          _otherColor.text != '' &&
                          _selectedPrice != null &&
                          _selectedDistance != null) {
                        return matchesAge &&
                            matchesColor &&
                            matchesPrice &&
                            matchDistance;
                      } else if (_otherBreedController.text != '' &&
                          _selectedAge == null &&
                          _otherColor.text != '' &&
                          _selectedPrice != null &&
                          _selectedDistance != null) {
                        return matchesBreed &&
                            matchesColor &&
                            matchesPrice &&
                            matchDistance;
                      } else if (_otherBreedController.text != '' &&
                          _selectedAge != null &&
                          _otherColor.text == '' &&
                          _selectedPrice != null &&
                          _selectedDistance != null) {
                        return matchesBreed &&
                            matchesAge &&
                            matchesPrice &&
                            matchDistance;
                      } else if (_otherBreedController.text != '' &&
                          _selectedAge != null &&
                          _otherColor.text != '' &&
                          _selectedPrice == null &&
                          _selectedDistance != null) {
                        return matchesBreed &&
                            matchesAge &&
                            matchesColor &&
                            matchDistance;
                      } else if (_otherBreedController.text != '' &&
                          _selectedAge != null &&
                          _otherColor.text != '' &&
                          _selectedPrice != null &&
                          _selectedDistance == null) {
                        return matchesBreed &&
                            matchesAge &&
                            matchesColor &&
                            matchesPrice;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge == null &&
                          _otherColor.text != '' &&
                          _selectedPrice != null &&
                          _selectedDistance != null) {
                        return matchesColor && matchesPrice && matchDistance;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge != null &&
                          _otherColor.text == '' &&
                          _selectedPrice != null &&
                          _selectedDistance != null) {
                        return matchesAge && matchesPrice && matchDistance;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge != null &&
                          _otherColor.text != '' &&
                          _selectedPrice == null &&
                          _selectedDistance != null) {
                        return matchesAge && matchesColor && matchDistance;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge != null &&
                          _otherColor.text != '' &&
                          _selectedPrice != null &&
                          _selectedDistance == null) {
                        return matchesAge && matchesColor && matchesPrice;
                      } else if (_otherBreedController.text != '' &&
                          _selectedAge == null &&
                          _otherColor.text == '' &&
                          _selectedPrice != null &&
                          _selectedDistance != null) {
                        return matchesBreed && matchesPrice && matchDistance;
                      } else if (_otherBreedController.text != '' &&
                          _selectedAge == null &&
                          _otherColor.text != '' &&
                          _selectedPrice == null &&
                          _selectedDistance != null) {
                        return matchesBreed && matchesColor && matchDistance;
                      } else if (_otherBreedController.text != '' &&
                          _selectedAge == null &&
                          _otherColor.text != '' &&
                          _selectedPrice != null &&
                          _selectedDistance == null) {
                        return matchesBreed && matchesColor && matchesPrice;
                      } else if (_otherBreedController.text != '' &&
                          _selectedAge != null &&
                          _otherColor.text == '' &&
                          _selectedPrice == null &&
                          _selectedDistance != null) {
                        return matchesBreed && matchesAge && matchDistance;
                      } else if (_otherBreedController.text != '' &&
                          _selectedAge != null &&
                          _otherColor.text == '' &&
                          _selectedPrice != null &&
                          _selectedDistance == null) {
                        return matchesBreed && matchesAge && matchesPrice;
                      } else if (_otherBreedController.text != '' &&
                          _selectedAge != null &&
                          _otherColor.text != '' &&
                          _selectedPrice == null &&
                          _selectedDistance == null) {
                        return matchesBreed && matchesAge && matchesColor;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge == null &&
                          _otherColor.text == '' &&
                          _selectedPrice != null &&
                          _selectedDistance != null) {
                        return matchesPrice && matchDistance;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge == null &&
                          _otherColor.text != '' &&
                          _selectedPrice == null &&
                          _selectedDistance != null) {
                        return matchesColor && matchDistance;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge == null &&
                          _otherColor.text != '' &&
                          _selectedPrice != null &&
                          _selectedDistance == null) {
                        return matchesColor && matchesPrice;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge != null &&
                          _otherColor.text == '' &&
                          _selectedPrice == null &&
                          _selectedDistance != null) {
                        return matchesAge && matchDistance;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge != null &&
                          _otherColor.text == '' &&
                          _selectedPrice != null &&
                          _selectedDistance == null) {
                        return matchesAge && matchesPrice;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge != null &&
                          _otherColor.text != '' &&
                          _selectedPrice == null &&
                          _selectedDistance == null) {
                        return matchesAge && matchesColor;
                      } else if (_otherBreedController.text != '' &&
                          _selectedAge == null &&
                          _otherColor.text == '' &&
                          _selectedPrice == null &&
                          _selectedDistance != null) {
                        return matchesBreed && matchDistance;
                      } else if (_otherBreedController.text != '' &&
                          _selectedAge == null &&
                          _otherColor.text == '' &&
                          _selectedPrice != null &&
                          _selectedDistance == null) {
                        return matchesBreed && matchesPrice;
                      } else if (_otherBreedController.text != '' &&
                          _selectedAge == null &&
                          _otherColor.text != '' &&
                          _selectedPrice == null &&
                          _selectedDistance == null) {
                        return matchesBreed && matchesColor;
                      } else if (_otherBreedController.text != '' &&
                          _selectedAge != null &&
                          _otherColor.text == '' &&
                          _selectedPrice == null &&
                          _selectedDistance == null) {
                        return matchesBreed && matchesAge;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge == null &&
                          _otherColor.text == '' &&
                          _selectedPrice == null &&
                          _selectedDistance != null) {
                        return matchDistance;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge == null &&
                          _otherColor.text == '' &&
                          _selectedPrice != null &&
                          _selectedDistance == null) {
                        return matchesPrice;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge == null &&
                          _otherColor.text != '' &&
                          _selectedPrice == null &&
                          _selectedDistance == null) {
                        return matchesColor;
                      } else if (_otherBreedController.text == '' &&
                          _selectedAge != null &&
                          _otherColor.text == '' &&
                          _selectedPrice == null &&
                          _selectedDistance == null) {
                        return matchesAge;
                      } else {
                        return matchesBreed;
                      }
                    }).toList();
                    petUserDataList = filteredPets;
                  }

                  return Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshData,
                      //นำข้อมูลสัตว์เลี้ยงที่ได้มาแสดงผลใน ListView.builder โดยดึงข้อมูลเกี่ยวกับอายุของสัตว์เลี้ยงและข้อมูลของผู้ใช้ที่เป็นเจ้าของสัตว์เลี้ยงด้วย
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: petUserDataList.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> petData = petUserDataList[index];
                          DateTime birthDate =
                              DateTime.parse(petData['birthdate']);
                          final now = DateTime.now();
                          int years = now.year - birthDate.year;
                          int months = now.month - birthDate.month;

                          if (now.day < birthDate.day) {
                            months--;
                          }

                          if (months < 0) {
                            years--;
                            months += 12;
                          }

                          String ageString = '';
                          if (years > 0) {
                            ageString += '$years ปี';
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
                            future:
                                ApiUserService.getUserData(petData['user_id']),
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
                              Map<String, dynamic> userData = userSnapshot.data!
                                  .data() as Map<String, dynamic>;
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
                                                  Profile_pet_AllPage(
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
                                                  color: petData['gender'] ==
                                                          'ตัวผู้'
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                // ปุ่มสำหรับผู้ใช้ที่ไม่ใช่ Anonymous
                                                GestureDetector(
                                                  onTap: (hasPrimaryPet &&
                                                          !user!
                                                              .isAnonymous) // ตรวจสอบว่ามีสัตว์เลี้ยงหลักและไม่เป็น anonymous
                                                      ? () {
                                                          // โค้ดสำหรับทำงานปกติเมื่อมีสัตว์เลี้ยงหลัก
                                                          add_Faverite(petData[
                                                              'pet_id']);
                                                        }
                                                      : () {
                                                          // แสดงการแจ้งเตือนให้ผู้ใช้เพิ่มสัตว์เลี้ยงหลักก่อน หรือให้ล็อกอิน
                                                          if (user!
                                                              .isAnonymous) {
                                                            _showSignInDialog(
                                                                context); // แสดงการแจ้งเตือนให้ล็อกอิน
                                                          } else {
                                                            _showNoPrimaryPetDialog(
                                                                context); // แสดงการแจ้งเตือนให้เพิ่มสัตว์เลี้ยงหลัก
                                                          }
                                                        },
                                                  child: Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: (hasPrimaryPet &&
                                                              !user!
                                                                  .isAnonymous)
                                                          ? Colors.blue.shade600
                                                              .withOpacity(0.8)
                                                          : Colors.grey,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.grey
                                                              .withOpacity(0.5),
                                                          spreadRadius: 1,
                                                          blurRadius: 3,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Icon(
                                                      Icons.star_rounded,
                                                      color: Colors.yellow,
                                                      size: 20,
                                                    ),
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
                                                              'user_id'],
                                                          userId_req:
                                                              userId.toString(),
                                                        ),
                                                      ),
                                                    )
                                                  },
                                                  child: Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .grey.shade500
                                                          .withOpacity(0.5),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              40),
                                                    ),
                                                    child: Center(
                                                      child: CircleAvatar(
                                                        radius: 40,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        child: ClipOval(
                                                          child: userImageURL !=
                                                                  null
                                                              ? Image.memory(
                                                                  base64Decode(
                                                                      userImageURL),
                                                                  width: 40,
                                                                  height: 40,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                )
                                                              : const Icon(
                                                                  Icons.person,
                                                                  size: 40,
                                                                ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: (hasPrimaryPet &&
                                                          !user!
                                                              .isAnonymous) // ตรวจสอบว่ามีสัตว์เลี้ยงหลักและไม่เป็น anonymous
                                                      ? () {
                                                          // โค้ดสำหรับทำงานปกติเมื่อมีสัตว์เลี้ยงหลัก
                                                          _showRequestDialog(
                                                              context,
                                                              petData['name'],
                                                              petData['pet_id'],
                                                              petData[
                                                                  'user_id'],
                                                              petData[
                                                                  'img_profile']);
                                                        }
                                                      : () {
                                                          // แสดงการแจ้งเตือนให้ผู้ใช้เพิ่มสัตว์เลี้ยงหลักก่อน หรือให้ล็อกอิน
                                                          if (user!
                                                              .isAnonymous) {
                                                            _showSignInDialog(
                                                                context); // แสดงการแจ้งเตือนให้ล็อกอิน
                                                          } else {
                                                            _showNoPrimaryPetDialog(
                                                                context); // แสดงการแจ้งเตือนให้เพิ่มสัตว์เลี้ยงหลัก
                                                          }
                                                        },
                                                  child: Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: (hasPrimaryPet &&
                                                              !user!
                                                                  .isAnonymous)
                                                          ? Colors.white
                                                          : Colors
                                                              .grey, // สีปุ่มเปลี่ยนตามสถานะ
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.grey
                                                              .withOpacity(0.5),
                                                          spreadRadius: 1,
                                                          blurRadius: 3,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Icon(
                                                      Icons.favorite,
                                                      color: (hasPrimaryPet &&
                                                              !user!
                                                                  .isAnonymous)
                                                          ? Colors.pinkAccent
                                                          : Colors.white,
                                                      size: 20,
                                                    ),
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
                    ),
                  );
                });
              },
            ),
          ],
        ),
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
          : FloatingActionButton(
              onPressed: _scrollToTop,
              child: Icon(Icons.arrow_upward),
            ),
    );
  }

  void _showRequestDialog(BuildContext context, petName, petId, petUser, Img) {
    TextEditingController des = TextEditingController();
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
                      Navigator.of(context).pop();
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

  void historyMatch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? petId = prefs.getString(userId.toString());

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            Historymatch_Page(
                idPet: petId.toString(), idUser: userId.toString()),
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
    _getUserDataFromFirestore();
    _getUsage_pet(search.toString());
  }

  void add_match(String petIdd, String userIdd, String img_profile,
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
          'updates_at': formatted
        });

        String docId = newPetMatch.id;

        await newPetMatch.update({'id_match': docId});

        sendNotificationToUser(
            userIdd, // ผู้ใช้เป้าหมายที่จะได้รับแจ้งเตือน
            pet_respone,
            "คุณมีคำขอใหม่!",
            "สัตว์เลี้ยง $name_petrep ของคุณได้รับคำขอจาก $petName ไปดูรายละเอียดได้เลย!");
        setState(() {
          isLoading = false;
        });
        _showHeartAnimation();

        _getUserDataFromFirestore();
        _getUsage_pet(search.toString());
      }
    } catch (error) {
      print("Failed to add pet: $error");

      setState(() {
        isLoading = false;
      });
    }
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
}
