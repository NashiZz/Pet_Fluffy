
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetNotiandLocationPage extends StatefulWidget {
  const SetNotiandLocationPage({Key? key}) : super(key: key);

  @override
  State<SetNotiandLocationPage> createState() => _SetNotiandLocationState();
}

class _SetNotiandLocationState extends State<SetNotiandLocationPage> {
  bool _isNotificationEnabled = false;
  bool isSavingSettings = false;

  @override
  void initState() {
    super.initState();
    requestNotificationPermissions();
    loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "ตั้งค่าการแจ้งเตือนและตำแหน่งที่ตั้ง",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              ListTile(
                title: const Text("เปิดการแจ้งเตือน"),
                trailing: Switch(
                  value: _isNotificationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isNotificationEnabled = value;
                      _toggleNotifications(value);
                    });
                  },
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _saveSettings,
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isSavingSettings
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "บันทึก",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void requestNotificationPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  void _toggleNotifications(bool isEnabled) async {
    if (isEnabled) {
      await FirebaseMessaging.instance.subscribeToTopic('all');
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic('all');
    }
  }


  void loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? false;
    });
  }

  void _saveSettings() async {
    setState(() {
      isSavingSettings = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationEnabled', _isNotificationEnabled);

    setState(() {
      isSavingSettings = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('บันทึกการตั้งค่าเรียบร้อยแล้ว'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
