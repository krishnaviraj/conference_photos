// ignore_for_file: use_super_parameters
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/date_format_service.dart';
import 'services/google_drive_service.dart';
import 'theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';

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
  
  // Check if onboarding is complete
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  
  runApp(ConferencePhotosApp(
    storageService: storageService,
    onboardingComplete: onboardingComplete,
  ));
}

class ConferencePhotosApp extends StatelessWidget {
  final StorageService storageService;
  final bool onboardingComplete;

  const ConferencePhotosApp({
    Key? key,
    required this.storageService,
    this.onboardingComplete = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mosaic',
      theme: AppTheme.darkTheme, // Use our custom theme
      home: onboardingComplete
          ? HomeScreen(storageService: storageService)
          : OnboardingScreen(storageService: storageService),
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}