// ignore_for_file: file_names, camel_case_types, avoid_print, no_leading_underscores_for_local_identifiers

import 'package:Pet_Fluffy/features/page/navigator_page.dart';
import 'package:Pet_Fluffy/features/services/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

//หน้า แก้ไขข้อมูลสัตว์เลี้ยง
class Edit_Pet_Page extends StatefulWidget {
  final Map<String, dynamic> petUserData;

  const Edit_Pet_Page({super.key, required this.petUserData});

  @override
  State<Edit_Pet_Page> createState() => _Edit_Pet_PageState();
}

class _Edit_Pet_PageState extends State<Edit_Pet_Page> {
  final ProfileService _profileService = ProfileService();
  User? user = FirebaseAuth.instance.currentUser;

  static const String tempPetImageUrl =
      "https://e7.pngegg.com/pngimages/59/659/png-clipart-computer-icons-scalable-graphics-avatar-emoticon-animal-fox-jungle-safari-zoo-icon-animals-orange-thumbnail.png";
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _desController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Uint8List? _profileImage;
  Uint8List? _normalImage;
  final TextEditingController _imageFileController = TextEditingController();

  String? _selectedType;
  String? _selectedBreed;
  String? _selectedGender;
  String? _selectedStatus;

  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();

  final TextEditingController _otherBreedController = TextEditingController();
  bool _isOtherBreed = false;
  bool _isLoading = false;

  final List<String> _genders = ['ตัวผู้', 'ตัวเมีย'];
  final List<String> _status = [
    'เสียชีวิต',
    'พร้อมผสมพันธุ์',
    'ไม่พร้อมผสมพันธุ์'
  ];
  final List<String> _types = [];
  final List<String> _breedsOfType1 = [];
  final List<String> _breedsOfType2 = [];

