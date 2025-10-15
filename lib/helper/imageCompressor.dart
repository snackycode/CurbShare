import 'dart:io';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart'; // Ensure XFile is imported
import 'package:path_provider/path_provider.dart'; // You might not need this if not saving
import 'dart:typed_data'; // Import Uint8List

class ImageCompressor {
  // Compress image to ≤1MB and return as bytes (Uint8List)
  Future<Uint8List?> compressImage(File file) async {
    try {
      List<int> imageBytes = await file.readAsBytes();
      int quality = 90;
      Uint8List? compressedBytes;

      do {
        compressedBytes = await FlutterImageCompress.compressWithList(
          Uint8List.fromList(imageBytes),
          quality: quality,
        );
        quality -= 10;
      } while (compressedBytes != null && compressedBytes.length > 512 * 512 && quality > 10);

      return compressedBytes;
    } catch (e) {
      print("Error compressing image: $e");
      return null;
    }
  }
  Future<File?> readCompressedFile(Uint8List bytes, String fileName) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/$fileName.jpg";
      File file = File(filePath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print("Error converting Uint8List to File: $e");
      return null;
    }
  }
}
