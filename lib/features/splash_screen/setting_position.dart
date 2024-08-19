// ignore_for_file: unnecessary_null_comparison

import 'dart:async';

import 'package:Pet_Fluffy/features/page/navigator_page.dart';
import 'package:Pet_Fluffy/features/splash_screen/setting_pet.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

//หน้า Set ตำแหน่ง Pet ก่อนใช้งาน 
class LocationSelectionPage extends StatefulWidget {
  const LocationSelectionPage({super.key});

  @override
  _LocationSelectionPageState createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  LatLng? _selectedLocation;
  LocationData? _locationData;
  final Set<Marker> _markers = {};

  bool _isLocationAdded = true;

  @override
  void initState() {
    super.initState();
    getLocation(); //เพื่อดึงข้อมูลตำแหน่งที่ตั้งของผู้ใช้
    checkLocationData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_location_alt_rounded,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(
              height: 20,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'ก่อนเริ่มใช้งานแอป กรุณาเพิ่มตำแหน่งในการแสดงบนแผนที่ของสัตว์เลี้ยงคุณ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showLocationPickerDialog();
                  },
                  style: ButtonStyle(
                    minimumSize: WidgetStateProperty.all(
                        const Size(260, 40)), // กำหนดความกว้างและความสูงของปุ่ม
                  ),
                  child: const Text('เพิ่มแหน่ง'),
                ),
                const SizedBox(width: 20),
                if (!_isLocationAdded) ...[
                  ElevatedButton(
                    onPressed: () {
                      Get.to(() => const Setting_Pet_Page());
                    },
                    style: ButtonStyle(
                      minimumSize: WidgetStateProperty.all(const Size(
                          260, 40)), // กำหนดความกว้างและความสูงของปุ่ม
                    ),
                    child: const Text('ต่อไป'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Show Dialog Map ขึ้นมา
  void _showLocationPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SizedBox(
              width: double.maxFinite,
              height: 500,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_locationData != null)
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _locationData!.latitude!,
                          _locationData!.longitude!,
                        ),
                        zoom: 14,
                      ),
                      onTap: (LatLng latLng) {
                        setState(() {
                          _selectedLocation = latLng;
                        });
                      },
                      markers: _selectedLocation != null
                          ? {
                              Marker(
                                markerId: const MarkerId('selectedLocation'),
                                position: _selectedLocation!,
                              )
                            }
                          : {},
                    ),
                  const Positioned(
                    top: 10,
                    child: Text(
                      'เลือกตำแหน่งที่ตั้งสัตว์เลี้ยงของคุณ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_selectedLocation != null)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: ElevatedButton(
                        onPressed: () {
                          _selectLocation(_selectedLocation!);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Select'),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  // หลังจากผู้ใช้เลือกตำแหน่งจะมาทำงานในนี้ต่อ
  void _selectLocation(LatLng position) {
    final Marker newMarker = Marker(
      markerId: const MarkerId('userSelectedLocation'),
      position: position,
    );

    setState(() {
      _markers.add(newMarker);
    });

    _saveLocationToFirestore(position);
  }

  //ดึงเอาตำแหน่งปัจจุบันของผู้ใช้
  void getLocation() async {
    Location location = Location();
    _locationData = await location.getLocation();
  }

  // บันทึกข้อมูลลงฐานข้อมูล
  Future<void> _saveLocationToFirestore(LatLng location) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;
        final userData = {
          'location': GeoPoint(location.latitude, location.longitude)
        };

        DocumentReference userDocRef =
            FirebaseFirestore.instance.collection('user').doc(userId);

        await userDocRef.update({
          'lat': userData['location']?.latitude,
          'lng': userData['location']?.longitude,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกตำแหน่งสำเร็จ'),
          ),
        );
        setState(() {
          _isLocationAdded = false;
        });
      }
    } catch (error) {
      print('เกิดข้อผิดพลาดในการบันทึกตำแหน่ง: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการบันทึกตำแหน่ง'),
        ),
      );
    }
  }

  // ทำการเช็คว่า ถ้าผู้ใช้มีการตั้งค่า ตำแหน่งแล้วให้ผู้ใช้ไปหน้าอื่น
  void checkLocationData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      final userDocRef =
          FirebaseFirestore.instance.collection('user').doc(userId);
      final userData = await userDocRef.get();

      if (userData.exists) {
        final lat = userData.data()?['lat'];
        final lng = userData.data()?['lng'];

        if (lat != null && lng != null) {
          // ถ้ามีค่า lat และ lng ใน Firestore ให้เปลี่ยนไปยังหน้าอื่น
          Get.to(() => const Navigator_Page(initialIndex: 0));
        }
      }
    }
  }
}
