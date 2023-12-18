import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_login/features/page/login_page.dart';
import 'package:google_login/pages/auth_service.dart';
import 'package:google_login/pages/home_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key, User? user});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {

  //รับข้อมูลผู้ใช้ที่เข้าสู่ระบบในปัจจุบัน 
  User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            //การเรียกใช้ข้อมูลผู้ใช้จาก Google Firebase
            CircleAvatar(
              backgroundImage: NetworkImage(user!.photoURL!),
              radius: 50,
            ),
            Padding(padding: EdgeInsets.all(20.0)),
            Text(user!.email!),
            Text(user!.displayName!),
            Padding(padding: EdgeInsets.all(100.0)),
            _googleSignInButton(),
          ],
        ),
      )
    );
  }

  //ปุ่ม Sign Out การออกจากระบบ
  Widget _googleSignInButton() {
    return Center(
      child: SizedBox(
        height: 50,
        child: SignInButton(
          Buttons.google,
          text: "Log Out",
          onPressed: () async{
           await GoogleSignIn().signOut();
           FirebaseAuth.instance.signOut();
           print("Sign Out Success!!");
           Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
          } ,
        ),
      ),
    );
  }

  Widget _userinfo() {
    return SizedBox();
  }
}