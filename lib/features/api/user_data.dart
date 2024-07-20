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
  if (userId.isNotEmpty) {
    try {
      return await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .get();
    } catch (e) {
      print('Error getting user data from Firestore: $e');
      return Future.error('Error getting user data from Firestore: $e');
    }
  } else {
    // ignore: null_argument_to_non_null_type
    return Future.value(null); //
  }
}

}
