import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/editPeriod_Page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:intl/intl.dart';

class PeriodDetailPage extends StatefulWidget {
  final Map<String, dynamic> report;
  final String userId;
  final String idPeriod;

  const PeriodDetailPage({
    Key? key,
    required this.report,
    required this.idPeriod,
    required this.userId,
  }) : super(key: key);

  @override
  _PeriodDetailPageState createState() => _PeriodDetailPageState();
}

class _PeriodDetailPageState extends State<PeriodDetailPage> {
  User? user = FirebaseAuth.instance.currentUser;
  late Map<String, dynamic> _report;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
  }

  Future<void> _navigateToEditPeriodPage() async {
    final updatedReport = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EditPeriodPage(report: _report, userId: widget.userId),
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
        title: Text('ข้อมูลประจำเดือน'),
        centerTitle: true,
        actions: [
          if (widget.userId == user!.uid)
            IconButton(
              onPressed: () => _navigateToEditPeriodPage(),
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
                            'รายละเอียดการเป็นประจำเดือน',
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
                                  'วันที่เริ่มเป็น ',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  formattedDate,
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
                                  'รายละอียด ',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${_report['des']}',
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.end,
                                ),
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
              left:
                  MediaQuery.of(context).size.width / 2 - 55, // ปรับให้ตรงกลาง
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(40),
                ),
                padding: EdgeInsets.all(20),
                child: Icon(
                  LineAwesomeIcons.calendar_with_day_focus,
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
