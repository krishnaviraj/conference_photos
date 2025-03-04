import 'package:flutter/material.dart';
import '../services/date_format_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirmation_dialog.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService? storageService;
  
  const SettingsScreen({Key? key, this.storageService}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedDateFormat = DateFormatService.getCurrentFormat();
  late StorageService _storageService;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? StorageService();
    if (widget.storageService == null) {
      _initializeStorageService();
    }
  }

  Future<void> _initializeStorageService() async {
    await _storageService.initialize();
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
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
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
                  'Date Format',
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
            
            // Section Title for danger zone
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Danger Zone',
                style: TextStyle(
                  color: Colors.red[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
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
                  'This will delete all talks and photos',
                  style: TextStyle(
                    color: Colors.red[100],
                    fontSize: 14,
                  ),
                ),
                onTap: _showClearDataConfirmation,
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
                'Choose Date Format',
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
        title: 'Clear All Data',
        message: 'This will delete all talks and photos. This cannot be undone.',
        confirmLabel: 'Clear All Data',
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