// ignore_for_file: camel_case_types, avoid_print, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:Pet_Fluffy/features/api/user_data.dart';
import 'package:Pet_Fluffy/features/page/historyMatch.dart';
import 'package:Pet_Fluffy/features/page/owner_pet/profile_user.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/Profile_pet.dart';
import 'package:Pet_Fluffy/features/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
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
  FirebaseAccessToken firebaseAccessToken = FirebaseAccessToken();
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
  final TextEditingController _controllerSearch = TextEditingController();
  late String petId;
  String petImg = '';
  late String pet_type;
  late String petName;
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
  final AuthService _authService = AuthService();
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

  // void initState() {
  //   super.initState();
  //   location = Location();
  //   _locationSubscription =
  //       location.onLocationChanged.listen((LocationData currentLocation) {
  //     _updateUserLocationMarker();
  //     setState(() {
  //       _locationData = currentLocation;
  //       _loadSelectedLocation();
  //     });
  //   });
  //   getLocation(); // เรียก getLocation ที่นี่
  //   _getUserDataFromFirestore();
  // }

  @override
  void initState() {
    super.initState();
    location = Location();
    isAnonymousUser = _authService.isAnonymous();
    _locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _locationData = currentLocation;
        _updateUserLocationMarker();
        _loadSelectedLocation();
      });
    });

    // แยกการโหลดข้อมูลเป็นครั้งๆ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getLocation();
      _loadPetDataAsync();
    });
  }

  void _loadPetDataAsync() async {
    // ทำการโหลดข้อมูลสัตว์เลี้ยง
    _getUserDataFromFirestore();

    // โหลดข้อมูลแยกกันเพื่อไม่ให้หนักไปในครั้งเดียว
    _loadAllPetLocations(context);
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
          petName = petDocSnapshot['name'] ?? '';

          Map<String, dynamic>? userMap =
              await ApiUserService.getUserDataFromFirestore(userId);

          if (userMap != null) {
            userImageBase64 = userMap['photoURL'] ?? '';
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
            // ดึงข้อมูลจากคอลเล็กชัน favorites
            QuerySnapshot petUserQuerySnapshot = await FirebaseFirestore
                .instance
                .collection('match')
                .doc(userId)
                .collection('match_pet')
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
    if (_locationData != null) {
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
  }

  void _updateUserLocationMarker() {
    if (mounted) {
      setState(() {
        _markers.removeWhere(
            (marker) => marker.markerId.value == 'currentLocation');
        _createUserLocationMarker();
      });
    }
  }

  void getLocation() async {
    _locationData = await location.getLocation();
    if (_locationData != null) {
      setState(() {
        _initialCameraPosition = CameraPosition(
          bearing: 192.8334901395799,
          target: LatLng(_locationData!.latitude!, _locationData!.longitude!),
          tilt: 59.4407176971435555,
          zoom: 19.151926040649414,
        );
        _createUserLocationMarker();
        _isMapInitialized = true;
      });
      _goToTheLake();
    }
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
                                                    location = Location();
                                                    _locationSubscription =
                                                        location
                                                            .onLocationChanged
                                                            .listen((LocationData
                                                                currentLocation) {
                                                      setState(() {
                                                        _locationData =
                                                            currentLocation;
                                                        _updateUserLocationMarker();
                                                      });
                                                    });
                                                    getLocation(); // เรียก getLocation ที่นี่
                                                    _getUserDataFromFirestore();
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

  // ฟังก์ชันโหลดภาพจาก bytes
  Future<ui.Image> _loadImage(Uint8List imgBytes) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(imgBytes, (ui.Image img) {
      if (img != null) {
        completer.complete(img);
      } else {
        completer.completeError('Failed to decode image');
      }
    });
    return completer.future;
  }

  Future<BitmapDescriptor> _createCustomMarker(Uint8List imageBytes) async {
    final double markerSize = 120; // ขนาดของ Marker
    final double triangleHeight = 30; // ความสูงของสามเหลี่ยม

    // สร้าง ui.Image จาก bytes
    ui.Image image = await _loadImage(Uint8List.fromList(imageBytes));

    // ขนาดที่แท้จริงของ Canvas ที่รองรับทั้ง Marker และสามเหลี่ยม
    final double canvasWidth = markerSize;
    final double canvasHeight = markerSize + triangleHeight;

    // สร้าง Canvas สำหรับการวาดภาพ
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder,
        Rect.fromLTWH(0, 0, canvasWidth, canvasHeight)); // กำหนดขนาดของ Canvas

    // วาดพื้นหลังกลม
    final Paint circlePaint = Paint()
      ..color = Colors.blueAccent // สีพื้นหลัง
      ..style = PaintingStyle.fill; // เปลี่ยนเป็น fill สำหรับการเติมสี
    canvas.drawCircle(
        Offset(markerSize / 2, markerSize / 2), markerSize / 2, circlePaint);

    // วาดเงา
    final Paint shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(markerSize / 2, markerSize / 2 + 2),
        markerSize / 2, shadowPaint);

    // สร้าง Path เป็นรูปวงกลมเพื่อตัดภาพ (Clip)
    final Path clipPath = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(markerSize / 2, markerSize / 2),
          radius: markerSize / 2 - 8)); // ใช้ borderWidth เพื่อ Clip

    canvas.clipPath(clipPath);

    // วาดรูปภาพที่เป็น marker
    final double imageSize = markerSize - 16; // ลดขนาดให้เข้ากับขอบ
    canvas.drawImageRect(
      image,
      Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(8, 8, imageSize, imageSize),
      Paint(),
    );

    // วาด Polygon ที่มุมล่างให้เป็นรูปสามเหลี่ยมชี้ลง
    final Paint trianglePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill; // เปลี่ยนเป็น fill สำหรับการเติมสี
    final Path trianglePath = Path()
      ..moveTo(markerSize / 2 - 20, markerSize) // จุดซ้ายล่างของสามเหลี่ยม
      ..lineTo(markerSize / 2 + 20, markerSize) // จุดขวาล่างของสามเหลี่ยม
      ..lineTo(
          markerSize / 2, markerSize + triangleHeight) // จุดล่างสุดที่ชี้ลง
      ..close();

    // วาด Polygon
    canvas.drawPath(trianglePath, trianglePaint);

    // เพิ่มเงาให้กับสามเหลี่ยม
    canvas.drawPath(
        trianglePath.shift(Offset(0, 2)),
        Paint()
          ..color = Colors.black26
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4));

    // แปลง Canvas เป็น BitmapDescriptor
    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
          canvasWidth.toInt(),
          canvasHeight.toInt(),
        );

    final ByteData? byteData = await markerAsImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    final Uint8List markerBytes = byteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(markerBytes);
  }

  Future<void> _loadSelectedLocation() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      String userId = userData.uid;

      try {
        // ระบุคอลเลคชันที่จะใช้ใน Firestore
        DocumentReference userDocRef =
            FirebaseFirestore.instance.collection('user').doc(userId);

        DocumentSnapshot userDoc = await userDocRef.get();

        if (userDoc.exists) {
          // ดึงข้อมูล lat และ lng จาก Firestore
          double lat = userDoc.get('lat');
          double lng = userDoc.get('lng');

          // เก็บตำแหน่งใน _selectedLocation
          setState(() {
            _selectedLocation = LatLng(lat, lng);
          });

          // เพิ่ม Marker บนแผนที่
          await _addExistingMarker(LatLng(lat,
              lng)); // ใช้ await เพื่อให้แน่ใจว่า Marker ถูกเพิ่มก่อนที่จะอัปเดต UI
        }
      } catch (e) {
        print('Error loading location from Firestore: $e');
      }
    }
  }

  void _debugBase64Image(String base64String) {
    if (base64String == null || base64String.isEmpty) {
      print('Base64 string is null or empty');
    } else {
      print('Base64 string length: ${base64String.length}');
    }
  }

  Uint8List _base64ToUint8List(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error decoding Base64 string: $e');
      return Uint8List(0); // ส่งกลับ Uint8List ว่างเปล่า
    }
  }

  Future<void> _addExistingMarker(LatLng position) async {
    try {
      // ตรวจสอบ Base64 string
      _debugBase64Image(petImg);

      // แปลง Base64 string เป็น Uint8List
      Uint8List imageBytes = _base64ToUint8List(petImg);

      // ตรวจสอบว่าภาพถูกถอดรหัสอย่างถูกต้อง
      if (imageBytes.isEmpty) {
        throw Exception('Decoded image data is empty');
      }

      // สร้าง BitmapDescriptor ที่สวยงาม
      final BitmapDescriptor customIcon = await _createCustomMarker(imageBytes);

      // สร้าง Marker
      final Marker existingMarker = Marker(
        markerId: const MarkerId('userSelectedLocation'),
        position: position,
        icon: customIcon, // ใช้ไอคอนที่กำหนดเอง
        infoWindow: InfoWindow(
          title: '$petName',
          snippet: 'สัตว์เลี้ยงของคุณอยู่ที่นี่', // ข้อความเพิ่มเติม
        ),
      );

      setState(() {
        // ลบ Marker ที่มีอยู่ก่อนหน้าออกจากแผนที่
        _markers.removeWhere(
            (marker) => marker.markerId.value == 'userSelectedLocation');
        // เพิ่ม Marker ใหม่ที่ตำแหน่งใหม่
        _markers.add(existingMarker);
      });
    } catch (e) {
      print('Error loading pet icon: $e');
    }
  }

  //เลือกตำแหน่งแสดงผลสัตว์เลี้ยง
  void _startSelectingLocation() async {
    // สร้างตัวแปรเพื่อเก็บค่า markerId
    final String markerId = 'selected-location';

    showDialog(
      context: context,
      barrierDismissible: false,
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
                    padding: const EdgeInsets.all(16.0),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocation ??
                            LatLng(
                              _locationData!.latitude!,
                              _locationData!.longitude!,
                            ),
                        zoom: 14.4746,
                      ),
                      onTap: (LatLng location) async {
                        setState(() {
                          _selectedLocation = location;

                          // เพิ่ม Marker แบบปกติที่ตำแหน่งที่เลือก
                          _markers.removeWhere(
                              (marker) => marker.markerId.value == markerId);
                          _markers.add(
                            Marker(
                              markerId: MarkerId(markerId),
                              position: _selectedLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor
                                      .hueBlue), // Marker แบบปกติแต่เป็นสีฟ้า
                            ),
                          );
                        });
                      },
                      markers: Set<Marker>.of(_markers),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      if (_selectedLocation != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // อัปเดต Marker รูปสัตว์เลี้ยงที่ตำแหน่งใหม่
                              final Uint8List imageBytes = base64Decode(petImg);
                              final BitmapDescriptor customIcon =
                                  await _createCustomMarker(imageBytes);

                              setState(() {
                                // อัปเดต Marker รูปสัตว์เลี้ยงที่ตำแหน่งใหม่
                                _markers.removeWhere((marker) =>
                                    marker.markerId.value == markerId);
                                _markers.add(
                                  Marker(
                                    markerId: MarkerId(markerId),
                                    position: _selectedLocation!,
                                    icon: customIcon,
                                  ),
                                );
                              });

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
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // ลบ Marker สีฟ้าออกจากแผนที่เมื่อปิด Dialog
                            setState(() {
                              _markers.removeWhere((marker) =>
                                  marker.markerId.value == markerId);
                            });
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
          color: Colors.white,
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
      bool chekDataSearch = false;
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
      bool isAnonymousUser =
          FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
      await Future.forEach(petUserDocsSnapshot.docs, (doc) async {
        Map<String, dynamic> data = doc.data();
        if (isAnonymousUser) {
          if (_selectedDistance == null &&
              _selectedAge == null &&
              _otherBreedController.text == '' &&
              _otherColor.text == '' &&
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

                // ตรวจสอบประเภทและเพศ
                if (petStatus == 'พร้อมผสมพันธุ์') {
                  String userPhotoURL = userSnapshot['photoURL'] ?? '';
                  String petID = data['pet_id'] ?? '';
                  String petName = data['name'] ?? '';
                  String petImageBase64 = data['img_profile'] ?? '';
                  String weight = data['weight'] ?? '0.0';
                  String des = data['description'] ?? '';
                  String birthdateStr = data['birthdate'] ?? '';
                  DateTime birthdate = DateTime.parse(birthdateStr);
                  String age = calculateAge(birthdate);
                  String petUserId = data['user_id'];

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
                          distanceStr, // เพิ่มระยะห่างที่นี่
                          petUserId,
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
                  } catch (e) {
                    errors.add(
                        'Error creating marker for document ${doc.id}: $e');
                  }
                }
              } else {
                return;
              }
            } else {
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

              // ตรวจสอบประเภทและเพศ
              if (petStatus == 'พร้อมผสมพันธุ์') {
                String userPhotoURL = userSnapshot['photoURL'] ?? '';
                String petID = data['pet_id'] ?? '';
                String petName = data['name'] ?? '';
                String petImageBase64 = data['img_profile'] ?? '';
                String weight = data['weight'] ?? '0.0';
                String des = data['description'] ?? '';
                String birthdateStr = data['birthdate'] ?? '';
                DateTime birthdate = DateTime.parse(birthdateStr);
                String age = calculateAge(birthdate);
                String petUserId = data['user_id'];

                Uint8List? bytes = markerImages[doc.id];
                if (bytes == null) {
                  errors.add('Marker image not found for document ${doc.id}');
                  return;
                }

                try {
                  // คำนวณระยะห่าง
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
                          distanceStr, // เพิ่มระยะห่างที่นี่
                          petUserId);
                    },
                    icon: (await _createMarkerIcon(bytes).toBitmapDescriptor()),
                    infoWindow: InfoWindow(
                      title: petName,
                      snippet: distanceStr,
                    ),
                  );

                  markers.add(petMarker);
                } catch (e) {
                  errors
                      .add('Error creating marker for document ${doc.id}: $e');
                }
              }
            }
          } else {
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

            if (petStatus == 'พร้อมผสมพันธุ์') {
              if (_otherBreedController.text != '' &&
                  _selectedAge != null &&
                  _otherColor.text != '' &&
                  _selectedPrice != null &&
                  _selectedDistance != null) {
                if (matchesBreed &&
                    matchesAge &&
                    matchesColor &&
                    matchesPrice &&
                    matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge != null &&
                  _otherColor.text != '' &&
                  _selectedPrice != null &&
                  _selectedDistance != null) {
                if (matchesAge &&
                    matchesColor &&
                    matchesPrice &&
                    matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text != '' &&
                  _selectedAge == null &&
                  _otherColor.text != '' &&
                  _selectedPrice != null &&
                  _selectedDistance != null) {
                if (matchesBreed &&
                    matchesColor &&
                    matchesPrice &&
                    matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text != '' &&
                  _selectedAge != null &&
                  _otherColor.text == '' &&
                  _selectedPrice != null &&
                  _selectedDistance != null) {
                if (matchesBreed &&
                    matchesAge &&
                    matchesPrice &&
                    matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text != '' &&
                  _selectedAge != null &&
                  _otherColor.text != '' &&
                  _selectedPrice == null &&
                  _selectedDistance != null) {
                if (matchesBreed &&
                    matchesAge &&
                    matchesColor &&
                    matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text != '' &&
                  _selectedAge != null &&
                  _otherColor.text != '' &&
                  _selectedPrice != null &&
                  _selectedDistance == null) {
                if (matchesBreed &&
                    matchesAge &&
                    matchesColor &&
                    matchesPrice) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge == null &&
                  _otherColor.text != '' &&
                  _selectedPrice != null &&
                  _selectedDistance != null) {
                if (matchesColor && matchesPrice && matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge != null &&
                  _otherColor.text == '' &&
                  _selectedPrice != null &&
                  _selectedDistance != null) {
                if (matchesAge && matchesPrice && matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge != null &&
                  _otherColor.text != '' &&
                  _selectedPrice == null &&
                  _selectedDistance != null) {
                if (matchesAge && matchesColor && matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge != null &&
                  _otherColor.text != '' &&
                  _selectedPrice != null &&
                  _selectedDistance == null) {
                if (matchesAge && matchesColor && matchesPrice) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text != '' &&
                  _selectedAge == null &&
                  _otherColor.text == '' &&
                  _selectedPrice != null &&
                  _selectedDistance != null) {
                if (matchesBreed && matchesPrice && matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text != '' &&
                  _selectedAge == null &&
                  _otherColor.text != '' &&
                  _selectedPrice == null &&
                  _selectedDistance != null) {
                if (matchesBreed && matchesColor && matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text != '' &&
                  _selectedAge == null &&
                  _otherColor.text != '' &&
                  _selectedPrice != null &&
                  _selectedDistance == null) {
                if (matchesBreed && matchesColor && matchesPrice) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text != '' &&
                  _selectedAge != null &&
                  _otherColor.text == '' &&
                  _selectedPrice == null &&
                  _selectedDistance != null) {
                if (matchesBreed && matchesAge && matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text != '' &&
                  _selectedAge != null &&
                  _otherColor.text == '' &&
                  _selectedPrice != null &&
                  _selectedDistance == null) {
                if (matchesBreed && matchesAge && matchesPrice) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text != '' &&
                  _selectedAge != null &&
                  _otherColor.text != '' &&
                  _selectedPrice == null &&
                  _selectedDistance == null) {
                if (matchesBreed && matchesAge && matchesColor) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge == null &&
                  _otherColor.text == '' &&
                  _selectedPrice != null &&
                  _selectedDistance != null) {
                if (matchesPrice && matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge == null &&
                  _otherColor.text != '' &&
                  _selectedPrice == null &&
                  _selectedDistance != null) {
                if (matchesColor && matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge == null &&
                  _otherColor.text != '' &&
                  _selectedPrice != null &&
                  _selectedDistance == null) {
                if (matchesColor && matchesPrice) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge != null &&
                  _otherColor.text == '' &&
                  _selectedPrice == null &&
                  _selectedDistance != null) {
                if (matchesAge && matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge != null &&
                  _otherColor.text == '' &&
                  _selectedPrice != null &&
                  _selectedDistance == null) {
                if (matchesAge && matchesPrice) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge != null &&
                  _otherColor.text != '' &&
                  _selectedPrice == null &&
                  _selectedDistance == null) {
                if (matchesAge && matchesColor) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text != '' &&
                  _selectedAge == null &&
                  _otherColor.text == '' &&
                  _selectedPrice == null &&
                  _selectedDistance != null) {
                if (matchesBreed && matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text != '' &&
                  _selectedAge == null &&
                  _otherColor.text == '' &&
                  _selectedPrice != null &&
                  _selectedDistance == null) {
                if (matchesBreed && matchesPrice) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text != '' &&
                  _selectedAge == null &&
                  _otherColor.text != '' &&
                  _selectedPrice == null &&
                  _selectedDistance == null) {
                if (matchesBreed && matchesColor) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text != '' &&
                  _selectedAge != null &&
                  _otherColor.text == '' &&
                  _selectedPrice == null &&
                  _selectedDistance == null) {
                if (matchesBreed && matchesAge) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge == null &&
                  _otherColor.text == '' &&
                  _selectedPrice == null &&
                  _selectedDistance != null) {
                if (matchDistance) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge == null &&
                  _otherColor.text == '' &&
                  _selectedPrice != null &&
                  _selectedDistance == null) {
                if (matchesPrice) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge == null &&
                  _otherColor.text != '' &&
                  _selectedPrice == null &&
                  _selectedDistance == null) {
                if (matchesColor) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else if (_otherBreedController.text == '' &&
                  _selectedAge != null &&
                  _otherColor.text == '' &&
                  _selectedPrice == null &&
                  _selectedDistance == null) {
                if (matchesAge) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              } else {
                if (matchesBreed) {
                  chekDataSearch = true;
                } else {
                  chekDataSearch = false;
                }
              }

              if (chekDataSearch) {
                String userPhotoURL = userSnapshot['photoURL'] ?? '';
                String petID = data['pet_id'] ?? '';
                String petName = data['name'] ?? '';
                String petImageBase64 = data['img_profile'] ?? '';
                String weight = data['weight'] ?? '0.0';
                String des = data['description'] ?? '';
                String birthdateStr = data['birthdate'] ?? '';
                DateTime birthdate = DateTime.parse(birthdateStr);
                String age = calculateAge(birthdate);
                String petUserId = data['user_id'];

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
                          distanceStr, // เพิ่มระยะห่างที่นี่
                          petUserId);
                    },
                    icon: (await _createMarkerIcon(bytes).toBitmapDescriptor()),
                    infoWindow: InfoWindow(
                      title: petName,
                      snippet: distanceStr,
                    ),
                  );

                  markers.add(petMarker);
                } catch (e) {
                  errors
                      .add('Error creating marker for document ${doc.id}: $e');
                }
              }
            }
          }
        } else {
          bool isMacth = false;
          bool isFavorite = false;
          for (var doc in petDataMatchList) {
            if (doc['pet_id'] == data['pet_id']) {
              isMacth = true;
              // print('isMatch' + data['name'] + ' && '+doc['name']);
              return;
            }
          }
          for (var doc in petDataFavoriteList) {
            if (doc['pet_id'] == data['pet_id']) {
              isFavorite = true;
              // print('isFavorite' + data['name'] + ' && '+doc['name']);
              return;
            }
          }
          if (isMacth == false && isFavorite == false) {
            if (_selectedDistance == null &&
                _selectedAge == null &&
                _otherBreedController.text == '' &&
                _otherColor.text == '' &&
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

                String ageDifference =
                    '$yearsDifferenceปี$monthsDifferenceเดือน';

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

                  // ตรวจสอบประเภทและเพศ
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
                      String petUserId = data['user_id'];

                      Uint8List? bytes = markerImages[doc.id];
                      if (bytes == null) {
                        errors.add(
                            'Marker image not found for document ${doc.id}');
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
                              distanceStr, // เพิ่มระยะห่างที่นี่
                              petUserId,
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
                      } catch (e) {
                        errors.add(
                            'Error creating marker for document ${doc.id}: $e');
                      }
                    }
                  }
                } else {
                  return;
                }
              } else {
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
                String petStatus = data['status'] ?? '';

                // ตรวจสอบประเภทและเพศ
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
                    String petUserId = data['user_id'];

                    Uint8List? bytes = markerImages[doc.id];
                    if (bytes == null) {
                      errors
                          .add('Marker image not found for document ${doc.id}');
                      return;
                    }

                    try {
                      // คำนวณระยะห่าง
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
                              distanceStr, // เพิ่มระยะห่างที่นี่
                              petUserId);
                        },
                        icon: (await _createMarkerIcon(bytes)
                            .toBitmapDescriptor()),
                        infoWindow: InfoWindow(
                          title: petName,
                          snippet: distanceStr,
                        ),
                      );

                      markers.add(petMarker);
                    } catch (e) {
                      errors.add(
                          'Error creating marker for document ${doc.id}: $e');
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
              bool matchesAge =
                  isAgeInRange(_selectedAge.toString(), birthDate);
              bool matchesColor = data['color']
                  .toString()
                  .toLowerCase()
                  .contains(_otherColor.text.toLowerCase());
              bool matchesPrice = isPriceInRange(
                  data['price'].toString(), _selectedPrice.toString());

              if (petStatus == 'พร้อมผสมพันธุ์') {
                if (petType == pet_type && petGender != gender) {
                  print(data['name']);
                  print(matchesAge);
                  if (_otherBreedController.text != '' &&
                      _selectedAge != null &&
                      _otherColor.text != '' &&
                      _selectedPrice != null &&
                      _selectedDistance != null) {
                    if (matchesBreed &&
                        matchesAge &&
                        matchesColor &&
                        matchesPrice &&
                        matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge != null &&
                      _otherColor.text != '' &&
                      _selectedPrice != null &&
                      _selectedDistance != null) {
                    if (matchesAge &&
                        matchesColor &&
                        matchesPrice &&
                        matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text != '' &&
                      _selectedAge == null &&
                      _otherColor.text != '' &&
                      _selectedPrice != null &&
                      _selectedDistance != null) {
                    if (matchesBreed &&
                        matchesColor &&
                        matchesPrice &&
                        matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text != '' &&
                      _selectedAge != null &&
                      _otherColor.text == '' &&
                      _selectedPrice != null &&
                      _selectedDistance != null) {
                    if (matchesBreed &&
                        matchesAge &&
                        matchesPrice &&
                        matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text != '' &&
                      _selectedAge != null &&
                      _otherColor.text != '' &&
                      _selectedPrice == null &&
                      _selectedDistance != null) {
                    if (matchesBreed &&
                        matchesAge &&
                        matchesColor &&
                        matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text != '' &&
                      _selectedAge != null &&
                      _otherColor.text != '' &&
                      _selectedPrice != null &&
                      _selectedDistance == null) {
                    if (matchesBreed &&
                        matchesAge &&
                        matchesColor &&
                        matchesPrice) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge == null &&
                      _otherColor.text != '' &&
                      _selectedPrice != null &&
                      _selectedDistance != null) {
                    if (matchesColor && matchesPrice && matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge != null &&
                      _otherColor.text == '' &&
                      _selectedPrice != null &&
                      _selectedDistance != null) {
                    if (matchesAge && matchesPrice && matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge != null &&
                      _otherColor.text != '' &&
                      _selectedPrice == null &&
                      _selectedDistance != null) {
                    if (matchesAge && matchesColor && matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge != null &&
                      _otherColor.text != '' &&
                      _selectedPrice != null &&
                      _selectedDistance == null) {
                    if (matchesAge && matchesColor && matchesPrice) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text != '' &&
                      _selectedAge == null &&
                      _otherColor.text == '' &&
                      _selectedPrice != null &&
                      _selectedDistance != null) {
                    if (matchesBreed && matchesPrice && matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text != '' &&
                      _selectedAge == null &&
                      _otherColor.text != '' &&
                      _selectedPrice == null &&
                      _selectedDistance != null) {
                    if (matchesBreed && matchesColor && matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text != '' &&
                      _selectedAge == null &&
                      _otherColor.text != '' &&
                      _selectedPrice != null &&
                      _selectedDistance == null) {
                    if (matchesBreed && matchesColor && matchesPrice) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text != '' &&
                      _selectedAge != null &&
                      _otherColor.text == '' &&
                      _selectedPrice == null &&
                      _selectedDistance != null) {
                    if (matchesBreed && matchesAge && matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text != '' &&
                      _selectedAge != null &&
                      _otherColor.text == '' &&
                      _selectedPrice != null &&
                      _selectedDistance == null) {
                    if (matchesBreed && matchesAge && matchesPrice) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text != '' &&
                      _selectedAge != null &&
                      _otherColor.text != '' &&
                      _selectedPrice == null &&
                      _selectedDistance == null) {
                    if (matchesBreed && matchesAge && matchesColor) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge == null &&
                      _otherColor.text == '' &&
                      _selectedPrice != null &&
                      _selectedDistance != null) {
                    if (matchesPrice && matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge == null &&
                      _otherColor.text != '' &&
                      _selectedPrice == null &&
                      _selectedDistance != null) {
                    if (matchesColor && matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge == null &&
                      _otherColor.text != '' &&
                      _selectedPrice != null &&
                      _selectedDistance == null) {
                    if (matchesColor && matchesPrice) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge != null &&
                      _otherColor.text == '' &&
                      _selectedPrice == null &&
                      _selectedDistance != null) {
                    if (matchesAge && matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge != null &&
                      _otherColor.text == '' &&
                      _selectedPrice != null &&
                      _selectedDistance == null) {
                    if (matchesAge && matchesPrice) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge != null &&
                      _otherColor.text != '' &&
                      _selectedPrice == null &&
                      _selectedDistance == null) {
                    if (matchesAge && matchesColor) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text != '' &&
                      _selectedAge == null &&
                      _otherColor.text == '' &&
                      _selectedPrice == null &&
                      _selectedDistance != null) {
                    if (matchesBreed && matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text != '' &&
                      _selectedAge == null &&
                      _otherColor.text == '' &&
                      _selectedPrice != null &&
                      _selectedDistance == null) {
                    if (matchesBreed && matchesPrice) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text != '' &&
                      _selectedAge == null &&
                      _otherColor.text != '' &&
                      _selectedPrice == null &&
                      _selectedDistance == null) {
                    if (matchesBreed && matchesColor) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text != '' &&
                      _selectedAge != null &&
                      _otherColor.text == '' &&
                      _selectedPrice == null &&
                      _selectedDistance == null) {
                    if (matchesBreed && matchesAge) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge == null &&
                      _otherColor.text == '' &&
                      _selectedPrice == null &&
                      _selectedDistance != null) {
                    if (matchDistance) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge == null &&
                      _otherColor.text == '' &&
                      _selectedPrice != null &&
                      _selectedDistance == null) {
                    if (matchesPrice) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge == null &&
                      _otherColor.text != '' &&
                      _selectedPrice == null &&
                      _selectedDistance == null) {
                    if (matchesColor) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else if (_otherBreedController.text == '' &&
                      _selectedAge != null &&
                      _otherColor.text == '' &&
                      _selectedPrice == null &&
                      _selectedDistance == null) {
                    if (matchesAge) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  } else {
                    if (matchesBreed) {
                      chekDataSearch = true;
                    } else {
                      chekDataSearch = false;
                    }
                  }

                  if (chekDataSearch) {
                    String userPhotoURL = userSnapshot['photoURL'] ?? '';
                    String petID = data['pet_id'] ?? '';
                    String petName = data['name'] ?? '';
                    String petImageBase64 = data['img_profile'] ?? '';
                    String weight = data['weight'] ?? '0.0';
                    String des = data['description'] ?? '';
                    String birthdateStr = data['birthdate'] ?? '';
                    DateTime birthdate = DateTime.parse(birthdateStr);
                    String age = calculateAge(birthdate);
                    String petUserId = data['user_id'];

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
                              distanceStr, // เพิ่มระยะห่างที่นี่
                              petUserId);
                        },
                        icon: (await _createMarkerIcon(bytes)
                            .toBitmapDescriptor()),
                        infoWindow: InfoWindow(
                          title: petName,
                          snippet: distanceStr,
                        ),
                      );

                      markers.add(petMarker);
                    } catch (e) {
                      errors.add(
                          'Error creating marker for document ${doc.id}: $e');
                    }
                  }
                }
              }
            }
          }
        }
      });

      _markers.clear();
      _markers.addAll(markers);
      print(_markers.length);
      print(markers.length);

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

  void add_Faverite(String petIdd) async {
    // setState(() {
    //   isLoading = true;
    // });
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? petId = prefs.getString(userId.toString());
    String pet_request = petId.toString();
    String pet_respone = petIdd.toString();

    // รับวันและเวลาปัจจุบันในโซนเวลาไทย
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formatted =
        formatter.format(now.toUtc().add(Duration(hours: 7)));

    // อ้างอิงถึงเอกสาร userId ในคอลเลกชัน favorites
    DocumentReference userFavoritesRef =
        FirebaseFirestore.instance.collection('favorites').doc(userId);

    // อ้างอิงถึงคอลเลกชันย่อย pet_favorite ในเอกสาร userId
    CollectionReference petFavoriteRef =
        userFavoritesRef.collection('pet_favorite');

    try {
      // ตรวจสอบว่ามีเอกสารที่มี pet_request และ pet_respone เดียวกันอยู่หรือไม่
      QuerySnapshot querySnapshot = await petFavoriteRef
          .where('pet_request', isEqualTo: pet_request)
          .where('pet_respone', isEqualTo: pet_respone)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // ถ้ามีเอกสารที่ซ้ำกันอยู่แล้ว
        // setState(() {
        //   isLoading = false;
        // });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.of(context).pop(true); // ปิดไดอะล็อกหลังจาก 1 วินาที
            });
            return AlertDialog(
              title: Column(
                children: [
                  Icon(LineAwesomeIcons.star_1,
                      color: Colors.yellow.shade800, size: 50),
                  SizedBox(height: 20),
                  Text('คุณมีการกดถูกใจนี้อยู่แล้ว',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          },
        );
      } else {
        // ถ้าไม่มีเอกสารที่ซ้ำกันอยู่
        DocumentReference newPetfav = await petFavoriteRef.add({
          'created_at': formatted,
          'pet_request': pet_request,
          'pet_respone': pet_respone,
        });

        String docId = newPetfav.id;

        await newPetfav.update({'id_fav': docId});

        showDialog(
          context: context,
          builder: (BuildContext context) {
            Future.delayed(const Duration(seconds: 1), () {
              Navigator.of(context).pop(true); // ปิดไดอะล็อกหลังจาก 1 วินาที
            });
            return AlertDialog(
              title: Column(
                children: [
                  Icon(LineAwesomeIcons.star_1,
                      color: Colors.yellow.shade800, size: 50),
                  SizedBox(height: 20),
                  Text('เพิ่มการกดถูกใจเรียบร้อย',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          },
        );
      }
    } catch (error) {
      print("Failed to add pet: $error");

      setState(() {
        isLoading = false;
      });
    }
  }

  void add_match(String petIdd, petId, petUserId, String img_profile,
      String name_petrep, String des) async {
    String pet_request = petIdd.toString();
    String pet_respone = petId.toString();

    print(pet_request);
    print(pet_respone);

    // รับวันและเวลาปัจจุบันในโซนเวลาไทย
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formatted =
        formatter.format(now.toUtc().add(Duration(hours: 7)));

    CollectionReference petMatchRef =
        FirebaseFirestore.instance.collection('match');
    try {
      // ตรวจสอบว่ามีเอกสารที่มี pet_request และ pet_respone เดียวกันอยู่หรือไม่
      QuerySnapshot querySnapshot = await petMatchRef
          .where('pet_request', isEqualTo: pet_request)
          .where('pet_respone', isEqualTo: pet_respone)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // ถ้ามีเอกสารที่ซ้ำกันอยู่แล้ว ให้ทำการอัพเดตเอกสารนั้น
        querySnapshot.docs.forEach((doc) async {
          await doc.reference
              .update({'status': 'จับคู่แล้ว', 'updates_at': formatted});
        });

        // อ้างอิงถึงคอลเลกชันย่อย pet_favorite ในเอกสาร userId
        CollectionReference petMatchRef =
            FirebaseFirestore.instance.collection('match');

        try {
          // ตรวจสอบว่ามีเอกสารที่มี pet_request และ pet_respone เดียวกันอยู่หรือไม่
          QuerySnapshot querySnapshot = await petMatchRef
              .where('pet_request', isEqualTo: pet_request)
              .where('pet_respone', isEqualTo: pet_respone)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            // ถ้ามีเอกสารที่ซ้ำกันอยู่แล้ว
            setState(() {
              isLoading = false;
            });

            showDialog(
              context: context,
              builder: (BuildContext context) {
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.of(context)
                      .pop(true); // ปิดไดอะล็อกหลังจาก 1 วินาที
                });
                return const AlertDialog(
                  title: Text('Error'),
                  content: Text('สัตว์เลี้ยงนี้มีอยู่ในรายการแล้ว'),
                );
              },
            );
          }
        } catch (error) {
          print("Failed to add pet: $error");

          setState(() {
            isLoading = false;
          });
        }
      } else {
        // อ้างอิงถึงคอลเลกชันย่อย pet_favorite ในเอกสาร userId
        CollectionReference petMatchRef =
            FirebaseFirestore.instance.collection('match');

        try {
          // ตรวจสอบว่ามีเอกสารที่มี pet_request และ pet_respone เดียวกันอยู่หรือไม่
          QuerySnapshot querySnapshot = await petMatchRef
              .where('pet_request', isEqualTo: pet_request)
              .where('pet_respone', isEqualTo: pet_respone)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            // ถ้ามีเอกสารที่ซ้ำกันอยู่แล้ว
            setState(() {
              isLoading = false;
            });

            showDialog(
              context: context,
              builder: (BuildContext context) {
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.of(context)
                      .pop(true); // ปิดไดอะล็อกหลังจาก 1 วินาที
                });
                return const AlertDialog(
                  title: Text('Error'),
                  content: Text('สัตว์เลี้ยงนี้มีอยู่ในรายการแล้ว'),
                );
              },
            );
          } else {
            // ถ้าไม่มีเอกสารที่ซ้ำกันอยู่
            DocumentReference newPetMatch = await petMatchRef.add({
              'created_at': formatted,
              'description': des,
              'pet_request': pet_request,
              'pet_respone': pet_respone,
              'status': 'กำลังรอ',
              'updates_at': formatted
            });

            String docId = newPetMatch.id;

            await newPetMatch.update({'id_match': docId});

            sendNotificationToUser(
                userId, // ผู้ใช้เป้าหมายที่จะได้รับแจ้งเตือน
                pet_respone,
                "คุณมีคำขอใหม่!",
                "สัตว์เลี้ยง $name_petrep ของคุณได้รับคำขอจาก $petName ไปดูรายละเอียดได้เลย!");
            setState(() {
              isLoading = false;
            });
          }
        } catch (error) {
          print("Failed to add pet: $error");

          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (error) {
      print("Failed to add pet: $error");

      setState(() {
        isLoading = false;
      });
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
      String distance,
      String petUserId) {
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
                                        Colors.blue.shade800.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: IconButton(
                                      onPressed: () {
                                        add_Faverite(petID);
                                        Navigator.of(context).pop();
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
                                        _showRequestDialog(
                                            context,
                                            petName,
                                            petId,
                                            petID,
                                            petUserId,
                                            petImageBase64);
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

  void _showRequestDialog(
      BuildContext context, petName, petId, petID, petUserId, Img) {
    TextEditingController des = TextEditingController();
    print('pet request: $petId, pet respone: $petID, userID: $petUserId');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      'ส่งคำขอจับคู่ไปหา ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      petName,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade600),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 150,
                height: 120,
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.memory(
                      base64Decode(Img),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: des,
                decoration: InputDecoration(
                  hintText: 'พิมพ์ข้อความที่ต้องการส่งไปหา....',
                ),
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.deepPurpleAccent, // เปลี่ยนสีพื้นหลังของปุ่ม
                    ),
                    child: Text('ยกเลิกการส่งคำขอ',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      add_match(
                          petId, petID, petUserId, Img, petName, des.text);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.pinkAccent, // เปลี่ยนสีพื้นหลังของปุ่ม
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            LineAwesomeIcons.paper_plane_1,
                            color: Colors.white,
                          ),
                        ),
                        Text('ส่งคำขอ', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void sendNotificationToUser(
      String userIdd, String petRespone, String title, String body) async {
    try {
      // ตรวจสอบว่า userIdd ไม่ตรงกับผู้ใช้ปัจจุบัน (หมายถึงผู้ใช้ที่ถูกส่งคำขอ)
      if (userIdd != FirebaseAuth.instance.currentUser!.uid) {
        // ดึงข้อมูลผู้ใช้จาก Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('user')
            .doc(userIdd)
            .get();

        // ดึง FCM Token ของผู้ใช้จากข้อมูลที่ได้มา
        String? fcmToken = userDoc['fcm_token'];

        if (fcmToken != null) {
          // ส่งการแจ้งเตือนโดยเรียกใช้ฟังก์ชัน sendPushMessage
          await sendPushMessage(fcmToken, title, body);

          // บันทึกข้อมูลการแจ้งเตือนลงใน Firestore
          await _saveNotificationToFirestore(userIdd, petRespone, title, body);
        } else {
          print("FCM Token is null, unable to send notification");
        }
      } else {
        print(
            "No notification sent because the user is the one who made the request.");
      }
    } catch (error) {
      print("Error sending notification to user: $error");
    }
  }

  Future<void> _saveNotificationToFirestore(
      String userId, String petId, String title, String body) async {
    try {
      // รับวันและเวลาปัจจุบันในโซนเวลาไทย
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      final String formattedDate =
          formatter.format(now.toUtc().add(Duration(hours: 7)));

      // อ้างอิงถึงคอลเลกชัน notifications ในเอกสาร userId
      CollectionReference notificationsRef = FirebaseFirestore.instance
          .collection('notification')
          .doc(userId)
          .collection('pet_notification');

      // เพิ่มเอกสารใหม่ลงในคอลเลกชัน notifications
      await notificationsRef.add({
        'pet_id': petId, // เพิ่มข้อมูล pet_id
        'title': title,
        'body': body,
        'status': 'unread', // สถานะเริ่มต้นเป็น 'unread'
        'created_at': formattedDate,
        'scheduled_at': formattedDate, // เวลาที่การแจ้งเตือนถูกตั้งค่า
      });

      print("Notification saved to Firestore successfully");
    } catch (error) {
      print("Error saving notification to Firestore: $error");
    }
  }

  Future<void> sendPushMessage(
      String token_user, String title, String body) async {
    try {
      print("Sending notification to token: $token_user");

      // ดึง Firebase Access Token
      String token = await firebaseAccessToken.getToken();

      final data = {
        "message": {
          "token": token_user,
          "notification": {"title": title, "body": body}
        }
      };

      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/login-3c8fb/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print("Notification sent successfully");
      } else {
        print("Failed to send notification");
        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (error) {
      print("Error sending notification: $error");
    }
  }
}
