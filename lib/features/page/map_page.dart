// ignore_for_file: camel_case_types, avoid_print, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:Pet_Fluffy/features/api/user_data.dart';
import 'package:Pet_Fluffy/features/page/owner_pet/profile_user.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

//หน้า Menu Maps ของ App
class Maps_Page extends StatefulWidget {
  const Maps_Page({super.key});

  @override
  State<Maps_Page> createState() => _MapsPageState();
}

class _MapsPageState extends State<Maps_Page> {
  User? user =
      FirebaseAuth.instance.currentUser; //ใช้เก็บข้อมูลของผู้ใช้ปัจจุบัน
  late List<Map<String, dynamic>> petUserDataList =
      []; //ใช้เก็บข้อมูลของสัตว์เลี้ยง
  LocationData? _locationData; //เก็บตำแหน่งข้อมูล as GPS
  late Location location;
  bool _isSelectingLocation = false;

  LatLng? _selectedLocation; //ใช้เก็บตำแหน่งที่ถูกเลือก
  final Set<Marker> _markers = {};
  StreamSubscription<LocationData>?
      _locationSubscription; //ติดตามการเปลี่ยนแปลงของตำแหน่งทางภูมิศาสตร์ที่มาจาก GPS

  late String petId;
  late String petImg;
  late String pet_type;
  late String gender;
  late String userId;
  late String userImageBase64;
  List<String> userAllImg = []; //เก็บรูปภาพไว้ show Maker บน Maps
  bool isLoading = true;
  bool isAnonymous = false;

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>(); //เก็บตัวควบคุมแผนที่

  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    location = Location();
    _getUserDataFromFirestore();
    _locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _locationData = currentLocation;
        _updateUserLocationMarker();
      });
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _getUserDataFromFirestore() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      userId = userData.uid;
      isAnonymous = userData.isAnonymous;
      if (isAnonymous) {
        setState(() {
          userImageBase64 = ''; // หรือคุณอาจจะใช้รูปภาพ default ที่คุณต้องการ
          isLoading = false;
        });
      } else {
        try {
          DocumentSnapshot idpetDocSnapshot = await FirebaseFirestore.instance
              .collection('Usage_pet')
              .doc(userId)
              .get();

          petId = idpetDocSnapshot['pet_id'];

          DocumentSnapshot petDocSnapshot = await FirebaseFirestore.instance
              .collection('Pet_User')
              .doc(petId)
              .get();

          petImg = petDocSnapshot['img_profile'];
          pet_type = petDocSnapshot['type_pet'];
          gender = petDocSnapshot['gender'];

          Map<String, dynamic>? userMap =
              await ApiUserService.getUserDataFromFirestore(userId);

          if (userMap != null) {
            userImageBase64 = userMap['photoURL'] ?? '';
            getLocation(); // เมื่อโหลดข้อมูลผู้ใช้เสร็จสิ้นแล้ว ก็โหลดตำแหน่งและแสดง Marker
          } else {
            print("User data does not exist");
          }
        } catch (e) {
          print('Error getting user data from Firestore: $e');
        }
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  String calculateDistance(LatLng start, LatLng end) {
    // คำนวณระยะทางในหน่วยเมตร
    double distanceInMeters = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );

    // ตรวจสอบและแปลงหน่วย
    if (distanceInMeters >= 1000) {
      // แปลงเป็นกิโลเมตรและคืนค่าเป็นสตริง
      double distanceInKilometers = distanceInMeters / 1000;
      return '${distanceInKilometers.toStringAsFixed(2)} กิโลเมตร';
    } else {
      // คืนค่าเป็นเมตร
      return '${distanceInMeters.toStringAsFixed(0)} เมตร';
    }
  }

  void _createUserLocationMarker() {
    _markers.add(Marker(
      markerId: const MarkerId('currentLocation'),
      position: LatLng(_locationData!.latitude!, _locationData!.longitude!),
      icon: BitmapDescriptor.defaultMarker,
      infoWindow: const InfoWindow(
        title: 'ตำแหน่งของคุณ',
        snippet: 'อยู่ที่นี่',
      ),
    ));
  }

  void _updateUserLocationMarker() {
    setState(() {
      _markers
          .removeWhere((marker) => marker.markerId.value == 'currentLocation');
      _createUserLocationMarker();
    });
  }

  void getLocation() async {
    _locationData = await location.getLocation();
    setState(() {
      _initialCameraPosition = CameraPosition(
        bearing: 192.8334901395799,
        target: LatLng(_locationData!.latitude!, _locationData!.longitude!),
        tilt: 59.4407176971435555,
        zoom: 19.151926040649414,
      );
      _createUserLocationMarker();
    });
    _goToTheLake();
    _loadAllPetLocations(context);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 15),
              Text('กำลังโหลดแผนที่ รอสักครู่....')
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              mapType: MapType.normal,
              initialCameraPosition: _initialCameraPosition,
              onTap: _isSelectingLocation ? _selectLocation : null,
              onMapCreated: (GoogleMapController controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
              markers: _markers,
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Card(
                elevation: 4,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        child: ClipOval(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const Profile_user_Page()),
                              );
                            },
                            child: isAnonymous
                                ? Image.asset(
                                    'assets/images/user-286-512.png', // ใส่ที่อยู่ของรูปภาพ default ที่คุณต้องการ
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  )
                                : petImg != null
                                    ? Image.memory(
                                        base64Decode(petImg),
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      )
                                    : const CircularProgressIndicator(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'ค้นหา',
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {},
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Add code for notification button
                        },
                        icon: const Icon(Icons.notifications),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _startSelectingLocation();
        },
        tooltip: 'Select Location',
        child: const Icon(Icons.location_on),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    controller
        .animateCamera(CameraUpdate.newCameraPosition(_initialCameraPosition));
  }

  //เลือกตำแหน่งแสดงผลสัตว์เลี้ยง
  void _startSelectingLocation() {
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

  //เก็บตำแหน่งที่เลือกมาเก็บไว้ในนี้และ บันทึกลงฐานข้อมูล
  void _selectLocation(LatLng position) {
    final Marker newMarker = Marker(
      markerId: const MarkerId('userSelectedLocation'),
      position: position,
    );

    setState(() {
      _markers.add(newMarker);
      _initialCameraPosition = CameraPosition(
        target: position,
        zoom: 14.0,
      );
      _isSelectingLocation = false;
    });

    _goToTheLake();
    _addLocationToFirestore(position);
  }

  //บันทึกข้อมูลตำแหน่ง lat lng ลงฐานข้อมูล
  void _addLocationToFirestore(LatLng position) async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      String userId = userData.uid;

      try {
        // ระบุคอลเลคชันที่จะใช้ใน Firestore
        DocumentReference userDocRef =
            FirebaseFirestore.instance.collection('user').doc(userId);

        // เพิ่มข้อมูลลงใน Firestore
        await userDocRef.update({
          'lat': position.latitude,
          'lng': position.longitude,
        });

        print('Location added to Firestore');
      } catch (e) {
        print('Error adding location to Firestore: $e');
      }
    }
  }

  // สร้างตัวแปร global เพื่อเก็บรูปภาพ marker ที่โหลดไว้ล่วงหน้า
  Map<String, Uint8List> markerImages = {};

  // เมธอดเพื่อโหลดรูปภาพล่วงหน้า
  Future<void> _preloadMarkerImages() async {
    QuerySnapshot<Map<String, dynamic>> petUserDocsSnapshot =
        await FirebaseFirestore.instance.collection('Pet_User').get();

    await Future.forEach(petUserDocsSnapshot.docs, (doc) async {
      Map<String, dynamic> data = doc.data();
      String petImageBase64 = data['img_profile'] ?? '';
      // Convert base64 encoded string to bytes
      Uint8List bytes = base64Decode(petImageBase64);
      // เก็บรูปภาพไว้ในรูปแบบที่สามารถเข้าถึงได้ต่อไป
      markerImages[doc.id] = bytes;
    });
  }

  //สร้าง Maker สำหรับแสดง รูปภาพสัตว์เลี้ยงของผู้ใช้ทั้งหมด
  Widget _createMarkerIcon(Uint8List markerImages) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.memory(
          markerImages,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  //คำนวณอายุสัตว์เลี้ยง
  String calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    int years = now.year - birthdate.year;
    int months = now.month - birthdate.month;

    if (months < 0) {
      years--;
      months += 12;
    }

    String ageString = '';
    if (years > 0) {
      ageString += '$years ขวบ';
      if (months > 0) {
        ageString += ' ';
      }
    }
    if (months > 0 || years == 0) {
      if (years == 0 && months == 0) {
        ageString = 'ไม่ถึง 1 เดือน';
      } else {
        ageString += '$months เดือน';
      }
    }

    return ageString;
  }

  // ดึงข้อมูลสัตว์เลี้ยงของผู้ใช้ทั้งหมด
  Future<void> _loadAllPetLocations(BuildContext context) async {
    try {
      setState(() {
        isLoading = true;
      });

      List<Marker> markers = [];
      List<String> errors = [];

      if (markerImages.isEmpty) {
        await _preloadMarkerImages();
      }

      // ดึงข้อมูลทั้งหมด
      QuerySnapshot<Map<String, dynamic>> petUserDocsSnapshot =
          await FirebaseFirestore.instance.collection('Pet_User').get();

      // ตำแหน่งของผู้ใช้
      LatLng userLocation = LatLng(
        _locationData?.latitude ?? 0.0,
        _locationData?.longitude ?? 0.0,
      );

      await Future.forEach(petUserDocsSnapshot.docs, (doc) async {
        Map<String, dynamic> data = doc.data();

        // ข้ามข้อมูลของสัตว์เลี้ยงที่เป็นของผู้ใช้เอง
        if (data['user_id'] == user?.uid) {
          return;
        }

        DocumentSnapshot userSnapshot =
            await ApiUserService.getUserData(data['user_id']);

        double lat = userSnapshot['lat'] ?? 0.0;
        double lng = userSnapshot['lng'] ?? 0.0;
        lat += Random().nextDouble() * 0.0002;
        lng += Random().nextDouble() * 0.0002;
        LatLng petLocation = LatLng(lat, lng);

        String petType = data['type_pet'] ?? '';
        String petGender = data['gender'] ?? '';

        // ตรวจสอบประเภทและเพศ
        if (petType == pet_type && petGender != gender) {
          String userPhotoURL = userSnapshot['photoURL'] ?? '';
          String petID = data['pet_id'] ?? '';
          String petName = data['name'] ?? '';
          String petImageBase64 = data['img_profile'] ?? '';
          String weight = data['weight'] ?? '0.0';
          String des = data['description'] ?? '';
          String birthdateStr = data['birthdate'] ?? '';
          DateTime birthdate = DateTime.parse(birthdateStr);
          String age = calculateAge(birthdate);

          Uint8List? bytes = markerImages[doc.id];
          if (bytes == null) {
            errors.add('Marker image not found for document ${doc.id}');
            return;
          }

          try {
            // คำนวณระยะห่าง
            String distanceStr = calculateDistance(userLocation, petLocation);

            Marker petMarker = Marker(
              markerId: MarkerId(doc.id),
              position: petLocation,
              onTap: () {
                _showPetDetails(
                  context,
                  petID,
                  petName,
                  petImageBase64,
                  weight,
                  petGender,
                  userPhotoURL,
                  age,
                  petType,
                  des,
                  distanceStr, // เพิ่มระยะห่างที่นี่
                );
              },
              icon: (await _createMarkerIcon(bytes).toBitmapDescriptor()),
              infoWindow: InfoWindow(
                title: petName,
                snippet: distanceStr,
              ),
            );

            markers.add(petMarker);
          } catch (e) {
            errors.add('Error creating marker for document ${doc.id}: $e');
          }
        }
      });

      _markers.addAll(markers);

      setState(() {
        isLoading = false;
      });

      if (errors.isNotEmpty) {
        for (var error in errors) {
          print(error);
        }
      }
    } catch (e) {
      print('Error loading pet locations from Firestore: $e');
    }
  }

  //Show Dialog เมื่อมีการคลิก Maker สัตว์เลี้ยง
  void _showPetDetails(
      BuildContext context,
      String petID,
      String petName,
      String petImageBase64,
      String weight,
      String gender,
      String userPhotoURL,
      String age,
      String type,
      String des,
      String distance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return FractionallySizedBox(
              heightFactor: constraints.maxHeight > constraints.maxWidth
                  ? 0.68
                  : constraints.maxHeight > 600
                      ? 0.65
                      : 0.8,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                icon: Icon(
                                  Icons.cancel_rounded,
                                  color: Colors.grey.shade800,
                                ),
                                iconSize: 40,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          Profile_pet_Page(petId: petID),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'ดูโปรไฟล์ทั้งหมด',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.transparent,
                            child: ClipOval(
                              child: Image.memory(
                                base64Decode(petImageBase64),
                                width: 160,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 25),
                            child: SizedBox(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        petName,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        type,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 20),
                                        child: Container(
                                          width: 45,
                                          height: 45,
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade200
                                                .withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Center(
                                            child: gender == 'ตัวผู้'
                                                ? const Icon(Icons.male,
                                                    size: 40,
                                                    color: Colors.purple)
                                                : gender == 'ตัวเมีย'
                                                    ? const Icon(Icons.female,
                                                        size: 40,
                                                        color: Colors.pink)
                                                    : const Icon(
                                                        Icons.help_outline,
                                                        size: 40,
                                                        color: Colors.black),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 20),
                                        child: Container(
                                          width: 50,
                                          height: 45,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade400
                                                .withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    age,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 45,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade300
                                              .withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  weight,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const Text('kg.')
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'คำอธิบาย',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.blue,
                                    ),
                                    Text(
                                      '  ห่าง ${distance}จากคุณ',
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 200,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 153, 148, 148)
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      des,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.blue.shade800.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: IconButton(
                                      onPressed: () {
                                        // Add your code to handle the "exit" action here
                                      },
                                      icon: const Icon(
                                        Icons.star_rounded,
                                        color: Colors.yellow,
                                      ),
                                      iconSize: 40,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.grey.shade500.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: Center(
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.transparent,
                                      child: ClipOval(
                                        child: Image.memory(
                                          base64Decode(userPhotoURL),
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade50,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: IconButton(
                                      onPressed: () {
                                        // Add your code to handle the "heart" action here
                                      },
                                      icon: Icon(
                                        Icons.favorite,
                                        color: Colors.pinkAccent.shade400,
                                      ),
                                      iconSize: 30,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
