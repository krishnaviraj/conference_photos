import 'package:flutter/foundation.dart';
import 'photo.dart';

class PhotoGroup {
  final String id;
  final String label;
  final List<Photo> photos;
  final DateTime createdAt;

  PhotoGroup({
    required this.id,
    required this.label,
    required this.photos,
    required this.createdAt,
  });

  PhotoGroup copyWith({
    String? label,
    List<Photo>? photos,
  }) {
    return PhotoGroup(
      id: id,
      label: label ?? this.label,
      photos: photos ?? this.photos,
      createdAt: createdAt,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'photos': photos.map((photo) => photo.id).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory PhotoGroup.fromJson(Map<String, dynamic> json, List<Photo> allPhotos) {
  final photoIds = List<String>.from(json['photos']);
  
  // More robust photo finding
  final groupPhotos = photoIds.map((photoId) {
    // Find the photo by ID, or return null if not found
    final matchingPhotos = allPhotos.where((p) => p.id == photoId);
    return matchingPhotos.isNotEmpty ? matchingPhotos.first : null;
  })
  .where((photo) => photo != null) // Filter out any nulls
  .cast<Photo>() // Cast the non-null photos
  .toList();
  
  // Print debug info
  print('Loading group: ${json['label']} with ${photoIds.length} photo IDs, found ${groupPhotos.length} photos');
  
  return PhotoGroup(
    id: json['id'],
    label: json['label'],
    photos: groupPhotos,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

}