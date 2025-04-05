import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF1E2C4A); // Keep original blue as primary
  static const Color tealColor = Color(0xFF009688); // Add teal as a new color
  static const Color accentColor = Color(0xFFF2D9BE); // Cream/beige accent color
  static const Color cardColor = Color(0xFF2A3A5A); // Slightly lighter blue for cards
  static const Color surfaceColor = Color(0xFF171F36); // Darker blue for surfaces
  static const Color textPrimaryColor = Colors.white; // Primary text color
  static const Color textSecondaryColor = Color(0xCCFFFFFF); // Secondary text with opacity

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E2C4A), Color(0xFF0F1526)], // Keep original gradient
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Add a teal gradient if needed
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF009688), Color(0xFF00796B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Rounded corner radiuses
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;
  static const double borderRadiusExtraLarge = 32.0;

  // Spacings
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withAlpha(25),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  // Create the base app theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito', // Base font for the app
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        onPrimary: primaryColor, // Keep as original blue
        secondary: tealColor, // Use teal as secondary
        onSecondary: Colors.white,
        surface: surfaceColor,
        background: primaryColor, // Keep blue background
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: primaryColor, // Keep blue background
      cardTheme: CardTheme(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        elevation: 0,
        margin: const EdgeInsets.all(spacingMedium),
      ),
      textTheme: const TextTheme(
        // Montserrat for headlines and app title
        displayLarge: TextStyle(fontFamily: 'Montserrat', color: textPrimaryColor, fontWeight: FontWeight.w800),
        displayMedium: TextStyle(fontFamily: 'Montserrat', color: textPrimaryColor, fontWeight: FontWeight.w800),
        displaySmall: TextStyle(fontFamily: 'Montserrat', color: textPrimaryColor, fontWeight: FontWeight.w800),
        headlineLarge: TextStyle(fontFamily: 'Montserrat', color: textPrimaryColor, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(fontFamily: 'Montserrat', color: textPrimaryColor, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontFamily: 'Montserrat', color: textPrimaryColor, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontFamily: 'Montserrat', color: textPrimaryColor, fontWeight: FontWeight.w600),
        
        // Nunito for body text and smaller UI elements (inherits from base fontFamily)
        titleMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimaryColor),
        bodyMedium: TextStyle(color: textSecondaryColor),
        bodySmall: TextStyle(color: textSecondaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: primaryColor, // Keep as blue
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusLarge),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusLarge),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Montserrat', // Use Montserrat for app bar titles
          color: textPrimaryColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimaryColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Colors.black54),
        labelStyle: const TextStyle(color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMedium,
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24.0),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
      ),
    );
  }
}

// Custom style extensions for easier application of styles
extension StyleExtensions on Widget {
  Widget withPadding({
    double horizontal = 0,
    double vertical = 0,
    double all = 0,
  }) {
    if (all > 0) {
      return Padding(
        padding: EdgeInsets.all(all),
        child: this,
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      child: this,
    );
  }

  Widget withCard({Color? color, double? borderRadius, List<BoxShadow>? shadow}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppTheme.cardColor,
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.borderRadiusMedium),
        boxShadow: shadow ?? AppTheme.cardShadow,
      ),
      child: this,
    );
  }
}