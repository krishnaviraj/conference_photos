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
import '../services/date_format_service.dart';
import 'storage_service.dart';

class GoogleDriveService {
  static const String _backupFolderName = 'TalkToMeBackups';
  static const String _lastBackupTimeKey = 'last_backup_time';
  static const String _backupMetadataKey = 'backup_metadata';
  late SharedPreferences _prefs;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );
  
  final StorageService _storageService;
  
  GoogleDriveService(this._storageService) {
  _initPrefs();
}

Future<void> _initPrefs() async {
  _prefs = await SharedPreferences.getInstance();
  debugPrint('SharedPreferences initialized');
}
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

void _debugPrintBackupStructure(String directory) {
  try {
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      debugPrint('Directory does not exist: $directory');
      return;
    }
    
    debugPrint('------ Backup Structure ------');
    _printDirectoryContents(dir, 0);
    debugPrint('-----------------------------');
  } catch (e) {
    debugPrint('Error printing backup structure: $e');
  }
}

void _printDirectoryContents(Directory dir, int depth) {
  final indent = '  ' * depth;
  final entities = dir.listSync();
  debugPrint('$indent${path.basename(dir.path)}/');
  
  for (final entity in entities) {
    if (entity is Directory) {
      _printDirectoryContents(entity, depth + 1);
    } else if (entity is File) {
      final size = entity.lengthSync();
      final sizeStr = size < 1024 
          ? '${size}B' 
          : size < 1024 * 1024 
              ? '${(size / 1024).toStringAsFixed(1)}KB' 
              : '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
      debugPrint('$indent  ${path.basename(entity.path)} ($sizeStr)');
    }
  }
}

  // Create a backup of all app data
  // Complete updated createBackup method
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
    double progressIncrement = 0.6 / (talks.isEmpty ? 1 : talks.length); // Avoid division by zero
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
    await zipFile.writeAsBytes(zipData);

    // Debug print backup structure
    _debugPrintBackupStructure(backupDir.path);

    // 5. Upload to Google Drive
    onStatusUpdate('Uploading to Google Drive...');
    onProgressUpdate(0.9);
    
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      onStatusUpdate('Failed to connect to Google Drive');
      return false;
    }

    // Check if the app folder exists, create if not
    debugPrint('Getting or creating app folder');
    String folderId;
    try {
      folderId = await _getOrCreateFolder(driveApi);
      debugPrint('Using folder ID: $folderId');
    } catch (e) {
      debugPrint('Error getting/creating folder: $e');
      onStatusUpdate('Failed to create backup folder: ${e.toString()}');
      return false;
    }
    
    // Upload the backup file
    final timestamp = DateTime.now();
    final fileMetadata = drive.File();
    fileMetadata.name = backupFileName;
    fileMetadata.parents = [folderId]; // Explicitly set the parents array
    fileMetadata.description = 'Talk to me app backup from ${timestamp.toIso8601String()}';
    fileMetadata.mimeType = 'application/zip';

    debugPrint('File metadata: name=${fileMetadata.name}, parents=${fileMetadata.parents}, mimeType=${fileMetadata.mimeType}');

    final media = drive.Media(
      zipFile.openRead(),
      await zipFile.length(),
    );

    try {
      final driveFile = await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
      );
      
      debugPrint('Successfully created file with ID: ${driveFile.id}');
      
      // Verify the file was created in the correct folder
      final fileInfo = await driveApi.files.get(driveFile.id!) as drive.File;
      debugPrint('Created file info: ${fileInfo.name}, parents: ${fileInfo.parents}');
      
      // Store backup metadata
      await _saveBackupMetadata(driveFile.id!, timestamp);
    } catch (e) {
      debugPrint('Error creating backup file: $e');
      onStatusUpdate('Failed to upload backup: ${e.toString()}');
      return false;
    }

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
      try {
        backupFile = await driveApi.files.get(backupId) as drive.File;
      } catch (e) {
        onStatusUpdate('Error accessing backup: ${e.toString()}');
        return false;
      }
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
    
    try {
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
    } catch (e) {
      onStatusUpdate('Error extracting backup: ${e.toString()}');
      debugPrint('Extraction error: $e');
      return false;
    }
   _debugPrintBackupStructure('${extractDir.path}');


    // Clear existing data - but be careful not to clear the backup metadata
    onStatusUpdate('Preparing for restoration...');
    onProgressUpdate(0.5);
    
    // Save the current backup metadata before clearing
    String? backupMetadata = await _prefs.getString(_backupMetadataKey);
    
    await _storageService.clearAllData();

    // Restore talks
    onStatusUpdate('Restoring talk data...');
    onProgressUpdate(0.6);
    
    final talksFile = File('${extractDir.path}/talks.json');
    if (await talksFile.exists()) {
      try {
        final talksJson = await talksFile.readAsString();
        debugPrint('Talks JSON content: $talksJson');
        final talksData = jsonDecode(talksJson) as List;
        debugPrint('Decoded talks data length: ${talksData.length}');
        final talks = talksData.map((talkJson) => 
          Talk(
            id: talkJson['id'],
            name: talkJson['name'],
            presenter: talkJson['presenter'],
            createdAt: DateTime.parse(talkJson['createdAt']),
            photoCount: talkJson['photoCount'] ?? 0,
          )
        ).toList();

        debugPrint('Created talks objects: ${talks.length}');
        await _storageService.saveTalks(talks);
      } catch (e) {
        onStatusUpdate('Error restoring talks: ${e.toString()}');
        debugPrint('Talk restoration error: $e');
        return false;
      }
    } else {
      debugPrint('Talks file not found at: ${talksFile.path}');
      onStatusUpdate('No talks found in backup');
      return false;
    }

    // Restore photos
    onStatusUpdate('Restoring photos...');
    onProgressUpdate(0.7);
    
    final photosDir = Directory('${extractDir.path}/photos');
    bool photosRestored = false;
    
    if (await photosDir.exists()) {
      final appDir = await getApplicationDocumentsDirectory();
      final appPhotosDir = Directory('${appDir.path}/photos');
      
      if (await appPhotosDir.exists()) {
        await appPhotosDir.delete(recursive: true);
      }
      
      await appPhotosDir.create(recursive: true);
      
      // Copy directories for each talk
      try {
        await for (final entity in photosDir.list()) {
          if (entity is Directory) {
            final talkId = path.basename(entity.path);
            final destTalkDir = Directory('${appPhotosDir.path}/$talkId');
            
            if (!await destTalkDir.exists()) {
              await destTalkDir.create();
            }
            
            // Restore photo metadata
            final photosMetadataFile = File('${entity.path}/photos_metadata.json');
            if (await photosMetadataFile.exists()) {
              final photosJson = await photosMetadataFile.readAsString();
              final photosData = jsonDecode(photosJson) as List;
              
              final photos = <Photo>[];
              
              for (var photoJson in photosData) {
                try {
                  final originalPath = photoJson['path'];
                  final fileName = path.basename(originalPath);
                  final sourceFile = File('${entity.path}/$fileName');
                  
                  if (await sourceFile.exists()) {
                    final newPath = '${destTalkDir.path}/$fileName';
                    
                    // Create parent directories if they don't exist
                    final newFile = File(newPath);
                    if (!await newFile.parent.exists()) {
                      await newFile.parent.create(recursive: true);
                    }
                    
                    // Copy file and verify
                    await sourceFile.copy(newPath);
                    final newPathExists = await File(newPath).exists();
                    
                    debugPrint('Restored photo: $fileName to $newPath (exists: $newPathExists)');
                    
                    if (newPathExists) {
                      photos.add(Photo(
                        id: photoJson['id'],
                        path: newPath,
                        annotation: photoJson['annotation'],
                        createdAt: DateTime.parse(photoJson['createdAt']),
                      ));
                    } else {
                      debugPrint('Failed to copy photo: source exists but destination doesn\'t exist after copy');
                    }
                  } else {
                    debugPrint('Source file doesn\'t exist: ${sourceFile.path}');
                  }
                } catch (e) {
                  debugPrint('Error restoring individual photo: $e');
                  // Continue with next photo rather than failing entire restore
                }
              }
              
              if (photos.isNotEmpty) {
                await _storageService.savePhotos(talkId, photos);
                photosRestored = true;
              }
            }
          }
        }
      } catch (e) {
        onStatusUpdate('Error restoring photos: ${e.toString()}');
        debugPrint('Photo restoration error: $e');
        return false;
      }
      _debugPrintBackupStructure('${appPhotosDir.path}');
    }
    

    
    if (!photosRestored) {
      onStatusUpdate('No photos found or restored');
      // Continue anyway, as this might be a valid backup with just talks
    }

    // Restore backup metadata so last backup info doesn't get lost
    if (backupMetadata != null) {
      await _prefs.setString(_backupMetadataKey, backupMetadata);
      
      try {
        final metadata = jsonDecode(backupMetadata) as Map<String, dynamic>;
        if (metadata.containsKey('timestamp')) {
          await _prefs.setString(_lastBackupTimeKey, metadata['timestamp']);
        }
      } catch (e) {
        // Just log and continue if there's an error restoring backup metadata
        debugPrint('Error restoring backup metadata: $e');
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
      debugPrint('Not signed in when getting backups list');
      return [];
    }

    debugPrint('Getting backup list for account: ${account.email}');
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      debugPrint('Failed to get Drive API');
      return [];
    }

    // Always try to get or create the folder
    String folderId;
    try {
      folderId = await _getOrCreateFolder(driveApi);
    } catch (e) {
      debugPrint('Error with folder: $e');
      return [];
    }
    
    debugPrint('Looking for backups in folder: $folderId');
    final fileList = await driveApi.files.list(
      q: "'$folderId' in parents and mimeType='application/zip'",
      orderBy: 'createdTime desc',
      $fields: 'files(id, name, createdTime, size)',
    );

    if (fileList.files == null) {
      debugPrint('No files returned from Drive API');
      return [];
    }

    debugPrint('Found ${fileList.files!.length} backups');
    return fileList.files!.map((file) {
      DateTime? createdTime;
      try {
        if (file.createdTime != null) {
          createdTime = file.createdTime;
          debugPrint('Backup date: ${file.createdTime}');
        }
      } catch (e) {
        debugPrint('Error parsing time: $e');
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
  // Make sure prefs is initialized
  if (_prefs == null) {
    await _initPrefs();
  }
  
  final timestamp = _prefs.getString(_lastBackupTimeKey);
  debugPrint('Last backup timestamp from prefs: $timestamp');
  
  if (timestamp == null) {
    return null;
  }
  
  try {
    return DateTime.parse(timestamp);
  } catch (e) {
    debugPrint('Error parsing timestamp: $e');
    return null;
  }
}

  // Store backup metadata
  Future<void> _saveBackupMetadata(String fileId, DateTime timestamp) async {
  final localTimestamp = timestamp.toLocal();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_lastBackupTimeKey, localTimestamp.toIso8601String());
  
  final metadata = {
    'fileId': fileId,
    'timestamp': localTimestamp.toIso8601String(),
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
  try {
    // Check if folder already exists
    final existingFolderId = await _getFolderIdIfExists(driveApi);
    if (existingFolderId != null) {
      debugPrint('Found existing app folder with ID: $existingFolderId');
      return existingFolderId;
    }

    // Create a new folder
    debugPrint('Creating new app folder: $_backupFolderName');
    final folderMetadata = drive.File()
      ..name = _backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final folder = await driveApi.files.create(folderMetadata);
    
    if (folder.id == null) {
      debugPrint('Error: Created folder but ID is null');
      throw Exception('Failed to create folder - missing ID');
    }
    
    debugPrint('Successfully created folder with ID: ${folder.id}');
    return folder.id!;
  } catch (e) {
    debugPrint('Error creating folder: $e');
    throw Exception('Failed to create or get folder: $e');
  }
}

  // Find the folder ID if it exists
  Future<String?> _getFolderIdIfExists(drive.DriveApi driveApi) async {
  try {
    debugPrint('Searching for folder: $_backupFolderName');
    final query = "mimeType='application/vnd.google-apps.folder' and name='$_backupFolderName'";
    debugPrint('Query: $query');
    
    final result = await driveApi.files.list(
      q: query,
      spaces: 'drive',
    );

    if (result.files == null) {
      debugPrint('No files returned in response');
      return null;
    }
    
    debugPrint('Found ${result.files!.length} folders matching name');
    
    if (result.files!.isNotEmpty) {
      final folderId = result.files!.first.id!;
      debugPrint('Using folder ID: $folderId');
      return folderId;
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
  // Convert to local time
  final localTime = createdTime.toLocal();
  
  // Use the app's date format service
  try {
    return DateFormatService.formatDateTime(localTime);
  } catch (e) {
    // Fallback in case service is not initialized
    return '${localTime.day}/${localTime.month}/${localTime.year} ${localTime.hour}:${localTime.minute.toString().padLeft(2, '0')}';
  }
}
}