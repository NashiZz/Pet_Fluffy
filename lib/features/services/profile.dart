import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> loadPetData(String petId) async {
    DocumentSnapshot petDocSnapshot = await _firestore.collection('Pet_User').doc(petId).get();
    if (petDocSnapshot.exists) {
      return petDocSnapshot.data() as Map<String, dynamic>;
    }
    throw Exception('Document does not exist');
  }

  Future<List<String>> fetchVacData(String collectionName) async {
    QuerySnapshot querySnapshot = await _firestore.collection(collectionName).get();
    return querySnapshot.docs.map((doc) => doc['name'] as String).toList();
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    DocumentSnapshot userDoc = await _firestore.collection('user').doc(userId).get();
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
    final String formatted = formatter.format(now.toUtc().add(Duration(hours: 7)));

    DocumentReference newData = await _firestore.collection('report_period').doc(userId).collection('pet_user').add({
      'pet_id': petId,
      'date': date,
      'des': description,
      'created_at': formatted,
      'updates_at': formatted,
    });
    String docId = newData.id;
    await newData.update({'id_period': docId});
  }

  Future<void> saveVaccineToFirestore({
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
    final String formatted = formatter.format(now.toUtc().add(Duration(hours: 7)));

    DocumentReference newData = await _firestore.collection('vac_history').doc(userId).collection('vac_pet').add({
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
