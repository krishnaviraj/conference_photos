import 'package:flutter/material.dart';
import '../services/google_drive_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirmation_dialog.dart';

class BackupManagementScreen extends StatefulWidget {
  final GoogleDriveService googleDriveService;

  const BackupManagementScreen({
    super.key,
    required this.googleDriveService,
  });

  @override
  State<BackupManagementScreen> createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen> {
  List<BackupInfo> _backups = [];
  bool _isLoading = true;
  String? _selectedBackupId;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _isLoading = true;
    });

    final backups = await widget.googleDriveService.getBackupsList();
    
    setState(() {
      _backups = backups;
      _isLoading = false;
      
      // Auto-select the most recent backup if any exist
      if (backups.isNotEmpty) {
        _selectedBackupId = backups.first.id;
      }
    });
  }

  Future<void> _deleteBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Backup',
        message: 'Are you sure you want to delete this backup? This cannot be undone.',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final success = await widget.googleDriveService.deleteBackup(backupId);
    
    if (success) {
      await _loadBackups(); // Refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete backup'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _restoreFromBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Restore from Backup',
        message: 'This will replace all current data with the backed-up data. Continue?',
        confirmLabel: 'Restore',
        cancelLabel: 'Cancel',
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    
    if (confirmed != true) return;
    
    // Show restore progress dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackupProgressDialog(
        googleDriveService: widget.googleDriveService,
        isRestore: true,
        backupId: backupId,
      ),
    );
    
    if (result == true && mounted) {
      // Restore successful, navigate back to settings
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restore completed successfully'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Manage backups',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _loadBackups,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _backups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 64,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No backups found',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a backup to get started',
                          style: TextStyle(
                            color: Colors.white.withAlpha(179),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.backup),
                          label: const Text('Create backup'),
                          onPressed: () async {
                            final success = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => BackupProgressDialog(
                                googleDriveService: widget.googleDriveService,
                                isRestore: false,
                              ),
                            );
                            
                            if (success == true) {
                              await _loadBackups();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Select a backup to restore or delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _backups.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemBuilder: (context, index) {
                            final backup = _backups[index];
                            final isSelected = backup.id == _selectedBackupId;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.accentColor.withAlpha(40)
                                    : AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(
                                        color: AppTheme.accentColor,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: ListTile(
                                onTap: () {
                                  setState(() {
                                    _selectedBackupId = backup.id;
                                  });
                                },
                                leading: Radio<String>(
                                  value: backup.id,
                                  groupValue: _selectedBackupId,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedBackupId = value;
                                    });
                                  },
                                  activeColor: AppTheme.accentColor,
                                ),
                                title: Text(
                                  'Backup ${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      backup.formattedDate,
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(179),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Size: ${backup.formattedSize}',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(179),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => _deleteBackup(backup.id),
                                  tooltip: 'Delete backup',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_selectedBackupId != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.restore),
                                  label: const Text('Restore selected'),
                                  onPressed: () => _restoreFromBackup(_selectedBackupId!),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentColor,
                                    foregroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

// Dialog to show backup/restore progress
class BackupProgressDialog extends StatefulWidget {
  final GoogleDriveService googleDriveService;
  final bool isRestore;
  final String? backupId;

  const BackupProgressDialog({
    Key? key,
    required this.googleDriveService,
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
    bool success;
    
    if (widget.isRestore) {
      success = await widget.googleDriveService.restoreFromBackup(
        backupId: widget.backupId,
        onStatusUpdate: (status) {
          setState(() {
            _status = status;
          });
        },
        onProgressUpdate: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );
    } else {
      success = await widget.googleDriveService.createBackup(
        onStatusUpdate: (status) {
          setState(() {
            _status = status;
          });
        },
        onProgressUpdate: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );
    }
    
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
        ],
      ),
      actions: [
        if (_isDone)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(!_isError);
            },
            child: Text(_isError ? 'Close' : 'Done'),
          ),
      ],
    );
  }
}