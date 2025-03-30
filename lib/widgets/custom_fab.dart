import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class FlowerShapedFab extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double size;
  final bool animate; // New property to control animation
  
  const FlowerShapedFab({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.size = 72.0,
    this.animate = false, // Default to no animation
  }) : super(key: key);
  
  @override
  State<FlowerShapedFab> createState() => _FlowerShapedFabState();
}

class _FlowerShapedFabState extends State<FlowerShapedFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 12), // Slow rotation over 12 seconds
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi, // Full rotation (2π)
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
    
    // Start animation if animate is true
    if (widget.animate) {
      _controller.repeat(); // Continuously rotate
    }
  }
  
  @override
  void didUpdateWidget(FlowerShapedFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle changes to the animate property
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onPressed,
        splashColor: Colors.white.withAlpha(50),
        highlightColor: Colors.white.withAlpha(30),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating flower background
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: widget.animate ? _animation.value : 0.0,
                    child: CustomPaint(
                      painter: FlowerButtonPainter(AppTheme.accentColor),
                      size: Size(widget.size, widget.size),
                    ),
                  );
                },
              ),
              // Stationary icon
              Icon(
                widget.icon,
                color: AppTheme.primaryColor,
                size: widget.size * 0.45,
              ),
            ],
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