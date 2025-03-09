import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/talk.dart';
import '../models/photo.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class StorageService {
  static const String _talksKey = 'talks';
  static const String _photosPrefix = 'photos_';
  late SharedPreferences _prefs;
  
  Future<void> initialize() async {
  debugPrint('Initializing StorageService');
  _prefs = await SharedPreferences.getInstance();
  debugPrint('SharedPreferences initialized');
  
  // Verify preferences are working by reading a test value
  try {
    final testValue = _prefs.getString(_talksKey);
    debugPrint('Test read from preferences: ${testValue != null ? 'Success' : 'No data yet'}');
  } catch (e) {
    debugPrint('Error reading from SharedPreferences: $e');
  }
}

  // Convert Talk to/from JSON
  Map<String, dynamic> _talkToJson(Talk talk) {
    return {
      'id': talk.id,
      'name': talk.name,
      'presenter': talk.presenter,
      'createdAt': talk.createdAt.toIso8601String(),
      'photoCount': talk.photoCount,
    };
  }

  Talk _talkFromJson(Map<String, dynamic> json) {
    return Talk(
      id: json['id'],
      name: json['name'],
      presenter: json['presenter'],
      createdAt: DateTime.parse(json['createdAt']),
      photoCount: json['photoCount'] ?? 0,
    );
  }

  // Convert Photo to/from JSON
  Map<String, dynamic> _photoToJson(Photo photo) {
    return {
      'id': photo.id,
      'path': photo.path,
      'annotation': photo.annotation,
      'createdAt': photo.createdAt.toIso8601String(),
    };
  }

  Photo _photoFromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      path: json['path'],
      annotation: json['annotation'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  void debugPrintPhotoMetadata(String talkId) {
  final photosString = _prefs.getString('${_photosPrefix}$talkId');
  debugPrint('Photos metadata for talk $talkId:');
  debugPrint(photosString ?? 'No metadata found');
}

  // Save talks
  Future<void> saveTalks(List<Talk> talks) async {
    final talksJson = talks.map((talk) => _talkToJson(talk)).toList();
    await _prefs.setString(_talksKey, jsonEncode(talksJson));
  }

  // Load talks
  Future<List<Talk>> loadTalks() async {
  final talksString = _prefs.getString(_talksKey);
  debugPrint('Loading talks from preferences: ${talksString != null ? 'Found data' : 'No data'}');
  
  if (talksString == null) return [];

  try {
    final talksJson = jsonDecode(talksString) as List;
    final loadedTalks = talksJson
        .map((talkJson) => _talkFromJson(talkJson as Map<String, dynamic>))
        .toList();
    
    debugPrint('Successfully loaded ${loadedTalks.length} talks');
    return loadedTalks;
  } catch (e) {
    debugPrint('Error parsing talks data: $e');
    return [];
  }
}

  // Save photos for a talk
  Future<void> savePhotos(String talkId, List<Photo> photos) async {
  final photosJson = photos.map((photo) => _photoToJson(photo)).toList();
  await _prefs.setString('${_photosPrefix}$talkId', jsonEncode(photosJson));
  }

  // Load photos for a talk
  Future<List<Photo>> loadPhotos(String talkId) async {
  final photosString = _prefs.getString('${_photosPrefix}$talkId');
  if (photosString == null) return [];

  final photosJson = jsonDecode(photosString) as List;
  return photosJson
      .map((photoJson) => _photoFromJson(photoJson as Map<String, dynamic>))
      .toList();
}

Future<List<Photo>> updatePhotoAnnotation(String talkId, String photoId, String newAnnotation) async {
    final photos = await loadPhotos(talkId);
    final updatedPhotos = photos.map((photo) {
      if (photo.id == photoId) {
        return photo.copyWith(annotation: newAnnotation);
      }
      return photo;
    }).toList();
    
    await savePhotos(talkId, updatedPhotos);
    return updatedPhotos;
  }

  // Save a photo file
  Future<String> savePhotoFile(String talkId, File photoFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${directory.path}/photos/$talkId');
    await photosDir.create(recursive: true);

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await photoFile.copy('${photosDir.path}/$fileName');
    return savedFile.path;
  }

  // Delete a photo file
  // Future<void> deletePhotoFile(String path) async {
  //   final file = File(path);
  //   if (await file.exists()) {
  //     await file.delete();
  //   }
  // }

  Future<void> deletePhoto(String talkId, Photo photo) async {
    // Delete the physical file
    final file = File(photo.path);
    if (await file.exists()) {
      await file.delete();
    }

    // Remove from metadata
    final photos = await loadPhotos(talkId);
    photos.removeWhere((p) => p.id == photo.id);
    await savePhotos(talkId, photos);

    // Update talk photo count
    final talks = await loadTalks();
    final updatedTalks = talks.map((talk) {
      if (talk.id == talkId) {
        return talk.updatePhotoCount(photos.length);
      }
      return talk;
    }).toList();
    await saveTalks(updatedTalks);
  }

  Future<void> deleteTalk(String talkId) async {
    // Delete all photos in the talk
    final photos = await loadPhotos(talkId);
    for (final photo in photos) {
      final file = File(photo.path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Delete the talk's photo directory
    final directory = await getApplicationDocumentsDirectory();
    final talkDir = Directory('${directory.path}/photos/$talkId');
    if (await talkDir.exists()) {
      await talkDir.delete(recursive: true);
    }

    // Remove talk metadata
    final talks = await loadTalks();
    talks.removeWhere((t) => t.id == talkId);
    await saveTalks(talks);

    // Remove photos metadata
    await _prefs.remove('${_photosPrefix}$talkId');
  }

  Future<List<Photo>> savePhotoOrder(String talkId, List<Photo> photos) async {
  // Simply save the photos in their current order
  await savePhotos(talkId, photos);
  return photos;
}

  // Clean up unused photo files
  Future<void> cleanupPhotos(String talkId, List<Photo> currentPhotos) async {
    final directory = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${directory.path}/photos/$talkId');
    
    if (!await photosDir.exists()) return;

    final currentPaths = currentPhotos.map((p) => p.path).toSet();
    await for (final file in photosDir.list()) {
      if (!currentPaths.contains(file.path)) {
        await file.delete();
      }
    }
  }

  Future<void> hardReset() async {
  debugPrint('Performing hard reset of StorageService');
  _prefs = await SharedPreferences.getInstance();
  await _prefs.reload();
  debugPrint('StorageService hard reset completed');
}

  Future<void> clearAllData() async {
  // Clear SharedPreferences
  await _prefs.clear();
  
  // Clear photo files
  final directory = await getApplicationDocumentsDirectory();
  final photosDir = Directory('${directory.path}/photos');
  
  if (await photosDir.exists()) {
    try {
      await photosDir.delete(recursive: true);
      debugPrint('Successfully deleted photos directory');
    } catch (e) {
      debugPrint('Error deleting photos directory: $e');
    }
  }
}

}