import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as path;

class CameraService {
  final ImagePicker _picker = ImagePicker();
  
  /// Captures a photo using the native camera
  /// Returns the path to the saved image file, or null if cancelled/failed
  Future<String?> captureImage() async {
    try {
      // Capture image using native camera
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95, // High quality but with slight compression
        maxWidth: 2048,   // Reasonable max dimensions to prevent huge files
        maxHeight: 2048,
      );
      
      if (image == null) return null;
      
      // Get app's local storage directory
      final directory = await getApplicationDocumentsDirectory();
      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = path.join(directory.path, filename);
      
      // Copy image to app's storage
      await File(image.path).copy(savedPath);
      
      // Clean up temporary image file
      await File(image.path).delete();
      
      return savedPath;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }
  
  /// Imports a photo from the device gallery
  /// Returns the path to the saved image file, or null if cancelled/failed
  Future<String?> importFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      
      if (image == null) return null;
      
      final directory = await getApplicationDocumentsDirectory();
      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = path.join(directory.path, filename);
      
      await File(image.path).copy(savedPath);
      
      return savedPath;
    } catch (e) {
      debugPrint('Error importing image: $e');
      return null;
    }
  }
  
  /// Saves an image file to the app's storage for a specific talk
  /// Returns the path to the saved file
  Future<String> saveImageToTalkDirectory(String talkId, File imageFile) async {
  final directory = await getApplicationDocumentsDirectory();
  final talkDirectory = Directory('${directory.path}/photos/$talkId');
  await talkDirectory.create(recursive: true);
  
  final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
  final savedPath = path.join(talkDirectory.path, filename);
  
  await imageFile.copy(savedPath);
  return savedPath;
}
  
  /// Removes a photo file from storage
  Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}