import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_login/features/page/login_page.dart';
import 'package:google_login/pages/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Home_Page extends StatefulWidget {
  const Home_Page({super.key});

  @override
  State<Home_Page> createState() => _HomePageState();
}

class _HomePageState extends State<Home_Page> {

  //รับข้อมูลผู้ใช้ที่เข้าสู่ระบบในปัจจุบัน 
  User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text("HomePage"),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
                child: Text(
              "Welcome Home buddy!",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            )),
            Padding(padding: EdgeInsets.all(20.0)),
            //การเรียกใช้ข้อมูลผู้ใช้จาก Google Firebase
            Text(user!.email!),
            Padding(padding: EdgeInsets.all(100.0)),
            SizedBox(
              height: 30,
            ),
            GestureDetector(
              //ปุ่ม Sign Out การออกจากระบบ
              onTap: () async {
                await GoogleSignIn().signOut();
                FirebaseAuth.instance.signOut();
                print("Sign Out Success!!");
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
              },
              child: Container(
                height: 45,
                width: 100,
                decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    "Sign out",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
              ),
            )
          ],
        ));
  }
}