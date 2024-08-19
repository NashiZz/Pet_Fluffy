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
    return WillPopScope(
      onWillPop: () async {
        // Return false to prevent the back action
        return false;
      },
      child: Scaffold(
        body: FutureBuilder(
          future: getLocation(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error fetching location data'));
            } else {
              return Container(
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _showLocationPickerDialog();
                          },
                          style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(const Size(
                                260, 40)), // กำหนดความกว้างและความสูงของปุ่ม
                          ),
                          child: const Text('เพิ่มตำแหน่ง'),
                        ),
                        const SizedBox(width: 20),
                        if (!_isLocationAdded)
                          ElevatedButton(
                            onPressed: () {
                              Get.to(() => const Setting_Pet_Page());
                            },
                            style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(const Size(
                                  260, 40)), // กำหนดความกว้างและความสูงของปุ่ม
                            ),
                            child: const Text('ต่อไป'),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _showLocationPickerDialog() async {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 20, right: 20, left: 20),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Text(
                        'เลือกตำแหน่งที่จะแสดงผลสัตว์เลี้ยง',
                        style:
                            TextStyle(fontSize: 18, color: Colors.deepPurple),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.maxFinite,
                  height: 500,
                  child: Padding(
                    padding: const EdgeInsets.all(
                        16.0), // Adjust the padding value as needed
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _locationData!.latitude!,
                          _locationData!.longitude!,
                        ),
                        zoom: 14.4746,
                      ),
                      onTap: (LatLng location) {
                        setState(() {
                          _selectedLocation = location;
                        });
                      },
                      markers: _selectedLocation == null
                          ? {}
                          : {
                              Marker(
                                markerId: const MarkerId('selected-location'),
                                position: _selectedLocation!,
                              ),
                            },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      if (_selectedLocation != null)
                        SizedBox(
                          width: double
                              .infinity, // Make the button take up the full width
                          child: ElevatedButton(
                            onPressed: () async {
                              _selectLocation(_selectedLocation!);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text(
                              'ยืนยันตำแหน่ง',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double
                            .infinity, // Make the button take up the full width
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('ยกเลิก'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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

  Future<void> getLocation() async {
    Location location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
  }

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
