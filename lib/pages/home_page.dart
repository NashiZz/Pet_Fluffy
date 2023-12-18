import 'package:flutter/material.dart';
import 'package:google_login/pages/app_screen.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {

  signInwithGoogle() async {
    try {
      print("Hi Google Login");

      //auth ส่งไปยังระบบการยืนยันสิทธิ์ของ Firebase
      FirebaseAuth auth = FirebaseAuth.instance;
      //สร้างมาเก็บข้อมูลข้องผู้ใช้
      User? user;

      //gSn ส่งไปยังระบบการเข้าสู่ระบบของ Google
      final GoogleSignIn gSn = GoogleSignIn();

      //รอให้ผู้ใช้เข้าสู่ระบบด้วยบัญชี Google แล้วเก็บข้อมูลในตัวแปร gAcc
      final GoogleSignInAccount? gAcc = await gSn.signIn();

      //เช็คการเข้าสู่ระบบ
      if (gAcc != null) {
        //รอรับข้อมูลการยืนยันสิทธิ์จาก Google
        final GoogleSignInAuthentication gAuth = await gAcc.authentication;

        //สร้างข้อมูลประจำตัวสำหรับเข้าสู่ระบบ Firebase
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );

        try {
          //รอผลการเข้าสู่ระบบ
          final UserCredential userCredential = await auth.signInWithCredential(credential);
          user = userCredential.user;
          print(user?.email);
          print(user?.displayName);
          Navigator.push(context, MaterialPageRoute(builder: (context) => AppPage(user: user)));

        }on FirebaseAuthException catch (e) {
          print(e);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Google SignIn"),
      ),
      body: _googleSignInButton(),
    );
  }

  Widget _googleSignInButton() {
    return Center(
      child: SizedBox(
        height: 50,
        child: SignInButton(
          Buttons.google,
          text: "Sign up with Google",
          onPressed: () {
            signInwithGoogle();
          } ,
        ),
      ),
    );
  }
}
