import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_login/features/page/home.dart';
import 'package:google_login/features/page/map_page.dart';
import 'package:google_login/features/page/sign_up_page.dart';
import 'package:google_login/features/widgets/form_container_widget.dart';
import 'package:google_login/pages/app_screen.dart';
import 'package:google_login/pages/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSigning = false;

  //ใช้สำหรับการรับรองความถูกต้องด้วย Firebase Authentication
  final FirebaseAuthService _auth = FirebaseAuthService();

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  //ทำการลบตัวควบคุม หลังจากใช้งานเสร็จ เพื่อป้องกันการรั่วไหลของทรัพยากร
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Login"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Login",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 30,
              ),
              FormContainerWidget(
                controller: _emailController,
                hintText: "Email",
                isPasswordField: false,
              ),
              SizedBox(
                height: 10,
              ),
              FormContainerWidget(
                controller: _passwordController,
                hintText: "Password",
                isPasswordField: true,
              ),
              forgetPassword(context),
              SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () {
                  _signIn();
                },
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _isSigning ? CircularProgressIndicator(
                      color: Colors.white,) : Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10,),
              GestureDetector(
                onTap: () {
                  signInwithGoogle();

                },
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon(FontAwesomeIcons.google, color: Colors.white,),
                        SizedBox(width: 5,),
                        Text(
                          "Sign in with Google",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),


              SizedBox(
                height: 20,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?"),
                  SizedBox(
                    width: 5,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpPage()),
                            (route) => false,
                      );
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          Navigator.push(context, MaterialPageRoute(builder: (context) => Maps_Page()));

        }on FirebaseAuthException catch (e) {
          print(e);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  void _signIn() async {
    setState(() {
      _isSigning = true;
    });

    //ดึงค่าอีเมลและรหัสผ่านจากตัวควบคุม
    String email = _emailController.text;
    String password = _passwordController.text;

    //เข้าสู่ระบบด้วยอีเมลและรหัสผ่านที่ดึงมาจากฟอร์ม
    User? user = await _auth.signInWithEmailAndPassword(email, password);

    setState(() {
      _isSigning = false;
    });

    //ตรวจสอบการเข้าสู่ระบบ
    if (user != null) {
      print("User is Successfully sign-in");
      Navigator.push(context, MaterialPageRoute(builder: (context) => Maps_Page()));
    } else {
      print("Some error happend");
    }

  }

  Widget forgetPassword(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 35,
      alignment: Alignment.bottomRight,
      child: TextButton(child: Text("Forget Password", style: TextStyle(color: Colors.black54), textAlign: TextAlign.right,), onPressed: () {

      },),
    );
  }


}