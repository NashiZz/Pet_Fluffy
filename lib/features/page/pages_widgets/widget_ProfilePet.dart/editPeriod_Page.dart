import 'package:Pet_Fluffy/features/services/profile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class EditPeriodPage extends StatefulWidget {
  final Map<String, dynamic> report;
  final String userId;

  const EditPeriodPage({
    Key? key,
    required this.report,
    required this.userId,
  }) : super(key: key);

  @override
  _EditPeriodPageState createState() => _EditPeriodPageState();
}

class _EditPeriodPageState extends State<EditPeriodPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ProfileService profileService = ProfileService();
  late TextEditingController dateController;
  late TextEditingController desController;

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.8), // สีพื้นหลังดำ
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

  void _confirmDeletePeriod() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: [
              const Icon(LineAwesomeIcons.calendar_with_week_focus,
                  color: Colors.pink, size: 50),
            ],
          ),
          content: Text(
            "คุณต้องการลบข้อมูลประจำเดือนนี้?",
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
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
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();

                        _deletePeriod();
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

  

  void _deletePeriod() {
    _showLoadingDialog();
    try {
      profileService
          .deleteReportFromFirestore(widget.userId, widget.report['id_period'])
          .then((_) {
        Navigator.of(context).pop(); // ปิด Dialog โหลดข้อมูล
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบข้อมูลเรียบร้อยแล้ว')),
        );
        Navigator.of(context).pop(true); // กลับไปหน้าเดิม
      }).catchError((error) {
        Navigator.of(context)
            .pop(); // ปิด Dialog โหลดข้อมูลในกรณีเกิดข้อผิดพลาด
        print("Error deleting Period data: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการลบข้อมูล')),
        );
      });
    } catch (e) {
      Navigator.of(context).pop(); // ปิด Dialog โหลดข้อมูลในกรณีเกิดข้อผิดพลาด
      print("Error deleting contest data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการลบข้อมูล')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    dateController = TextEditingController(text: widget.report['date'] ?? '');
    desController = TextEditingController(text: widget.report['des'] ?? '');
  }

  @override
  void dispose() {
    dateController.dispose();
    desController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไขข้อมูลประจำเดือน'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: dateController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'วันที่',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.parse(
                                  widget.report['date'] ??
                                      DateTime.now().toString()),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );

                            if (pickedDate != null) {
                              dateController.text =
                                  DateFormat('yyyy-MM-dd').format(pickedDate);
                            }
                          },
                        ),
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
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      style: const TextStyle(fontSize: 14),
                      controller: desController,
                      decoration: InputDecoration(
                        labelText: 'รายละเอียด',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: _confirmDeletePeriod,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  LineAwesomeIcons.alternate_trash,
                                ),
                              ),
                              Text(
                                'ลบข้อมูล',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red.shade400,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _showLoadingDialog();
                              profileService
                                  .updatePeriod_ToFirestore(
                                userId: widget.userId,
                                docId: widget.report['id_period'] ?? '',
                                petId: widget.report['pet_id'] ?? '',
                                description: desController.text,
                                date: dateController.text,
                              )
                                  .then((_) {
                                Navigator.of(context)
                                    .pop(); // ปิด Dialog โหลดข้อมูล
                                Navigator.of(context).pop({
                                  'id_period': widget.report['id_period'] ?? '',
                                  'des': desController.text,
                                  'date': dateController.text,
                                });
                              }).catchError((error) {
                                Navigator.of(context)
                                    .pop(); // ปิด Dialog โหลดข้อมูลในกรณีเกิดข้อผิดพลาด
                                print("Error updating vaccine data: $error");
                              });
                            }
                          },
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  LineAwesomeIcons.alternate_cloud_upload,
                                ),
                              ),
                              Text(
                                widget.report == null ? 'บันทึก' : 'อัปเดต',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
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
