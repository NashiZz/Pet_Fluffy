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
        actions: [
          IconButton(
            onPressed: () {
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
                Navigator.of(context).pop(); // ปิด Dialog โหลดข้อมูล
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
            },
            icon: const Icon(LineAwesomeIcons.save),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Form(
                child: Column(
                  children: [
                    TextField(
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
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(LineAwesomeIcons.trash),
                              ),
                              Text('ลบข้อมูล'),
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
