// ignore_for_file: use_super_parameters
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/date_format_service.dart';
import 'services/google_drive_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  // Initialize services
  final storageService = StorageService();
  await storageService.initialize();
  
  // Initialize date format service
  await DateFormatService.initialize();
  
  runApp(ConferencePhotosApp(storageService: storageService));
}

class ConferencePhotosApp extends StatelessWidget {
  final StorageService storageService;

  const ConferencePhotosApp({
    super.key,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talk to me',
      theme: AppTheme.darkTheme, // Use our custom theme
      home: HomeScreen(storageService: storageService),
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}