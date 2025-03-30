import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class SpotlightBackground extends StatefulWidget {
  final Widget child;
  
  const SpotlightBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<SpotlightBackground> createState() => _SpotlightBackgroundState();
}

class _SpotlightBackgroundState extends State<SpotlightBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Base colors
  final Color darkBlue = const Color(0xFF0A1020); // Very dark blue
  final Color mediumBlue = AppTheme.primaryColor;
  final Color lightBlue = const Color(0xFF33548A); // Lighter accent for the spotlight
  
  // Animation paths
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 15), // Slow movement
      vsync: this,
    )..repeat();
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  // Calculate spotlight position using a figure-8 pattern
  Offset _calculateSpotlightPosition(Size size, double value) {
    // Figure-8 pattern
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    
    // Size of the figure-8 pattern
    final double radiusX = size.width * 0.3;
    final double radiusY = size.height * 0.2;
    
    // Calculate position using parametric equation of figure-8
    final double t = value * 2 * math.pi;
    final double x = centerX + radiusX * math.sin(t);
    final double y = centerY + radiusY * math.sin(t) * math.cos(t);
    
    return Offset(x, y);
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final spotlightPosition = _calculateSpotlightPosition(
              size, 
              _animation.value
            );
            
            return Container(
              decoration: BoxDecoration(
                // Base gradient
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [darkBlue, mediumBlue],
                ),
              ),
              child: Stack(
                children: [
                  // Radial gradient that moves
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(
                            2 * spotlightPosition.dx / size.width - 1,
                            2 * spotlightPosition.dy / size.height - 1,
                          ),
                          radius: 0.7,
                          colors: [
                            lightBlue.withOpacity(0.5),  // Center of spotlight
                            mediumBlue.withOpacity(0.1), // Middle
                            darkBlue.withOpacity(0.0),   // Edge (transparent)
                          ],
                          stops: const [0.0, 0.3, 1.0],
                        ),
                      ),
                    ),
                  ),
                  
                  // Content
                  child!,
                ],
              ),
            );
          },
        );
      },
      child: widget.child,
    );
  }
}