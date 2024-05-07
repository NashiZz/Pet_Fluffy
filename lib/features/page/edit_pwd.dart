import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class EditPassPage extends StatefulWidget {
  const EditPassPage({Key? key}) : super(key: key);

  @override
  State<EditPassPage> createState() => _EditPassPageState();
}

class _EditPassPageState extends State<EditPassPage> {
  late User? user;
  late String userId;
  late Map<String, dynamic> userData = {};
  bool isSigningUp = false;

  late String userEmail = '';

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user!.uid;
      _getUserDataFromFirestore();
    }
  }

  Future<void> _getUserDataFromFirestore() async {
    try {
      DocumentSnapshot userDocSnapshot =
          await FirebaseFirestore.instance.collection('user').doc(userId).get();

      setState(() {
        userData = userDocSnapshot.data() as Map<String, dynamic>;
        userEmail = userData['email'] ?? '';
      });
    } catch (e) {
      print('Error getting user data from Firestore: $e');
    }
  }

  Future passwordReset() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          Future.delayed(const Duration(seconds: 5), () {
            Navigator.of(context).pop(true);
            Navigator.pop(context); 
          });
          return const AlertDialog(
            title: Text('Success'),
            content: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                  'ส่งลิงค์เปลี่ยนรหัสผ่านไปให้คุณแล้ว กรุณาเข้าไปตรวจสอบที่อีเมลของคุณ'),
            ),
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      print(e);
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(content: Text(e.message!));
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("เปลี่ยนรหัสผ่าน"),
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(LineAwesomeIcons.angle_left)),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  "กรุณากดปุ่ม เพื่อส่งลิงค์การเปลี่ยนรหัสผ่านไปที่ Email ของคุณ",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () {
                  passwordReset();
                },
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: isSigningUp
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "ส่ง",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            )),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
