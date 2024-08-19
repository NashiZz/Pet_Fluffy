import 'dart:convert';
import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

Future<List<Map<String, dynamic>>> fetchMatchData(String petId) async {
  // ดึงข้อมูลที่เกี่ยวข้องกับ pet_request
  QuerySnapshot requestSnapshot = await FirebaseFirestore.instance
      .collection('match')
      .where('pet_request', isEqualTo: petId)
      .where('status', isEqualTo: "ไม่ยอมรับ")
      .get();

  // ดึงข้อมูลที่เกี่ยวข้องกับ pet_respone
  QuerySnapshot responseSnapshot = await FirebaseFirestore.instance
      .collection('match')
      .where('pet_respone', isEqualTo: petId)
      .where('status', isEqualTo: "ไม่ยอมรับ")
      .get();

  // รวมผลลัพธ์ทั้งสอง โดยเลือกฟิลด์ที่เหมาะสม
  List<Map<String, dynamic>> combinedResults = [];

  for (var doc in requestSnapshot.docs) {
    combinedResults.add({
      'matchedPetId': doc['pet_respone'],
      'data': doc.data(),
    });
  }

  for (var doc in responseSnapshot.docs) {
    combinedResults.add({
      'matchedPetId': doc['pet_request'],
      'data': doc.data(),
    });
  }

  return combinedResults;
}

Future<DocumentSnapshot> fetchPetUserData(String petId) async {
  return FirebaseFirestore.instance.collection('Pet_User').doc(petId).get();
}

void showHistoryDialog({
  required BuildContext context,
  required String userId,
  required String petId,
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
                      'ประวัติการจับคู่',
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
                        'เคยจับคู่',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      Spacer(),
                    ],
                  ),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchMatchData(petId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: const CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              Map<String, dynamic> reportData =
                                  snapshot.data![index];
                              String petID = reportData['matchedPetId'];
                              Map<String, dynamic> report = reportData['data'];

                              return FutureBuilder<DocumentSnapshot>(
                                future: fetchPetUserData(petID),
                                builder: (context, petSnapshot) {
                                  if (petSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: const CircularProgressIndicator(),
                                    );
                                  }
                                  if (petSnapshot.hasError) {
                                    return Text('Error: ${petSnapshot.error}');
                                  }
                                  if (petSnapshot.hasData) {
                                    Map<String, dynamic> petData =
                                        petSnapshot.data!.data()
                                            as Map<String, dynamic>;
                                    String petImageBase64 =
                                        petData['img_profile'] ?? '';
                                    String petName = petData['name'] ?? '';
                                    String description = report['des'] ?? '';
                                    final date =
                                        DateTime.parse(report['created_at']);
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
                                                Profile_pet_Page(
                                              petId: petID,
                                            ),
                                            transitionsBuilder: (context,
                                                animation,
                                                secondaryAnimation,
                                                child) {
                                              const begin = Offset(1.0, 0.0);
                                              const end = Offset.zero;
                                              const curve = Curves.ease;

                                              var tween = Tween(
                                                      begin: begin, end: end)
                                                  .chain(
                                                      CurveTween(curve: curve));

                                              return SlideTransition(
                                                position:
                                                    animation.drive(tween),
                                                child: child,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
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
                                                child: petImageBase64.isNotEmpty
                                                    ? Image.memory(
                                                        base64Decode(
                                                            petImageBase64),
                                                        width: 70,
                                                        height: 70,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : const CircularProgressIndicator(),
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
                                                            petName,
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          formattedDate,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      description,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                  return SizedBox.shrink();
                                },
                              );
                            },
                          );
                        }
                        return Column(
                          children: [
                            SizedBox(height: 15),
                            Text('ไม่มีบันทึกการจับคู่ที่ถูกปฏิเสธ'),
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
