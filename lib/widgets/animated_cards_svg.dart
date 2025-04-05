import 'package:flutter/material.dart';

class AnimatedCardsSvg extends StatefulWidget {
  final bool startAnimation;
  final Key? controllerKey;

  const AnimatedCardsSvg({
    Key? key, 
    this.startAnimation = true,
    this.controllerKey,
  }) : super(key: key);

  @override
  State<AnimatedCardsSvg> createState() => AnimatedCardsSvgState();
}

class AnimatedCardsSvgState extends State<AnimatedCardsSvg> with TickerProviderStateMixin {
  late final AnimationController _controller;
  
  // Position animations for each card
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Single controller for synchronized animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Create a single animation for all cards
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    // Start animation if flag is true
    if (widget.startAnimation) {
      _startAnimation();
    }
  }
  
  // Reset and restart animation
  void resetAndStartAnimations() {
    _controller.reset();
    _startAnimation();
  }
  
  @override
  void didUpdateWidget(AnimatedCardsSvg oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If startAnimation changed from false to true, start animation
    if (!oldWidget.startAnimation && widget.startAnimation) {
      resetAndStartAnimations();
    }
  }
  
  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300)); // Initial delay
    if (mounted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          final scale = MediaQuery.of(context).size.width < 400 ? 0.7 : 1.0;
          return SizedBox(
            width: 240 * scale,
            height: 160 * scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background rectangle
                Positioned(
                  left: 55 * scale,
                  top: 5 * scale,
                  width: 135 * scale,
                  height: 150 * scale,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5DDC7),
                      borderRadius: BorderRadius.circular(10 * scale),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 5 * scale,
                          spreadRadius: 1 * scale,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Top card (first row) - starts left, moves right
                Positioned(
                  // Lerp between starting position (left) and end position (perfectly centered)
                  left: lerpDouble(20, 60, _slideAnimation.value)! * scale,
                  top: 20 * scale,
                  child: _buildCardSimple(false, scale),
                ),
                
                // Middle card (second row) - starts right, moves left
                Positioned(
                  // Lerp between starting position (right) and end position (perfectly centered)
                  left: lerpDouble(90, 60, _slideAnimation.value)! * scale,
                  top: 60 * scale,
                  child: _buildCardSimple(true, scale),
                ),
                
                // Bottom card (third row) - starts left, moves right
                Positioned(
                  // Lerp between starting position (left) and end position (perfectly centered)
                  left: lerpDouble(20, 60, _slideAnimation.value)! * scale,
                  top: 100 * scale,
                  child: _buildCardSimple(false, scale),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // Card widget
  Widget _buildCardSimple(bool isRightAligned, double scale) {
    return Container(
      width: 125 * scale,
      height: 35 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 3 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: Row(
        children: [
          // Camera box on left for left-aligned cards
          if (!isRightAligned) _buildCameraIcon(scale),
          
          // Text lines in the middle
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 6.0 * scale, 
                vertical: 4.0 * scale,
              ),
              child: Stack(
                children: [
                  // Top text line
                  Positioned(
                    left: 0,
                    top: 6 * scale,
                    right: 10 * scale,
                    child: Container(
                      height: 5 * scale,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB4DAFF),
                        borderRadius: BorderRadius.circular(3 * scale),
                      ),
                    ),
                  ),
                  
                  // Bottom text line
                  Positioned(
                    left: 0,
                    top: 18 * scale,
                    right: 25 * scale,
                    child: Container(
                      height: 5 * scale,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDEE9FC),
                        borderRadius: BorderRadius.circular(3 * scale),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Camera box on right for right-aligned cards
          if (isRightAligned) _buildCameraIcon(scale),
        ],
      ),
    );
  }
  
  Widget _buildCameraIcon(double scale) {
    return Container(
      width: 35 * scale,
      height: 35 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFF009688),
        borderRadius: BorderRadius.circular(5 * scale),
      ),
      child: Icon(
        Icons.camera_alt_outlined,
        color: Colors.white,
        size: 18 * scale,
      ),
    );
  }
  
  // Helper function for double interpolation
  double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}