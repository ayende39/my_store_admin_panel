import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static Future<List<Uint8List>?> pickImages() async {
    final ImagePicker picker = ImagePicker();

    // On mobile and web, pick multiple images (web: multi-image supported)
    final List<XFile>? pickedFiles = await picker.pickMultiImage();

    if (pickedFiles == null || pickedFiles.isEmpty) return null;

    // Convert all picked files to Uint8List bytes for preview & upload
    List<Uint8List> imagesBytes = [];
    for (final file in pickedFiles) {
      final bytes = await file.readAsBytes();
      imagesBytes.add(bytes);
    }
    return imagesBytes;
  }
}
