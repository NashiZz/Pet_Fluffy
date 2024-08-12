import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/editVacDetail_Page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class VaccineDetailPage extends StatefulWidget {
  final Map<String, dynamic> report;
  final String userId;
  final String pet_type;

  const VaccineDetailPage({
    Key? key,
    required this.report,
    required this.userId,
    required this.pet_type,
  }) : super(key: key);

  @override
  _VaccineDetailPageState createState() => _VaccineDetailPageState();
}

class _VaccineDetailPageState extends State<VaccineDetailPage> {
  User? user = FirebaseAuth.instance.currentUser;
  late Map<String, dynamic> _report;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
  }

  Future<void> _navigateToEditVaccinePage() async {
    final updatedReport = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EditVaccinePage(
                report: _report,
                userId: widget.userId,
                pet_type: widget.pet_type),
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
        title: Text('ข้อมูลวัคซีน'),
        centerTitle: true,
        actions: [
          if (widget.userId == user!.uid)
            IconButton(
              onPressed: _navigateToEditVaccinePage,
              icon: const Icon(LineAwesomeIcons.edit),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(children: [
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
                          _report['vacName'] ?? '',
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
                            Expanded(
                              flex: 2,
                              child: Text(
                                'น้ำหนักที่วัดตอนไปฉีด ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${_report['weight'] ?? ''} kg',
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
                              flex: 1,
                              child: Text(
                                'ราคาวัคซีน ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${_report['price'] ?? ''} บาท',
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
                                'สถานที่ไปฉีด ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${_report['location'] ?? ''}',
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
                            Text(
                              'วันที่ไปฉีด ',
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: MediaQuery.of(context).size.width / 2 - 55, // ปรับให้ตรงกลาง
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(40),
              ),
              padding: EdgeInsets.all(20),
              child: Icon(
                LineAwesomeIcons.syringe,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
