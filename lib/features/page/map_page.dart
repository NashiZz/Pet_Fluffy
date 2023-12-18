import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_login/features/page/login_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Maps_Page extends StatefulWidget {
  const Maps_Page({super.key});

  @override
  State<Maps_Page> createState() => _MapsPageState();
}

class _MapsPageState extends State<Maps_Page> {

  User? user = FirebaseAuth.instance.currentUser;

  static const LatLng _pGooglePlex = LatLng(37.4223, -122.0848);
  static const LatLng _pApplePlex = LatLng(37.3346, -122.0090);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(user!.displayName!),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Show Snackbar',
            onPressed: () async {
              await GoogleSignIn().signOut();
              FirebaseAuth.instance.signOut();
              print("Sign Out Success!!");
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => LoginPage()));
            },
          ),
        ],
      ),
      body: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _pGooglePlex,
            zoom: 13,
          ),
          markers: {
            Marker(
                markerId: MarkerId("_currentLocation"),
                icon: BitmapDescriptor.defaultMarker,
                position: _pApplePlex),
            Marker(
                markerId: MarkerId("_sourceLocation"),
                icon: BitmapDescriptor.defaultMarker,
                position: _pGooglePlex),
          }),
    );
  }
}
