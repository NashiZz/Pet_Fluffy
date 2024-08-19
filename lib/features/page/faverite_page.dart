<<<<<<< HEAD

import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

=======
import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
class FaveritePage extends StatefulWidget {
  const FaveritePage({Key? key}) : super(key: key);

  @override
  State<FaveritePage> createState() => _FaveritePageState();
}

class _FaveritePageState extends State<FaveritePage> {
  late List<Map<String, dynamic>> petUserDataList = [];
  late List<Map<String, dynamic>> getPetDataList = [];
<<<<<<< HEAD
  User? user = FirebaseAuth.instance.currentUser;
  late String userId;
  late String id_fav;
  bool isLoading = true;

=======
  
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
  @override
  void initState() {
    super.initState();
    _getPetUserDataFromFirestore();
  }

<<<<<<< HEAD
  //ดึงข้อมูลจาก firebase
  Future<void> _getPetUserDataFromFirestore() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      userId = userData.uid;
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? petId = prefs.getString(userId);
        // ดึงข้อมูลจากคอลเล็กชัน favorites
        QuerySnapshot petUserQuerySnapshot = await FirebaseFirestore.instance
            .collection('favorites')
            .doc(userId)
            .collection('pet_favorite')
            .where('pet_request', isEqualTo: petId)
            .get();

        // ดึงข้อมูลจากเอกสารในรูปแบบ Map<String, dynamic> และดึงเฉพาะฟิลด์ pet_respone
        List<dynamic> petResponses = petUserQuerySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        // ประกาศตัวแปร เพื่อรอรับข้อมูลใน for
        List<Map<String, dynamic>> allPetDataList = [];

        // ลูปเพื่อดึงข้อมูลแต่ละรายการ
        for (var petRespone in petResponses) {
          String petResponeId = petRespone['pet_respone'];

          // ดึงข้อมูลจาก pet_user
          QuerySnapshot getPetQuerySnapshot = await FirebaseFirestore.instance
              .collection('Pet_User')
              .where('pet_id', isEqualTo: petResponeId)
              .get();

          // เพิ่มข้อมูลลงใน List
          allPetDataList.addAll(getPetQuerySnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList());
        }
        // ส่วนที่ถูกนำไปแสดง
        List<Map<String, dynamic>> nonDeletedPets =
            allPetDataList.where((pet) => pet['status'] != 'ถูกลบ').toList();

        // ส่วนที่ถูกนำไปลบใน favorites
        List<Map<String, dynamic>> pet_Deleted =
            allPetDataList.where((pet) => pet['status'] == 'ถูกลบ').toList();
        for (var idpet_res in pet_Deleted) {
          String petResId = idpet_res['pet_id'];

          DocumentReference userFavoritesRef =
              FirebaseFirestore.instance.collection('favorites').doc(userId);
          CollectionReference petFavoriteRef =
              userFavoritesRef.collection('pet_favorite');
          // ดึงเอกสารที่มี pet_respone ตรงกับ petId
          QuerySnapshot querySnapshot = await petFavoriteRef
              .where('pet_respone', isEqualTo: petResId)
              .get();
          if (querySnapshot.docs.isNotEmpty) {
            // สมมติว่า pet_id มีค่า unique ดังนั้นจะมีเอกสารเพียงเอกสารเดียว
            DocumentSnapshot docSnapshot = querySnapshot.docs.first;

            // ดึง id_fav จากเอกสาร
            String idFav = docSnapshot.get('id_fav');

            // อ้างอิงถึงเอกสารที่มี id_fav
            DocumentReference docRef = petFavoriteRef.doc(idFav);

            // ตรวจสอบเอกสารก่อนที่จะลบ
            DocumentSnapshot docToCheck = await docRef.get();

            if (docToCheck.exists) {
              // ลบเอกสารโดยใช้ id_fav
              await docRef.delete();

              // ดึงข้อมูลใหม่หลังจากลบสำเร็จ (ถ้าต้องการ)
              _getPetUserDataFromFirestore();

              print('Document with id_fav $idFav deleted successfully');
            } else {
              print('No document found with id_fav: $idFav');
            }
          } else {
            print('No document found with pet_id: $petId');
          }
        }

