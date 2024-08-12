import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/EditContest_Page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'dart:convert';

class ContestDetailPage extends StatefulWidget {
  final Map<String, dynamic> report;
  final String userId;
  final String idContest;

  const ContestDetailPage({
    Key? key,
    required this.report,
    required this.userId,
    required this.idContest,
  }) : super(key: key);

  @override
  _ContestDetailPageState createState() => _ContestDetailPageState();
}

class _ContestDetailPageState extends State<ContestDetailPage> {
  User? user = FirebaseAuth.instance.currentUser;
  late Map<String, dynamic> _report;
  late List<String> _imageBase64Strings;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _imageBase64Strings = _extractImageBase64Strings(_report);
  }

  List<String> _extractImageBase64Strings(Map<String, dynamic> report) {
    List<String> imageBase64Strings = [];
    report.forEach((key, value) {
      if (key.startsWith('img_')) {
        imageBase64Strings.add(value);
      }
    });
    return imageBase64Strings;
  }

  Future<void> _navigateToEditContestPage() async {
    // กรอง field ที่มีค่า
    final reportWithValues = Map.fromEntries(_report.entries.where(
        (entry) => entry.value != null && entry.value.toString().isNotEmpty));

    final updatedReport = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EditContestPage(
          report: reportWithValues, // ส่งข้อมูลที่มีค่า
          userId: widget.userId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (updatedReport != null) {
      setState(() {
        _report = updatedReport;
        _imageBase64Strings = _extractImageBase64Strings(_report);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(_report['date']);
    final formattedDate = DateFormat('d MMM yyyy', 'th_TH').format(date);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('ข้อมูลการประกวด'),
        centerTitle: true,
        actions: [
          if (widget.userId == user!.uid)
            IconButton(
              onPressed: () => _navigateToEditContestPage(),
              icon: const Icon(LineAwesomeIcons.edit),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Positioned(
              top: 40, // ปรับความสูงของการ์ด
              left: 0,
              right: 0,
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 30), // เพิ่มพื้นที่ด้านบน
                      Column(
                        children: [
                          SizedBox(height: 8),
                          Text(
                            _report['award'] ?? '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Valid',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'วันที่ประกวด ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                              Text(
                                formattedDate,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'รายละเอียด ',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${_report['des'] ?? ''}',
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'รูปภาพ ',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          if (_imageBase64Strings.any(
                              (base64) => base64 != null && base64.isNotEmpty))
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8.0,
                                mainAxisSpacing: 8.0,
                              ),
                              itemCount: _imageBase64Strings
                                  .where((base64) =>
                                      base64 != null && base64.isNotEmpty)
                                  .length,
                              itemBuilder: (context, index) {
                                final base64String = _imageBase64Strings
                                    .where((base64) =>
                                        base64 != null && base64.isNotEmpty)
                                    .toList()[index];
                                final bytes = base64Decode(base64String);
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(20.0),
                                  child: Image.memory(
                                    bytes,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            )
                          else
                            Center(
                              // จัดตำแหน่งข้อความ "ไม่มีรูป" ให้ตรงกลาง
                              child: Text(
                                'ไม่มีรูป',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left:
                  MediaQuery.of(context).size.width / 2 - 55, // ปรับให้ตรงกลาง
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(40),
                ),
                padding: EdgeInsets.all(20),
                child: Icon(
                  LineAwesomeIcons.certificate,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
