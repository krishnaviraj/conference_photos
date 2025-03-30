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
      duration: const Duration(milliseconds: 500),
    );
    
    // Create a single animation for all cards
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
    _controller.forward();
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
          return SizedBox(
            width: 240,
            height: 160,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background rectangle
                Positioned(
                  left: 55,
                  top: 5,
                  width: 135,
                  height: 150,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5DDC7),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Top card (first row) - starts left, moves right
                Positioned(
                  // Lerp between starting position (left) and end position (perfectly centered)
                  left: lerpDouble(20, 60, _slideAnimation.value)!,
                  top: 20,
                  child: _buildCardSimple(false),
                ),
                
                // Middle card (second row) - starts right, moves left
                Positioned(
                  // Lerp between starting position (right) and end position (perfectly centered)
                  left: lerpDouble(90, 60, _slideAnimation.value)!,
                  top: 60,
                  child: _buildCardSimple(true),
                ),
                
                // Bottom card (third row) - starts left, moves right
                Positioned(
                  // Lerp between starting position (left) and end position (perfectly centered)
                  left: lerpDouble(20, 60, _slideAnimation.value)!,
                  top: 100,
                  child: _buildCardSimple(false),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // Card widget
  Widget _buildCardSimple(bool isRightAligned) {
    return Container(
      width: 125,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Camera box on left for left-aligned cards
          if (!isRightAligned) _buildCameraIcon(),
          
          // Text lines in the middle
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              child: Stack(
                children: [
                  // Top text line
                  Positioned(
                    left: 0,
                    top: 6,
                    right: 10,
                    child: Container(
                      height: 5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB4DAFF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  
                  // Bottom text line
                  Positioned(
                    left: 0,
                    top: 18,
                    right: 25,
                    child: Container(
                      height: 5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDEE9FC),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Camera box on right for right-aligned cards
          if (isRightAligned) _buildCameraIcon(),
        ],
      ),
    );
  }
  
  Widget _buildCameraIcon() {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: const Color(0xFF1485FD),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Icon(
        Icons.camera_alt_outlined,
        color: Colors.white,
        size: 18,
      ),
    );
  }
  
  // Helper function for double interpolation
  double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}