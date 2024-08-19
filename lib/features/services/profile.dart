import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<Map<String, dynamic>> loadPetdigreeData(
      String petId, String userId) async {
    QuerySnapshot petQuerySnapshot = await _firestore
        .collection('petdigree')
        .doc(userId)
        .collection('Data_Petdigree')
        .where('pet_id', isEqualTo: petId)
        .get();

    if (petQuerySnapshot.docs.isNotEmpty) {
      // Assuming you expect only one document with the given petId
      DocumentSnapshot petDocSnapshot = petQuerySnapshot.docs.first;
      return petDocSnapshot.data() as Map<String, dynamic>;
    }

    throw Exception('Document does not exist');
  }

  Future<List<String>> fetchVacDataDog(String collectionName) async {
    QuerySnapshot querySnapshot =
        await _firestore.collection(collectionName).doc('Qy38o0xCXKQlIngPz9jb').collection('vaccines_more').get();
    return querySnapshot.docs.map((doc) => doc['vaccine'] as String).toList();
  }

  Future<List<String>> fetchVacDataCat(String collectionName) async {
    QuerySnapshot querySnapshot =
        await _firestore.collection(collectionName).doc('5yWv1hawXz6Gh15gEed1').collection('vaccines_more').get();
    return querySnapshot.docs.map((doc) => doc['vaccine'] as String).toList();
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('user').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future<Uint8List?> pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      return await file.readAsBytes();
    } else {
      return null;
    }
  }

  Future<Uint8List?> compressImage(Uint8List image) async {
    try {
      List<int> compressedImage = await FlutterImageCompress.compressWithList(
        image,
        minHeight: 720, // ลดความสูงเป็น 720 pixel
        minWidth: 1280, // ลดความกว้างเป็น 1280 pixel
        quality: 85, // ลดคุณภาพรูปภาพเป็น 85%
      );
      return Uint8List.fromList(compressedImage);
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  Future<void> saveAwardToFirestore({
    required String userId,
    required String petId,
    required String nameAward,
    required String date,
    required String description,
    required String img1,
    required String img2,
  }) async {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formatted =
        formatter.format(now.toUtc().add(Duration(hours: 7)));

    DocumentReference newData = await _firestore
        .collection('contest_pet')
        .doc(userId)
        .collection('pet_contest')
        .add({
      'pet_id': petId,
      'award': nameAward,
      'date': date,
      'des': description,
      'img_1': img1,
      'img_2': img2,
      'created_at': formatted,
      'updates_at': formatted,
    });
    String docId = newData.id;
    await newData.update({'id_contest': docId});
  }

  Future<void> deleteAwardFromFirestore(String userId, docId) async {
    try {
      await _firestore
          .collection('contest_pet')
          .doc(userId)
          .collection('pet_contest')
          .doc(docId)
          .delete();
    } catch (e) {
      print('Error deleting contest data: $e');
      throw e;
    }
  }

  Future<void> updateAward_ToFirestore({
    required String docId,
    required String userId,
    required String nameAward,
    required String description,
    required String date,
    required String img1,
    required String img2,
  }) async {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formatted =
        formatter.format(now.toUtc().add(Duration(hours: 7)));

    await FirebaseFirestore.instance
        .collection('contest_pet')
        .doc(userId)
        .collection('pet_contest')
        .doc(docId)
        .update({
      'award': nameAward,
      'date': date,
      'des': description,
      'img_1': img1,
      'img_2': img2,
      'updates_at': formatted,
    });
  }

  Future<void> savePetDigreeToFirestore({
    required String userId,
    required String petId,
    required String numPet,
    required String numPetF,
    required String numPetM,
    required String img_PetDigree,
  }) async {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formatted =
        formatter.format(now.toUtc().add(Duration(hours: 7)));

    DocumentReference newData = await _firestore
        .collection('petdigree')
        .doc(userId)
        .collection('Data_Petdigree')
        .add({
      'pet_id': petId,
      'num_pet': numPet,
      'num_pet_f': numPetF,
      'num_pet_m': numPetM,
      'img_pet': img_PetDigree,
      'created_at': formatted,
      'updates_at': formatted,
    });
    String docId = newData.id;
    await newData.update({'id_petdigree': docId});
  }

  Future<void> updatePetdigree_ToFirestore({
    required String id_petdigree,
    required String userId,
    required String petId,
    required String numPet,
    required String numPetF,
    required String numPetM,
    required String img_PetDigree,
  }) async {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formatted =
        formatter.format(now.toUtc().add(Duration(hours: 7)));

    await FirebaseFirestore.instance
        .collection('petdigree')
        .doc(userId)
        .collection('Data_Petdigree')
        .doc(id_petdigree)
        .update({
      'num_pet': numPet,
      'num_pet_f': numPetF,
      'num_pet_m': numPetM,
      'img_pet': img_PetDigree,
      'updates_at': formatted,
    });
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
        .collection('period_pet')
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

  Future<void> deleteReportFromFirestore(
    String userId,
    periodId,
  ) async {
    try {
      await _firestore
          .collection('report_period')
          .doc(userId)
          .collection('period_pet')
          .doc(periodId)
          .delete();
      print("Document successfully deleted!");
    } catch (e) {
      print("Error removing document: $e");
    }
  }

  Future<void> updatePeriod_ToFirestore({
    required String docId,
    required String userId,
    required String petId,
    required String description,
    required String date,
  }) async {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formatted =
        formatter.format(now.toUtc().add(Duration(hours: 7)));

    await FirebaseFirestore.instance
        .collection('report_period')
        .doc(userId)
        .collection('period_pet')
        .doc(docId)
        .update({
      'des': description,
      'date': date,
      'updates_at': formatted,
    });
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

    // ตรวจสอบว่ามีเอกสารที่ตรงกันใน Firestore หรือไม่
    final QuerySnapshot querySnapshot = await _firestore
        .collection('vac_history')
        .doc(userId)
        .collection('vac_pet')
        .where('pet_id', isEqualTo: petId)
        .where('vacName', isEqualTo: vacName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // ถ้ามีเอกสารที่ตรงกัน
      final DocumentSnapshot existingDoc = querySnapshot.docs.first;
      final String docId = existingDoc.id;

      // อัปเดตเอกสารที่มีอยู่
      await _firestore
          .collection('vac_history')
          .doc(userId)
          .collection('vac_pet')
          .doc(docId)
          .update({
        'weight': weight,
        'price': price,
        'date': date,
        'status': status,
        'updates_at': formatted,
      });
    } else {
      // ถ้าไม่มีเอกสารที่ตรงกัน
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
      await newData.update({'id_vac': docId});
    }
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
    await newData.update({'id_vacmore': docId});
  }

  Future<void> deleteVaccine_MoreFromFirestore(String userId, docId) async {
    try {
      // ระบุ DocumentReference ที่ต้องการลบ
      DocumentReference docRef = _firestore
          .collection('vac_more')
          .doc(userId)
          .collection('vac_pet')
          .doc(docId);

      // ลบเอกสาร
      await docRef.delete();
      print('Document with ID $docId has been deleted successfully.');
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  Future<void> updateVaccine_MoreToFirestore({
    required String docId,
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

    await FirebaseFirestore.instance
        .collection('vac_more')
        .doc(userId)
        .collection('vac_pet')
        .doc(docId)
        .update({
      'vacName': vacName,
      'weight': weight,
      'price': price,
      'location': location,
      'date': date,
      'updates_at': formatted,
    });
  }
}
