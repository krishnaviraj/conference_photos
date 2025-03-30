import 'package:flutter/material.dart';
import '../services/date_format_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirmation_dialog.dart';
import '../services/storage_service.dart';
import '../services/google_drive_service.dart';
import 'backup_management_screen.dart';
import '../screens/home_screen.dart';
import 'package:flutter/material.dart';
import '../services/app_state_manager.dart';
import '../widgets/backup_progress_dialog.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService? storageService;
  
  const SettingsScreen({Key? key, this.storageService}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedDateFormat = DateFormatService.getCurrentFormat();
  late StorageService _storageService;
  late GoogleDriveService _googleDriveService;
  bool _isSignedIn = false;
  bool _isCheckingSignIn = true;
  String? _userEmail;
  DateTime? _lastBackupTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? StorageService();
    if (widget.storageService == null) {
      _initializeStorageService();
    }
    _googleDriveService = GoogleDriveService(_storageService);
    _checkSignInStatus();
    _loadLastBackupTime();
  }

  Future<void> _initializeStorageService() async {
    await _storageService.initialize();
  }

  Future<void> _checkSignInStatus() async {
  setState(() {
    _isCheckingSignIn = true;
  });
  
  final isSignedIn = await _googleDriveService.isSignedIn();
  
  if (isSignedIn) {
    final account = await _googleDriveService.getCurrentAccount();
    setState(() {
      _isSignedIn = true;
      _userEmail = account?.email;
    });
    
    // Always reload backup metadata when signed in
    _loadLastBackupTime();
  } else {
    setState(() {
      _isSignedIn = false;
      _userEmail = null;
    });
  }
  
  setState(() {
    _isCheckingSignIn = false;
  });
}

  Future<void> _loadLastBackupTime() async {
  try {
    final lastBackup = await _googleDriveService.getLastBackupTime();
    setState(() {
      _lastBackupTime = lastBackup;
    });
    debugPrint('Last backup time loaded: $_lastBackupTime');
  } catch (e) {
    debugPrint('Error loading last backup time: $e');
  }
}

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });
    
    final account = await _googleDriveService.signIn();
    
    setState(() {
      _isSignedIn = account != null;
      _userEmail = account?.email;
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    await _googleDriveService.signOut();
    setState(() {
      _isSignedIn = false;
      _userEmail = null;
    });
  }

  Future<void> _startBackup() async {
    setState(() {
      _isLoading = true;
    });
    
    // Show backup progress dialog
    final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => BackupProgressDialog(
      googleDriveService: _googleDriveService,
      storageService: _storageService, 
      isRestore: false,
    ),
  );
    
    if (result == true) {
      // Backup successful
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup completed successfully'),
          duration: Duration(seconds: 3),
        ),
      );
      
      // Refresh last backup time
      _loadLastBackupTime();
    }
    
    setState(() {
      _isLoading = false;
    });
  }

void _navigateToBackupManagement() {
  Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => BackupManagementScreen(
        googleDriveService: _googleDriveService,
        storageService: _storageService,
      ),
    ),
  ).then((success) {
    // Refresh last backup time
    _loadLastBackupTime();
    
    // If returning from a successful restore, show a message
    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restore completed successfully'),
          duration: Duration(seconds: 3),
        ),
      );
      
      // The navigate-back-to-home will automatically trigger data reload
      // through the .then() callback we added to the settings navigation
    }
  });
}

