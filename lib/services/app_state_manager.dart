// lib/services/app_state_manager.dart
import 'package:flutter/foundation.dart';

class AppStateManager {
  static final AppStateManager _instance = AppStateManager._internal();
  
  factory AppStateManager() => _instance;
  
  AppStateManager._internal();
  
  // Use to track when a restore operation has occurred
  bool _pendingDataReload = false;
  
  bool get needsDataReload => _pendingDataReload;
  
  void markForReload() {
    _pendingDataReload = true;
    debugPrint('App marked for data reload');
  }
  
  void clearReloadFlag() {
    _pendingDataReload = false;
    debugPrint('App reload flag cleared');
  }
}