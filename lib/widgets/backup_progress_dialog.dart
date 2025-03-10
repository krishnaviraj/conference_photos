import 'package:flutter/material.dart';
import '../services/google_drive_service.dart';
import '../services/storage_service.dart';
import '../services/app_state_manager.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
/// A dialog that shows progress during backup and restore operations.
/// 
/// This dialog works with GoogleDriveService to show real-time progress
/// of backup creation and restoration. It handles both the UI presentation
/// and coordination with the required services.
class BackupProgressDialog extends StatefulWidget {
  final GoogleDriveService googleDriveService;
  final StorageService storageService;
  final bool isRestore;
  final String? backupId;
  /// Creates a backup progress dialog.
  /// 
  /// The [googleDriveService] and [storageService] are required to perform
  /// the backup/restore operations. Set [isRestore] to true for restore operations,
  /// and provide a [backupId] when restoring from a specific backup.
  const BackupProgressDialog({
    Key? key,
    required this.googleDriveService,
    required this.storageService,
    required this.isRestore,
    this.backupId,
  }) : super(key: key);

  @override
  State<BackupProgressDialog> createState() => _BackupProgressDialogState();
}

class _BackupProgressDialogState extends State<BackupProgressDialog> {
  String _status = 'Initializing...';
  double _progress = 0.0;
  bool _isDone = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _startOperation();
  }

  Future<void> _startOperation() async {
  bool success = false;
  try {
    if (widget.isRestore) {
      success = await widget.googleDriveService.restoreFromBackup(
        backupId: widget.backupId,
        onStatusUpdate: (status) {
          if (mounted) {
            setState(() {
              _status = status;
            });
          }
        },
        onProgressUpdate: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
            });
          }
        },
      );
      
      // If restoration was successful, explicitly reinitialize storage
      if (success) {
        // Keep these existing lines
        await widget.storageService.hardReset();
        AppStateManager().markForReload();
        
        // Add this new code to set the deep reload flag
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('_force_complete_reload_', true);
        
        debugPrint('Restoration complete - deep reload flag set in SharedPreferences');
      }
    } else {
      // Backup code remains unchanged
      success = await widget.googleDriveService.createBackup(
        onStatusUpdate: (status) {
          if (mounted) {
            setState(() {
              _status = status;
            });
          }
        },
        onProgressUpdate: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
            });
          }
        },
      );
    }
  } catch (e) {
    debugPrint('Operation error: $e');
    success = false;
  }
  
  if (!mounted) return;
  
  setState(() {
    _isDone = true;
    _isError = !success;
  });
}

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isRestore ? 'Restoring from backup' : 'Creating backup',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_status),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _isError ? Colors.red : AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text('${(_progress * 100).toInt()}%'),
          if (_isDone && !_isError && widget.isRestore) ...[
            const SizedBox(height: 16),
            const Text(
              'If the restored data doesn\'t appear, try restarting the app',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
          if (_isError) ...[
            const SizedBox(height: 16),
            const Text(
              'An error occurred during the operation',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        if (_isDone)
          TextButton(
            onPressed: () => Navigator.of(context).pop(!_isError),
            child: Text(_isError ? 'Close' : 'Done'),
          ),
      ],
    );
  }
}