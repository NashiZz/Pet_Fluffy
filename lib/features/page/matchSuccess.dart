import 'dart:convert';

import 'package:Pet_Fluffy/features/page/profile_all_user.dart';
import 'package:flutter/material.dart';

class Matchsuccess_Page extends StatefulWidget {
  final String pet_request; // pat ร้องขอ
  final String pet_respone; // pat ตอบรับ
  final String pet_request_name; // pat ร้องขอ
  final String pet_respone_name;
  final String idUser_pet;
  final String idUser_petReq;
  const Matchsuccess_Page(
      {super.key,
      required this.pet_request,
      required this.pet_respone,
      required this.idUser_pet,
      required this.pet_request_name,
      required this.pet_respone_name,
      required this.idUser_petReq});

  @override
  State<Matchsuccess_Page> createState() => _Matchsuccess_PageState();
}

class _Matchsuccess_PageState extends State<Matchsuccess_Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF7F57F0),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height / 10)),
                Stack(
                  children: [
                    // เงาด้านล่างของข้อความ

                    Positioned(
                      top: 3,
                      left: 3,
                      child: Text(
                        "จับคู่สำเร็จ!",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                          color: Colors.black.withOpacity(0.5),
                          decoration:
                              TextDecoration.none, // เอาเส้นขีดออก// สีเงา
                        ),
                      ),
                    ),
                    // ข้อความจริง
                    Text(
                      "จับคู่สำเร็จ!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 40,
                        color: const Color.fromARGB(255, 238, 238, 238),
                        decoration: TextDecoration
                            .none, // เอาเส้นขีดออก // สีข้อความจริง
                      ),
                    ),
                  ],
                ),

                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height / 1.8,
                  // decoration: BoxDecoration(
                  //   border: Border.all(
                  //     color: Colors.red,
                  //     width: 2.0,
                  //   ),
                  // ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: MediaQuery.of(context).size.height / 28,
                        left: 10,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              30), // กำหนด borderRadius ให้กับรูปภาพ
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 2,
                            height: 200,
                            child: Image.memory(
                              base64Decode(widget.pet_request),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                          top: MediaQuery.of(context).size.height / 4,
                          left: MediaQuery.of(context).size.width / 16,
                          child: Container(
                            width: MediaQuery.of(context).size.width / 2.8,
                            height: MediaQuery.of(context).size.height / 11,
                            // decoration: BoxDecoration(
                            //   border: Border.all(
                            //     color: Colors.red,
                            //     width: 2.0,
                            //   ),
                            // ),
                            child: Center(
                              child: Text(
                                widget.pet_request_name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                  color:
                                      const Color.fromARGB(255, 238, 238, 238),
                                ),
                              ),
                            ),
                          )),
                      Positioned(
                        right: 10,
                        top: MediaQuery.of(context).size.height / 9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              30), // กำหนด borderRadius ให้กับรูปภาพ
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 2,
                            height: 200,
                            child: Image.memory(
                              base64Decode(widget.pet_respone),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                          top: MediaQuery.of(context).size.height / 3.05,
                          right: MediaQuery.of(context).size.width / 30,
                          child: Container(
                            width: MediaQuery.of(context).size.width / 2.1,
                            height: MediaQuery.of(context).size.height / 11,
                            // decoration: BoxDecoration(
                            //   border: Border.all(
                            //     color: Colors.red,
                            //     width: 2.0,
                            //   ),
                            // ),
                            child: Center(
                              child: Text(
                                widget.pet_respone_name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                  color:
                                      const Color.fromARGB(255, 238, 238, 238),
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                //ปุ่มม

                Container(
                  width: MediaQuery.of(context).size.width / 2.5,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileAllUserPage(
                            userId: widget.idUser_pet,
                            userId_req: widget.idUser_petReq.toString(),
                          ),
                          settings: RouteSettings(name: 'matchSuccess')
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 0),
                      backgroundColor: const Color.fromARGB(255, 228, 216, 216),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "คลิก",
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ]),
        ),
      ),
    );
  }
}
