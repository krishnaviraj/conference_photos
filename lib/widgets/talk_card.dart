import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/talk.dart';
import '../services/date_format_service.dart';
import '../theme/app_theme.dart';

class TalkCard extends StatelessWidget {
  final Talk talk;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const TalkCard({
    Key? key,
    required this.talk,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
  }) : super(key: key);

  // Get a random decorative pattern for the talk card
  Widget _getDecorativePattern() {
    // Generate a pseudo-random pattern based on the talk ID
    final random = math.Random(talk.id.hashCode);
    
    final patternType = random.nextInt(3); // 0, 1, or 2 for different patterns
    final baseColor = _getBaseColor();
    
    switch (patternType) {
      case 0: // Diagonal lines
        return CustomPaint(
          painter: DiagonalLinesPainter(baseColor),
          size: const Size(120, 120),
        );
      case 1: // Circles
        return CustomPaint(
          painter: CirclesPainter(baseColor),
          size: const Size(120, 120),
        );
      case 2: // Wavy lines
        return CustomPaint(
          painter: WavyLinesPainter(baseColor),
          size: const Size(120, 120),
        );
      default:
        return const SizedBox();
    }
  }
  
  // Get a base color for the card based on talk ID
  Color _getBaseColor() {
    final random = math.Random(talk.id.hashCode);
    final colorIndex = random.nextInt(5);
    
    switch (colorIndex) {
      case 0:
        return const Color(0xFFF38181); // Coral red
      case 1:
        return const Color(0xFF6EB5FF); // Light blue
      case 2:
        return const Color(0xFF3CB371); // Green
      case 3:
        return const Color(0xFFAF8EB5); // Purple
      case 4:
        return const Color(0xFFFFB347); // Orange
      default:
        return const Color(0xFF6EB5FF); // Default light blue
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _getBaseColor();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      color: baseColor.withAlpha(38), // Using withAlpha instead of withOpacity (38 is ~15%)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        side: isSelected
            ? BorderSide(
                color: AppTheme.accentColor,
                width: 2.0,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Stack(
          children: [
            // Decorative pattern positioned to the right
            Positioned(
              right: -20,
              top: 0,
              bottom: 0,
              child: _getDecorativePattern(),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Talk name
                  Text(
                    talk.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  // Add speaker name if available
                  if (talk.presenter != null && talk.presenter!.isNotEmpty) ...[
                    const SizedBox(height: 6.0),
                    Text(
                      talk.presenter!,
                      style: TextStyle(
                        color: Colors.white.withAlpha(230),
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 12.0),
                  
                  // Date and photo count both on the left
                  Row(
                    children: [
                      // Date
                      Text(
                        DateFormatService.formatDate(talk.createdAt),
                        style: TextStyle(
                          color: Colors.white.withAlpha(179),
                          fontSize: 14,
                        ),
                      ),
                      
                      // Add separator between date and photo count
                      Text(
                        " • ",
                        style: TextStyle(
                          color: Colors.white.withAlpha(179),
                          fontSize: 14,
                        ),
                      ),
                      
                      // Photo count (moved from right to left)
                      Text(
                        '${talk.photoCount} photos',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
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

// The custom painters remain unchanged
class DiagonalLinesPainter extends CustomPainter {
  final Color baseColor;
  
  DiagonalLinesPainter(this.baseColor);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor.withAlpha(102) // Using withAlpha instead of withOpacity (102 is ~40%)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    for (var i = -20.0; i < size.width + size.height; i += 14.0) { // Converted to double
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CirclesPainter extends CustomPainter {
  final Color baseColor;
  
  CirclesPainter(this.baseColor);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor.withAlpha(102) // Using withAlpha instead of withOpacity
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.3), 20.0, paint); // Converted to double
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.5), 30.0, paint); // Converted to double
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.7), 15.0, paint); // Converted to double
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WavyLinesPainter extends CustomPainter {
  final Color baseColor;
  
  WavyLinesPainter(this.baseColor);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor.withAlpha(102) // Using withAlpha instead of withOpacity
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final path1 = Path();
    final path2 = Path();
    final path3 = Path();
    
    // First wavy line
    path1.moveTo(size.width * 0.1, size.height * 0.3);
    for (var i = 0; i < 6; i++) {
      final i_double = i.toDouble(); // Convert to double
      path1.quadraticBezierTo(
        size.width * (0.2 + i_double * 0.15), size.height * (0.2 + (i % 2).toDouble() * 0.2),
        size.width * (0.3 + i_double * 0.15), size.height * 0.3,
      );
    }
    
    // Second wavy line
    path2.moveTo(size.width * 0.05, size.height * 0.5);
    for (var i = 0; i < 5; i++) {
      final i_double = i.toDouble(); // Convert to double
      path2.quadraticBezierTo(
        size.width * (0.15 + i_double * 0.15), size.height * (0.4 + (i % 2).toDouble() * 0.2),
        size.width * (0.25 + i_double * 0.15), size.height * 0.5,
      );
    }
    
    // Third wavy line
    path3.moveTo(size.width * 0.15, size.height * 0.7);
    for (var i = 0; i < 4; i++) {
      final i_double = i.toDouble(); // Convert to double
      path3.quadraticBezierTo(
        size.width * (0.25 + i_double * 0.15), size.height * (0.6 + (i % 2).toDouble() * 0.2),
        size.width * (0.35 + i_double * 0.15), size.height * 0.7,
      );
    }
    
    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}