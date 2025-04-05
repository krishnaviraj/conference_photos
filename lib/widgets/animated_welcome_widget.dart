import 'package:flutter/material.dart';

class AnimatedWelcomeWidget extends StatefulWidget {
  final bool startAnimation;

  const AnimatedWelcomeWidget({
    Key? key, 
    this.startAnimation = true,
  }) : super(key: key);

  @override
  State<AnimatedWelcomeWidget> createState() => AnimatedWelcomeWidgetState();
}

class AnimatedWelcomeWidgetState extends State<AnimatedWelcomeWidget> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _cornerAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    
    // Create controller for the animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Create slide animation
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller, 
        curve: Curves.easeOutBack,
      ),
    );
    
    // Create corner animation (for rounding transition)
    _cornerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller, 
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    // Start animation if flag is true
    if (widget.startAnimation) {
      _startAnimation();
    }
  }
  
  // Reset and restart animation
  void resetAndStartAnimations() {
    if (!mounted || _isAnimating) return;
    _controller.reset();
    _startAnimation();
  }
  
  @override
  void didUpdateWidget(AnimatedWelcomeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If startAnimation changed from false to true, start animation
    if (!oldWidget.startAnimation && widget.startAnimation) {
      resetAndStartAnimations();
    }
  }
  
  void _startAnimation() async {
    if (!mounted || _isAnimating) return;
    
    _isAnimating = true;
    await Future.delayed(const Duration(milliseconds: 300)); // Initial delay
    
    if (mounted) {
      _controller.forward().then((_) {
        if (mounted) {
          _isAnimating = false;
        }
      });
    } else {
      _isAnimating = false;
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
        animation: _controller,
        builder: (context, child) {
          // Calculate positions based on animation
          final photoOffset = lerpDouble(-30, 0, _slideAnimation.value)!;
          final noteOffset = lerpDouble(30, 0, _slideAnimation.value)!;
          
          // Calculate corner radius for joining faces (start rounded, end squared)
          final photoBottomRadius = lerpDouble(8.0, 0.0, _cornerAnimation.value)!;
          final noteTopRadius = lerpDouble(8.0, 0.0, _cornerAnimation.value)!;
          
          final scale = MediaQuery.of(context).size.width < 400 ? 0.7 : 1.0;
          return SizedBox(
            width: 170 * scale,
            height: 200 * scale,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Background circle
                Container(
                  width: 150 * scale,
                  height: 150 * scale,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFF5DDC7),
                        Color(0xFFFAEADD),
                      ],
                    ),
                  ),
                ),
                
                // Photo section (starts at top, moves down)
                Positioned(
                  top: (25 + photoOffset) * scale,
                  child: _buildPhotoSection(
                    topCornerRadius: 8.0, 
                    bottomCornerRadius: photoBottomRadius,
                    scale: scale,
                  ),
                ),
                
                // Annotation section (starts at bottom, moves up)
                Positioned(
                  top: (115 + noteOffset) * scale,
                  child: _buildAnnotationSection(
                    topCornerRadius: noteTopRadius, 
                    bottomCornerRadius: 8.0,
                    scale: scale,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // Photo section with camera header
  Widget _buildPhotoSection({
    required double topCornerRadius, 
    required double bottomCornerRadius,
    required double scale,
  }) {
    return Container(
      width: 110 * scale,
      height: 90 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFF009688),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(topCornerRadius * scale),
          topRight: Radius.circular(topCornerRadius * scale),
          bottomLeft: Radius.circular(bottomCornerRadius * scale),
          bottomRight: Radius.circular(bottomCornerRadius * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4 * scale,
            offset: Offset(0, 1 * scale),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 32 * scale,
        ),
      ),
    );
  }
  
  // Annotation section (note card)
  Widget _buildAnnotationSection({
    required double topCornerRadius, 
    required double bottomCornerRadius,
    required double scale,
  }) {
    return Container(
      width: 110 * scale,
      height: 60 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(topCornerRadius * scale),
          topRight: Radius.circular(topCornerRadius * scale),
          bottomLeft: Radius.circular(bottomCornerRadius * scale),
          bottomRight: Radius.circular(bottomCornerRadius * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4 * scale,
            offset: Offset(0, 1 * scale),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(10.0 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              height: 3 * scale,
              width: 90 * scale,
              color: const Color(0xFFB4DAFF),
            ),
            Container(
              height: 3 * scale,
              width: 70 * scale,
              color: const Color(0xFFDFEAFB),
            ),
            Container(
              height: 3 * scale,
              width: 60 * scale,
              color: const Color(0xFFB4DAFF),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper function for double interpolation
  double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}