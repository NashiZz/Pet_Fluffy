// ignore_for_file: camel_case_types, avoid_print, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:Pet_Fluffy/features/api/user_data.dart';
import 'package:Pet_Fluffy/features/page/historyMatch.dart';
import 'package:Pet_Fluffy/features/page/owner_pet/profile_user.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  late double latUser;
  late double lngUser;
  late LatLng locationUser;

  LatLng? _selectedLocation; //ใช้เก็บตำแหน่งที่ถูกเลือก
  final Set<Marker> _markers = {};
  StreamSubscription<LocationData>?
      _locationSubscription; //ติดตามการเปลี่ยนแปลงของตำแหน่งทางภูมิศาสตร์ที่มาจาก GPS
  final TextEditingController _controllerSearch = TextEditingController();
  late String petId;
  String petImg = '';
  late String pet_type;
  late String gender;
  late String userId;
  late String userImageBase64;
  List<String> userAllImg = []; //เก็บรูปภาพไว้ show Maker บน Maps
  bool isLoading = true;
  bool isAnonymous = false;
  bool _isMapInitialized = false; // ใช้เพื่อตรวจสอบการโหลดแผนที่
  bool isAnonymousUser = false;
  String? search;
  String? _selectedDistance;
  String? _selectedAge;
  String? _selectedPrice;
  final TextEditingController _otherBreedController = TextEditingController();
  final TextEditingController _otherColor = TextEditingController();
  late List<Map<String, dynamic>> petDataMatchList = [];
  late List<Map<String, dynamic>> petDataFavoriteList = [];
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>(); //เก็บตัวควบคุมแผนที่

  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  final List<String> _Distance = [
    '0 - 500 เมตร',
    '500 - 1000 เมตร ',
    '1 - 5 กิโลเมตร',
    '5 - 20 กิโลเมตร',
    '20 - 100 กิโลเมตร',
    'มากกว่า 100 กิโลเมตร'
  ];
  final List<String> _Age = [
    '6 เดือน - 1 ปี',
    '1 ปี - 1 ปี 6 เดือน',
    '1 ปี 6 เดือน - 2 ปี',
    'มากกว่า 2 ปี'
  ];
  final List<String> _Price = [
    'น้อยกว่า 1000 บาท',
    '1000-5000 บาท',
    '5000-10000 บาท',
    '10000-30000 บาท',
    'มากกว่า 30000 บาท'
  ];

  @override
  void initState() {
    super.initState();
    location = Location();
    _locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _locationData = currentLocation;
        _updateUserLocationMarker();
      });
    });
    getLocation(); // เรียก getLocation ที่นี่
    _getUserDataFromFirestore();
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
          userImageBase64 = '';
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
            latUser = userMap['lat'] ?? '';
            lngUser = userMap['lng'] ?? '';
            locationUser = LatLng(latUser, lngUser);
          } else {
            print("User data does not exist");
          }
        } catch (e) {
          print('Error getting user data from Firestore: $e');
        }

        User? userData = FirebaseAuth.instance.currentUser;
        if (userData != null) {
          userId = user!.uid;
          try {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? petId = prefs.getString(userId.toString());
            QuerySnapshot petUserQuerySnapshot = await FirebaseFirestore
                .instance
                .collection('match')
                .where('pet_request', isEqualTo: petId)
                .get();

            // ดึงข้อมูลจากเอกสารในรูปแบบ Map<String, dynamic> และดึงเฉพาะฟิลด์ pet_respone
            List<dynamic> petResponses = petUserQuerySnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();

            // ประกาศตัวแปร เพื่อรอรับข้อมูลใน for
            List<Map<String, dynamic>> allPetDataList = [];

            // ลูปเพื่อดึงข้อมูลแต่ละรายการ
            for (var petRespone in petResponses) {
              String petResponeId = petRespone['pet_respone'];

              // ดึงข้อมูลจาก pet_user
              QuerySnapshot getPetQuerySnapshot = await FirebaseFirestore
                  .instance
                  .collection('Pet_User')
                  .where('pet_id', isEqualTo: petResponeId)
                  .where('type_pet', isEqualTo: pet_type)
                  .get();

              allPetDataList.addAll(getPetQuerySnapshot.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList());
            }
            // อัปเดต petUserDataList ด้วยข้อมูลทั้งหมดที่ได้รับ
            print(allPetDataList.length);
            setState(() {
              petDataMatchList = allPetDataList;
              isLoading = false;
            });
          } catch (e) {
            print('Error getting pet user data from Match: $e');
            setState(() {
              isLoading = false;
            });
          }

          // ส่วน Favorite
          try {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? petId = prefs.getString(userId.toString());
            // ดึงข้อมูลจากคอลเล็กชัน favorites
            QuerySnapshot petUserQuerySnapshot = await FirebaseFirestore
                .instance
                .collection('favorites')
                .doc(userId)
                .collection('pet_favorite')
                .where('pet_request', isEqualTo: petId)
                .get();

            // ดึงข้อมูลจากเอกสารในรูปแบบ Map<String, dynamic> และดึงเฉพาะฟิลด์ pet_respone
            List<dynamic> petResponses = petUserQuerySnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();

            // ประกาศตัวแปร เพื่อรอรับข้อมูลใน for
            List<Map<String, dynamic>> allPetDataList = [];

            // ลูปเพื่อดึงข้อมูลแต่ละรายการ
            for (var petRespone in petResponses) {
              String petResponeId = petRespone['pet_respone'];

              // ดึงข้อมูลจาก pet_user
              QuerySnapshot getPetQuerySnapshot = await FirebaseFirestore
                  .instance
                  .collection('Pet_User')
                  .where('pet_id', isEqualTo: petResponeId)
                  .where('type_pet', isEqualTo: pet_type)
                  .get();

              // เพิ่มข้อมูลลงใน List
              allPetDataList.addAll(getPetQuerySnapshot.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList());
            }

            // อัปเดต petUserDataList ด้วยข้อมูลทั้งหมดที่ได้รับ
            setState(() {
              petDataFavoriteList = allPetDataList;
              if (locationUser != null) {
                _markers.add(Marker(
                  markerId: MarkerId('user-location'),
                  position: locationUser,
                  infoWindow: InfoWindow(title: 'Your Location'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue),
                ));
              }
              isLoading = false;
            });
          } catch (e) {
            print('Error getting pet user data from Firestore: $e');
            setState(() {
              isLoading = false;
            });
          }
        }
      }
    }
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
      _isMapInitialized =
          true; // ตั้งค่าเป็น true เมื่อกำหนดค่าตำแหน่งเสร็จสิ้น
    });
    _goToTheLake();
    _loadAllPetLocations(context);
  }

  void _logSearchValue() {
    setState(() {
      _selectedDistance = null;
      _selectedAge = null;
      _otherBreedController.text = '';
      _otherColor.text = '';
      _selectedPrice = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchValue = _controllerSearch.text;
      search = searchValue.toString();
      // _getUsage_pet();
      location = Location();
      _locationSubscription =
          location.onLocationChanged.listen((LocationData currentLocation) {
        setState(() {
          _locationData = currentLocation;
          _updateUserLocationMarker();
        });
      });
      getLocation(); // เรียก getLocation ที่นี่
      _getUserDataFromFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isMapInitialized
            ? Stack(
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
                      controller.setMapStyle('''
                       [
                        {
                          "elementType": "geometry",
                          "stylers": [
                            {
                              "color": "#1d2c4d"
                            }
                          ]
                        },
                        {
                          "elementType": "labels.text.fill",
                          "stylers": [
                            {
                              "color": "#8ec3b9"
                            }
                          ]
                        },
                        {
                          "elementType": "labels.text.stroke",
                          "stylers": [
                            {
                              "color": "#1a3646"
                            }
                          ]
                        },
                        {
                          "featureType": "administrative.country",
                          "elementType": "geometry.stroke",
                          "stylers": [
                            {
                              "color": "#4b6878"
                            }
                          ]
                        },
                        {
                          "featureType": "administrative.land_parcel",
                          "elementType": "labels.text.fill",
                          "stylers": [
                            {
                              "color": "#64779e"
                            }
                          ]
                        },
                        {
                          "featureType": "administrative.province",
                          "elementType": "geometry.stroke",
                          "stylers": [
                            {
                              "color": "#4b6878"
                            }
                          ]
                        },
                        {
                          "featureType": "landscape.man_made",
                          "elementType": "geometry.stroke",
                          "stylers": [
                            {
                              "color": "#334e87"
                            }
                          ]
                        },
                        {
                          "featureType": "landscape.natural",
                          "elementType": "geometry",
                          "stylers": [
                            {
                              "color": "#023e58"
                            }
                          ]
                        },
                        {
                          "featureType": "poi",
                          "elementType": "geometry",
                          "stylers": [
                            {
                              "color": "#283d6a"
                            }
                          ]
                        },
                        {
                          "featureType": "poi",
                          "elementType": "labels.text.fill",
                          "stylers": [
                            {
                              "color": "#6f9ba5"
                            }
                          ]
                        },
                        {
                          "featureType": "poi",
                          "elementType": "labels.text.stroke",
                          "stylers": [
                            {
                              "color": "#1d2c4d"
                            }
                          ]
                        },
                        {
                          "featureType": "poi.park",
                          "elementType": "geometry.fill",
                          "stylers": [
                            {
                              "color": "#023e58"
                            }
                          ]
                        },
                        {
                          "featureType": "poi.park",
                          "elementType": "labels.text.fill",
                          "stylers": [
                            {
                              "color": "#3C7680"
                            }
                          ]
                        },
                        {
                          "featureType": "road",
                          "elementType": "geometry",
                          "stylers": [
                            {
                              "color": "#304a7d"
                            }
                          ]
                        },
                        {
                          "featureType": "road",
                          "elementType": "labels.text.fill",
                          "stylers": [
                            {
                              "color": "#98a5be"
                            }
                          ]
                        },
                        {
                          "featureType": "road",
                          "elementType": "labels.text.stroke",
                          "stylers": [
                            {
                              "color": "#1d2c4d"
                            }
                          ]
                        },
                        {
                          "featureType": "road.highway",
                          "elementType": "geometry",
                          "stylers": [
                            {
                              "color": "#2c6675"
                            }
                          ]
                        },
                        {
                          "featureType": "road.highway",
                          "elementType": "geometry.stroke",
                          "stylers": [
                            {
                              "color": "#255763"
                            }
                          ]
                        },
                        {
                          "featureType": "road.highway",
                          "elementType": "labels.text.fill",
                          "stylers": [
                            {
                              "color": "#b0d5ce"
                            }
                          ]
                        },
                        {
                          "featureType": "road.highway",
                          "elementType": "labels.text.stroke",
                          "stylers": [
                            {
                              "color": "#023e58"
                            }
                          ]
                        },
                        {
                          "featureType": "transit",
                          "elementType": "labels.text.fill",
                          "stylers": [
                            {
                              "color": "#98a5be"
                            }
                          ]
                        },
                        {
                          "featureType": "transit",
                          "elementType": "labels.text.stroke",
                          "stylers": [
                            {
                              "color": "#1d2c4d"
                            }
                          ]
                        },
                        {
                          "featureType": "transit.line",
                          "elementType": "geometry.fill",
                          "stylers": [
                            {
                              "color": "#283d6a"
                            }
                          ]
                        },
                        {
                          "featureType": "transit.station",
                          "elementType": "geometry",
                          "stylers": [
                            {
                              "color": "#3a4762"
                            }
                          ]
                        },
                        {
                          "featureType": "water",
                          "elementType": "geometry",
                          "stylers": [
                            {
                              "color": "#0e1626"
                            }
                          ]
                        },
                        {
                          "featureType": "water",
                          "elementType": "labels.text.fill",
                          "stylers": [
                            {
                              "color": "#4e6d70"
                            }
                          ]
                        }
                      ]
                      ''');
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            Row(
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
                                              'assets/images/user-286-512.png',
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                            )
                                          : petImg.isNotEmpty
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
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _controllerSearch,
                                    decoration: InputDecoration(
                                      hintText: 'ค้นหา',
                                      border: InputBorder.none,
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.search),
                                        onPressed: _logSearchValue,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: isAnonymousUser
                                      ? null
                                      : () {
                                          historyMatch();
                                        },
                                  icon: const Icon(
                                    Icons.favorite,
                                    color: Colors.pinkAccent,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled:
                                      true, // เพิ่มการตั้งค่านี้เพื่อให้สามารถเลื่อนขึ้นลงได้
                                  builder: (BuildContext context) {
                                    return SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.8, // ปรับขนาดความสูงตามต้องการ
                                      child: SingleChildScrollView(
                                        // เพิ่ม SingleChildScrollView เพื่อให้สามารถเลื่อนขึ้นลงได้
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              const Text('การค้นหาขั้นสูง',
                                                  style:
                                                      TextStyle(fontSize: 20)),
                                              const SizedBox(height: 15),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child:
                                                        DropdownButtonFormField<
                                                            String>(
                                                      value: _selectedDistance,
                                                      items: _Distance.map(
                                                          (String value) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: value,
                                                          child: Text(value),
                                                        );
                                                      }).toList(),
                                                      onChanged:
                                                          (String? newValue) {
                                                        setState(() {
                                                          _selectedDistance =
                                                              newValue;
                                                        });
                                                      },
                                                      decoration:
                                                          InputDecoration(
                                                        labelText:
                                                            'ระยะความห่าง',
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      30.0),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 10,
                                                          horizontal: 15,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 15),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child:
                                                        DropdownButtonFormField<
                                                            String>(
                                                      value: _selectedAge,
                                                      items: _Age.map(
                                                          (String value) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: value,
                                                          child: Text(value),
                                                        );
                                                      }).toList(),
                                                      onChanged:
                                                          (String? newValue) {
                                                        setState(() {
                                                          _selectedAge =
                                                              newValue;
                                                        });
                                                      },
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: 'ช่วงอายุ',
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      30.0),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 10,
                                                          horizontal: 15,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 15),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      style: const TextStyle(
                                                          fontSize: 15),
                                                      controller:
                                                          _otherBreedController,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: 'สายพันธุ์',
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      30.0),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 10,
                                                          horizontal: 15,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 15),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      style: const TextStyle(
                                                          fontSize: 15),
                                                      controller: _otherColor,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: 'สี',
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      30.0),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 10,
                                                          horizontal: 15,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 15),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child:
                                                        DropdownButtonFormField<
                                                            String>(
                                                      value: _selectedPrice,
                                                      items: _Price.map(
                                                          (String value) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: value,
                                                          child: Text(value),
                                                        );
                                                      }).toList(),
                                                      onChanged:
                                                          (String? newValue) {
                                                        setState(() {
                                                          _selectedPrice =
                                                              newValue;
                                                        });
                                                      },
                                                      decoration:
                                                          InputDecoration(
                                                        labelText:
                                                            'ราคา (ค่าผสมพันธุ์)',
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      30.0),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 10,
                                                          horizontal: 15,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 15),
                                              ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedDistance =
                                                        _selectedDistance;
                                                    _selectedAge = _selectedAge;
                                                    _otherBreedController.text =
                                                        _otherBreedController
                                                            .text;
                                                    _otherColor.text =
                                                        _otherColor.text;
                                                    _selectedPrice =
                                                        _selectedPrice;
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                ),
                                                child: const Text('ค้นหา',
                                                    style: TextStyle(
                                                        fontSize: 16)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                // ใช้ขนาดที่จำเป็นเท่านั้น
                                children: [
                                  Text(
                                    'ค้นหาขั้นสูง',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: const Color.fromARGB(
                                          255, 110, 110, 110), // สีของตัวอักษร
                                    ),
                                  ),
                                  const SizedBox(
                                      width:
                                          8.0), // ระยะห่างระหว่าง Text และ Icon
                                  Icon(
                                    Icons.keyboard_arrow_down_sharp,
                                    color: const Color.fromARGB(
                                        255, 110, 110, 110), // สีของไอคอน
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: () {
                        _startSelectingLocation();
                      },
                      tooltip: 'Add Pet Location',
                      child: const Icon(Icons.location_on),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 20,
                    child: FloatingActionButton(
                      onPressed: () {
                        _goToTheLake();
                      },
                      tooltip: 'My Location',
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    controller
        .animateCamera(CameraUpdate.newCameraPosition(_initialCameraPosition));
  }

  void _startSelectingLocation() async {
    // Fetch the user's location from Firestore
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();
    double userLat = userSnapshot['lat'];
    double userLng = userSnapshot['lng'];
    LatLng userLocation = LatLng(userLat, userLng);

    // Set the initial selected location to the fetched location
    _selectedLocation = userLocation;

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
                        target: userLocation,
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
                              _addLocationToFirestore(_selectedLocation!);
                              Navigator.pop(context);
                              _selectedLocation = null;
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text('ยืนยันตำแหน่ง',style: TextStyle(color: Colors.white),),
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

  void historyMatch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? petId = prefs.getString(userId.toString());

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            Historymatch_Page(
                idPet: petId.toString(), idUser: userId.toString()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
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
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.shade700,
          width: 6,
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

    if (now.day < birthdate.day) {
      months--;
    }

    if (months < 0) {
      years--;
      months += 12;
    }

    String ageString = '';
    if (years > 0) {
      ageString += '$years ปี';
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

      QuerySnapshot<Map<String, dynamic>> petUserDocsSnapshot =
          await FirebaseFirestore.instance.collection('Pet_User').get();

      LatLng userLocation = LatLng(
        _locationData?.latitude ?? 0.0,
        _locationData?.longitude ?? 0.0,
      );

      await Future.forEach(petUserDocsSnapshot.docs, (doc) async {
        Map<String, dynamic> data = doc.data();

        // พิมพ์ชื่อสัตว์เลี้ยง
        print('Processing pet: ${data['name']}');

        bool isMacth = false;
        bool isFavorite = false;

        for (var doc in petDataMatchList) {
          if (doc['pet_id'] == data['pet_id']) {
            isMacth = true;
            print('Skipped ${data['name']} (isMatch)');
            return;
          }
        }

        for (var doc in petDataFavoriteList) {
          if (doc['pet_id'] == data['pet_id']) {
            isFavorite = true;
            print('Skipped ${data['name']} (isFavorite)');
            return;
          }
        }

        if (!isMacth && !isFavorite) {
          if (_selectedDistance == null &&
              _selectedAge == null &&
              _otherBreedController.text.isEmpty &&
              _otherColor.text.isEmpty &&
              _selectedPrice == null) {
            if (search.toString() != 'null') {
              bool matchesName = data['name']
                  .toString()
                  .toLowerCase()
                  .contains(search.toString().toLowerCase());

              DateTime birthDate = DateTime.parse(data['birthdate']);
              DateTime now = DateTime.now();
              int yearsDifference = now.year - birthDate.year;
              int monthsDifference = now.month - birthDate.month;

              if (now.day < birthDate.day) {
                monthsDifference--;
              }

              if (monthsDifference < 0) {
                yearsDifference--;
                monthsDifference += 12;
              }

              String ageDifference = '$yearsDifferenceปี$monthsDifferenceเดือน';

              bool matchesAge = ageDifference
                  .toLowerCase()
                  .contains(search.toString().toLowerCase());

              bool matchesBreed = data['breed_pet']
                  .toString()
                  .toLowerCase()
                  .contains(search.toString().toLowerCase());

              bool matchesGender = data['gender']
                  .toString()
                  .toLowerCase()
                  .contains(search.toString().toLowerCase());

              bool matchesColor = data['color']
                  .toString()
                  .toLowerCase()
                  .contains(search.toString().toLowerCase());

              if (matchesName ||
                  matchesAge ||
                  matchesBreed ||
                  matchesGender ||
                  matchesColor) {
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
                String petStatus = data['status'] ?? '';

                if (petStatus == 'พร้อมผสมพันธุ์') {
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
                      errors
                          .add('Marker image not found for document ${doc.id}');
                      return;
                    }

                    try {
                      String distanceStr =
                          calculateDistance(userLocation, petLocation);
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
                            distanceStr,
                          );
                        },
                        icon: (await _createMarkerIcon(bytes)
                            .toBitmapDescriptor()),
                        infoWindow: InfoWindow(
                          title: petName,
                          snippet: distanceStr,
                        ),
                      );

                      markers.add(petMarker);
                      print('Added marker for ${data['name']}');
                    } catch (e) {
                      errors.add(
                          'Error creating marker for document ${doc.id}: $e');
                    }
                  }
                }
              } else {
                print('No match for search query: ${data['name']}');
              }
            } else {
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
              String petStatus = data['status'] ?? '';

              if (petStatus == 'พร้อมผสมพันธุ์') {
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
                    String distanceStr =
                        calculateDistance(userLocation, petLocation);

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
                          distanceStr,
                        );
                      },
                      icon:
                          (await _createMarkerIcon(bytes).toBitmapDescriptor()),
                      infoWindow: InfoWindow(
                        title: petName,
                        snippet: distanceStr,
                      ),
                    );

                    markers.add(petMarker);
                    print('Added marker for ${data['name']}');
                  } catch (e) {
                    errors.add(
                        'Error creating marker for document ${doc.id}: $e');
                  }
                }
              }
            }
          }
        } else {
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
          String petStatus = data['status'] ?? '';

          String distanceStr = calculateDistance(userLocation, petLocation);
          bool matchDistance =
              isDistanceRange(distanceStr, _selectedDistance.toString());
          bool matchesBreed = data['breed_pet']
              .toString()
              .toLowerCase()
              .contains(_otherBreedController.text.toLowerCase());

          DateTime birthDate = DateTime.parse(data['birthdate']);
          bool matchesAge = isAgeInRange(_selectedAge.toString(), birthDate);

          bool matchesColor = data['color']
              .toString()
              .toLowerCase()
              .contains(_otherColor.text.toLowerCase());

          bool matchesPrice = isPriceInRange(
              data['price'].toString(), _selectedPrice.toString());

          if (matchDistance &&
              matchesBreed &&
              matchesAge &&
              matchesColor &&
              matchesPrice) {
            print('Match found: ${data['name']}');
            // Add marker code here as necessary
          } else {
            print('No match for filters: ${data['name']}');
          }
        }
      });

      _markers.clear();
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

  int convertToMonths(String ageString) {
    int months = 0;
    RegExp regExp = RegExp(r'(\d+)\s*ปี');
    Match? match = regExp.firstMatch(ageString);
    if (match != null) {
      int years = int.parse(match.group(1)!);
      months += years * 12;
    }
    regExp = RegExp(r'(\d+)\s*เดือน');
    match = regExp.firstMatch(ageString);
    if (match != null) {
      int extraMonths = int.parse(match.group(1)!);
      months += extraMonths;
    }
    return months;
  }

  bool isAgeInRange(String ageRange, DateTime birthDate) {
    DateTime now = DateTime.now();
    int yearsDifference = now.year - birthDate.year;
    int monthsDifference = now.month - birthDate.month;

    if (now.day < birthDate.day) {
      monthsDifference--;
    }

    if (monthsDifference < 0) {
      yearsDifference--;
      monthsDifference += 12;
    }

    // แปลงอายุเป็นเดือน
    int totalMonths = yearsDifference * 12 + monthsDifference;

    // แปลงช่วงอายุเป็นเดือน
    List<String> parts = ageRange.split(' - ');
    if (parts.length == 2) {
      int minMonths = convertToMonths(parts[0]);
      int maxMonths = convertToMonths(parts[1]);

      // ตรวจสอบช่วงอายุ
      return totalMonths >= minMonths && totalMonths <= maxMonths;
    } else {
      // กรณีไม่มีการระบุช่วง เช่น 'มากกว่า 2 ปี'
      if (ageRange == 'มากกว่า 2 ปี') {
        return totalMonths > 24; // มากกว่า 24 เดือน
      }
    }

    return false;
  }

  bool isPriceInRange(String priceString, String selectedPrice) {
    // แปลงราคาที่เป็นข้อความเป็นตัวเลข
    double price = double.tryParse(priceString.replaceAll(',', '')) ?? 0.0;

    // แปลงช่วงราคาที่เลือก
    double? minPrice;
    double? maxPrice;

    // ตรวจสอบช่วงราคาที่เลือก
    if (selectedPrice.contains('น้อยกว่า')) {
      maxPrice = double.parse(selectedPrice
          .replaceAll('น้อยกว่า', '')
          .replaceAll(' บาท', '')
          .trim());
    } else if (selectedPrice.contains('มากกว่า')) {
      minPrice = double.parse(selectedPrice
          .replaceAll('มากกว่า', '')
          .replaceAll(' บาท', '')
          .trim());
    } else if (selectedPrice.contains('-')) {
      List<String> parts = selectedPrice.split('-');
      minPrice = double.parse(parts[0].replaceAll(' บาท', '').trim());
      maxPrice = double.parse(parts[1].replaceAll(' บาท', '').trim());
    }

    // ตรวจสอบว่าราคาอยู่ในช่วงที่เลือกหรือไม่
    if (minPrice != null && maxPrice != null) {
      return price >= minPrice && price <= maxPrice;
    } else if (minPrice != null) {
      return price > minPrice;
    } else if (maxPrice != null) {
      return price < maxPrice;
    } else {
      return false; // ไม่มีช่วงราคาที่กำหนด
    }
  }

  bool isDistanceRange(String distanceStr, String selectedRange) {
    // แปลง distanceStr เป็นค่าตัวเลข
    double distance = _parseDistance(distanceStr);

    // แปลง selectedRange เป็นช่วงระยะทาง
    List<double> range = _parseRange(selectedRange);

    // ตรวจสอบว่าระยะทางอยู่ในช่วงหรือไม่
    return distance >= range[0] && distance <= range[1];
  }

  double _parseDistance(String distanceStr) {
    final RegExp regex = RegExp(r'(\d+\.?\d*)\s*(กิโลเมตร|เมตร)');
    final match = regex.firstMatch(distanceStr);
    if (match != null) {
      double value = double.parse(match.group(1)!);
      String unit = match.group(2)!;

      // แปลงหน่วยเป็นเมตร
      if (unit == 'กิโลเมตร') {
        return value * 1000;
      } else {
        return value;
      }
    }
    return 0.0;
  }

  List<double> _parseRange(String rangeStr) {
    final RegExp regexRange = RegExp(r'(\d+)\s*-\s*(\d+)\s*(เมตร|กิโลเมตร)');
    final RegExp regexMoreThan = RegExp(r'มากกว่า\s*(\d+)\s*(เมตร|กิโลเมตร)');
    final matchRange = regexRange.firstMatch(rangeStr);
    final matchMoreThan = regexMoreThan.firstMatch(rangeStr);

    if (matchRange != null) {
      double start = double.parse(matchRange.group(1)!);
      double end = double.parse(matchRange.group(2)!);
      String unit = matchRange.group(3)!;

      // แปลงหน่วยเป็นเมตร
      if (unit == 'กิโลเมตร') {
        start *= 1000;
        end *= 1000;
      }

      return [start, end];
    } else if (matchMoreThan != null) {
      double start = double.parse(matchMoreThan.group(1)!);
      String unit = matchMoreThan.group(2)!;

      // แปลงหน่วยเป็นเมตร
      if (unit == 'กิโลเมตร') {
        start *= 1000;
      }

      return [
        start,
        double.infinity
      ]; // ใช้ double.infinity สำหรับค่าที่ไม่จำกัด
    }

    return [0.0, 0.0];
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
