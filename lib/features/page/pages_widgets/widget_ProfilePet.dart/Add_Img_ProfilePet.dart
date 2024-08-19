import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class ImagePickerDialog extends StatefulWidget {
  final List<String> firestoreImages;
  final Function(List<Uint8List?>, List<String?>) onSaveImages;
  final String petId;
  final Future<void> Function(String) deleteImageFromFirestore;

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
  List<String> imagesToDelete = [];

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
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              LineAwesomeIcons.image,
              color: Colors.deepPurple,
            ),
          ),
          Text('เพิ่มรูปภาพ'),
        ],
      ),
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: Image.memory(
                              imageData,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  imagesToDelete
                                      .add(widget.firestoreImages[index]);
                                  widget.firestoreImages.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: Image.memory(
                              compressedImages[
                                  index - widget.firestoreImages.length]!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(LineAwesomeIcons.photo_video),
                  ),
                  Text('เลือกรูปจาก Gallery'),
                ],
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blueGrey,
              ),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(LineAwesomeIcons.camera),
                  ),
                  Text('ถ่ายรูปจาก Camera'),
                ],
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple.shade400,
              ),
            ),
          ],
        ),
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
                width: 120,
                child: TextButton(
                  onPressed: () async {
                    for (String imageBase64 in imagesToDelete) {
                      await widget.deleteImageFromFirestore(imageBase64);
                    }
                    widget.onSaveImages(compressedImages, base64Images);
                    Navigator.of(context).pop();
                  },
                  child: const Text("ยืนยันการเพิ่ม"),
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
  }
}
