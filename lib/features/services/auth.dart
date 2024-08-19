<<<<<<< HEAD
import 'dart:async';
=======
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
<<<<<<< HEAD
import 'package:googleapis_auth/auth_io.dart';
=======
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

<<<<<<< HEAD
  // เข้าสู่ระบบโดยไม่สมัครสมาชิก
  Future<User?> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print('Error during anonymous sign-in: $e');
      return null;
    }
  }

  bool isAnonymous() {
    User? user = _auth.currentUser;
    return user != null && user.isAnonymous;
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      // เข้าสู่ระบบด้วยอีเมลและรหัสผ่าน
=======
  // เข้าสู่ระบบด้วยอีเมลและรหัสผ่าน
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      //เข้าสู่ระบบด้วยบัญชีผู้ใช้ที่มีอยู่
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
<<<<<<< HEAD
        // จัดการข้อผิดพลาดเมื่ออีเมลหรือรหัสผ่านไม่ถูกต้อง
        print('Invalid email or password.');
      } else {
        // จัดการข้อผิดพลาดอื่นๆ
        print('An error occurred: ${e.code}');
      }
    } catch (e) {
      // จัดการข้อผิดพลาดทั่วไป
      print('An unexpected error occurred: $e');
    }
    return null;
  }

  // เข้าสู่ระบบด้วยอีเมลและรหัสผ่าน
  Future<User?> signInWithUsernameAndPassword(
      String username, String password) async {
    try {
      // ดึงข้อมูลของผู้ใช้จาก Firestore โดยใช้ชื่อผู้ใช้
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('user')
          .where('username', isEqualTo: username)
          .get();

      if (userQuery.docs.isNotEmpty) {
        // ใช้ข้อมูลผู้ใช้ที่ดึงมาเพื่อเข้าสู่ระบบ
        String email =
            userQuery.docs.first['email']; // ดึงอีเมลของผู้ใช้จากเอกสาร
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return userCredential.user;
      } else {
        print('Username not found.');
      }
    } on FirebaseAuthException catch (e) {
      // จัดการข้อผิดพลาดของ FirebaseAuthException
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        print('Invalid username or password.');
      } else {
        print('An error occurred: ${e.code}');
      }
    } catch (e) {
      // จัดการข้อผิดพลาดทั่วไป
      print('An unexpected error occurred: $e');
=======
        // showToast(message: 'Invalid email or password.');
      } else {
        // showToast(message: 'An error occurred: ${e.code}');
      }
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
    }
    return null;
  }

  // เข้าสู่ระบบด้วย Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        User? user = userCredential.user;

<<<<<<< HEAD
        // await saveUserGoogle(user!);

=======
        await saveUserGoogle(user!);
        
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
        return user;
      }
    } catch (error) {
      print("Error signing in with Google: $error");
      throw error;
    }

    return null;
  }

  // Check Email
  Future<bool> checkDuplicateEmail(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('user')
          .where('email', isEqualTo: email)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (error) {
      print('Error checking duplicate email: $error');
      return false;
    }
  }

  // SignUp email and password
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.sendEmailVerification();
      return userCredential;
    } catch (error) {
      print("Error creating user: $error");
      return null;
    }
  }

  // บันทึกข้อมูลผู้ใช้ที่ลงทะเบียนด้วย Google
