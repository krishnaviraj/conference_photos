import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class FlowerShapedFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double size;
  
  const FlowerShapedFab({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.size = 72.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        splashColor: Colors.white.withAlpha(50),
        highlightColor: Colors.white.withAlpha(30),
        child: Container(
          width: size,
          height: size,
          child: CustomPaint(
            painter: FlowerButtonPainter(AppTheme.accentColor),
            child: Center(
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: size * 0.45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FlowerButtonPainter extends CustomPainter {
  final Color color;
  
  FlowerButtonPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = 1
      ..isAntiAlias = true;
    
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(40)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw shadow first (slightly offset)
    final shadowPath = createFlowerPath(center, radius, 8);
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Draw the main shape
    final path = createFlowerPath(center, radius, 8);
    canvas.drawPath(path, paint);
  }
  
  Path createFlowerPath(Offset center, double radius, int petalCount) {
    final path = Path();
    
    // Radius of the inner circle
    final innerRadius = radius * 0.7;
    
    // Start the path at the right edge of the circle
    path.moveTo(center.dx + radius, center.dy);
    
    // Draw each petal
    for (int i = 0; i < petalCount; i++) {
      final petalAngle = (2 * math.pi / petalCount);
      final startAngle = i * petalAngle;
      final endAngle = (i + 1) * petalAngle;
      final midAngle = (startAngle + endAngle) / 2;
      
      final startPoint = Offset(
        center.dx + radius * math.cos(startAngle),
        center.dy + radius * math.sin(startAngle),
      );
      
      final endPoint = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );
      
      final controlPoint = Offset(
        center.dx + (radius * 1.3) * math.cos(midAngle),
        center.dy + (radius * 1.3) * math.sin(midAngle),
      );
      
      if (i == 0) {
        path.moveTo(startPoint.dx, startPoint.dy);
      } else {
        path.lineTo(startPoint.dx, startPoint.dy);
      }
      
      path.quadraticBezierTo(
        controlPoint.dx,
        controlPoint.dy,
        endPoint.dx,
        endPoint.dy,
      );
    }
    
    path.close();
    return path;
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}