import 'dart:convert';

import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/AddContest_Page.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/ContestDetail_Page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

void showContestDialog({
  required BuildContext context,
  required String userId,
  required String petId,
  required String userPet,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            Future<QuerySnapshot>? _future;

            if (_future == null) {
              _future = FirebaseFirestore.instance
                  .collection('contest_pet')
                  .doc(userId)
                  .collection('pet_contest')
                  .where('pet_id', isEqualTo: petId)
                  .get();
            }

            return Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.65,
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Spacer(),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                  Center(
                    child: Text(
                      'ประวัติการประกวด',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      Text(
                        'การประกวด',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      Spacer(),
                      if (userId == userPet)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        AddContestPage(
                                  userId: userId,
                                  petId: petId,
                                ),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.ease;

                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));

                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                              ),
                            ).then((_) {
                              // Refresh data after returning from AddContestPage
                              setState(() {
                                _future = FirebaseFirestore.instance
                                    .collection('contest_pet')
                                    .doc(userId)
                                    .collection('pet_contest')
                                    .where('pet_id', isEqualTo: petId)
                                    .get();
                              });
                            });
                          },
                          child: Text(
                            'เพิ่ม',
                            style: TextStyle(
                                color: Colors.blueAccent, fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: FutureBuilder<QuerySnapshot>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                              child: const CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (snapshot.hasData &&
                            snapshot.data!.docs.isNotEmpty) {
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              DocumentSnapshot reportDoc =
                                  snapshot.data!.docs[index];
                              Map<String, dynamic> report =
                                  reportDoc.data() as Map<String, dynamic>;

                              final base64String = report['img_1'];
                              final hasImage = base64String != null &&
                                  base64String.isNotEmpty;

                              final date = DateTime.parse(report['date']);
                              final idContest = reportDoc.id;

                              final formattedDate =
                                  DateFormat('d MMM yyyy', 'th_TH')
                                      .format(date);

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          ContestDetailPage(
                                        report: report,
                                        userId: userId,
                                        idContest: idContest,
                                      ),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.ease;

                                        var tween = Tween(
                                                begin: begin, end: end)
                                            .chain(CurveTween(curve: curve));

                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                    ),
                                  ).then((_) {
                                    // Refresh data after returning from ContestDetailPage
                                    setState(() {
                                      _future = FirebaseFirestore.instance
                                          .collection('contest_pet')
                                          .doc(userId)
                                          .collection('pet_contest')
                                          .where('pet_id', isEqualTo: petId)
                                          .get();
                                    });
                                  });
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  elevation: 3,
                                  margin: const EdgeInsets.all(8.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.all(2),
                                          child: hasImage
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Image.memory(
                                                    base64Decode(base64String),
                                                    width: 55,
                                                    height: 55,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      print(
                                                          'Error displaying image: $error');
                                                      return Icon(
                                                        LineAwesomeIcons
                                                            .certificate,
                                                        color: Colors.grey[600],
                                                      );
                                                    },
                                                  ),
                                                )
                                              : Icon(
                                                  LineAwesomeIcons.certificate,
                                                  color: Colors.grey[600],
                                                  size: 50,
                                                ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'การประกวด',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    formattedDate,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                report['award'] ?? 'N/A',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        return Column(
                          children: [
                            SizedBox(height: 15),
                            Text('ไม่มีบันทึกการประกวด'),
                            SizedBox(height: 15),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
