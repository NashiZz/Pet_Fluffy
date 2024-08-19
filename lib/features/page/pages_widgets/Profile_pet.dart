// ignore_for_file: camel_case_types, file_names, avoid_print
import 'dart:typed_data';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/PetDegreeDetail.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/showDialogContest.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/showDialogHistory_Match.dart';
import 'package:Pet_Fluffy/features/services/notification_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:Pet_Fluffy/features/api/user_data.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/edit_Profile_Pet.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/table_dataVac.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/Add_Img_ProfilePet.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/periodDetail_Page.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/vacDetail_Page.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/vac_More.dart';
import 'package:Pet_Fluffy/features/services/age_calculator_service.dart';
import 'package:Pet_Fluffy/features/services/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

//หน้า Profile ของ สัตว์เลี้ยง
class Profile_pet_Page extends StatefulWidget {
  final String petId;
  const Profile_pet_Page({super.key, required this.petId});

  @override
  State<Profile_pet_Page> createState() => _Profile_pet_PageState();
}

class _Profile_pet_PageState extends State<Profile_pet_Page>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final AgeCalculatorService _ageCalculatorService = AgeCalculatorService();

  User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _infoController = TextEditingController();

  final TextEditingController _dateVacController = TextEditingController();
  final TextEditingController _vacWeight = TextEditingController();
  final TextEditingController _vacPrice = TextEditingController();
  final TextEditingController _vacLocation = TextEditingController();

  final TextEditingController _dateVacTable = TextEditingController();
  final TextEditingController _vacWeightTable = TextEditingController();
  final TextEditingController _vacPriceTable = TextEditingController();

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

  String? userId;
  String? userImageBase64;

  bool isLoading = true;
  late List<Map<String, dynamic>> petUserDataList = [];
  List<Map<String, dynamic>> vaccinationSchedule = [];
  List<Map<String, dynamic>> vaccination_Table = [];
  List<Map<String, dynamic>> vaccinationDataFromFirestore = [];
  List<String> _selectedVaccines = []; // เก็บวัคซีนที่ถูกเลือกแล้ว
  List<Map<String, String>> _availableVaccinations = [];
  late List<Map<String, dynamic>> vaccinePetDatas = [];
  String? _vacStatus_Table;
  String? _selectedVac;
  String? _selectedVac_Table;
  List<String> _vacOfDog = [];
  List<String> _vacOfCat = [];

  final double coverHeight = 180;
  final double profileHeight = 90;

  List<String> _firestoreImages = [];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();

    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _refreshHomePage();
      _refreshData();
      _loadAllPet(widget.petId);
      _getUserDataFromFirestore();
      _fetchVaccinationData();
      _fetchVacDataDog();
      _fetchVacDataCat();
      _updateVaccinationList();
    }
    isLoading = true;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _getVaccines_petData() async {
    String idTypePet = '';

    if (pet_type == 'แมว') {
      idTypePet = '5yWv1hawXz6Gh15gEed1';
    } else if (pet_type == 'สุนัข') {
      idTypePet = 'Qy38o0xCXKQlIngPz9jb';
    }

    try {
      QuerySnapshot vaccinesPetQuerySnapshot = await FirebaseFirestore.instance
          .collection('pet_vaccines')
          .doc(idTypePet)
          .collection("pet_vaccines")
          .orderBy("id_table_vacc", descending: false)
          .get();

      List<Map<String, dynamic>> allVaccine = vaccinesPetQuerySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        vaccinePetDatas = allVaccine;
        isLoading = false;
      });
    } catch (e) {
      print('Error getting pet vaccines data from Firestore: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshHomePage() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    await _loadAllPet(widget.petId); // โหลดข้อมูลใหม่
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
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
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  Future<List<String>> _fetchImgsFromFirestore(String petId) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('imgs_pet')
        .doc(petId)
        .get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<String> images = [];
      for (int i = 1; i <= 9; i++) {
        String? img = data['img_$i'];
        if (img != null && img.isNotEmpty) {
          images.add(img);
        }
      }
      print('Fetched images from Firestore for petId $petId: $images');
      return images;
    } else {
      print('No images found for petId $petId');
      return [];
    }
  }

  Future<void> _loadAllPet(String petId) async {
    try {
      Map<String, dynamic> petData = await _profileService.loadPetData(petId);
      List<String> firestoreImages = await _fetchImgsFromFirestore(petId);
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
        status = petData['status'] ?? 'พร้อมผสมพันธุ์';
        _firestoreImages = firestoreImages;

        vaccination_Table =
            (pet_type == 'สุนัข') ? vaccinationDog_Table : vaccinationCat_Table;

        _fetchVaccinationData();
        _getVaccines_petData();
        isLoading = false;
      });
      print(
          'Pet user ID: $pet_user'); // เพิ่มเพื่อดูค่า pet_user ว่าถูกต้องหรือไม่
    } catch (e) {
      print('Error getting pet user data from Firestore: $e');
    }
  }

  void showImageDialog(BuildContext context, String imageUrl) {
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
                  base64Decode(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddImg() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ImagePickerDialog(
          firestoreImages: List.from(_firestoreImages), // ส่ง copy ของรายการ
          onSaveImages: (compressedImages, base64Images) async {
            await _saveImgsPetToFirestore(
              petId: widget.petId,
              base64Images: base64Images,
            );
          },
          petId: widget.petId,
          deleteImageFromFirestore:
              _deleteImageFromFirestore, // Pass the delete function
        );
      },
    );
  }

  Future<int> _getNextAvailableIndex(Map<String, dynamic> existingData) async {
    for (int i = 1; i <= 9; i++) {
      if (existingData['img_$i'] == null || existingData['img_$i'].isEmpty) {
        return i;
      }
    }
    return 10; // หมายความว่าไม่มีตำแหน่งที่ว่าง
  }

  Future<void> _deleteImageFromFirestore(String imageBase64) async {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection('imgs_pet').doc(widget.petId);

    // ดึงข้อมูลที่มีอยู่จาก Firestore
    DocumentSnapshot docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

      // หา field ที่มีค่า base64 ตรงกับรูปภาพที่จะลบ
      String? fieldName;
      data.forEach((key, value) {
        if (value == imageBase64) {
          fieldName = key;
        }
      });

      if (fieldName != null) {
        Map<String, dynamic> updateData = {
          fieldName!: FieldValue.delete(),
        };
        try {
          print('Deleting image with field: $fieldName from Firestore');
          await docRef.update(updateData);
          print('Deleted image from Firestore (field: $fieldName)');

          // อัปเดต UI โดยการลบรูปภาพ
          setState(() {
            _firestoreImages.remove(imageBase64);
          });
        } catch (error) {
          print('Error deleting image: $error');
        }
      } else {
        print('Image not found in Firestore fields');
      }
    } else {
      print('Document does not exist');
    }
  }

  Future<void> _saveImgsPetToFirestore({
    required String petId,
    required List<String?> base64Images,
  }) async {
    DocumentReference imgData =
        FirebaseFirestore.instance.collection('imgs_pet').doc(petId);

    // ดึงข้อมูลที่มีอยู่แล้วจาก Firestore
    DocumentSnapshot doc = await imgData.get();
    Map<String, dynamic> existingData = {};
    if (doc.exists) {
      existingData = doc.data() as Map<String, dynamic>;
    }

    // อัปเดตรูปภาพใหม่ในช่องที่ว่างเท่านั้น
    Map<String, dynamic> updateData = {
      'pet_id': petId,
    };
    int nextIndex = await _getNextAvailableIndex(existingData);

    for (String? base64Image in base64Images) {
      if (base64Image != null) {
        while (nextIndex <= 9 &&
            existingData['img_$nextIndex'] != null &&
            existingData['img_$nextIndex'].isNotEmpty) {
          nextIndex++;
        }
        if (nextIndex <= 9) {
          updateData['img_$nextIndex'] = base64Image;
          nextIndex++;
        } else {
          break; // ถ้าไม่มีช่องว่างหยุดการอัปเดต
        }
      }
    }

    try {
      // อัปเดตข้อมูลใน Firestore
      await imgData.set(updateData, SetOptions(merge: true));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')));
      _refreshHomePage();
    } catch (e) {
      print('Error saving images to Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')));
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

