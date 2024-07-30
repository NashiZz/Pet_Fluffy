import 'dart:convert';
import 'dart:typed_data';
import 'package:Pet_Fluffy/features/services/profile.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class EditPetDigreePage extends StatefulWidget {
  final String userId;
  final String petId;
  final String id_petdigree;

  const EditPetDigreePage({
    Key? key,
    required this.userId,
    required this.petId,
    required this.id_petdigree,
  }) : super(key: key);

  @override
  _EditPetDigreePageState createState() => _EditPetDigreePageState();
}

class _EditPetDigreePageState extends State<EditPetDigreePage> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService profileService = ProfileService();
  final TextEditingController _numPetController = TextEditingController();
  final TextEditingController _numPetFController = TextEditingController();
  final TextEditingController _numPetMController = TextEditingController();

  Uint8List? _petDigreeImage;
  bool isLoading = true; // ใช้สำหรับตรวจสอบสถานะการโหลด

  @override
  void initState() {
    super.initState();
    _loadPetDigreeData();
  }

  Future<void> _loadPetDigreeData() async {
    try {
      final petData = await profileService.loadPetdigreeData(widget.petId, widget.userId);
      setState(() {
        _numPetController.text = petData['num_pet'] ?? '';
        _numPetFController.text = petData['num_pet_f'] ?? '';
        _numPetMController.text = petData['num_pet_m'] ?? '';
        if (petData['img_pet'] != null) {
          _petDigreeImage = base64Decode(petData['img_pet']);
        }
        isLoading = false; // อัปเดตสถานะการโหลด
      });
    } catch (e) {
      print('Error loading pet digree data: $e');
      setState(() {
        isLoading = false; // อัปเดตสถานะการโหลดในกรณีเกิดข้อผิดพลาด
      });
    }
  }

  Future<void> selectImage() async {
    Uint8List? img = await profileService.pickImage(ImageSource.gallery);
    if (img != null) {
      Uint8List? compressedImage = await profileService.compressImage(img);
      if (compressedImage != null) {
        setState(() {
          _petDigreeImage = compressedImage;
        });
      } else {
        print('Failed to compress image');
      }
    } else {
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
        await profileService.updatePetdigree_ToFirestore(
            userId: widget.userId,
            petId: widget.petId,
            numPet: _numPetController.text,
            numPetF: _numPetFController.text,
            numPetM: _numPetMController.text,
            img_PetDigree: _petDigreeImage != null ? base64Encode(_petDigreeImage!) : '', 
            id_petdigree: widget.id_petdigree, 
        );

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
    _numPetController.dispose();
    _numPetFController.dispose();
    _numPetMController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไขข้อมูลการประกวด'),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (_petDigreeImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Image.memory(
                              _petDigreeImage!,
                              width: 300,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Container(
                              width: 300,
                              height: 150,
                              color: Colors.grey[300],
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
                            bottom: -10,
                            right: -10,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey,
                              child: IconButton(
                                onPressed: selectImage,
                                icon: const Icon(Icons.add_a_photo, size: 20),
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            style: const TextStyle(fontSize: 14),
                            controller: _numPetController,
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
                            controller: _numPetFController,
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
                            controller: _numPetMController,
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
                                    Icon(LineAwesomeIcons.save),
                                    SizedBox(width: 8),
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
