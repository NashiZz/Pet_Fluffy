import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:Pet_Fluffy/features/services/profile.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class AddContestPage extends StatefulWidget {
  final String userId;
  final String petId;

  const AddContestPage({
    Key? key,
    required this.userId,
    required this.petId,
  }) : super(key: key);

  @override
  _AddContestPageState createState() => _AddContestPageState();
}

class _AddContestPageState extends State<AddContestPage> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService profileService = ProfileService();
  final TextEditingController _nameAwardController = TextEditingController();
  final TextEditingController _desController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  DateTime? _selectedDate;
  List<String> base64Images = [];

  Future<void> _pickAndCompressImage(ImageSource source) async {
    if (base64Images.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สามารถเพิ่มรูปภาพได้สูงสุด 2 รูป')),
      );
      return;
    }

    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      Uint8List? imageBytes = await file.readAsBytes();
      if (imageBytes != null) {
        Uint8List? compressedBytes =
            await profileService.compressImage(imageBytes);
        if (compressedBytes != null) {
          setState(() {
            base64Images.add(uint8ListToBase64(compressedBytes));
          });
        } else {
          print('Failed to compress image');
        }
      } else {
        print('Failed to read image bytes');
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

  Future<void> _saveAward() async {
    if (_formKey.currentState!.validate()) {
      if (base64Images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('กรุณาเพิ่มรูปภาพ')),
        );
        return;
      }

      _showLoadingDialog();

      try {
        await profileService.saveAwardToFirestore(
          userId: widget.userId,
          petId: widget.petId,
          nameAward: _nameAwardController.text,
          date: _dateController.text,
          description: _desController.text,
          img1: base64Images.isNotEmpty ? base64Images[0] : '',
          img2: base64Images.length > 1 ? base64Images[1] : '',
        );

        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pop(); // Close the page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')),
        );
      } catch (e) {
        Navigator.of(context).pop(); // Close loading dialog in case of error
        print("Error updating award data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
        );
      }
    }
  }

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
    _nameAwardController.dispose();
    _dateController.dispose();
    _desController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เพิ่มข้อมูลการประกวด'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),
                TextFormField(
                  style: const TextStyle(fontSize: 14),
                  controller: _nameAwardController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อการประกวด',
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
                      return 'กรุณากรอกชื่อการประกวด';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  readOnly: true,
                  controller: _dateController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'วันที่',
                    suffixIcon: Icon(Icons.calendar_today),
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
                      return 'กรุณากรอกวันที่';
                    }
                    return null;
                  },
                  onTap: () => selectDate(context),
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
                    contentPadding: const EdgeInsets.fromLTRB(10, 40, 15, 10),
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'รูปภาพ',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          _pickAndCompressImage(ImageSource.gallery),
                      child: const Text('เพิ่มรูปภาพ'),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                if (base64Images.isNotEmpty)
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 8.0,
                    children: List.generate(base64Images.length, (index) {
                      return Stack(
                        children: [
                          Image.memory(
                            base64Decode(base64Images[index]),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon:
                                  Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  base64Images.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: _saveAward,
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
        ),
      ),
    );
  }
}