<<<<<<< HEAD
  // ดึงข้อมูล Vac Dog
  void _fetchVacDataDog() async {
=======
  //ดึงข้อมูลสัตว์เลี้ยงของผู้ใช้ทั้งหมด
  Future<void> _loadAllPet(String petId) async {
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
    try {
      List<String> breeds =
          await _profileService.fetchVacDataDog('vaccines_more');
      setState(() {
        _vacOfDog = breeds;
      });
    } catch (error) {
      print("Failed to fetch breed data: $error");
    }
  }

  // ดึงข้อมูล Vac Cat
  void _fetchVacDataCat() async {
    try {
      List<String> breeds =
          await _profileService.fetchVacDataCat('vaccines_more');
      setState(() {
        _vacOfCat = breeds;
      });
    } catch (error) {
      print("Failed to fetch breed data: $error");
    }
  }

  // ดึงข้อมูล Vac_table ที่บันทึกลงไป
  Future<void> _fetchVaccinationData() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('vac_history')
          .doc(userId)
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
        // อัปเดตลิสต์วัคซีนที่ถูกเลือก
        _updateVaccinationList();
      });
    } catch (e) {
      print('Error fetching vaccination data: $e');
    }
  }

<<<<<<< HEAD
  // บันทึกข้อมูล Vac_table ลง FireStore
  Future<void> _saveVaccineToFirestore() async {
    try {
      await _profileService.saveVaccineToFirestore(
          userId: userId!,
          petId: pet_id,
          vacName: _selectedVac_Table ?? '',
          weight: _vacWeightTable.text,
          price: _vacPriceTable.text,
          date: _dateVacTable.text,
          status: _vacStatus_Table ?? 'ไม่ได้ฉีด');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')),
      );
      setState(() {
        _selectedVac = null;
      });
      _refreshHomePage();
    } catch (e) {
      print('Error saving vaccine data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
      );
=======
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
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
    }
  }

  // บันทึกข้อมูล Vac_more ลง FireStore
  Future<void> _saveVaccineTo_MoreFirestore() async {
    try {
      await _profileService.saveVaccine_MoreToFirestore(
        userId: userId!,
        petId: pet_id,
        vacName: _selectedVac ?? '',
        weight: _vacWeight.text,
        price: _vacPrice.text,
        location: _vacLocation.text,
        date: _dateVacController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')),
      );
      setState(() {
        _selectedVac = null;
      });
      _refreshHomePage();
    } catch (e) {
      print('Error saving vaccine data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
      );
    }
  }

  // บันทึกข้อมูลประจำเดือน ลง FireStore
  Future<void> _saveReportToFirestore() async {
    try {
      await _profileService.saveReportToFirestore(
        userId: userId!,
        petId: pet_id,
        date: _dateController.text,
        description: _infoController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')),
      );

      // scheduleNotification(dateSend);

      _refreshHomePage();
    } catch (e) {
      print('Error saving report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return WillPopScope(
      onWillPop: () async {
        // ทำการรีเฟรชข้อมูลเมื่อผู้ใช้กลับมาจากหน้าที่เคยเปิดอยู่
        _refreshHomePage();
        return true; // ทำการย้อนกลับ
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "โปรไฟล์สัตว์เลี้ยง",
            style: TextStyle(color: Color.fromARGB(255, 49, 42, 42)),
          ),
          centerTitle: true,
          toolbarHeight: 70,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Edit_Pet_Page(petUserData: {
                        'pet_id': pet_id,
                        'name': petName,
                        'breed_pet': type,
                        'img_profile': petImageBase64,
                        'color': color,
                        'weight': weight,
                        'gender': gender,
                        'description': des,
                        'price': price,
                        'birthdate': birthdateStr,
                        'type_pet': pet_type,
                        'status': status
                      }),
                    )).then((_) {
                  // Refresh data after returning from Edit_Pet_Page
                  _refreshHomePage();
                });
              },
              icon: const Icon(
                Icons.edit,
              ),
            ),
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
                          context: context,
                          userId: userId ?? '',
                          petId: pet_id)),
                  MenuPetWidget(
                      title: "การประกวด",
                      icon: LineAwesomeIcons.certificate,
                      onPress: () => showContestDialog(
                          context: context,
                          userId: userId ?? '',
                          petId: pet_id,
                          userPet: pet_user)),
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
                            userId: userId ?? '',
                            petId: pet_id,
                          ),
