// ignore_for_file: use_super_parameters
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/date_format_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: HomeScreen(storageService: storageService),
    );
  }
}