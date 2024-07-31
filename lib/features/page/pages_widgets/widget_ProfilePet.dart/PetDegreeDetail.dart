import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/AddPetDigree.dart';
import 'package:Pet_Fluffy/features/page/pages_widgets/widget_ProfilePet.dart/EditPetDigree.dart';
import 'package:Pet_Fluffy/features/services/profile.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class PetdigreeDetailPage extends StatefulWidget {
  final String userId;
  final String petId;

  const PetdigreeDetailPage({
    Key? key,
    required this.userId,
    required this.petId,
  }) : super(key: key);

  @override
  _PetdigreeDetailPageState createState() => _PetdigreeDetailPageState();
}

class _PetdigreeDetailPageState extends State<PetdigreeDetailPage> {
  final ProfileService _profileService = ProfileService();
  String id_petdigree = '';
  String numpet = '';
  String num_pet_f = '';
  String num_pet_m = '';
  String? img_petdigree;
  bool isLoading = true; 

  void showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(20.0)),
                child: InteractiveViewer(
        panEnabled: true, // อนุญาตให้เลื่อน
        minScale: 1,
        maxScale: 5,
        child: Image.memory(
          base64Decode(imageUrl),
          fit: BoxFit.contain, // ปรับขนาดให้พอดีกับหน้าจอ
        ),
      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAllPet(widget.petId, widget.userId);
  }

  Future<void> _loadAllPet(String petId, String userId) async {
    try {
      Map<String, dynamic> petData =
          await _profileService.loadPetdigreeData(petId, userId);
      setState(() {
        numpet = petData['num_pet'] ?? '';
        num_pet_f = petData['num_pet_f'] ?? '';
        num_pet_m = petData['num_pet_m'] ?? '';
        img_petdigree = petData['img_pet'] ?? '';
        id_petdigree = petData['id_petdigree'] ?? '';

        isLoading = false; // เปลี่ยนสถานะการโหลดเป็นเสร็จสิ้น
      });
    } catch (e) {
      print('Error getting pet user data from Firestore: $e');
      setState(() {
        isLoading =
            false; // เปลี่ยนสถานะการโหลดเป็นเสร็จสิ้นในกรณีเกิดข้อผิดพลาด
      });
    }
  }

  Future<void> _navigateToEditPetDigreePage() async {
    // เรียกใช้ Navigator.push เพื่อเปิดหน้า EditPetDigreePage
    final updatedPetDigree = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EditPetDigreePage(
          userId: widget.userId,
          petId: widget.petId,
          id_petdigree: id_petdigree,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    // เรียกใช้ _loadAllPet เพื่อดึงข้อมูลใหม่
    if (updatedPetDigree != null) {
      _loadAllPet(widget.petId, widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('ข้อมูลใบเพ็ดดีกรี'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: isLoading
                ? null
                : () {
                    if (img_petdigree == null || img_petdigree!.isEmpty) {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  AddPetDigreePage(
                            userId: widget.userId,
                            petId: widget.petId,
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.ease;

                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                        ),
                      );
                    } else {
                      // If data exists, navigate to edit page
                      _navigateToEditPetDigreePage();
                    }
                  },
            icon: const Icon(LineAwesomeIcons.edit),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Positioned(
              top: 40, // ปรับความสูงของการ์ด
              left: 0,
              right: 0,
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 30), // เพิ่มพื้นที่ด้านบน
                      Column(
                        children: [
                          if (img_petdigree != null &&
                              img_petdigree!.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                showImageDialog(context, img_petdigree!);
                              },
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(10.0), // กำหนดมุมโค้ง
                                child: Image.memory(
                                  base64Decode(img_petdigree!),
                                  width: 340,
                                  height: 170,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Container(
                                width: 340,
                                height: 170,
                                color: Colors.grey[300],
                                child: Center(
                                  child: Icon(Icons.photo, size: 32),
                                ),
                              ),
                            ),
                          SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'เลขทะเบียน : ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                numpet,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'REG.NO',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'เลขทะเบียนพ่อ ',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                              Text(
                                num_pet_f,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'เลขทะเบียนแม่ ',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  num_pet_m,
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left:
                  MediaQuery.of(context).size.width / 2 - 55, // ปรับให้ตรงกลาง
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(40),
                ),
                padding: EdgeInsets.all(20),
                child: Icon(
                  LineAwesomeIcons.dna,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
