import 'package:image_picker/image_picker.dart';
//ไม่เกี่ยววว
pickImage(ImageSource source) async{
  final ImagePicker imgPicker = ImagePicker();
  XFile? file = await imgPicker.pickImage(source: source);
  if (file != null) {
    return await file.readAsBytes();
  }
  print('No Images Selected!');
}