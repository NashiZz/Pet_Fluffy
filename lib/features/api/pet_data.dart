// import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_auth/firebase_auth.dart';

class ApiPetService {
  //ดึงข้อมูลสัตว์ทั้งหมดมา random
  static Future<List<Map<String, dynamic>>> loadAllPet() async {
    try {
      // รับ UID ของผู้ใช้ปัจจุบัน
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // ดึงข้อมูลสัตว์เลี้ยงจาก Firestore
      QuerySnapshot<Map<String, dynamic>> petUserDocsSnapshot =
          await FirebaseFirestore.instance
              .collection('Pet_User')
              .where('user_id', isNotEqualTo: currentUserId)
              .get();

      List<Map<String, dynamic>> petList = [];

      for (var doc in petUserDocsSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        petList.add(data);
      }
      

      petList.shuffle();
      
      return petList;
    } catch (e) {
      print('Error loading pet locations from Firestore: $e');
      return [];
    }
  }

  static Stream<QuerySnapshot> getPetUserDataStream() {
    return FirebaseFirestore.instance.collection('Pet_User').snapshots();
  }
}
