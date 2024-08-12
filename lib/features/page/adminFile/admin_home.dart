import 'dart:developer';

import 'package:Pet_Fluffy/features/page/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late User? user;
  late List<Map<String, dynamic>> TypePetdatas = [];
  late List<Map<String, dynamic>> genePetDatas = [];
  late List<Map<String, dynamic>> vaccinePetDatas = [];
  final TextEditingController _nameTypeController = TextEditingController();
  final TextEditingController _nameGeneController = TextEditingController();
  final TextEditingController _nameVaccController = TextEditingController();
  final TextEditingController _nameAgeController = TextEditingController();
  final TextEditingController _nameDoseController = TextEditingController();
  bool isLoading = true;
  final TextEditingController _controller = TextEditingController();
  String? petId_main;
  String typePet = '5yWv1hawXz6Gh15gEed1';
  bool isDog = true; // ตัวแปรสถานะเริ่มต้นเป็นสุนัข

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _getTypePetData('');
      _getGene_petData('');
      _getVaccines_petData('');
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
    } catch (e) {
      print('Error getting pet user data from Firestore: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getGene_petData(String searchValue) async {
    try {
      QuerySnapshot genePetQuerySnapshot = await FirebaseFirestore.instance
          .collection('gene_pet')
          .doc(typePet)
          .collection('gene_pet')
          .get();

      List<Map<String, dynamic>> allGene = genePetQuerySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      if (searchValue.isNotEmpty) {
        List<Map<String, dynamic>> allGeneData = allGene.where((type) {
          bool matchesName = type['name']
              .toString()
              .toLowerCase()
              .contains(searchValue.toLowerCase());
          return matchesName;
        }).toList();

        setState(() {
          genePetDatas = allGeneData;
          isLoading = false;
        });
      } else {
        setState(() {
          genePetDatas = allGene;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error getting pet user data from Firestore: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getVaccines_petData(String searchValue) async {
    try {
      QuerySnapshot vaccinesPetQuerySnapshot = await FirebaseFirestore.instance
          .collection('pet_vaccines')
          .doc(typePet)
          .collection("pet_vaccines")
          .orderBy("id_table_vacc", descending: false)
          .get();

      List<Map<String, dynamic>> allVaccine = vaccinesPetQuerySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      if (searchValue.isNotEmpty) {
        List<Map<String, dynamic>> allVaccData = allVaccine.where((type) {
          bool matchesName = type['vaccine']
              .toString()
              .toLowerCase()
              .contains(searchValue.toLowerCase());
          return matchesName;
        }).toList();

        setState(() {
          vaccinePetDatas = allVaccData;
          isLoading = false;
        });
      } else {
        setState(() {
          vaccinePetDatas = allVaccine;
          isLoading = false;
        });
      }
      log(vaccinePetDatas.length.toString());
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
    _getTypePetData(value);
    _getGene_petData(value);
    _getVaccines_petData(value); // Log the current value of the TextField
  }

  void _logSearchValue() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchValue = _controller.text;
      // log(searchValue.toString());
      _getTypePetData(searchValue);
      _getGene_petData(searchValue);
      _getVaccines_petData(searchValue);
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
                    _buildTypePet(TypePetdatas),
                    _buildGenePet(genePetDatas),
                    _buildVaccPet(vaccinePetDatas)
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.deepPurple,
            onPressed: () {
              setState(() {
                isDog = !isDog;
                if (typePet == '5yWv1hawXz6Gh15gEed1') {
                  typePet = 'Qy38o0xCXKQlIngPz9jb';
                } else if (typePet == 'Qy38o0xCXKQlIngPz9jb') {
                  typePet = '5yWv1hawXz6Gh15gEed1';
                }
                _getGene_petData(_controller.text);
                _getVaccines_petData(_controller.text);
              });
            },
            child: Icon(
              isDog
                  ? LineAwesomeIcons.cat
                  : LineAwesomeIcons.dog, // ใช้ไอคอนสุนัขหรือแมวตามสถานะ
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypePet(List<Map<String, dynamic>> TypePetList) {
    return TypePetList.isEmpty
        ? const Center(
            child: Text(
              'ไม่มีข้อมูลประเภทสัตว์เลี้ยง',
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
                    return _buildTypePetCard(TypePetList[index]);
                  },
                ),
                const SizedBox(height: 40),
                Center(
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.0),
                      onTap: () {
                        _nameTypeController.text = '';
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                'เพิ่มประเภทสัตว์เลี้ยง',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              content: TextField(
                                controller: _nameTypeController,
                                decoration: const InputDecoration(
                                    hintText: "กรุณากรอกชื่อประเภทสัตว์เลี้ยง"),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("ยกเลิก"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    addType();
                                  },
                                  child: const Text("บันทึก"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        child: Center(
                          child: Icon(
                            Icons.add,
                            size: 40.0,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 63),
              ],
            ),
          );
  }

  // ข้อมูลสัตว์เลี้ยงที่แสดงผล
  Widget _buildTypePetCard(Map<String, dynamic> TypePetData) {
    return GestureDetector(
      onTap: () {
        _nameTypeController.text = TypePetData['name'];
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'แก้ไขประเภทสัตว์เลี้ยง',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              content: TextField(
                controller: _nameTypeController,
                decoration: const InputDecoration(
                    hintText: "กรุณากรอกชื่อประเภทสัตว์เลี้ยง"),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("ยกเลิก"),
                ),
                TextButton(
                  onPressed: () {
                    editTypePet(TypePetData['id_type_pet']);
                  },
                  child: const Text("บันทึก"),
                ),
              ],
            );
          },
        );
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
                        title: Column(
                          children: [
                            const Icon(LineAwesomeIcons.trash,
                                color: Colors.deepPurple, size: 50),
                            SizedBox(height: 20),
                            Text('คุณต้องการลบข้อมูลประเภทสัตว์เลี้ยง',
                                style: TextStyle(fontSize: 18)),
                          ],
                        ),
                        content: Text(
                          "${TypePetData['name']}?",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 25),
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
                                      deleteType(TypePetData['id_type_pet']);
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
                },
                icon: const Icon(LineAwesomeIcons.minus),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenePet(List<Map<String, dynamic>> GenePetList) {
    return GenePetList.isEmpty
        ? const Center(
            child: Text(
              'ไม่มีข้อมูลพันธู์สัตว์เลี้ยง',
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
                  itemCount: GenePetList.length,
                  itemBuilder: (context, index) {
                    return _buildGenePetCard(GenePetList[index]);
                  },
                ),
                const SizedBox(height: 40),
                Center(
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.0),
                      onTap: () {
                        _nameGeneController.text = '';
                        String? nameTypePet;
                        if (typePet == '5yWv1hawXz6Gh15gEed1') {
                          nameTypePet = 'แมว';
                        } else if (typePet == 'Qy38o0xCXKQlIngPz9jb') {
                          nameTypePet = 'สุนัข';
                        }
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Center(
                              child: AlertDialog(
                                title: Text(
                                  'เพิ่มพันธุ์สัตว์เลี้ยงของ$nameTypePet',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                content: TextField(
                                  controller: _nameGeneController,
                                  decoration: const InputDecoration(
                                      hintText: "กรุณากรอกชื่อพันธุ์สัตว์เลี้ยง"),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("ยกเลิก"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      addGene();
                                    },
                                    child: const Text("บันทึก"),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        child: Center(
                          child: Icon(
                            Icons.add,
                            size: 40.0,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 63),
              ],
            ),
          );
  }

  // ข้อมูลสัตว์เลี้ยงที่แสดงผล
  Widget _buildGenePetCard(Map<String, dynamic> genePetData) {
    return GestureDetector(
      onTap: () {
        _nameGeneController.text = genePetData['name'];
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'แก้ไขพันธุ์สัตว์เลี้ยง',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              content: TextField(
                controller: _nameGeneController,
                decoration: const InputDecoration(
                    hintText: "กรุณากรอกชื่อพันธุ์สัตว์เลี้ยง"),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("ยกเลิก"),
                ),
                TextButton(
                  onPressed: () {
                    editGenePet(genePetData['id_gene_pet']);
                  },
                  child: const Text("บันทึก"),
                ),
              ],
            );
          },
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ListTile(
          title: Text(
            genePetData['name'] ?? '',
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
                        title: Column(
                          children: [
                            const Icon(LineAwesomeIcons.trash,
                                color: Colors.deepPurple, size: 50),
                            SizedBox(height: 20),
                            Text('คุณต้องการลบข้อมูลพันธ์',
                                style: TextStyle(fontSize: 18)),
                          ],
                        ),
                        content: Text(
                          "${genePetData['name']}?",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 25),
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
                                      deleteGene(genePetData['id_gene_pet']);
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
                },
                icon: const Icon(LineAwesomeIcons.minus),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVaccPet(List<Map<String, dynamic>> VaccPetList) {
    return VaccPetList.isEmpty
        ? const Center(
            child: Text(
              'ไม่มีข้อมูล',
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
                  itemCount: VaccPetList.length,
                  itemBuilder: (context, index) {
                    return _buildVaccPetCard(VaccPetList[index]);
                  },
                ),
                const SizedBox(height: 40),
                Center(
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.0),
                      onTap: () {
                        _nameVaccController.text = '';
                        _nameAgeController.text = '';
                        _nameDoseController.text = '';
                        String? nameTypePet;
                        if (typePet == '5yWv1hawXz6Gh15gEed1') {
                          nameTypePet = 'แมว';
                        } else if (typePet == 'Qy38o0xCXKQlIngPz9jb') {
                          nameTypePet = 'สุนัข';
                        }
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                'เพิ่มพันธุ์สัตว์เลี้ยงของ$nameTypePet',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: _nameVaccController,
                                      decoration: const InputDecoration(
                                          hintText:
                                              "กรุณากรอกชื่อวัคซีนสัตว์เลี้ยง"),
                                    ),
                                    TextField(
                                      controller: _nameAgeController,
                                      decoration: const InputDecoration(
                                          hintText:
                                              "กรุณากรอกช่วงอายุที่ต้องฉีดวัคซีน"),
                                    ),
                                    TextField(
                                      controller: _nameDoseController,
                                      decoration: const InputDecoration(
                                          hintText: "กรุณากรอกเข็มที่เท่าไหร่"),
                                    ),
                                  ]),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("ยกเลิก"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    addVacc();
                                  },
                                  child: const Text("บันทึก"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        child: Center(
                          child: Icon(
                            Icons.add,
                            size: 40.0,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 63),
              ],
            ),
          );
  }

  // ข้อมูลสัตว์เลี้ยงที่แสดงผล
  Widget _buildVaccPetCard(Map<String, dynamic> VaccPetData) {
    return GestureDetector(
      onTap: () {
        _nameVaccController.text = VaccPetData['vaccine'];
        _nameAgeController.text = VaccPetData['age'];
        _nameDoseController.text = VaccPetData['dose'];
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: Text(
                    'แก้ไขเกณฑ์การฉีดวัคซีนสัตว์เลี้ยง',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _nameVaccController,
                        decoration: const InputDecoration(
                            hintText: "กรุณากรอกชื่อวัคซีนสัตว์เลี้ยง"),
                      ),
                      TextField(
                        controller: _nameAgeController,
                        decoration: const InputDecoration(
                            hintText: "กรุณากรอกช่วงอายุที่ต้องฉีดวัคซีน"),
                      ),
                      TextField(
                        controller: _nameDoseController,
                        decoration: const InputDecoration(
                            hintText: "กรุณากรอกเข็มที่เท่าไหร่"),
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("ยกเลิก"),
                    ),
                    TextButton(
                      onPressed: () {
                        editVaccPet(VaccPetData['id_pet_vaccines']);
                      },
                      child: const Text("บันทึก"),
                    ),
                  ]);
            });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ListTile(
            title: Text(
              VaccPetData['vaccine'] ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Age: ${VaccPetData['age'] ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Padding(padding: EdgeInsets.only(left: 10)),
                Text(
                  'Dose: ${VaccPetData['dose'] ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
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
                          title: Column(
                            children: [
                              const Icon(LineAwesomeIcons.trash,
                                  color: Colors.deepPurple, size: 50),
                              SizedBox(height: 20),
                              Text('คุณต้องการลบข้อมูลวัคซีน',
                                  style: TextStyle(fontSize: 18)),
                            ],
                          ),
                          content: Text(
                            "${VaccPetData['vaccine']}?",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20),
                          ),
                          actions: <Widget>[
                            Center(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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
                                        deleteVacc(
                                            VaccPetData['id_pet_vaccines']);
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
                  },
                  icon: const Icon(LineAwesomeIcons.minus),
                ),
              ],
            )),
      ),
    );
  }

  void addType() async {
    bool chek = false;
    for (var element in TypePetdatas) {
      if (element['name'] == _nameTypeController.text) {
        chek = true;
      }
    }

    if (chek) {
      showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('The information is already in the system.'),
                ],
              ),
            ),
          );
        },
      );
    } else {
      CollectionReference type =
          FirebaseFirestore.instance.collection('pet_type');
      try {
        DocumentReference newTypeRef =
            await type.add({'name': _nameTypeController.text});
        String docId = newTypeRef.id;

        await newTypeRef.update({'id_type_pet': docId});

        setState(() {
          Navigator.pop(context);
          _getTypePetData('');
        });
      } catch (e) {
        print('Error Add type data: $e');
      }
    }
  }

  void addGene() async {
    bool chek = false;
    for (var element in genePetDatas) {
      if (element['name'] == _nameGeneController.text) {
        chek = true;
      }
    }
    if (chek) {
      showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('The information is already in the system.'),
                ],
              ),
            ),
          );
        },
      );
    } else {
      CollectionReference gene = FirebaseFirestore.instance
          .collection('gene_pet')
          .doc(typePet)
          .collection('gene_pet');
      try {
        DocumentReference newGeneRef =
            await gene.add({'name': _nameGeneController.text});
        String docId = newGeneRef.id;

        await newGeneRef.update({'id_gene_pet': docId});

        setState(() {
          Navigator.pop(context);
          _getGene_petData('');
        });
      } catch (e) {
        print('Error Add gene data: $e');
      }
    }
  }

  void addVacc() async {
    bool chek = false;
    int id_table_vacc = vaccinePetDatas.last['id_table_vacc'] + 1;

    for (var element in vaccinePetDatas) {
      if (element['vaccine'] == _nameVaccController.text &&
          element['dose'] == _nameDoseController.text) {
        chek = true;
      }
    }
    log(chek.toString());
    if (chek) {
      showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('The information is already in the system.'),
                ],
              ),
            ),
          );
        },
      );
    } else {
      CollectionReference vacc = FirebaseFirestore.instance
          .collection('pet_vaccines')
          .doc(typePet)
          .collection('pet_vaccines');
      try {
        DocumentReference newGeneRef = await vacc.add({
          'vaccine': _nameVaccController.text,
          'age': _nameAgeController.text,
          'dose': _nameDoseController.text,
          'id_table_vacc': id_table_vacc
        });
        String docId = newGeneRef.id;
        await newGeneRef.update({'id_pet_vaccines': docId});
        setState(() {
          Navigator.pop(context);
          _getVaccines_petData('');
        });
      } catch (e) {
        print('Error Add gene data: $e');
      }
    }
  }

  void deleteType(String id_type_pet) async {
    try {
      await FirebaseFirestore.instance
          .collection('pet_type')
          .doc(id_type_pet)
          .delete();

      // ลบข้อมูลสัตว์เลี้ยงสำเร็จ ให้รีเฟรชหน้าเพื่อแสดงข้อมูลใหม่

      setState(() {
        Navigator.pop(context);
        _getTypePetData('');
      });
    } catch (e) {
      print('Error deleting pet data: $e');
    }
  }

  void deleteGene(String id_gene_pet) async {
    try {
      await FirebaseFirestore.instance
          .collection('gene_pet')
          .doc(typePet)
          .collection('gene_pet')
          .doc(id_gene_pet)
          .delete();

      // ลบข้อมูลสัตว์เลี้ยงสำเร็จ ให้รีเฟรชหน้าเพื่อแสดงข้อมูลใหม่

      setState(() {
        Navigator.pop(context);
        _getGene_petData('');
      });
    } catch (e) {
      print('Error deleting pet data: $e');
    }
  }

  void deleteVacc(String id_vacc_pet) async {
    try {
      await FirebaseFirestore.instance
          .collection('pet_vaccines')
          .doc(typePet)
          .collection('pet_vaccines')
          .doc(id_vacc_pet)
          .delete();

      // ลบข้อมูลสัตว์เลี้ยงสำเร็จ ให้รีเฟรชหน้าเพื่อแสดงข้อมูลใหม่

      setState(() {
        Navigator.pop(context);
        _getVaccines_petData('');
      });
    } catch (e) {
      print('Error deleting pet data: $e');
    }
  }

  void editTypePet(String id_type_pet) {
    CollectionReference type =
        FirebaseFirestore.instance.collection('pet_type');
    type
        .doc(id_type_pet)
        .update({'name': _nameTypeController.text}).then((value) {
      setState(() {
        Navigator.pop(context);
        _getTypePetData('');
      });
    });
  }

  void editGenePet(String id_gene_pet) {
    CollectionReference type = FirebaseFirestore.instance
        .collection('gene_pet')
        .doc(typePet)
        .collection('gene_pet');
    type
        .doc(id_gene_pet)
        .update({'name': _nameGeneController.text}).then((value) {
      setState(() {
        Navigator.pop(context);
        _getGene_petData('');
      });
    });
  }

  void editVaccPet(String id_pet_vaccines) {
    CollectionReference type = FirebaseFirestore.instance
        .collection('pet_vaccines')
        .doc(typePet)
        .collection('pet_vaccines');
    type.doc(id_pet_vaccines).update({
      'vaccine': _nameVaccController.text,
      'age': _nameAgeController.text,
      'dose': _nameDoseController.text
    }).then((value) {
      setState(() {
        Navigator.pop(context);
        _getVaccines_petData('');
      });
    });
  }
}
