import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:intl/intl.dart';

class NotificationMore_Page extends StatefulWidget {
  final String idPet;
  const NotificationMore_Page({Key? key, required this.idPet})
      : super(key: key);

  @override
  State<NotificationMore_Page> createState() => _NotificationMore_PageState();
}

class _NotificationMore_PageState extends State<NotificationMore_Page> {
  late List<Map<String, dynamic>> petUserDataList_wait = [];
  bool isLoading = true;

  User? user = FirebaseAuth.instance.currentUser;
  late String userId;

  @override
  void initState() {
    super.initState();
    _getNotificationData(); // Fetch notifications
  }

  Future<void> _getNotificationData() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      userId = userData.uid;
      try {
        QuerySnapshot notificationQuerySnapshot = await FirebaseFirestore
            .instance
            .collection('notification')
            .doc(userId)
            .collection('pet_notification')
            .get();

        List<Map<String, dynamic>> notifications =
            notificationQuerySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'title': data['title'],
            'body': data['body'],
            'date': data['date'],
            'pet_type': data['pet_type'],
            'scheduled_at': data['scheduled_at'],
            'id': doc.id,
          };
        }).toList();

        // Sort notifications by date in descending order
        notifications.sort((a, b) {
          DateTime dateA = DateTime.parse(a['scheduled_at']);
          DateTime dateB = DateTime.parse(b['scheduled_at']);
          return dateB.compareTo(dateA); // Descending order
        });

        setState(() {
          petUserDataList_wait = notifications;
          isLoading = false;
        });
      } catch (e) {
        print('Error getting notification data from Firestore: $e');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Group notifications by date
  Map<String, List<Map<String, dynamic>>> _groupNotificationsByDate(
      List<Map<String, dynamic>> notifications) {
    Map<String, List<Map<String, dynamic>>> groupedNotifications = {};

    for (var notification in notifications) {
      String dateString = notification['scheduled_at'] ?? '';
      DateTime notificationDate;
      try {
        notificationDate = DateTime.parse(dateString);
      } catch (e) {
        notificationDate = DateTime.now();
      }

      String formattedDate =
          DateFormat('dd MMMM yyyy', 'th_TH').format(notificationDate);

      if (!groupedNotifications.containsKey(formattedDate)) {
        groupedNotifications[formattedDate] = [];
      }
      groupedNotifications[formattedDate]!.add(notification);
    }

    // Convert the map to a list and sort by date in descending order
    List<MapEntry<String, List<Map<String, dynamic>>>> sortedEntries =
        groupedNotifications.entries.toList()
          ..sort((a, b) {
            DateTime dateA = DateFormat('dd MMMM yyyy', 'th_TH').parse(a.key);
            DateTime dateB = DateFormat('dd MMMM yyyy', 'th_TH').parse(b.key);
            return dateB.compareTo(dateA); // Descending order
          });

    return Map.fromEntries(sortedEntries);
  }

  Future<void> _deleteAllNotifications() async {
    User? userData = FirebaseAuth.instance.currentUser;
    if (userData != null) {
      userId = userData.uid;
      try {
        QuerySnapshot notificationQuerySnapshot = await FirebaseFirestore
            .instance
            .collection('notification')
            .doc(userId)
            .collection('pet_notification')
            .get();

        // Delete all documents in the collection
        for (var doc in notificationQuerySnapshot.docs) {
          await doc.reference.delete();
        }

        // Refresh the notification list
        setState(() {
          petUserDataList_wait.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบการแจ้งเตือนทั้งหมดเรียบร้อยแล้ว')),
        );
      } catch (e) {
        print('Error deleting notifications: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการลบการแจ้งเตือน')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        toolbarHeight: 70,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            LineAwesomeIcons.angle_left,
            color: Colors.white,
          ),
        ),
        title: Text(
          "การแจ้งเตือน",
          style: TextStyle(color: Colors.white, fontSize: 26),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Column(
                      children: [
                        const Icon(LineAwesomeIcons.trash,
                            color: Colors.deepPurple, size: 50),
                        SizedBox(height: 20),
                        Text('คุณต้องการลบข้อมูลการแจ้งเตือนทั้งหมด',
                            style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    actions: <Widget>[
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              height: 40,
                              width: 90,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text("ยกเลิก"),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              width: 90,
                              child: TextButton(
                                onPressed: () {
                                  _deleteAllNotifications();
                                  Navigator.of(context).pop();
                                },
                                child: const Text("ยืนยัน"),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('ลบทั้งหมด',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          )
        ],
      ),
      backgroundColor:
          Colors.white, // Set the background color of the Scaffold to white
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังโหลดข้อมูล'),
                ],
              ),
            )
          : _buildNotificationList(petUserDataList_wait),
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> notifications) {
    Map<String, List<Map<String, dynamic>>> groupedNotifications =
        _groupNotificationsByDate(notifications);

    return groupedNotifications.isEmpty
        ? const Center(
            child: Text(
              'ไม่มีการแจ้งเตือน',
              style: TextStyle(fontSize: 16),
            ),
          )
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: groupedNotifications.entries.map((entry) {
                String dateKey = entry.key;
                List<Map<String, dynamic>> notificationsForDate = entry.value;

                // Use the already formatted date string
                String formattedDate = dateKey;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 20),
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          Text(formattedDate,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    ...notificationsForDate.map((notification) {
                      return _buildNotificationCard(notification);
                    }).toList(),
                  ],
                );
              }).toList(),
            ),
          );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    String dateString = notification['scheduled_at'] ??
        ''; // Changed from 'created_at' to 'date'
    DateTime notificationDate;
    try {
      notificationDate = DateTime.parse(dateString);
    } catch (e) {
      notificationDate = DateTime.now();
    }

    String formattedTime = DateFormat('HH:mm').format(notificationDate);
    String body = notification['body'] ?? 'ไม่มีรายละเอียด';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, // Background color of the card
        boxShadow: [], // Remove shadow to get rid of the border effect
        borderRadius: BorderRadius.circular(
            4), // Optional: Border radius for rounded corners
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor:
              Colors.grey.shade400, // Background color of the circle
          child: Icon(Icons.notifications_rounded,
              color: Colors.white), // Icon color
          radius: 24, // Radius of the circle
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis, // To handle long texts
              ),
            ),
            Text(
              '$formattedTime น.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
