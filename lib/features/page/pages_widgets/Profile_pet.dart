// ignore_for_file: camel_case_types, file_names, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:Pet_Fluffy/features/api/user_data.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/table_dataVac.dart';
import 'package:Pet_Fluffy/features/services/age_calculator_service.dart';
import 'package:Pet_Fluffy/features/services/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

//หน้า Profile ของ สัตว์เลี้ยง
class Profile_pet_Page extends StatefulWidget {
  final String petId;
  const Profile_pet_Page({super.key, required this.petId});

  @override
  State<Profile_pet_Page> createState() => _Profile_pet_PageState();
}

class _Profile_pet_PageState extends State<Profile_pet_Page> {
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
  final TextEditingController _vacStatusTable = TextEditingController();

  String pet_user = '';
  String pet_id = '';
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
  String pet_type = '';

  String? userId;
  String? userImageBase64;

  bool isLoading = true;
  late List<Map<String, dynamic>> petUserDataList = [];

  String? _selectedVac;
  List<String> _vacOfDog = [];
  List<String> _vacOfCat = [];

  final double coverHeight = 180;
  final double profileHeight = 90;

  List<XFile?> _images = [];
  List<String> _firestoreImages = [];

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _loadAllPet(widget.petId);
      _getUserDataFromFirestore();
      _fetchVacDataDog();
      _fetchVacDataCat();
    }
    isLoading = true;
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

  //ใช้สำหรับการบีบอัดรูปภาพ
  Future<Uint8List?> compressImage(Uint8List image) async {
    try {
      // ลดความสูงเป็น 480 pixel และลดความกว้างเป็น 640 pixel เพื่อลดขนาดของรูปภาพให้เล็กลง
      List<int> compressedImage = await FlutterImageCompress.compressWithList(
        image,
        minHeight: 480, // ลดความสูงเป็น 480 pixel
        minWidth: 640, // ลดความกว้างเป็น 640 pixel
        quality: 70, // ลดคุณภาพรูปภาพเป็น 70%
      );
      return Uint8List.fromList(compressedImage);
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  Future<Uint8List?> _pickAndCompressImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      Uint8List? imageBytes = await file.readAsBytes();
      if (imageBytes != null) {
        return await compressImage(imageBytes);
      } else {
        print('Failed to read image bytes');
        return null;
      }
    } else {
      print('No image selected');
      return null;
    }
  }

  String uint8ListToBase64(Uint8List data) {
    return base64Encode(data);
  }

  Uint8List? base64ToUint8List(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error decoding base64: $e');
      return null;
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
        color = petData['color'] ?? '';
        weight = petData['weight'] ?? '0.0';
        gender = petData['gender'] ?? '';
        des = petData['description'] ?? '';
        price = petData['price'] ?? '';
        birthdateStr = petData['birthdate'] ?? '';
        pet_type = petData['type_pet'] ?? '';
        DateTime birthdate = DateTime.parse(birthdateStr);
        age = _ageCalculatorService.calculateAge(birthdate);
        _firestoreImages = firestoreImages;
        isLoading = false;
      });
    } catch (e) {
      print('Error getting pet user data from Firestore: $e');
    }
  }

  void _showAddImg() async {
    final List<Uint8List?> compressedImages = [];
    final List<String?> base64Images = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('เพิ่มรูปภาพ'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300, // กำหนดความสูงของ Dialog Content
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // แสดงรูปภาพที่ถูกเลือกใน Dialog
                    if (_firestoreImages.isNotEmpty ||
                        compressedImages.isNotEmpty)
                      Container(
                        height: 200, // กำหนดความสูงของ GridView
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount:
                              _firestoreImages.length + compressedImages.length,
                          itemBuilder: (context, index) {
                            if (index < _firestoreImages.length) {
                              Uint8List? imageData =
                                  base64ToUint8List(_firestoreImages[index]);
                              if (imageData == null) {
                                return Container(
                                  color: Colors.grey,
                                  child: Center(
                                    child: Text(
                                      'Invalid image',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              }
                              return Stack(
                                children: [
                                  Image.memory(
                                    imageData,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon:
                                          Icon(Icons.close, color: Colors.red),
                                      onPressed: () {
                                        print(
                                            'Requesting confirmation for deleting image at index: $index');
                                        // Show confirmation dialog
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text('ยืนยันการลบ'),
                                              content: Text(
                                                  'คุณต้องการลบรูปภาพนี้ออกจากระบบหรือไม่?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(); // ปิด Dialog
                                                  },
                                                  child: Text('ยกเลิก'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(); // ปิด Dialog
                                                    _deleteImageFromFirestore(
                                                            index)
                                                        .then((_) {
                                                      setState(() {
                                                        _firestoreImages
                                                            .removeAt(index);
                                                      });
                                                    }).catchError((e) {
                                                      print(
                                                          'Error deleting image: $e');
                                                    });
                                                  },
                                                  child: Text('ยืนยัน'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Stack(
                                children: [
                                  Image.memory(
                                    compressedImages[
                                        index - _firestoreImages.length]!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon:
                                          Icon(Icons.close, color: Colors.red),
                                      onPressed: () {
                                        print(
                                            'Removing compressed image at index: ${index - _firestoreImages.length}');
                                        setState(() {
                                          compressedImages.removeAt(
                                              index - _firestoreImages.length);
                                          base64Images.removeAt(
                                              index - _firestoreImages.length);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    TextButton(
                      onPressed: () async {
                        final compressedImage =
                            await _pickAndCompressImage(ImageSource.gallery);
                        if (compressedImage != null) {
                          final base64Image =
                              uint8ListToBase64(compressedImage);
                          print('Picked image from gallery: $base64Image');
                          setState(() {
                            if (_firestoreImages.length +
                                    compressedImages.length <
                                9) {
                              _images.add(XFile.fromData(compressedImage));
                              compressedImages.add(compressedImage);
                              base64Images.add(base64Image);
                              print(
                                  'Added compressed image from gallery: $base64Image');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'คุณสามารถเพิ่มรูปภาพได้สูงสุด 9 รูป')),
                              );
                            }
                          });
                        }
                      },
                      child: Text('เลือกรูปจาก Gallery'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final compressedImage =
                            await _pickAndCompressImage(ImageSource.camera);
                        if (compressedImage != null) {
                          final base64Image =
                              uint8ListToBase64(compressedImage);
                          print('Picked image from camera: $base64Image');
                          setState(() {
                            if (_firestoreImages.length +
                                    compressedImages.length <
                                9) {
                              _images.add(XFile.fromData(compressedImage));
                              compressedImages.add(compressedImage);
                              base64Images.add(base64Image);
                              print(
                                  'Added compressed image from camera: $base64Image');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'คุณสามารถเพิ่มรูปภาพได้สูงสุด 9 รูป')),
                              );
                            }
                          });
                        }
                      },
                      child: Text('ถ่ายรูปจาก Camera'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: () async {
                    print('Saving images to Firestore: $base64Images');
                    await _saveImgsPetToFirestore(base64Images: base64Images);
                    Navigator.of(context).pop();
                  },
                  child: Text('ยืนยันการเพิ่ม'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<int> _getNextAvailableIndex() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('imgs_pet')
        .doc(widget.petId)
        .get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      for (int i = 1; i <= 9; i++) {
        if (data['img_$i'] == null || data['img_$i'].isEmpty) {
          return i;
        }
      }
    }
    return -1; // หมายความว่าไม่มีตำแหน่งที่ว่าง
  }

  Future<void> _deleteImageFromFirestore(int index) async {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection('imgs_pet').doc(pet_id);
    Map<String, dynamic> updateData = {
      'img_${index + 1}': FieldValue.delete(),
    };
    try {
      print('Deleting image at index: $index from Firestore');
      await docRef.update(updateData);
      print('Deleted image from Firestore');
    } catch (error) {
      print('Error deleting image: $error');
    }
  }

  Future<void> _saveImgsPetToFirestore({
    required List<String?> base64Images,
  }) async {
    try {
      final List<String?> images = List.generate(
          9, (index) => base64Images.length > index ? base64Images[index] : '');

      await _profileService.saveImgsPetToFirestore(
        petId: pet_id,
        img1: images[0] ?? '',
        img2: images[1] ?? '',
        img3: images[2] ?? '',
        img4: images[3] ?? '',
        img5: images[4] ?? '',
        img6: images[5] ?? '',
        img7: images[6] ?? '',
        img8: images[7] ?? '',
        img9: images[8] ?? '',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')),
      );
      setState(() {
        _selectedVac = null;
      });
      _refreshHomePage();
    } catch (e) {
      print('Error saving images to Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
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

  //ดึงข้อมูลสัตว์เลี้ยงของผู้ใช้ทั้งหมด
  // Future<void> _loadAllPet(String petId) async {
  //   try {
  //     Map<String, dynamic> petData = await _profileService.loadPetData(petId);
  //     setState(() {
  //       pet_user = petData['user_id'] ?? '';
  //       pet_id = petId;
  //       petName = petData['name'] ?? '';
  //       type = petData['breed_pet'] ?? '';
  //       petImageBase64 = petData['img_profile'] ?? '';
  //       color = petData['color'] ?? '';
  //       weight = petData['weight'] ?? '0.0';
  //       gender = petData['gender'] ?? '';
  //       des = petData['description'] ?? '';
  //       price = petData['price'] ?? '';
  //       birthdateStr = petData['birthdate'] ?? '';
  //       pet_type = petData['type_pet'] ?? '';
  //       DateTime birthdate = DateTime.parse(birthdateStr);
  //       age = _ageCalculatorService.calculateAge(birthdate);

  //       isLoading = false;
  //     });
  //     print(price);
  //   } catch (e) {
  //     print('Error getting pet user data from Firestore: $e');
  //   }
  // }

  // ดึงข้อมูล Vac Dog
  void _fetchVacDataDog() async {
    try {
      List<String> breeds = await _profileService.fetchVacData('dog_vac');
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
      List<String> breeds = await _profileService.fetchVacData('cat_vac');
      setState(() {
        _vacOfCat = breeds;
      });
    } catch (error) {
      print("Failed to fetch breed data: $error");
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
        setState(() {
          isLoading = false;
        });
      }
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
      _refreshHomePage();
    } catch (e) {
      print('Error saving report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
      );
    }
  }

  // บันทึกข้อมูล Vac ลง FireStore
  Future<void> _saveVaccineToFirestore() async {
    try {
      await _profileService.saveVaccineToFirestore(
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

  Future<void> _refreshHomePage() async {
    setState(() {
      isLoading = true; // ตั้งค่า isLoading เป็น true เพื่อแสดงการโหลด
    });
    await _loadAllPet(widget.petId); // เรียกโปรแกรมใหม่เพื่อโหลดข้อมูลใหม่
    setState(() {
      isLoading = false; // ตั้งค่า isLoading เป็น false เมื่อโหลดเสร็จสิ้น
    });
  }

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
                                        Row(
                                          children: [
                                            Row(
                                              children: [
                                                Padding(
                                                  padding:
                                                      EdgeInsets.only(right: 5),
                                                  child: Icon(
                                                      LineAwesomeIcons.image),
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
                                              .where('pet_id',
                                                  isEqualTo: widget.petId)
                                              .get(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const CircularProgressIndicator();
                                            }
                                            if (snapshot.hasError) {
                                              return Text(
                                                  'Error: ${snapshot.error}');
                                            }
                                            if (snapshot.hasData &&
                                                snapshot
                                                    .data!.docs.isNotEmpty) {
                                              // ดึงข้อมูลและแสดงผลใน GridView.builder
                                              return GridView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                gridDelegate:
                                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 1,
                                                  crossAxisSpacing: 10.0,
                                                  mainAxisSpacing: 10.0,
                                                ),
                                                itemCount:
                                                    snapshot.data!.docs.length,
                                                itemBuilder: (context, index) {
                                                  // ดึงข้อมูลทั้งหมดในเอกสารแต่ละเอกสาร
                                                  DocumentSnapshot imgDoc =
                                                      snapshot
                                                          .data!.docs[index];
                                                  Map<String, dynamic>? data =
                                                      imgDoc.data() as Map<
                                                          String, dynamic>?;

                                                  if (data != null &&
                                                      data.isNotEmpty) {
                                                    List<String> imageUrls = [];
                                                    for (int i = 1;
                                                        i <= 9;
                                                        i++) {
                                                      String? imageUrl =
                                                          data['img_$i']
                                                              as String?;
                                                      if (imageUrl != null &&
                                                          imageUrl.isNotEmpty) {
                                                        imageUrls.add(imageUrl);
                                                      }
                                                    }
                                                    return GridView.builder(
                                                      physics:
                                                          const NeverScrollableScrollPhysics(),
                                                      gridDelegate:
                                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: 3,
                                                        crossAxisSpacing: 8.0,
                                                        mainAxisSpacing: 8.0,
                                                      ),
                                                      itemCount:
                                                          imageUrls.length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        return ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          child: Image.memory(
                                                            base64Decode(
                                                                imageUrls[
                                                                    index]),
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const SizedBox(height: 15),
                                      Row(
                                        children: [
                                          Row(
                                            children: [
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(right: 5),
                                                child: Icon(LineAwesomeIcons
                                                    .calendar_with_day_focus),
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
                                      // แสดงข้อมูลบันทึกประจำเดือน
                                      FutureBuilder<QuerySnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('report_period')
                                            .doc(userId)
                                            .collection('pet_user')
                                            .where('pet_id',
                                                isEqualTo: widget.petId)
                                            .get(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          }
                                          if (snapshot.hasError) {
                                            return Text(
                                                'Error: ${snapshot.error}');
                                          }
                                          if (snapshot.hasData &&
                                              snapshot.data!.docs.isNotEmpty) {
                                            return ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  NeverScrollableScrollPhysics(),
                                              itemCount:
                                                  snapshot.data!.docs.length,
                                              itemBuilder: (context, index) {
                                                DocumentSnapshot reportDoc =
                                                    snapshot.data!.docs[index];
                                                Map<String, dynamic> report =
                                                    reportDoc.data()
                                                        as Map<String, dynamic>;
                                                final date = DateTime.parse(
                                                    report['date']);
                                                final formattedDate =
                                                    DateFormat('dd/MM/yyyy')
                                                        .format(date);

                                                return Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.0),
                                                  ),
                                                  elevation: 3,
                                                  margin:
                                                      const EdgeInsets.all(8.0),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12.0),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .pinkAccent
                                                                .withOpacity(
                                                                    0.2),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          padding:
                                                              EdgeInsets.all(8),
                                                          child: Icon(
                                                            LineAwesomeIcons
                                                                .calendar_with_day_focus,
                                                            color: Colors
                                                                .pinkAccent,
                                                          ),
                                                        ),
                                                        SizedBox(width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'รายละเอียดการบันทึกประจำเดือน',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 4),
                                                              Text(
                                                                report['des'] ??
                                                                    '',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                          .grey[
                                                                      600],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Text(
                                                              formattedDate,
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .grey[600],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
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
                                ),
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const SizedBox(height: 15),
                                      Row(
                                        children: [
                                          Row(
                                            children: [
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(right: 5),
                                                child: Icon(
                                                    LineAwesomeIcons.syringe),
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
                                            onPressed: _showVaccineTableDialog,
                                            child: Text('บันทึกข้อมูล'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0),
                                        child: Column(
                                          children: [
                                            MenuPetWidget(
                                              title: "ดูตารางการฉีดวัคซีน",
                                              icon: LineAwesomeIcons.table,
                                              onPress: () {
                                                _showVaccinationScheduleDialog(
                                                    context, pet_type);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.9,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.3,
                                        padding: EdgeInsets.all(20.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.vertical,
                                                  child: Table(
                                                    border: TableBorder.all(),
                                                    columnWidths: const <int,
                                                        TableColumnWidth>{
                                                      0: FixedColumnWidth(80),
                                                      1: FixedColumnWidth(180),
                                                      2: FixedColumnWidth(100),
                                                      3: FixedColumnWidth(80),
                                                      4: FixedColumnWidth(80),
                                                    },
                                                    defaultVerticalAlignment:
                                                        TableCellVerticalAlignment
                                                            .middle,
                                                    children: <TableRow>[
                                                      TableRow(
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[300],
                                                        ),
                                                        children: <Widget>[
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Text(
                                                              'สถานะ',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Text(
                                                              'วัคซีน (เข็มที่)',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Text(
                                                              'วัน/เดือน/ปี',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Text(
                                                              'น้ำหนัก',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Text(
                                                              'ราคา',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      _buildTableRow(
                                                          'ฉีดแล้ว',
                                                          'ถ่ายพยาธิ และตรวจสุขภาพ',
                                                          '15/05/2023',
                                                          '5 kg',
                                                          '350 บ.'),
                                                      _buildTableRow(
                                                        '',
                                                        'วัคซีนรวม 1',
                                                        '',
                                                        '',
                                                        '',
                                                      ),
                                                      _buildTableRow(
                                                          '',
                                                          'วัคซีนรวม 2\nวัคซีนพิษสุนัขบ้า 1',
                                                          '',
                                                          '',
                                                          ''),
                                                      _buildTableRow(
                                                          '',
                                                          'วัคซีนรวม 3\nวัคซีนพิษสุนัขบ้า 2',
                                                          '',
                                                          '',
                                                          ''),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            children: [
                                              Row(
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 5),
                                                    child: Icon(LineAwesomeIcons
                                                        .syringe),
                                                  ),
                                                  Text(
                                                    'การฉีดวัคซีน (เพิ่มเติม)',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                            future: FirebaseFirestore.instance
                                                .collection('vac_history')
                                                .doc(userId)
                                                .collection('vac_pet')
                                                .where('pet_id',
                                                    isEqualTo: widget.petId)
                                                .get(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const CircularProgressIndicator();
                                              }
                                              if (snapshot.hasError) {
                                                return Text(
                                                    'Error: ${snapshot.error}');
                                              }
                                              if (snapshot.hasData &&
                                                  snapshot
                                                      .data!.docs.isNotEmpty) {
                                                return ListView.builder(
                                                  shrinkWrap: true,
                                                  physics:
                                                      NeverScrollableScrollPhysics(),
                                                  itemCount: snapshot
                                                      .data!.docs.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    DocumentSnapshot reportDoc =
                                                        snapshot
                                                            .data!.docs[index];
                                                    Map<String, dynamic>
                                                        report =
                                                        reportDoc.data() as Map<
                                                            String, dynamic>;
                                                    final date = DateTime.parse(
                                                        report['date']);
                                                    final formattedDate =
                                                        DateFormat('dd/MM/yyyy')
                                                            .format(date);

                                                    return Card(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10.0),
                                                      ),
                                                      elevation: 3,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12.0),
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .blueAccent
                                                                    .withOpacity(
                                                                        0.2),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(8),
                                                              child: Icon(
                                                                LineAwesomeIcons
                                                                    .syringe,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                            SizedBox(width: 12),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      Text(
                                                                        report['vacName'] ??
                                                                            '',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        formattedDate,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              Colors.grey[600],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  SizedBox(
                                                                      height:
                                                                          4),
                                                                  Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .monitor_weight,
                                                                        color: Colors
                                                                            .black,
                                                                        size:
                                                                            16,
                                                                      ),
                                                                      SizedBox(
                                                                          width:
                                                                              4),
                                                                      Row(
                                                                        children: [
                                                                          Text(
                                                                            'น้ำหนัก ${report['weight'] ?? 'N/A'} kg',
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 14,
                                                                              color: Colors.grey[600],
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                              width: 10), // เพิ่มระยะห่างระหว่างข้อความ
                                                                          Text(
                                                                            'ราคา ${report['price'] ?? 'N/A'} บ.',
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 14,
                                                                              color: Colors.grey[600],
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  SizedBox(
                                                                      height:
                                                                          4),
                                                                  Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .location_on,
                                                                        color: Colors
                                                                            .black,
                                                                        size:
                                                                            16,
                                                                      ),
                                                                      SizedBox(
                                                                          width:
                                                                              4),
                                                                      Text(
                                                                        'สถานที่ ${report['location'] ?? 'N/A'}',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              Colors.grey[600],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: Icon(
                                                                Icons.edit,
                                                                color: Colors
                                                                    .blueAccent,
                                                              ),
                                                              onPressed: () {
                                                                // การกระทำเมื่อกดปุ่มแก้ไข
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                              return Text(
                                                  'ไม่มีบันทึกการฉัดวัคซีนเพิ่มเติม');
                                            },
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
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

  void _showInputDialog() {
    _dateController.clear();
    _infoController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            width:
                MediaQuery.of(context).size.width * 0.8, // ปรับขนาดของ Dialog
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'บันทึกประจำเดือน',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 10),
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
                TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );

                    if (pickedDate != null) {
                      setState(() {
                        _dateController.text =
                            pickedDate.toString().split(' ')[0];
                      });
                    }
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
                TextField(
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
                ElevatedButton(
                  onPressed: () {
                    // การกระทำเมื่อกดปุ่มบันทึก
                    print('Date: ${_dateController.text}');
                    print('Additional Info: ${_infoController.text}');
                    _saveReportToFirestore();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  child: Text('บันทึกข้อมูล'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showVaccineDialog() {
    _dateVacController.clear();
    _vacWeight.clear();
    _vacPrice.clear();
    _vacLocation.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'บันทึกการฉีดวัคซีน',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
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
                      items: (pet_type == 'สุนัข' ? _vacOfDog : _vacOfCat)
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
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
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
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
                      controller: _vacWeight,
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
                        padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
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
                      controller: _vacPrice,
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
                        padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
                        child: Text(
                          'สถานที่',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _vacLocation,
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
                        padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
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
                      controller: _dateVacController,
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
                          lastDate: DateTime(2101),
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
                    ElevatedButton(
                      onPressed: () {
                        _saveVaccineToFirestore();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      ),
                      child: Text('บันทึกข้อมูล'),
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

  void _showVaccineTableDialog() {
    // _dateVacController.clear();
    // _vacWeight.clear();
    // _vacPrice.clear();
    // _vacLocation.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'บันทึกการฉีดวัคซีนตามเกณฑ์',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
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
                      value: _selectedVac,
                      hint: Text('เลือกชื่อวัคซีน'),
                      items: (pet_type == 'สุนัข' ? _vacOfDog : _vacOfCat)
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
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
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
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
                        padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
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
                        padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
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
                          lastDate: DateTime(2101),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            _dateVacController.text =
                                pickedDate.toString().split(' ')[0];
                          });
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
                        child: Text(
                          'สถานะ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _vacStatusTable,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _saveVaccineToFirestore();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      ),
                      child: Text('บันทึกข้อมูล'),
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
                    Text(
                      'ตารางการฉีดวัคซีน',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Table(
                        border: TableBorder.all(),
                        columnWidths: const <int, TableColumnWidth>{
                          0: FixedColumnWidth(80),
                          1: FixedColumnWidth(150),
                          2: FixedColumnWidth(80),
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

  TableRow _buildTableRow(
      String status, String vaccine, String date, String weight, String price) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(status),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(vaccine),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(date),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(weight),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(price),
        ),
      ],
    );
  }

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