<<<<<<< HEAD
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.ease;
=======
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
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3

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
                ElevatedButton(
                  onPressed: _showAddImg,
                  child: Text('เพิ่มรูปภาพ'),
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

  Future<void> _refreshData() async {
    setState(() {
      fetchMonthlyData();
      fetchVacmoreData();
    });
  }

  Future<QuerySnapshot> fetchMonthlyData() {
    return FirebaseFirestore.instance
        .collection('report_period')
        .doc(userId)
        .collection('period_pet')
        .where('pet_id', isEqualTo: widget.petId)
        .orderBy('date', descending: true)
        .get();
  }

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
              ElevatedButton(
                onPressed: _showInputDialog,
                child: Text('บันทึกข้อมูล'),
              ),
            ],
          ),
          SizedBox(height: 10),
          FutureBuilder<QuerySnapshot>(
            future: fetchMonthlyData(),
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
                    final formattedDate =
                        DateFormat('d MMM yyyy', 'th_TH').format(date);
                    final idPeriod = reportDoc.id;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    PeriodDetailPage(
                              report: report,
                              userId: userId ?? '',
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
                        ).then((_) {
                          // รีเฟรชข้อมูลหลังจากกลับจากหน้ารายละเอียด
                          _refreshData();
                        });
                      },
                      child: Card(
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
                                  color: Colors.pinkAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  LineAwesomeIcons.calendar_with_day_focus,
                                  color: Colors.pinkAccent,
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
          ),
        ],
      ),
    );
  }

  Future<QuerySnapshot> fetchVacmoreData() {
    return FirebaseFirestore.instance
        .collection('vac_more')
        .doc(userId)
        .collection('vac_pet')
        .where('pet_id', isEqualTo: widget.petId)
        .orderBy('date', descending: true)
        .get();
  }

  // Tab ข้อมูลประวัติสุขภาพ
  Widget _buildHealthHistoryTab() {
    bool isVaccinationAvailable = _availableVaccinations.isNotEmpty;

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
              ElevatedButton(
                onPressed:
                    isVaccinationAvailable ? _showVaccineTableDialog : null,
                child: Text('บันทึกข้อมูล'),
              ),
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
                  ElevatedButton(
                    onPressed: _showVaccineDialog,
                    child: Text('บันทึกข้อมูล'),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // แสดงข้อมูลบันทึกวัคซีน
              FutureBuilder<QuerySnapshot>(
                future: fetchVacmoreData(),
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
                                  userId: userId ?? '',
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
                            ).then((_) {
                              // รีเฟรชข้อมูลหลังจากกลับจากหน้ารายละเอียด
                              _refreshData();
                            });
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
                          ' ($status)',
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
      },
    );
  }

  // รูป Banner
