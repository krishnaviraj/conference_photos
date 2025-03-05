import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/talk.dart';
import '../models/photo.dart';
import 'storage_service.dart';

class GoogleDriveService {
  static const String _backupFolderName = 'TalkToMeBackups';
  static const String _lastBackupTimeKey = 'last_backup_time';
  static const String _backupMetadataKey = 'backup_metadata';
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );
  
  final StorageService _storageService;
  
  GoogleDriveService(this._storageService);

  // Check if user is currently signed in
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // Sign in to Google account
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      debugPrint('Error signing in: $error');
      return null;
    }
  }

  // Sign out from Google account
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  // Get the current signed-in account
  Future<GoogleSignInAccount?> getCurrentAccount() async {
    return _googleSignIn.currentUser;
  }

  Future<void> _addDirectoryToArchive(Directory directory, String parentPath, Archive archive) async {
  final List<FileSystemEntity> entities = await directory.list().toList();
  
  for (var entity in entities) {
    final String relativePath = parentPath.isEmpty 
        ? path.basename(entity.path)
        : '$parentPath/${path.basename(entity.path)}';
    
    if (entity is File) {
      final bytes = await entity.readAsBytes();
      final archiveFile = ArchiveFile(relativePath, bytes.length, bytes);
      archive.addFile(archiveFile);
    } else if (entity is Directory) {
      await _addDirectoryToArchive(entity, relativePath, archive);
    }
  }
}

  // Create a backup of all app data
  Future<bool> createBackup({
    required Function(String) onStatusUpdate,
    required Function(double) onProgressUpdate,
  }) async {
    try {
      final account = await signIn();
      if (account == null) {
        onStatusUpdate('Google Sign-in failed');
        return false;
      }

      onStatusUpdate('Preparing backup data...');
      onProgressUpdate(0.1);

      // Create a temporary directory to store backup files
      final tempDir = await getTemporaryDirectory();
      final backupDir = Directory('${tempDir.path}/backup');
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
      await backupDir.create();

      // 1. Back up talk metadata
      onStatusUpdate('Backing up talk data...');
      onProgressUpdate(0.2);
      final talks = await _storageService.loadTalks();
      final talksJson = jsonEncode(talks.map((talk) => _talkToJson(talk)).toList());
      final talksFile = File('${backupDir.path}/talks.json');
      await talksFile.writeAsString(talksJson);

      // 2. Create a directory for photos
      final photosBackupDir = Directory('${backupDir.path}/photos');
      await photosBackupDir.create();

      // 3. Back up photos for each talk
      onStatusUpdate('Backing up photos...');
      double progressIncrement = 0.6 / talks.length; // 60% of progress is for photos
      double currentProgress = 0.2;

      for (var talk in talks) {
        onStatusUpdate('Backing up photos for "${talk.name}"...');
        
        // Create talk directory
        final talkDir = Directory('${photosBackupDir.path}/${talk.id}');
        await talkDir.create();
        
        // Back up photo metadata
        final photos = await _storageService.loadPhotos(talk.id);
        final photosJson = jsonEncode(photos.map((photo) => _photoToJson(photo)).toList());
        final photosMetadataFile = File('${talkDir.path}/photos_metadata.json');
        await photosMetadataFile.writeAsString(photosJson);
        
        // Copy photo files
        for (var photo in photos) {
          final originalFile = File(photo.path);
          if (await originalFile.exists()) {
            final fileName = path.basename(photo.path);
            final destinationFile = File('${talkDir.path}/$fileName');
            await originalFile.copy(destinationFile.path);
          }
        }
        
        currentProgress += progressIncrement;
        onProgressUpdate(currentProgress);
      }

      // 4. Create a zip archive
      onStatusUpdate('Compressing backup...');
      onProgressUpdate(0.8);
      
      final backupFileName = 'talktome_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
      final zipFile = File('${tempDir.path}/$backupFileName');
      
      // Create zip file
      // Using Archive 4.0.4 compatible approach
      final archive = Archive();
      await _addDirectoryToArchive(backupDir, '', archive);
      final zipData = ZipEncoder().encode(archive);
      if (zipData != null) {
        await zipFile.writeAsBytes(zipData);
      }

      // 5. Upload to Google Drive
      onStatusUpdate('Uploading to Google Drive...');
      onProgressUpdate(0.9);
      
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        onStatusUpdate('Failed to connect to Google Drive');
        return false;
      }

      // Check if the app folder exists, create if not
      final folderId = await _getOrCreateFolder(driveApi);
      
      // Upload the backup file
      final timestamp = DateTime.now();
      final fileMetadata = drive.File()
        ..name = backupFileName
        ..parents = [folderId]
        ..description = 'Talk to me app backup from ${timestamp.toIso8601String()}'
        ..mimeType = 'application/zip';

      final media = drive.Media(
        zipFile.openRead(),
        await zipFile.length(),
      );

      final driveFile = await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      // Store backup metadata
      await _saveBackupMetadata(driveFile.id!, timestamp);
      
      // Clean up temporary files
      await zipFile.delete();
      await backupDir.delete(recursive: true);

      onStatusUpdate('Backup completed successfully');
      onProgressUpdate(1.0);
      return true;
    } catch (e) {
      debugPrint('Backup error: $e');
      onStatusUpdate('Backup failed: ${e.toString()}');
      return false;
    }
  }

  // Restore from a backup
  Future<bool> restoreFromBackup({
    String? backupId,
    required Function(String) onStatusUpdate,
    required Function(double) onProgressUpdate,
  }) async {
    try {
      final account = await signIn();
      if (account == null) {
        onStatusUpdate('Google Sign-in failed');
        return false;
      }

      onStatusUpdate('Connecting to Google Drive...');
      onProgressUpdate(0.1);

      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        onStatusUpdate('Failed to connect to Google Drive');
        return false;
      }

      // Get the backup file
      drive.File? backupFile;
      if (backupId != null) {
        // Use the specified backup
        backupFile = await driveApi.files.get(backupId) as drive.File;
      } else {
        // Get the most recent backup
        final folderId = await _getFolderIdIfExists(driveApi);
        if (folderId == null) {
          onStatusUpdate('No backups found');
          return false;
        }

        final fileList = await driveApi.files.list(
          q: "'$folderId' in parents and mimeType='application/zip'",
          orderBy: 'createdTime desc',
        );

        if (fileList.files == null || fileList.files!.isEmpty) {
          onStatusUpdate('No backups found');
          return false;
        }

        backupFile = fileList.files!.first;
      }

      onStatusUpdate('Downloading backup...');
      onProgressUpdate(0.2);

      // Download the backup file
      final tempDir = await getTemporaryDirectory();
      final backupZipFile = File('${tempDir.path}/${backupFile.name}');
      
      final response = await driveApi.files.get(
        backupFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      
      final List<int> dataStore = [];
      await response.stream.forEach((data) {
        dataStore.addAll(data);
      });
      
      await backupZipFile.writeAsBytes(dataStore);

      // Extract the zip file
      onStatusUpdate('Extracting backup...');
      onProgressUpdate(0.4);
      
      final extractDir = Directory('${tempDir.path}/extract');
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create();
      
      final bytes = await backupZipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File('${extractDir.path}/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory('${extractDir.path}/$filename').createSync(recursive: true);
        }
      }

      // Clear existing data
      onStatusUpdate('Clearing existing data...');
      onProgressUpdate(0.5);
      await _storageService.clearAllData();

      // Restore talks
      onStatusUpdate('Restoring talk data...');
      onProgressUpdate(0.6);
      
      final talksFile = File('${extractDir.path}/backup/talks.json');
      if (await talksFile.exists()) {
        final talksJson = await talksFile.readAsString();
        final talksData = jsonDecode(talksJson) as List;
        final talks = talksData.map((talkJson) => 
          Talk(
            id: talkJson['id'],
            name: talkJson['name'],
            presenter: talkJson['presenter'],
            createdAt: DateTime.parse(talkJson['createdAt']),
            photoCount: talkJson['photoCount'] ?? 0,
          )
        ).toList();
        
        await _storageService.saveTalks(talks);
      }

      // Restore photos
      onStatusUpdate('Restoring photos...');
      onProgressUpdate(0.7);
      
      final photosDir = Directory('${extractDir.path}/backup/photos');
      if (await photosDir.exists()) {
        final appDir = await getApplicationDocumentsDirectory();
        final appPhotosDir = Directory('${appDir.path}/photos');
        
        if (!await appPhotosDir.exists()) {
          await appPhotosDir.create(recursive: true);
        }
        
        // Copy directories for each talk
        await for (final talkDir in photosDir.list()) {
          if (talkDir is Directory) {
            final talkId = path.basename(talkDir.path);
            final destTalkDir = Directory('${appPhotosDir.path}/$talkId');
            
            if (!await destTalkDir.exists()) {
              await destTalkDir.create();
            }
            
            // Restore photo metadata
            final photosMetadataFile = File('${talkDir.path}/photos_metadata.json');
            if (await photosMetadataFile.exists()) {
              final photosJson = await photosMetadataFile.readAsString();
              final photosData = jsonDecode(photosJson) as List;
              
              final photos = <Photo>[];
              
              for (var photoJson in photosData) {
                final originalPath = photoJson['path'];
                final fileName = path.basename(originalPath);
                final originalFile = File('${talkDir.path}/$fileName');
                
                if (await originalFile.exists()) {
                  final newPath = '${destTalkDir.path}/$fileName';
                  await originalFile.copy(newPath);
                  
                  photos.add(Photo(
                    id: photoJson['id'],
                    path: newPath,
                    annotation: photoJson['annotation'],
                    createdAt: DateTime.parse(photoJson['createdAt']),
                  ));
                }
              }
              
              await _storageService.savePhotos(talkId, photos);
            }
          }
        }
      }

      // Clean up
      onStatusUpdate('Finalizing restoration...');
      onProgressUpdate(0.9);
      
      await backupZipFile.delete();
      await extractDir.delete(recursive: true);

      onStatusUpdate('Restore completed successfully');
      onProgressUpdate(1.0);
      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      onStatusUpdate('Restore failed: ${e.toString()}');
      return false;
    }
  }

  // Get list of available backups
  Future<List<BackupInfo>> getBackupsList() async {
    try {
      final account = await getCurrentAccount();
      if (account == null) {
        return [];
      }

      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return [];
      }

      final folderId = await _getFolderIdIfExists(driveApi);
      if (folderId == null) {
        return [];
      }

      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and mimeType='application/zip'",
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, createdTime, size)',
      );

      if (fileList.files == null) {
        return [];
      }

      return fileList.files!.map((file) {
        DateTime? createdTime;
        try {
          if (file.createdTime != null) {
            createdTime = file.createdTime;
          }
        } catch (e) {
          // Parsing error, use current time as fallback
          createdTime = DateTime.now();
        }

        final size = file.size != null ? int.tryParse(file.size!) ?? 0 : 0;
        
        return BackupInfo(
          id: file.id!,
          fileName: file.name!,
          createdTime: createdTime ?? DateTime.now(),
          size: size,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting backups list: $e');
      return [];
    }
  }

  // Delete a specific backup
  Future<bool> deleteBackup(String backupId) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return false;
      }

      await driveApi.files.delete(backupId);
      return true;
    } catch (e) {
      debugPrint('Error deleting backup: $e');
      return false;
    }
  }

  // Get the last backup time
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastBackupTimeKey);
    if (timestamp == null) {
      return null;
    }
    return DateTime.parse(timestamp);
  }

  // Store backup metadata
  Future<void> _saveBackupMetadata(String fileId, DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupTimeKey, timestamp.toIso8601String());
    
    final metadata = {
      'fileId': fileId,
      'timestamp': timestamp.toIso8601String(),
    };
    await prefs.setString(_backupMetadataKey, jsonEncode(metadata));
  }

  // Get the Drive API client
  Future<drive.DriveApi?> _getDriveApi() async {
    final account = await getCurrentAccount();
    if (account == null) {
      return null;
    }

    final authHeaders = await account.authHeaders;
    final authenticatedClient = _AuthClient(authHeaders, http.Client());
    return drive.DriveApi(authenticatedClient);
  }

  // Get or create the app's folder in Drive
  Future<String> _getOrCreateFolder(drive.DriveApi driveApi) async {
    // Check if folder already exists
    final existingFolderId = await _getFolderIdIfExists(driveApi);
    if (existingFolderId != null) {
      return existingFolderId;
    }

    // Create a new folder
    final folderMetadata = drive.File()
      ..name = _backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final folder = await driveApi.files.create(folderMetadata);
    return folder.id!;
  }

  // Find the folder ID if it exists
  Future<String?> _getFolderIdIfExists(drive.DriveApi driveApi) async {
    try {
      final result = await driveApi.files.list(
        q: "mimeType='application/vnd.google-apps.folder' and name='$_backupFolderName'",
        spaces: 'drive',
      );

      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      }
      return null;
    } catch (e) {
      debugPrint('Error finding folder: $e');
      return null;
    }
  }

  // Convert Talk object to JSON for backup
  Map<String, dynamic> _talkToJson(Talk talk) {
    return {
      'id': talk.id,
      'name': talk.name,
      'presenter': talk.presenter,
      'createdAt': talk.createdAt.toIso8601String(),
      'photoCount': talk.photoCount,
    };
  }

  // Convert Photo object to JSON for backup
  Map<String, dynamic> _photoToJson(Photo photo) {
    return {
      'id': photo.id,
      'path': photo.path,
      'annotation': photo.annotation,
      'createdAt': photo.createdAt.toIso8601String(),
    };
  }
}

// Custom HTTP client that adds auth headers to requests
class _AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client;

  _AuthClient(this._headers, this._client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

// Class to hold backup information
class BackupInfo {
  final String id;
  final String fileName;
  final DateTime createdTime;
  final int size; // in bytes

  BackupInfo({
    required this.id,
    required this.fileName,
    required this.createdTime,
    required this.size,
  });

  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String get formattedDate {
    return '${createdTime.day}/${createdTime.month}/${createdTime.year} ${createdTime.hour}:${createdTime.minute.toString().padLeft(2, '0')}';
  }
}