<<<<<<< HEAD
  Future<void> saveUserGoogle(
    String uid,
    String username,
    String fullname,
    String email,
    String password,
    String image,
    String nickname,
    String phone,
    String facbook,
    String line,
    String? selectedGender,
    String birthdate,
    String? selectedCounty,
  ) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('user').doc(uid);
      final userData = await userRef.get();

      if (!userData.exists) {
        await userRef.set({
          'uid': uid,
          'username': username,
          'fullname': fullname,
          'email': email,
          'password': password,
          'photoURL': image,
          'phone': phone,
          'nickname': nickname,
          'gender': selectedGender,
          'birthdate': birthdate,
          'country': selectedCounty,
          'facebook': facbook,
          'line': line,
          'status': 'สมาชิก'
=======
  Future<void> saveUserGoogle(User user) async {
    try {
      final userRef =
          FirebaseFirestore.instance.collection('user').doc(user.uid);
      final userData = await userRef.get();
      String base64Image = await convertImageToBase64(user.photoURL!);

      if (!userData.exists) {
        await userRef.set({
          'uid': user.uid,
          'username': user.displayName,
          'fullname': '',
          'email': user.email,
          'password': '',
          'photoURL': base64Image,
          'phone': user.phoneNumber,
          'nickname': '',
          'gender': '',
          'birtdate': '',
          'country': '',
          'facebeook': '',
          'line': ''
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
        });
      }
    } catch (error) {
      throw error;
    }
  }

  // Save Data User
<<<<<<< HEAD
  Future<void> saveUserDataToFirestore(
      String userId,
      String username,
      String name,
      String email,
      String password,
      String? imageBase64, // เปลี่ยนชื่อเป็น imageBase64 เพื่อชัดเจน
      String nickname,
      String phone,
      String facebook,
      String line,
      String? gender,
      String? birthdate,
      String? county) async {
=======
  Future<void> saveUserDataToFirestore(String userId, String username,
      String name, String email, String password, Uint8List? image) async {
    String img = uint8ListToBase64(image!);
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
    DocumentReference userRef = _firestore.collection('user').doc(userId);

    await userRef.set({
      'uid': userId,
      'username': username,
      'fullname': name,
      'email': email,
      'password': password,
<<<<<<< HEAD
      'photoURL': imageBase64 ?? '', // ใช้ค่าว่างถ้า imageBase64 เป็น null
      'phone': phone,
      'nickname': nickname,
      'gender': gender ?? '',
      'birthdate': birthdate ?? '',
      'country': county ?? '',
      'facebook': facebook,
      'line': line,
      'status': 'สมาชิก'
=======
      'photoURL': img,
      'phone': '',
      'nickname': '',
      'gender': '',
      'birthdate': '',
      'country': '',
      'facebook': '',
      'line': ''
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
    }).then((_) {
      print("User data added to Firestore");
    }).catchError((error) {
      print("Failed to add user data: $error");
    });
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (error) {
      print("Error resetting password: $error");
      throw error;
    }
  }

  // Select Img
  Future<Uint8List?> pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      return await file.readAsBytes();
    } else {
      return null;
    }
  }

  // Compare Img to Base64
  String uint8ListToBase64(Uint8List image) {
    return base64Encode(image);
  }

  // แปลงรูปภาพให้เป็น Base64
  Future<String> convertImageToBase64(String imageUrl) async {
    http.Response response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      String base64Image = base64Encode(response.bodyBytes);
      return base64Image;
    } else {
      return '';
    }
  }
}
<<<<<<< HEAD

class FirebaseAccessToken {
  static String firebaseMsgScope =
      "https://www.googleapis.com/auth/firebase/firebase.messaging";
  Future<String> getToken() async {
    try {
      final credentials = ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": "",
        "private_key_id": " ",
        "private_key": "",
        "client_email": "",
        "client_id": "",
        "auth_uri": "",
        "token_uri": "",
        "auth_provider_x509_cert_url": "",
        "client_x509_cert_url": "",
        "universe_domain": "googleapis.com"
      });
      List<String> scopes = [
        "https://www.googleapis.com/auth/firebase.messaging"
      ];

      final client = await obtainAccessCredentialsViaServiceAccount(
          credentials, scopes, http.Client());
      final accessToken = client;
      Timer.periodic(const Duration(minutes: 59), (timer) {
        accessToken.refreshToken;
      });
      return accessToken.accessToken.data;
    } catch (e) {
      print(e);
    }

    return '';
  }
}
=======
>>>>>>> 071ad19bd082706dbb7cb72bf7b1da10402350a3
