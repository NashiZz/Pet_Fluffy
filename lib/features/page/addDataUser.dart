import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class addDataUser_Page extends StatefulWidget {
  const addDataUser_Page({Key? key}) : super(key: key);

  @override
  State<addDataUser_Page> createState() => _addDataUser_PageState();
}

class _addDataUser_PageState extends State<addDataUser_Page> {
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController lineController = TextEditingController();

  String? _selectedCounty;
  String? _selectedGender;
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();
  final List<String> _county = ['อุดรธานี', 'มหาสารคาม'];
  final List<String> _gender = ['ชาย', 'หญิง', 'อื่นๆ'];

  bool _isLoading = false;

  // เพื่อแสดงหน้าต่างเลือกวันที่และอัปเดตวันที่ที่เลือกและฟิลด์ข้อความที่เกี่ยวข้อง
  void selectDate(BuildContext context) async {
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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "เพิ่มข้อมูลส่วนตัวผู้ใช้",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              child: CircularProgressIndicator(), // แสดงสัญลักษณ์การโหลดข้อมูล
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    Form(
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "ข้อมูลส่วนตัว",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800]),
                            ),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            style: const TextStyle(fontSize: 14),
                            controller: nicknameController,
                            decoration: InputDecoration(
                              labelText: 'ชื่อเล่น',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0)),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // จังหวัด
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            items: _gender.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
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
                                  borderRadius: BorderRadius.circular(30.0)),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
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
                            onTap: () => selectDate(context),
                          ),
                          const SizedBox(height: 15),
                          // จังหวัด
                          DropdownButtonFormField<String>(
                            value: _selectedCounty,
                            items: _county.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCounty = newValue;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'จังหวัด',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0)),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                            ),
                          ),
                          const SizedBox(height: 25),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "ข้อมูลติดต่อ",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800]),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            style: const TextStyle(fontSize: 14),
                            controller: phoneController,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: InputDecoration(
                              labelText: 'เบอร์โทรศัพท์',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            style: const TextStyle(fontSize: 14),
                            controller: facebookController,
                            decoration: InputDecoration(
                              labelText: 'Facebook',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            style: const TextStyle(fontSize: 14),
                            controller: lineController,
                            decoration: InputDecoration(
                              labelText: 'Line',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          const SizedBox(height: 30),
                          ButtonTheme(
                            minWidth: 300,
                            height: 100,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text('เพิ่มข้อมูล',
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  //เพิ่มข้อมูลลงฐานข้อมูล
  // void addPetToFirestore() async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   String userId = user!.uid;
  //   String profileBase64 =
  //       _profileImage != null ? base64Encode(_profileImage!) : '';
  //   String name = _nameController.text;
  //   String color = _colorController.text;
  //   String birtdate = _dateController.text;
  //   String weight = _weightController.text;
  //   String price;
  //   if (_priceController.text == '') {
  //     price = '0';
  //   } else {
  //     price = _priceController.text;
  //   }

  //   String petdegreeBase64 =
  //       _normalImage != null ? base64Encode(_normalImage!) : '';
  //   String description = _desController.text;
  //   String type = _selectedType ?? '';
  //   String breed;
  //   String gender = _selectedGender ?? '';
  //   String status = _selectedStatus ?? '';

  //   if (_isOtherBreed) {
  //     breed = _otherBreedController.text;
  //   } else {
  //     breed = _selectedBreed ?? '';
  //   }

  //   CollectionReference pets =
  //       FirebaseFirestore.instance.collection('Pet_User');

  //   try {
  //     DocumentReference newPetRef = await pets.add({
  //       'user_id': userId,
  //       'img_profile': profileBase64,
  //       'name': name,
  //       'color': color,
  //       'birthdate': birtdate,
  //       'weight': weight,
  //       'price': price,
  //       'pet_degree': petdegreeBase64,
  //       'description': description,
  //       'type_pet': type,
  //       'breed_pet': breed,
  //       'status': status,
  //       'gender': gender,
  //     });

  //     String docId = newPetRef.id;

  //     await newPetRef.update({'pet_id': docId});

  //     // Async func to handle Futures easier; or use Future.then
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     prefs.setString(userId, docId);

  //     CollectionReference usagePet =
  //         FirebaseFirestore.instance.collection('Usage_pet');
  //     await usagePet.doc(userId).set({
  //       'pet_id': docId,
  //       'user_id': userId,
  //     });

  //     setState(() {
  //       _isLoading = false;
  //     });

  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         Future.delayed(const Duration(seconds: 1), () {
  //           Navigator.of(context).pop(true); // ปิดไดอะล็อกหลังจาก 2 วินาที
  //           Navigator.pushAndRemoveUntil(
  //             context,
  //             MaterialPageRoute(
  //                 builder: (context) => const Navigator_Page(initialIndex: 0)),
  //             (route) => false,
  //           );
  //         });
  //         return const AlertDialog(
  //           title: Text('Success'),
  //           content: Text('เพิ่มสัตว์เลี้ยงสำเร็จ'),
  //         );
  //       },
  //     );
  //   } catch (error) {
  //     print("Failed to add pet: $error");

  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }
}
