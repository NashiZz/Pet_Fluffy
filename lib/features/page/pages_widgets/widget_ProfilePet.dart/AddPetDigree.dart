import 'dart:convert';
import 'dart:typed_data';
import 'package:Pet_Fluffy/features/services/profile.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class AddPetDigreePage extends StatefulWidget {
  final String userId;
  final String petId;

  const AddPetDigreePage({
    Key? key,
    required this.userId,
    required this.petId,
  }) : super(key: key);

  @override
  _AddPetDigreePageState createState() => _AddPetDigreePageState();
}

class _AddPetDigreePageState extends State<AddPetDigreePage> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService profileService = ProfileService();
  final TextEditingController _numPet_Controller = TextEditingController();
  final TextEditingController _numPetF_Controller = TextEditingController();
  final TextEditingController _numPetM_Controller = TextEditingController();

  Uint8List? _petDigreeImage;

  //เลือกรูปภาพ โปรไฟล์สัตว์เลี้ยง
  Future<void> selectImage() async {
    Uint8List? img = await profileService.pickImage(ImageSource.gallery);
    if (img != null) {
      Uint8List? compressedImage = await profileService.compressImage(img);
      if (compressedImage != null) {
        // สร้างรูปภาพระเบิดจาก Uint8List
        setState(() {
          _petDigreeImage = compressedImage;
        });
      } else {
        // กรณีเกิดข้อผิดพลาดในการบีบอัดภาพ
        print('Failed to compress image');
      }
    } else {
      // กรณีไม่ได้เลือกรูปภาพ
      print('No image selected');
    }
  }

  String uint8ListToBase64(Uint8List data) {
    return base64Encode(data);
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(
                  'กำลังบันทึกข้อมูล',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _savePetDigree() async {
    if (_formKey.currentState!.validate()) {
      _showLoadingDialog();

      try {
        await profileService.savePetDigreeToFirestore(
            userId: widget.userId,
            petId: widget.petId,
            numPet: _numPet_Controller.text,
            numPetF: _numPetF_Controller.text,
            numPetM: _numPetM_Controller.text,
            img_PetDigree:
                _petDigreeImage != null ? base64Encode(_petDigreeImage!) : '');

        Navigator.of(context).pop(); // Close loading dialog
        Navigator.pop(context, 'updated');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')),
        );
      } catch (e) {
        Navigator.of(context).pop(); // Close loading dialog in case of error
        print("Error updating PetDigree data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เพิ่มข้อมูลใบเพ็ดดีกรี'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip
                    .none, // ใช้ Clip.none เพื่อให้ไอคอนสามารถทะลุออกจากรูปได้
                children: [
                  if (_petDigreeImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0), // กำหนดมุมโค้ง
                      child: Image.memory(
                        _petDigreeImage!,
                        width: 300,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (_petDigreeImage == null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0), // กำหนดมุมโค้ง
                      child: Container(
                        width: 300,
                        height: 150,
                        color: Colors.grey[300], // สีพื้นหลังเมื่อไม่มีภาพ
                        child: Center(
                          child: IconButton(
                            onPressed: selectImage,
                            icon: const Icon(Icons.add_a_photo, size: 32),
                          ),
                        ),
                      ),
                    ),
                  if (_petDigreeImage != null)
                    Positioned(
                      bottom: -10, // กำหนดให้ไอคอนกล้องทะลุออกจากรูป
                      right: -10, // กำหนดให้ไอคอนกล้องทะลุออกจากรูป
                      child: CircleAvatar(
                        radius: 20, // ขนาดของวงกลม
                        backgroundColor: Colors.grey, // สีพื้นหลังของวงกลม
                        child: IconButton(
                          onPressed: selectImage,
                          icon: const Icon(Icons.add_a_photo, size: 20),
                          color: Colors.white, // สีของไอคอน
                        ),
                      ),
                    )
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      style: const TextStyle(fontSize: 14),
                      controller: _numPet_Controller,
                      decoration: InputDecoration(
                        labelText: 'เลข ID ทะเบียนของสัตว์เลี้ยง',
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
                          return 'กรุณากรอกเลข ID ทะเบียนสัตว์เลี้ยง';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      style: const TextStyle(fontSize: 14),
                      controller: _numPetF_Controller,
                      decoration: InputDecoration(
                        labelText: 'เลข ID ทะเบียนพ่อ',
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
                          return 'กรุณากรอกเลข ID ทะเบียนพ่อ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      style: const TextStyle(fontSize: 14),
                      controller: _numPetM_Controller,
                      decoration: InputDecoration(
                        labelText: 'เลข ID ทะเบียนแม่',
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
                          return 'กรุณาเลข ID ทะเบียนแม่';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: _savePetDigree,
                          child: Row(
                            children: [
                              Icon(
                                LineAwesomeIcons.save,
                              ),
                              Text('บันทึก', style: TextStyle(fontSize: 16)),
                            ],
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
      ),
    );
  }
}
