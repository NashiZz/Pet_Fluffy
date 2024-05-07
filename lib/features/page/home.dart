import 'package:Pet_Fluffy/features/page/login_page.dart';
import 'package:Pet_Fluffy/features/page/sign_up_page.dart';
import 'package:flutter/material.dart';


// ignore: camel_case_types
class Home_Page extends StatefulWidget {
  const Home_Page({super.key});

  @override
  State<Home_Page> createState() => _HomePageState();
}

class _HomePageState extends State<Home_Page> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Image.asset('assets/images/Backgroud.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity),
          SafeArea(
              child: Center(
            child: Stack(
              children: [
                Positioned(
                  bottom: 350,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 250,
                      )
                    ],
                  ),
                ),
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()));
                      },
                      child: Container(
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                        child: const Center(
                          child: Text(
                            "เข้าสู่ระบบ",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignUpPage()));
                      },
                      child: Container(
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 5.0,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "สมัครสมาชิก",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 19,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