        setState(() {
          petUserDataList = nonDeletedPets;
          isLoading = false;
        });
      } catch (e) {
        print('Error getting pet user data from Firestore: $e');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get allPets => petUserDataList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(LineAwesomeIcons.angle_left),
        ),
        title: Text(
          "สัตว์เลี้ยงรายการโปรด",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // กำหนดให้ไม่แสดงปุ่ม Back
      ),
      body: Column(
        children: [
          Divider(),
          Expanded(
            child: isLoading
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
                : _buildPetList(allPets),
          )
        ],
=======
  //ดึงข้อมูลจาก firebase 
  Future<void> _getPetUserDataFromFirestore() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('idPet');
      print('kuyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy');
      print(token);
      //ดึงข้อมูลจาก firebase collection favorites where document pet_request = id pet request
      QuerySnapshot petUserQuerySnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('pet_request', isEqualTo: "rSduQynENWQx1aUESvCO")
          .get();

      // ดึงข้อมูลจากเอกสารในรูปแบบ Map<String, dynamic> และดึงเฉพาะฟิลด์ pet_respone
      List<dynamic> petResponses = petUserQuerySnapshot.docs
          .map((doc) => doc.data() ?? ['pet_respone'])
          .where((response) => response != null)
          .toList();

      // ประกาศตัวแปร เพื่อรอรับข้อมูลใน for
      List<Map<String, dynamic>> allPetDataList = [];

      // ลูปเพื่อดึงข้อมูลแต่ละรายการ
      for (var petRespone in petResponses) {
        print(petRespone);

        // ดึงข้อมูลจาก pet_user
        QuerySnapshot getPetQuerySnapshot = await FirebaseFirestore.instance
            .collection('Pet_User')
            .where('pet_id', isEqualTo: petRespone['pet_respone'])
            .get();

        // เพิ่มข้อมูลลงใน List
        allPetDataList.addAll(getPetQuerySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
      }
      

// อัปเดต petUserDataList ด้วยข้อมูลทั้งหมดที่ได้รับ
      setState(() {
        petUserDataList = allPetDataList;
      });
    } catch (e) {
      print('Error getting pet user data from Firestore: $e');
    }
  }

  List<Map<String, dynamic>> get filteredDogPets =>
      petUserDataList.where((pet) => pet['type_pet'] == 'สุนัข').toList();

  List<Map<String, dynamic>> get filteredCatPets =>
      petUserDataList.where((pet) => pet['type_pet'] == 'แมว').toList();

  @override
  Widget build(BuildContext context) {
    // print(filteredCatPets);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(LineAwesomeIcons.angle_left)),
          title: Text(
            "สัตว์เลี้ยงรายการโปรด",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          centerTitle: true,
          automaticallyImplyLeading: false, // กำหนดให้ไม่แสดงปุ่ม Back
          bottom: const TabBar(
            tabs: [
              Tab(text: 'สุนัข'),
              Tab(text: 'แมว'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            //สุนัข
            _buildPetList(filteredDogPets),
            //แมว
            _buildPetList(filteredCatPets),
          ],
        ),
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
      ),
    );
  }

  Widget _buildPetList(List<Map<String, dynamic>> petList) {
    return petList.isEmpty
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
                  itemCount: petList.length,
                  itemBuilder: (context, index) {
                    return _buildPetCard(petList[index]);
                  },
                ),
              ],
            ),
          );
  }

  Widget _buildPetCard(Map<String, dynamic> petUserData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Profile_pet_Page(petId: petUserData['pet_id']),
          ),
        );
      },
      child: Card(
<<<<<<< HEAD
        color: Colors.white,
=======
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 30,
            backgroundImage: petUserData['img_profile'] != null
                ? MemoryImage(
                    base64Decode(petUserData['img_profile'] as String))
                : null,
            child: petUserData['img_profile'] == null
                ? const ImageIcon(AssetImage('assets/default_pet_image.png'))
                : null,
          ),