<<<<<<< HEAD
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
          petImageBanner.isNotEmpty
              ? Positioned(
                  bottom: 10,
                  right: 10,
                  child: SizedBox(
                    width: 35,
                    height: 35,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
                        color: Colors.grey[800],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          _showBannerOptions(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(0),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                )
              : Positioned(
                  bottom: 70,
                  right: 170,
                  child: Container(
                    child: ElevatedButton(
                      onPressed: () {
                        _showBannerOptions(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.all(0),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 30,
                          ),
                          Text('เพิ่มรูปภาพ',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                )
        ],
      );

  Future<void> _changeBannerImage() async {
    final Uint8List? image =
        await _profileService.pickImage(ImageSource.gallery);
    if (image != null) {
      final Uint8List? compressedImage =
          await _profileService.compressImage(image);
      if (compressedImage != null) {
        setState(() {});
        // อัปเดตรูปภาพใน Firestore
        await FirebaseFirestore.instance
            .collection('Pet_User')
            .doc(pet_id)
            .update({'img_Banner': base64Encode(compressedImage)});
        _refreshHomePage(); // รีเฟรชหน้าเพื่อแสดงข้อมูลล่าสุด
      }
    }
  }

  Future<void> _changeProfileImage() async {
    final Uint8List? image =
        await _profileService.pickImage(ImageSource.gallery);
    if (image != null) {
      final Uint8List? compressedImage =
          await _profileService.compressImage(image);
      if (compressedImage != null) {
        setState(() {});
        // อัปเดตรูปภาพใน Firestore
        await FirebaseFirestore.instance
            .collection('Pet_User')
            .doc(pet_id)
            .update({'img_profile': base64Encode(compressedImage)});
        _refreshHomePage(); // รีเฟรชหน้าเพื่อแสดงข้อมูลล่าสุด
      }
    }
  }

  // รูป Profile
  Widget buildProfileImage(BuildContext context, String status) {
    return GestureDetector(
      onTap: () => _showEditOptions(context, status, petImageBase64),
      child: Container(
=======
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
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
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

  void _showBannerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.image),
                title: Text('ดูรูปภาพ'),
                onTap: () {
                  Navigator.of(context).pop();
                  showImageDialog(context, petImageBanner);
                },
              ),
              ListTile(
                leading: Icon(Icons.upload_rounded),
                title: Text('เปลี่ยนรูปภาพ'),
                onTap: () {
                  Navigator.of(context).pop(); // ปิด dialog แก้ไขข้อมูล
                  _changeBannerImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditOptions(
      BuildContext context, String status, String petImageBase64) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.image),
                title: Text('ดูรูปภาพ'),
                onTap: () {
                  Navigator.of(context).pop();
                  showImageDialog(context, petImageBase64);
                },
              ),
              ListTile(
                leading: Icon(Icons.upload_rounded),
                title: Text('เปลี่ยนรูปภาพ'),
                onTap: () {
                  Navigator.of(context).pop(); // ปิด dialog แก้ไขข้อมูล
                  _changeProfileImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('เปลี่ยนสถานะ'),
                onTap: () {
                  Navigator.of(context).pop(); // ปิด BottomSheet ก่อน
                  _showStatusOptions(context, status);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStatusOptions(BuildContext context, String currentStatus) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusOption(context, 'เสียชีวิต', currentStatus),
              _buildStatusOption(context, 'พร้อมผสมพันธุ์', currentStatus),
              _buildStatusOption(context, 'ไม่พร้อมผสมพันธุ์', currentStatus),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(
      BuildContext context, String status, String currentStatus) {
    return RadioListTile<String>(
      title: Text(status),
      value: status,
      groupValue: currentStatus,
      onChanged: (String? value) {
        if (value != null) {
          // อัปเดตสถานะใน Firestore
          FirebaseFirestore.instance
              .collection('Pet_User')
              .doc(pet_id)
              .update({'status': value});
          Navigator.of(context).pop(); // ปิด BottomSheet เปลี่ยนสถานะ
          _refreshHomePage();
        }
      },
    );
  }

  // บันทึกข้อมูลประจำเดือน
  void _showInputDialog() {
    _dateController.clear();
    _infoController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            width:
                MediaQuery.of(context).size.width * 0.8, // ปรับขนาดของ Dialog
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                        'บันทึกประจำเดือน',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
                        child: Text(
                          'วันที่เริ่มเป็นประจำเดือน',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            _dateController.text =
                                pickedDate.toString().split(' ')[0];
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกวันที่';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
                        child: Text(
                          'ข้อมูลเพิ่มเติม',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _infoController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'อาการ, พฤติกรรมของสัตว์เลี้ยง',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        height: 40,
                        width: 120,
                        child: TextButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final inputDate =
                                  DateTime.parse(_dateController.text);
                              final today = DateTime.now();

                              if (inputDate.isAfter(today)) {
                                // วันที่ใน _dateController.text เป็นวันในอนาคต
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('ไม่สามารถเลือกวันในอนาคตได้'),
                                  ),
                                );
                                return;
                              } else {
                                NotificationHelper.scheduledNotification(
                                  'Pet fluffy',
                                  '$petName ถึงช่วงเวลาผสมพันธุ์ที่ดีที่สุดแล้ว',
                                  _dateController.text,
                                  pet_type,
                                  user!.uid,
                                  pet_id,
                                );
                                _saveReportToFirestore();
                                Navigator.of(context).pop();
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                          ),
                          child: Center(
                            // ใช้ Center widget เพื่อตั้งค่า Row ให้อยู่ตรงกลาง
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // จัดให้อยู่ตรงกลางแนวนอน
                              children: [
                                Icon(
                                  pet_type == 'สุนัข'
                                      ? LineAwesomeIcons.dog
                                      : LineAwesomeIcons.cat,
                                ),
                                SizedBox(
                                    width:
                                        8), // เพิ่ม space ระหว่าง Icon กับ Text
                                Text('บันทึก', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // บันทึกการฉีดวัคซีน
  void _showVaccineDialog() {
    _dateVacController.clear();
    _vacWeight.clear();
    _vacPrice.clear();
    _vacLocation.clear();

    // Determine the list of vaccines based on the pet type
    List<String> vaccinationList =
        (pet_type == 'สุนัข') ? _vacOfDog : _vacOfCat;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                      'บันทึกการฉีดวัคซีน(เพิ่มเติม)',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, bottom: 5.0),
                              child: Text(
                                'ชื่อวัคซีน',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          DropdownButtonFormField<String>(
                            value: _selectedVac,
                            hint: Text('เลือกชื่อวัคซีน'),
                            items: vaccinationList.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child:
                                    Text(value, style: TextStyle(fontSize: 16)),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedVac = newValue;
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณาเลือกวัคซีน';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, bottom: 5.0),
                              child: Text(
                                'น้ำหนัก',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _vacWeight,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกน้ำหนัก';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, bottom: 5.0),
                              child: Text(
                                'ราคาวัคซีน',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _vacPrice,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกราคา ไม่มีให้ใส่ 0';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, bottom: 5.0),
                              child: Text(
                                'สถานที่ไปฉีด',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _vacLocation,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกสถานที่';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, bottom: 5.0),
                              child: Text(
                                'วันที่ฉีด',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _dateVacController,
                            decoration: InputDecoration(
                              suffixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกวันที่';
                              }
                              return null;
                            },
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );

                              if (pickedDate != null) {
                                setState(() {
                                  _dateVacController.text =
                                      pickedDate.toString().split(' ')[0];
                                });
                              }
                            },
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: SizedBox(
                              height: 40,
                              width: 120,
                              child: TextButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    _saveVaccineTo_MoreFirestore();
                                    Navigator.of(context).pop();
                                  }
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.blue,
                                ),
                                child: Center(
                                  // ใช้ Center widget เพื่อตั้งค่า Row ให้อยู่ตรงกลาง
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .center, // จัดให้อยู่ตรงกลางแนวนอน
                                    children: [
                                      Icon(
                                        pet_type == 'สุนัข'
                                            ? LineAwesomeIcons.dog
                                            : LineAwesomeIcons.cat,
                                      ),
                                      SizedBox(
                                          width:
                                              8), // เพิ่ม space ระหว่าง Icon กับ Text
                                      Text('บันทึก',
                                          style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _resetForm() {
    setState(() {
      _selectedVac_Table = null;
      _vacWeightTable.clear();
      _vacPriceTable.clear();
      _dateVacTable.clear();
      _vacStatus_Table = null;
    });
  }

  // ฟังก์ชันสำหรับอัปเดตลิสต์วัคซีนที่มีอยู่
  void _updateVaccinationList() {
    List<Map<String, String>> currentVaccination =
        (pet_type == 'สุนัข') ? vac_Dog : vac_Cat;

    // สร้างชุดข้อมูลวัคซีนที่มีสถานะเป็น "ฉีดแล้ว" เพื่อกรองรายการที่แสดง
    Set<String> vaccinatedVaccines = Set.from(vaccinationDataFromFirestore
        .where((data) => data['status'] == 'ฉีดแล้ว')
        .map((data) => data['vaccine']));

    setState(() {
      _availableVaccinations = currentVaccination
          .where((vac) => !vaccinatedVaccines.contains(vac['vaccine']))
          .toList();
    });
  }

  // ฟังก์ชันสำหรับแสดง Dialog เพื่อบันทึกข้อมูลวัคซีน
  void _showVaccineTableDialog() {
    _fetchVaccinationData();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
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
                    'บันทึกการฉีดวัคซีนตามเกณฑ์',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, bottom: 5.0),
                            child: Text(
                              'วัคซีน',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedVac_Table,
                          hint: Text('เลือกชื่อวัคซีน'),
                          items: _availableVaccinations.isNotEmpty
                              ? _availableVaccinations
                                  .map((Map<String, String> value) {
                                  return DropdownMenuItem<String>(
                                    value: value['vaccine'],
                                    child: Text(value['vaccine'] ?? '',
                                        style: TextStyle(fontSize: 14)),
                                  );
                                }).toList()
                              : [], // ให้ค่าเริ่มต้นเป็นลิสต์ว่างหากไม่มีวัคซีนให้เลือก
                          onChanged: (newValue) {
                            setState(() {
                              _selectedVac_Table = newValue;
                              if (newValue != null &&
                                  !_selectedVaccines.contains(newValue)) {
                                _selectedVaccines.add(newValue);
                                _fetchVaccinationData(); // อัปเดตข้อมูลวัคซีน
                              }
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                          ),
                        ),
                        SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, bottom: 5.0),
                            child: Text(
                              'น้ำหนัก',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        TextField(
                          controller: _vacWeightTable,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                          ),
                        ),
                        SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, bottom: 5.0),
                            child: Text(
                              'ราคา',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        TextField(
                          controller: _vacPriceTable,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                          ),
                        ),
                        SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, bottom: 5.0),
                            child: Text(
                              'วันที่ฉีด',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        TextField(
                          controller: _dateVacTable,
                          decoration: InputDecoration(
                            suffixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );

                            if (pickedDate != null) {
                              setState(() {
                                _dateVacTable.text =
                                    pickedDate.toString().split(' ')[0];
                              });
                            }
                          },
                        ),
                        SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, bottom: 5.0),
                            child: Text(
                              'สถานะ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: _vacStatus_Table,
                          hint: Text('เลือกสถานะ'),
                          items: ['ฉีดแล้ว', 'ยังไม่ฉีด'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child:
                                  Text(value, style: TextStyle(fontSize: 16)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _vacStatus_Table = newValue;
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: SizedBox(
                            height: 40,
                            width: 120,
                            child: TextButton(
                              onPressed: () {
                                String errorMessage = '';

                                if (_selectedVac_Table == null ||
                                    _vacStatus_Table == null) {
                                  errorMessage =
                                      'กรุณากรอกข้อมูลวัคซีนและสถานะก่อนทำการบันทึก';
                                } else if (_vacStatus_Table == 'ฉีดแล้ว' &&
                                    (_vacWeightTable.text.isEmpty ||
                                        _vacPriceTable.text.isEmpty ||
                                        _dateVacTable.text.isEmpty)) {
                                  errorMessage =
                                      'กรุณากรอกข้อมูลให้ครบทุกช่องสำหรับสถานะฉีดแล้ว';
                                }

                                if (errorMessage.isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('กรุณากรอกข้อมูลให้ครบ'),
                                        content: Text(
                                          errorMessage,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('ตกลง'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else {
                                  _saveVaccineToFirestore();
                                  setState(() {
                                    _selectedVaccines.add(_selectedVac_Table!);
                                    _updateVaccinationList();
                                  });
                                  Navigator.of(context).pop();
                                  _resetForm();
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue,
                              ),
                              child: Center(
                                // ใช้ Center widget เพื่อตั้งค่า Row ให้อยู่ตรงกลาง
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .center, // จัดให้อยู่ตรงกลางแนวนอน
                                  children: [
                                    Icon(
                                      pet_type == 'สุนัข'
                                          ? LineAwesomeIcons.dog
                                          : LineAwesomeIcons.cat,
                                    ),
                                    SizedBox(
                                        width:
                                            8), // เพิ่ม space ระหว่าง Icon กับ Text
                                    Text('บันทึก',
                                        style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  // แสดงตารางการฉีดวัคซีนตามเกณฑ์
  void _showVaccinationScheduleDialog(BuildContext context, String petType) {
    List<Map<String, String>> vaccinationSchedule = vaccinePetDatas.map((data) {
      // แปลง Map<String, dynamic> เป็น Map<String, String>
      return {
        'age': data['age']?.toString() ?? '',
        'vaccine': data['vaccine']?.toString() ?? '',
        'dose': data['dose']?.toString() ?? '',
      };
    }).toList();

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

  // ดึงข้อมูลที่บันทึกมาใส่ตารางการฉีดวัคซีนตามเกณฑ์
  List<TableRow> _buildTableRows(List<Map<String, dynamic>> vaccinationTable) {
    return vaccinationTable.map((scheduleTable) {
      // รวม vaccine และ dose เป็นค่าเดียวเพื่อใช้ในการค้นหา
      String vaccineWithDose =
          "${scheduleTable['vaccine']} ${scheduleTable['dose']}";

      // ค้นหาข้อมูลการฉีดวัคซีนที่ตรงกับ vaccine + dose จาก Firestore
      var firestoreData = vaccinationDataFromFirestore.firstWhere(
        (data) => data['vaccine'] == vaccineWithDose,
        orElse: () => {},
      );

      // ตรวจสอบว่าสถานะมีหรือไม่
      bool hasStatus =
          firestoreData.isNotEmpty && firestoreData['status'] != '';

      return TableRow(
        children: <Widget>[
          GestureDetector(
            onTap: hasStatus
                ? () {
                    // เปิดไดอะล็อกเพื่อแก้ไขข้อมูล
                    _showEditDialog(context, scheduleTable);
                  }
                : null, // ถ้าไม่มีสถานะ, ไม่สามารถแก้ไขได้
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(hasStatus ? firestoreData['status'] : ''),
            ),
          ),
          GestureDetector(
            onTap: hasStatus
                ? () {
                    _showEditDialog(context, scheduleTable);
                  }
                : null, // ถ้าไม่มีสถานะ, ไม่สามารถแก้ไขได้
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(vaccineWithDose),
            ),
          ),
          GestureDetector(
            onTap: hasStatus
                ? () {
                    _showEditDialog(context, scheduleTable);
                  }
                : null, // ถ้าไม่มีสถานะ, ไม่สามารถแก้ไขได้
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(hasStatus ? firestoreData['date'] : ''),
            ),
          ),
          GestureDetector(
            onTap: hasStatus
                ? () {
                    _showEditDialog(context, scheduleTable);
                  }
                : null, // ถ้าไม่มีสถานะ, ไม่สามารถแก้ไขได้
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(hasStatus ? firestoreData['weight'] : ''),
            ),
          ),
          GestureDetector(
            onTap: hasStatus
                ? () {
                    _showEditDialog(context, scheduleTable);
                  }
                : null, // ถ้าไม่มีสถานะ, ไม่สามารถแก้ไขได้
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(hasStatus ? firestoreData['price'] : ''),
            ),
          ),
        ],
      );
    }).toList();
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> data) {
    final String vaccineWithDose = "${data['vaccine']} ${data['dose']}";
    var firestoreData = vaccinationDataFromFirestore.firstWhere(
      (item) => item['vaccine'] == vaccineWithDose,
      orElse: () => {},
    );

    // ใช้ค่า default ถ้า firestoreData ว่างเปล่า
    firestoreData = firestoreData.isEmpty
        ? {
            'date': data['date'],
            'weight': data['weight'],
            'price': data['price'],
            'status': data['status'] ?? '',
          }
        : firestoreData;

    final TextEditingController dateController =
        TextEditingController(text: firestoreData['date']);
    final TextEditingController weightController =
        TextEditingController(text: firestoreData['weight']);
    final TextEditingController priceController =
        TextEditingController(text: firestoreData['price']);

    String? statusValue = firestoreData['status'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'แก้ไขข้อมูลตารางการฉีดวัคซีน',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${data['vaccine']} (${data['dose']})',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    labelText: 'วันที่ฉีด',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.datetime,
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    DateTime currentDate = DateTime.now();
                    DateTime? selectedDate = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.tryParse(dateController.text) ?? currentDate,
                      firstDate: DateTime(2000),
                      lastDate:
                          currentDate, // กำหนดให้ไม่สามารถเลือกวันที่เกินวันปัจจุบันได้
                    );
                    if (selectedDate != null) {
                      dateController.text =
                          DateFormat('yyyy-MM-dd').format(selectedDate);
                    }
                  },
                ),
                SizedBox(height: 10),
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(
                    labelText: 'น้ำหนัก',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'ราคา',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: statusValue,
                  items: [
                    DropdownMenuItem(
                      value: 'ฉีดแล้ว',
                      child: Text('ฉีดแล้ว'),
                    ),
                    DropdownMenuItem(
                      value: 'ยังไม่ฉีด',
                      child: Text('ยังไม่ฉีด'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'สถานะ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      statusValue = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
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
                        // อัปเดตข้อมูลที่ถูกแก้ไข
                        setState(() {
                          data['date'] = dateController.text;
                          data['weight'] = weightController.text;
                          data['price'] = priceController.text;
                          data['status'] = statusValue; // อัปเดตสถานะ
                          // อัปเดตข้อมูลที่ Firestore ด้วย
                          if (firestoreData.isNotEmpty) {
                            firestoreData['date'] = dateController.text;
                            firestoreData['weight'] = weightController.text;
                            firestoreData['price'] = priceController.text;
                            firestoreData['status'] =
                                statusValue; // อัปเดตสถานะ
                          }
                        });
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
