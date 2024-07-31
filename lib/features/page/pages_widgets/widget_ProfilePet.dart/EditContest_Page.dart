import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:Pet_Fluffy/features/services/profile.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class EditContestPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> report;

  const EditContestPage({
    Key? key,
    required this.userId,
    required this.report,
  }) : super(key: key);

  @override
  _EditContestPageState createState() => _EditContestPageState();
}

class _EditContestPageState extends State<EditContestPage> {
  final ProfileService profileService = ProfileService();
  final TextEditingController _nameAwardController = TextEditingController();
  final TextEditingController _desController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  DateTime? _selectedDate;
  List<Uint8List> images = [];

  @override
  void initState() {
    super.initState();

    // หากมีข้อมูลการประกวดให้ตั้งค่าฟอร์ม
    _nameAwardController.text = widget.report['award'] ?? '';
    _desController.text = widget.report['des'] ?? '';
    _dateController.text = widget.report['date'] ?? '';

    images.clear();
    // ดึงรูปภาพจาก base64
    if (widget.report['img_1'] != null)
      images.add(base64Decode(widget.report['img_1']));
    if (widget.report['img_2'] != null)
      images.add(base64Decode(widget.report['img_2']));
  }

  void _removeImage(int index) {
    setState(() {
      images.removeAt(index); // ลบรูปภาพจาก List
    });
  }

  Future<void> _pickAndCompressImage(ImageSource source) async {
    if (images.length >= 2) {
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
            images.add(compressedBytes);
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

  void _saveOrUpdateContest() {
    _showLoadingDialog(); // แสดง Dialog โหลดข้อมูล

    profileService
        .updateAward_ToFirestore(
      userId: widget.userId,
      docId: widget.report['id_contest'],
      nameAward: _nameAwardController.text,
      date: _dateController.text,
      description: _desController.text,
      img1: images.isNotEmpty ? uint8ListToBase64(images[0]) : '',
      img2: images.length > 1 ? uint8ListToBase64(images[1]) : '',
    )
        .then((_) {
      Navigator.of(context).pop(); // ปิด Dialog โหลดข้อมูล
      Navigator.of(context).pop({
        'id_contest': widget.report['id_contest'] ?? '',
        'award': _nameAwardController.text,
        'des': _desController.text,
        'date': _dateController.text,
        'img_1': images.isNotEmpty ? uint8ListToBase64(images[0]) : '',
        'img_2': images.length > 1 ? uint8ListToBase64(images[1]) : '',
      });
    }).catchError((error) {
      Navigator.of(context).pop(); // ปิด Dialog โหลดข้อมูลในกรณีเกิดข้อผิดพลาด
      print("Error updating Contest data: $error");
    });
  }

  void selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
        title: Text('แก้ไขข้อมูลการประกวด'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
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
                      onPressed: images.length < 2
                          ? () => _pickAndCompressImage(ImageSource.gallery)
                          : null,
                      child: const Text('เพิ่มรูปภาพ'),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                if (images.isNotEmpty)
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 8.0,
                    children: List.generate(images.length, (index) {
                      final image = images[index];
                      return Stack(
                        children: [
                          Image.memory(
                            image,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          if (images.length >
                              0) // แสดงปุ่มลบเฉพาะเมื่อมีมากกว่าหนึ่งรูป
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () => _removeImage(index),
                              ),
                            ),
                        ],
                      );
                    }),
                  )
                else
                  Center(
                    child: Text(
                      'ไม่มีรูปภาพ',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: _saveOrUpdateContest,
                      child: Row(
                        children: [
                          Icon(
                            LineAwesomeIcons.save,
                          ),
                          Text(
                            widget.report == null ? 'บันทึก' : 'อัปเดต',
                            style: TextStyle(fontSize: 16),
                          ),
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