  void _fetchTypeData() async {
    await FirebaseFirestore.instance
        .collection('pet_type')
        .get()
        .then((QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        String type = doc.get('name');
        setState(() {
          _types.add(type);
        });
      }
    }).catchError((error) {
      print("Failed to fetch type data: $error");
    });
  }

  void _fetchBreadDataDog() {
    FirebaseFirestore.instance
        .collection('gene_pet')
        .doc("Qy38o0xCXKQlIngPz9jb")
        .collection('gene_pet')
        .get()
        .then((QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        String bread = doc.get('name');
        setState(() {
          _breedsOfType1.add(bread);
        });
      }
    }).catchError((error) {
      print("Failed to fetch gender data: $error");
    });
  }

  void _fetchBreadDataCat() {
    FirebaseFirestore.instance
        .collection('gene_pet')
        .doc("5yWv1hawXz6Gh15gEed1")
        .collection('gene_pet')
        .get()
        .then((QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        String bread = doc.get('name');
        setState(() {
          _breedsOfType2.add(bread);
        });
      }
    }).catchError((error) {
      print("Failed to fetch gender data: $error");
    });
  }

  // เพื่อเข้าถึงตัวเลือกรูปภาพของอุปกรณ์
  void selectImage() async {
    Uint8List? img = await _profileService.pickImage(ImageSource.gallery);
    setState(() {
      _profileImage = img;
    });
  }

  void selectNormalImage() async {
    Uint8List? img = await _profileService.pickImage(ImageSource.gallery);
    setState(() {
      _normalImage = img;
      _imageFileController.text = _normalImage != null
          ? 'normal_image.jpg'
          : ''; // แสดงชื่อไฟล์เมื่อมีการเลือกรูปภาพ
    });
  }

  // เพื่อแปลงข้อมูลรูปภาพ (ในรูปแบบ Uint8List) เป็นการเข้ารหัสแบบ base64
  String uint8ListToBase64(Uint8List data) {
    return base64Encode(data);
  }

  // เพื่อแสดงหน้าต่างเลือกวันที่และอัปเดตวันที่ที่เลือกและฟิลด์ข้อความที่เกี่ยวข้อง
  void selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose(); // ล้างทรัพยากร
    _imageFileController.dispose(); // ล้าง Controller
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchTypeData();
    _fetchBreadDataDog();
    _fetchBreadDataCat();

    _nameController.text = widget.petUserData['name'] ?? '';
    _colorController.text = widget.petUserData['color'] ?? '';
    _weightController.text = widget.petUserData['weight'] ?? '';
    _priceController.text = widget.petUserData['price'] ?? '';
    _desController.text = widget.petUserData['description'] ?? '';
    _dateController.text = widget.petUserData['birthdate'] ?? '';

    _selectedType = widget.petUserData['type_pet'] ?? '';
    _selectedBreed = widget.petUserData['breed_pet'] ?? '';
    _selectedGender = widget.petUserData['gender'] ?? '';
    _selectedStatus = widget.petUserData['status'] ?? '';
    _otherBreedController.text = widget.petUserData['breed_pet'] ?? '';
    
    String profileImageUrl = widget.petUserData['img_profile'] ?? '';
    if (profileImageUrl.isNotEmpty) {
      _profileImage = base64Decode(profileImageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text("แก้ไขข้อมูล ${widget.petUserData['name']}",
              style: Theme.of(context).textTheme.headlineMedium),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        body: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(), // แสดงสัญลักษณ์การโหลดข้อมูล
              )
            : SingleChildScrollView(
                child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          _profileImage != null
                              ? CircleAvatar(
                                  radius: 64,
                                  backgroundImage: MemoryImage(_profileImage!),
                                )
                              : const CircleAvatar(
                                  radius: 64,
                                  backgroundImage: NetworkImage(tempPetImageUrl),
                                ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: IconButton(
                                  onPressed: selectImage,
                                  icon: const Icon(Icons.add_a_photo,
                                      color: Colors.white),
                                  iconSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      TextFormField(
                        style: const TextStyle(fontSize: 14),
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'ชื่อสัตว์เลี้ยง',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0)),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          counterText: '',  
                        ),
                        validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกชื่อสัตว์เลี้ยง';
                            }
                            return null;
                          },
                          maxLength: 20,
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              items: _types.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value,
                                      style: TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedType = newValue;
                                  _selectedBreed = null;
                                  _isOtherBreed = false;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'ประเภทสัตว์เลี้ยง',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 10),
                              ),
                              validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'กรุณากรอกประเภทสัตว์เลี้ยง';
                                    }
                                    return null;
                                  }
                            ),
                          ),
                          const Padding(padding: EdgeInsets.all(5)),
                          if (_selectedType != null)
                            Expanded(
                              child: TextFormField(
                                style: const TextStyle(fontSize: 14),
                                controller: _otherBreedController,
                                decoration: InputDecoration(
                                  labelText: 'ป้อนพันธุ์สัตว์เลี้ยงเอง',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 8),
                                  counterText: '',
                                ),
                                validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณาป้อนพันธุ์สัตว์เลี้ยง';
                              }
                              return null;
                            }
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              items: _genders.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value,
                                      style: TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedGender = newValue;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'เพศ',
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(30.0)),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 15),
                              ),
                             validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'กรุณากรอกเพศ';
                                    }
                                    return null;
                                  },
                            ),
                          ),
                          const Padding(padding: EdgeInsets.all(5)),
                          Expanded(
                            child: TextFormField(
                              style: const TextStyle(fontSize: 14),
                              controller: _colorController,
                              decoration: InputDecoration(
                                labelText: 'สี',
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(30.0)),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 15),
                                    counterText: '',
                              ),
                              validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'กรุณากรอกสีสัตว์เลี้ยง';
                                    }
                                    return null;
                                  }
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              controller: _dateController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'วันเกิด',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 15,
                                ),
                              ),
                              validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'กรุณากรอกวันเกิดสัตว์เลี้ยง';
                                    }
                                    return null;
                                  },
                              onTap:
                                  selectDate, // เรียกใช้ฟังก์ชัน selectDate เมื่อกดที่ TextField
                            ),
                          ),
                          const Padding(padding: EdgeInsets.all(5)),
                          Expanded(
                            child: TextFormField(
                              style: const TextStyle(fontSize: 14),
                              controller: _weightController,
                              keyboardType: TextInputType
                                  .number, // กำหนดให้แสดงช่องใส่เฉพาะตัวเลข
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter
                                    .digitsOnly // จำกัดให้ใส่เฉพาะตัวเลข
                              ],
                              decoration: InputDecoration(
                                labelText: 'น้ำหนัก',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 15,
                                ),
                                counterText: '',
                              ),
                              validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'กรุณากรอกน้ำหนักสัตว์เลี้ยง';
                                    }
                                    return null;
                                  },maxLength: 2,
                            ),
                            
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              style: const TextStyle(fontSize: 14),
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: InputDecoration(
                                labelText: 'ราคา (ค่าผสมพันธุ์)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 15,
                                ),
                                counterText: '',
                              ),
                              maxLength: 7,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              items: _status.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value,
                                      style: TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedStatus = newValue;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'สถานะ',
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(30.0)),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 15),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณาเลือกสถานะ';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.left,
                        controller: _desController,
                        decoration: InputDecoration(
                          labelText: 'รายละเอียดเพิ่มเติม',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          contentPadding:
                              const EdgeInsets.fromLTRB(10, 40, 15, 10),
                        ),
                        maxLength: 100,
                      ),
                      const SizedBox(height: 15),
                      ButtonTheme(
                        minWidth: 300,
                        height: 100,
                        child: GestureDetector(
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                               updatePetInFirestore(
                                widget.petUserData['pet_id']);         
                            }
                            
                          },
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        "บันทึก",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18),
                                      )),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )));
  }

  void updatePetInFirestore(String petId) {
    // ตรวจสอบว่าผู้ใช้เข้าสู่ระบบอยู่หรือไม่
    if (user != null) {
      String profileBase64 =
          _profileImage != null ? uint8ListToBase64(_profileImage!) : '';
      String name = _nameController.text;
      String color = _colorController.text;
      String birthdate = _dateController.text;
      String weight = _weightController.text;
      String price = _priceController.text;
      String petDegreeBase64 =
          _normalImage != null ? uint8ListToBase64(_normalImage!) : '';
      String description = _desController.text;
      String type = _selectedType ?? '';
      String breed = _otherBreedController.text;
      String gender = _selectedGender ?? '';
      String status = _selectedStatus ?? '';

      CollectionReference pets =
          FirebaseFirestore.instance.collection('Pet_User');

      // ส่งข้อมูลไปยัง Firestore เพื่ออัปเดตเอกสารที่มี petId ตรงกับที่ระบุ
      pets.doc(petId).update({
        'img_profile': profileBase64,
        'name': name,
        'color': color,
        'birthdate': birthdate,
        'weight': weight,
        'price': price,
        'pet_degree': petDegreeBase64,
        'description': description,
        'type_pet': type,
        'breed_pet': breed,
        'status': status,
        'gender': gender,
      }).then((value) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            Future.delayed(const Duration(seconds: 1), () {
              Navigator.of(context).pop(true); // ปิดไดอะล็อกหลังจาก 2 วินาที
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const Navigator_Page(initialIndex: 0)),
                (route) => false,
              );
            });
            return const AlertDialog(
              title: Text('Success'),
              content: Text('อัปเดตข้อมูลสัตว์เลี้ยงสำเร็จ'),
            );
          },
        );
      }).catchError((error) {
        print("Failed to update pet: $error");
      });
    }
  }

  List<String> _getBreedsByType(String type) {
    switch (type) {
      case 'สุนัข':
        return _breedsOfType1;
      case 'แมว':
        return _breedsOfType2;
      default:
        return [];
    }
  }
}
