import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

class ImagePickerDialog extends StatefulWidget {
  final List<String> firestoreImages;
  final Function(List<Uint8List?>, List<String?>) onSaveImages;
  final String petId;
  final Future<void> Function(int) deleteImageFromFirestore;

  ImagePickerDialog({
    required this.firestoreImages,
    required this.onSaveImages,
    required this.petId,
    required this.deleteImageFromFirestore,
  });

  @override
  _ImagePickerDialogState createState() => _ImagePickerDialogState();
}

class _ImagePickerDialogState extends State<ImagePickerDialog> {
  List<XFile?> _images = [];
  List<Uint8List?> compressedImages = [];
  List<String?> base64Images = [];

  Future<Uint8List?> compressImage(Uint8List image) async {
    try {
      List<int> compressedImage = await FlutterImageCompress.compressWithList(
        image,
        minHeight: 480,
        minWidth: 640,
        quality: 70,
      );
      return Uint8List.fromList(compressedImage);
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  Future<Uint8List?> _pickAndCompressImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      Uint8List? imageBytes = await file.readAsBytes();
      if (imageBytes != null) {
        return await compressImage(imageBytes);
      } else {
        print('Failed to read image bytes');
        return null;
      }
    } else {
      print('No image selected');
      return null;
    }
  }

  String uint8ListToBase64(Uint8List data) {
    return base64Encode(data);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('เพิ่มรูปภาพ'),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.firestoreImages.isNotEmpty ||
                compressedImages.isNotEmpty)
              Container(
                height: 250,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount:
                      widget.firestoreImages.length + compressedImages.length,
                  itemBuilder: (context, index) {
                    if (index < widget.firestoreImages.length) {
                      Uint8List? imageData =
                          base64Decode(widget.firestoreImages[index]);
                      if (imageData == null) {
                        return Container(
                          color: Colors.grey,
                          child: Center(
                            child: Text(
                              'Invalid image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          Image.memory(
                            imageData,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('ยืนยันการลบ'),
                                      content: Text(
                                          'คุณต้องการลบรูปภาพนี้ออกจากระบบหรือไม่?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('ยกเลิก'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await widget
                                                .deleteImageFromFirestore(
                                                    index);
                                            Navigator.of(context).pop();
                                            setState(
                                                () {}); // Refresh the dialog UI
                                          },
                                          child: Text('ยืนยัน'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Stack(
                        children: [
                          Image.memory(
                            compressedImages[
                                index - widget.firestoreImages.length]!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  compressedImages.removeAt(
                                      index - widget.firestoreImages.length);
                                  base64Images.removeAt(
                                      index - widget.firestoreImages.length);
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            TextButton(
              onPressed: () async {
                final compressedImage =
                    await _pickAndCompressImage(ImageSource.gallery);
                if (compressedImage != null) {
                  final base64Image = uint8ListToBase64(compressedImage);
                  setState(() {
                    if (widget.firestoreImages.length +
                            compressedImages.length <
                        9) {
                      _images.add(XFile.fromData(compressedImage));
                      compressedImages.add(compressedImage);
                      base64Images.add(base64Image);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('คุณสามารถเพิ่มรูปภาพได้สูงสุด 9 รูป')),
                      );
                    }
                  });
                }
              },
              child: Text('เลือกรูปจาก Gallery'),
            ),
            TextButton(
              onPressed: () async {
                final compressedImage =
                    await _pickAndCompressImage(ImageSource.camera);
                if (compressedImage != null) {
                  final base64Image = uint8ListToBase64(compressedImage);
                  setState(() {
                    if (widget.firestoreImages.length +
                            compressedImages.length <
                        9) {
                      _images.add(XFile.fromData(compressedImage));
                      compressedImages.add(compressedImage);
                      base64Images.add(base64Image);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('คุณสามารถเพิ่มรูปภาพได้สูงสุด 9 รูป')),
                      );
                    }
                  });
                }
              },
              child: Text('ถ่ายรูปจาก Camera'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('ยกเลิก'),
        ),
        TextButton(
          onPressed: () {
            widget.onSaveImages(compressedImages, base64Images);
            Navigator.of(context).pop();
          },
          child: Text('ยืนยันการเพิ่ม'),
        ),
      ],
    );
  }
}