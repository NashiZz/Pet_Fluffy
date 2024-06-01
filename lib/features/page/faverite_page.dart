import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
class FaveritePage extends StatefulWidget {
  const FaveritePage({Key? key}) : super(key: key);

  @override
  State<FaveritePage> createState() => _FaveritePageState();
}

class _FaveritePageState extends State<FaveritePage> {
  late List<Map<String, dynamic>> petUserDataList = [];
  late List<Map<String, dynamic>> getPetDataList = [];
  
  @override
  void initState() {
    super.initState();
    _getPetUserDataFromFirestore();
  }

  //ดึงข้อมูลจาก firebase 
  Future<void> _getPetUserDataFromFirestore() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('idPet');
      print('kuyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy');
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
          title: Text(
            petUserData['name'] ?? '',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'พันธุ์: ${petUserData['breed_pet'] ?? ''}',
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
}