Future<void> _resetOnboarding() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => ConfirmationDialog(
      title: 'Reset onboarding',
      message: 'This will show the welcome screens next time you restart the app.',
      confirmLabel: 'Reset',
      cancelLabel: 'Cancel',
      onConfirm: () {
        Navigator.of(context).pop(true);
      },
    ),
  );

  if (confirmed != true) return;

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_complete', false);
  
  if (!mounted) return;
  
  // Show confirmation
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Onboarding reset. Restart the app to see the welcome screens.'),
      duration: Duration(seconds: 3),
    ),
  );
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
            'Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Pop with a result to signal that we're returning from settings
              Navigator.pop(context, true);
              // This explicit signal can be used by anything that pushed this screen
            },
          ),
        ),
        body: Stack(
          children: [
            ListView(
              children: [
                const SizedBox(height: 16),
                
                // Date Format Option
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: const Text(
                      'Date format',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _selectedDateFormat,
                      style: TextStyle(
                        color: Colors.white.withAlpha(179),
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white,
                    ),
                    onTap: _showDateFormatOptions,
                  ),
                ),
                
                // Divider for visual separation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Divider(
                    color: Colors.white.withAlpha(50),
                    height: 1,
                  ),
                ),
                
                // Cloud Backup Section Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'Cloud backup',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Google Account Sign In Status
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isCheckingSignIn
                      ? const ListTile(
                          title: Text(
                            'Google Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : ListTile(
                          leading: const Icon(
                            Icons.account_circle,
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Google Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            _isSignedIn
                                ? _userEmail ?? 'Signed in'
                                : 'Not signed in',
                            style: TextStyle(
                              color: Colors.white.withAlpha(179),
                              fontSize: 14,
                            ),
                          ),
                          trailing: _isSignedIn
                              ? TextButton(
                                  onPressed: _signOut,
                                  child: const Text(
                                    'Sign out',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : TextButton(
                                  onPressed: _signIn,
                                  child: Text(
                                    'Sign in',
                                    style: TextStyle(
                                      color: AppTheme.accentColor,
                                    ),
                                  ),
                                ),
                        ),
                ),
                
                // Last Backup Info
                if (_isSignedIn)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.history,
                        color: Colors.white,
                      ),
                      title: const Text(
                        'Last backup',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                          _lastBackupTime != null
                              ? 'On ${DateFormatService.formatDateTime(_lastBackupTime!.toLocal())}'
                              : 'No backups yet',
                          style: TextStyle(
                            color: Colors.white.withAlpha(179),
                            fontSize: 14,
                          ),
                        ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.folder_open,
                          color: Colors.white,
                        ),
                        onPressed: _isSignedIn ? _navigateToBackupManagement : null,
                        tooltip: 'Manage backups',
                      ),
                    ),
                  ),
                
                // Backup/Restore Actions
                if (_isSignedIn)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.backup),
                            label: const Text('Back up now'),
                            onPressed: _isLoading ? null : _startBackup,
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
                        const SizedBox(height: 12),
                        Text(
                          'To restore from a backup, tap the folder icon above to manage your backups',
                          style: TextStyle(
                            color: Colors.white.withAlpha(179),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                
               
               
                // Clear All Data Option
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Clear all data',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'This will delete all groups and photos',
                      style: TextStyle(
                        color: Colors.red[100],
                        fontSize: 14,
                      ),
                    ),
                    onTap: _showClearDataConfirmation,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.replay_circle_filled,
                      color: Colors.orange,
                    ),
                    title: const Text(
                      'Reset onboarding',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Show the welcome screens again',
                      style: TextStyle(
                        color: Colors.orange[100],
                        fontSize: 14,
                      ),
                    ),
                    onTap: _resetOnboarding,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
            
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDateFormatOptions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppTheme.surfaceColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose date format',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildFormatOption(DateFormatService.FORMAT_MMDDYYYY),
              const Divider(color: Colors.white24),
              _buildFormatOption(DateFormatService.FORMAT_DDMMYYYY),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatOption(String format) {
    final isSelected = _selectedDateFormat == format;
    
    return InkWell(
      onTap: () async {
        await DateFormatService.setFormat(format);
        setState(() {
          _selectedDateFormat = format;
        });
        if (mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppTheme.accentColor.withAlpha(25) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              format,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? AppTheme.accentColor : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.accentColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Clear all data',
        message: 'This will delete all groups and photos. This cannot be undone.',
        confirmLabel: 'Clear all data',
        cancelLabel: 'Cancel',
        onConfirm: () async {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          try {
            await _storageService.clearAllData();
            
            if (!mounted) return;
            
            // Close loading dialog
            Navigator.pop(context);
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All data has been cleared'),
                duration: Duration(seconds: 2),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            
            // Close loading dialog
            Navigator.pop(context);
            
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to clear data: ${e.toString()}'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }
}