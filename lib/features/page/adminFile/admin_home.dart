import 'dart:convert';
import 'dart:developer';

import 'package:Pet_Fluffy/features/page/login_page.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/edit_Profile_Pet.dart';
import 'package:Pet_Fluffy/features/page/pet_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late User? user;
  late List<Map<String, dynamic>> TypePetdatas = [];
  bool isLoading = true;
  final TextEditingController _controller = TextEditingController();
  String? petId_main;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _getTypePetData('');
    }
  }

  Future<void> _getTypePetData(String searchValue) async {
    try {
      QuerySnapshot TypePetQuerySnapshot =
          await FirebaseFirestore.instance.collection('pet_type').get();

      List<Map<String, dynamic>> allType = TypePetQuerySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      if (searchValue.isNotEmpty) {
        List<Map<String, dynamic>> allTypedata = allType.where((type) {
          bool matchesName = type['name']
              .toString()
              .toLowerCase()
              .contains(searchValue.toLowerCase());
          return matchesName;
        }).toList();

        setState(() {
          TypePetdatas = allTypedata;
          isLoading = false;
        });
      } else {
        setState(() {
          TypePetdatas = allType;
          isLoading = false;
        });
      }
      log(TypePetdatas.length.toString());
    } catch (e) {
      print('Error getting pet user data from Firestore: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getPetData(String searchValue) async {
    try {
      QuerySnapshot TypePetQuerySnapshot =
          await FirebaseFirestore.instance.collection('pet_type').get();

      List<Map<String, dynamic>> allType = TypePetQuerySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      if (searchValue.isNotEmpty) {
        List<Map<String, dynamic>> allTypedata = allType.where((type) {
          bool matchesName = type['name']
              .toString()
              .toLowerCase()
              .contains(searchValue.toLowerCase());
          return matchesName;
        }).toList();

        setState(() {
          TypePetdatas = allTypedata;
          isLoading = false;
        });
      } else {
        setState(() {
          TypePetdatas = allType;
          isLoading = false;
        });
      }
      log(TypePetdatas.length.toString());
    } catch (e) {
      print('Error getting pet user data from Firestore: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  

  @override
  void dispose() {
    // Dispose controller when not needed
    _controller.dispose();
    super.dispose();
  }

  // ค้นหา
  void _logSearchValuee(String value) {
    _getTypePetData(value); // Log the current value of the TextField
  }
  void _logSearchValue() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchValue = _controller.text;
      // log(searchValue.toString());
      _getTypePetData(searchValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("ออกจากระบบ"),
                      content: const Text("คุณต้องการออกจากระบบหรือไม่?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // ปิด Popup
                          },
                          child: const Text("ยกเลิก"),
                        ),
                        TextButton(
                          onPressed: () async {
                            User? user = FirebaseAuth.instance.currentUser;
                            if (user != null && user.isAnonymous) {
                              // ลบบัญชี anonymous
                              try {
                                await user.delete();
                                print("Anonymous account deleted");
                              } catch (e) {
                                print("Error deleting anonymous account: $e");
                              }
                            } else {
                              await GoogleSignIn().signOut();
                            }
                            FirebaseAuth.instance.signOut();
                            print("Sign Out Success!!");
                            Navigator.pushAndRemoveUntil(
                              // ignore: use_build_context_synchronously
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                              (Route<dynamic> route) => false,
                            );
                          },
                          child: const Text("ตกลง"),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(LineAwesomeIcons.alternate_sign_out),
            ),
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "ผู้ดูแล",
                style: Theme.of(context).textTheme.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            centerTitle: true,
            automaticallyImplyLeading: false, // กำหนดให้ไม่แสดงปุ่ม Back
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(
                  kToolbarHeight + 60), // ปรับขนาด preferredSize
              child: Container(
                // decoration: BoxDecoration(
                //   border: Border.all(
                //     color: Colors.grey, // สีของกรอบ
                //     width: 2.0, // ความหนาของกรอบ
                //   ),
                //   borderRadius: BorderRadius.circular(12.0), // มุมโค้งของกรอบ
                // ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50.0, vertical: 14.0),
                      child: Container(
                        height: MediaQuery.of(context).size.height / 17,
                        child: TextField(
                          controller: _controller,
                          onChanged: (value) {
                            _logSearchValuee(value); // Log value as it's typed
                          },
                          decoration: InputDecoration(
                            hintText: 'ค้นหา',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: _logSearchValue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'ประเภทสัตว์เลี้ยง'),
                        Tab(text: 'พันธุ์สัตว์เลี้ยง'),
                        Tab(text: 'เกณฑ์การฉีดวัคซีนสัตว์เลี้ยง'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(
                          height:
                              16), // เพิ่มระยะห่างระหว่าง CircularProgressIndicator กับข้อความ
                      Text('กำลังโหลดข้อมูล'),
                    ],
                  ),
                )
              : TabBarView(
                  children: [
                    //สุนัข
                    _buildTypePet(TypePetdatas),
                    //แมว
                    Center(child: Text('เกณฑ์การฉีดวัคซีนสัตว์เลี้ยง')),
                    Center(child: Text('เกณฑ์การฉีดวัคซีนสัตว์เลี้ยง')),

                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Pet_Page()),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildTypePet(List<Map<String, dynamic>> TypePetList) {
    return TypePetList.isEmpty
        ? const Center(
            child: Text(
              'ไม่มีข้อมูลสัตว์เลี้ยง',
              style: TextStyle(fontSize: 16),
            ),
          )
        : SingleChildScrollView(
            // แสดงรายการสัตว์เลี้ยงเมื่อข้อมูลถูกโหลดเสร็จสิ้น
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: TypePetList.length,
                  itemBuilder: (context, index) {
                    return _buildPetCard(TypePetList[index]);
                  },
                ),
              ],
            ),
          );
  }

  // ข้อมูลสัตว์เลี้ยงที่แสดงผล
  Widget _buildPetCard(Map<String, dynamic> TypePetData) {
    return GestureDetector(
      onTap: () {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => Edit_Pet_Page(TypePetData: TypePetData),
        //   ),
        // );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ListTile(
          title: Text(
            TypePetData['name'] ?? '',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("ยืนยันการลบ"),
                        content:
                            const Text("คุณแน่ใจหรือไม่ที่ต้องการลบข้อมูลนี้?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("ยกเลิก"),
                          ),
                          TextButton(
                            onPressed: () {
                              _deletePetData(TypePetData['pet_id']);
                              Navigator.of(context).pop();
                            },
                            child: const Text("ยืนยัน"),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(LineAwesomeIcons.minus),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //ปุ่มลบข้อมูลสัตว์เลี้ยง
  void _deletePetData(String petId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Pet_User')
          .doc(petId)
          .update({'status': 'ถูกลบ'});
      // ลบข้อมูลสัตว์เลี้ยงสำเร็จ ให้รีเฟรชหน้าเพื่อแสดงข้อมูลใหม่
      _getTypePetData('');
    } catch (e) {
      print('Error deleting pet data: $e');
    }
  }
}