<<<<<<< HEAD
          title: Row(
            children: [
              Text(
                petUserData['name'] ?? '',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              petUserData['gender'] == 'ตัวผู้'
                  ? const Icon(Icons.male, size: 20, color: Colors.purple)
                  : petUserData['gender'] == 'ตัวเมีย'
                      ? const Icon(Icons.female, size: 20, color: Colors.pink)
                      : const Icon(Icons.help_outline,
                          size: 20, color: Colors.black),
            ],
=======
          title: Text(
            petUserData['name'] ?? '',
            style: Theme.of(context).textTheme.titleLarge,
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
<<<<<<< HEAD
                '${petUserData['breed_pet'] ?? ''}',
=======
                'พันธุ์: ${petUserData['breed_pet'] ?? ''}',
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'ค่าผสมพันธุ์: ${petUserData['price'] ?? ''}',
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
<<<<<<< HEAD
                        title: Column(
                          children: [
                            Icon(LineAwesomeIcons.star_1,
                                color: Colors.yellow.shade800, size: 50),
                            SizedBox(height: 20),
                            Text('คุณต้องการที่จะลบการกดถูกใจ',
                                style: TextStyle(fontSize: 18)),
                          ],
                        ),
                        content: Text(
                          "${petUserData['name']} หรือไม่?",
                          style:
                              TextStyle(fontSize: 30, color: Colors.deepPurple),
                          textAlign: TextAlign.center,
                        ),
                        actions: <Widget>[
                          SizedBox(
                            height: 20,
                          ),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    height: 40,
                                    width: 100,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(right: 8),
                                            child: Icon(
                                              LineAwesomeIcons.times,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Text("ยกเลิก"),
                                        ],
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    height: 40,
                                    width: 100,
                                    child: TextButton(
                                      onPressed: () {
                                        _deletePetData(petUserData['pet_id']);
                                        Navigator.of(context).pop();
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(right: 8),
                                            child: Icon(
                                              LineAwesomeIcons.star,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Text("ยืนยัน"),
                                        ],
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
=======
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
                              // _deletePetData(petUserData['pet_id']);
                              Navigator.of(context).pop();
                            },
                            child: const Text("ยืนยัน"),
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
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
<<<<<<< HEAD

  void _deletePetData(String petId) async {
    try {
      // อ้างอิงถึงเอกสาร userId ในคอลเลกชัน favorites
      DocumentReference userFavoritesRef =
          FirebaseFirestore.instance.collection('favorites').doc(userId);

      // อ้างอิงถึงคอลเลกชันย่อย pet_favorite ในเอกสาร userId
      CollectionReference petFavoriteRef =
          userFavoritesRef.collection('pet_favorite');

      // ดึงเอกสารที่มี pet_respone ตรงกับ petId
      QuerySnapshot querySnapshot =
          await petFavoriteRef.where('pet_respone', isEqualTo: petId).get();

      if (querySnapshot.docs.isNotEmpty) {
        // สมมติว่า pet_id มีค่า unique ดังนั้นจะมีเอกสารเพียงเอกสารเดียว
        DocumentSnapshot docSnapshot = querySnapshot.docs.first;

        // ดึง id_fav จากเอกสาร
        String idFav = docSnapshot.get('id_fav');

        // อ้างอิงถึงเอกสารที่มี id_fav
        DocumentReference docRef = petFavoriteRef.doc(idFav);

        // ตรวจสอบเอกสารก่อนที่จะลบ
        DocumentSnapshot docToCheck = await docRef.get();

        if (docToCheck.exists) {
          // ลบเอกสารโดยใช้ id_fav
          await docRef.delete();

          // ดึงข้อมูลใหม่หลังจากลบสำเร็จ (ถ้าต้องการ)
          _getPetUserDataFromFirestore();

          print('Document with id_fav $idFav deleted successfully');
        } else {
          print('No document found with id_fav: $idFav');
        }
      } else {
        print('No document found with pet_id: $petId');
      }
    } catch (e) {
      print('Error deleting pet data: $e');
    }
  }
=======
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
}
