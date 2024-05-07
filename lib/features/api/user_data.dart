// import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

class ApiUserService {
  //ดึงข้อมูลผู้ใช้ทั้งหมด
  static Future<Map<String, dynamic>?> getUserDataFromFirestore(
      String userId) async {
    try {
      DocumentSnapshot userDocSnapshot =
          await FirebaseFirestore.instance.collection('user').doc(userId).get();

      if (userDocSnapshot.exists) {
        return userDocSnapshot.data() as Map<String, dynamic>;
      } else {
        print("User data does not exist");
        return null;
      }
    } catch (e) {
      print('Error getting user data from Firestore: $e');
      return null;
    }
  }

  //ดึงข้อมูลรูปภาพของผู้ใช้ จาก user_id ที่ดึงมาจากสัตว์เลี้ยง
  static Future<DocumentSnapshot> getUserData(String userId) async {
    try {
      if (userId.isNotEmpty) {
        return await FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .get();
      } else {
        print("User ID is empty");
        return Future.error("User ID is empty");
      }
    } catch (e) {
      print('Error getting user data from Firestore: $e');
      return Future.error(e);
    }
  }
}
