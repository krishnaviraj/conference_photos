import 'package:shared_preferences/shared_preferences.dart';

class DateFormatService {
  static const String _dateFormatKey = 'date_format';
  static const String FORMAT_MMDDYYYY = 'MM/DD/YYYY';
  static const String FORMAT_DDMMYYYY = 'DD/MM/YYYY';
  
  // Default to MM/DD/YYYY as requested
  static String _currentFormat = FORMAT_MMDDYYYY;
  
  // Initialize from preferences
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentFormat = prefs.getString(_dateFormatKey) ?? FORMAT_MMDDYYYY;
  }
  
  // Format a date according to the current preference
  static String formatDate(DateTime date) {
    if (_currentFormat == FORMAT_MMDDYYYY) {
      return '${date.month}/${date.day}/${date.year}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  // Format date and time
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  // Get current format preference
  static String getCurrentFormat() {
    return _currentFormat;
  }
  
  // Set format preference
  static Future<void> setFormat(String format) async {
    if (format == FORMAT_MMDDYYYY || format == FORMAT_DDMMYYYY) {
      _currentFormat = format;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dateFormatKey, format);
    }
  }
}