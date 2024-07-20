import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> loadPetData(String petId) async {
    DocumentSnapshot petDocSnapshot =
        await _firestore.collection('Pet_User').doc(petId).get();
    if (petDocSnapshot.exists) {
      return petDocSnapshot.data() as Map<String, dynamic>;
    }
    throw Exception('Document does not exist');
  }

  Future<List<String>> fetchVacData(String collectionName) async {
    QuerySnapshot querySnapshot =
        await _firestore.collection(collectionName).get();
    return querySnapshot.docs.map((doc) => doc['name'] as String).toList();
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('user').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future<void> saveReportToFirestore({
    required String userId,
    required String petId,
    required String date,
    required String description,
  }) async {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formatted =
        formatter.format(now.toUtc().add(Duration(hours: 7)));

    DocumentReference newData = await _firestore
        .collection('report_period')
        .doc(userId)
        .collection('pet_user')
        .add({
      'pet_id': petId,
      'date': date,
      'des': description,
      'created_at': formatted,
      'updates_at': formatted,
    });
    String docId = newData.id;
    await newData.update({'id_period': docId});
  }

  Future<void> saveImgsPetToFirestore({
    required String petId,
    required String img1,
    required String img2,
    required String img3,
    required String img4,
    required String img5,
    required String img6,
    required String img7,
    required String img8,
    required String img9,
  }) async {
    DocumentReference imgData = _firestore.collection('imgs_pet').doc(petId);

    // สร้างข้อมูลสำหรับการอัปเดต
    Map<String, String> updateData = {
      'pet_id': petId,
      'img_1': img1,
      'img_2': img2,
      'img_3': img3,
      'img_4': img4,
      'img_5': img5,
      'img_6': img6,
      'img_7': img7,
      'img_8': img8,
      'img_9': img9,
    };

    try {
      // เช็คว่ามีข้อมูลใน Firestore หรือไม่
      DocumentSnapshot doc = await imgData.get();
      if (doc.exists) {
        // ถ้ามีข้อมูลให้ทำการอัปเดต
        await imgData.set(updateData, SetOptions(merge: true));
        print("Image data updated in Firestore");
      } else {
        // ถ้าไม่มีข้อมูลให้เพิ่มข้อมูลใหม่
        await imgData.set(updateData);
        print("Image data added to Firestore");
      }
    } catch (error) {
      print("Failed to save image data: $error");
    }
  }

  Future<void> saveVaccineToFirestore({
    required String userId,
    required String petId,
    required String vacName,
    required String weight,
    required String price,
    required String date,
    required String status,
  }) async {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formatted =
        formatter.format(now.toUtc().add(Duration(hours: 7)));

    DocumentReference newData = await _firestore
        .collection('vac_history')
        .doc(userId)
        .collection('vac_pet')
        .add({
      'pet_id': petId,
      'vacName': vacName,
      'weight': weight,
      'price': price,
      'date': date,
      'status': status,
      'created_at': formatted,
      'updates_at': formatted,
    });
    String docId = newData.id;
    await newData.update({'id_period': docId});
  }

  Future<void> saveVaccine_MoreToFirestore({
    required String userId,
    required String petId,
    required String vacName,
    required String weight,
    required String price,
    required String location,
    required String date,
  }) async {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formatted =
        formatter.format(now.toUtc().add(Duration(hours: 7)));

    DocumentReference newData = await _firestore
        .collection('vac_more')
        .doc(userId)
        .collection('vac_pet')
        .add({
      'pet_id': petId,
      'vacName': vacName,
      'weight': weight,
      'price': price,
      'location': location,
      'date': date,
      'created_at': formatted,
      'updates_at': formatted,
    });
    String docId = newData.id;
    await newData.update({'id_period': docId});
  }
}
