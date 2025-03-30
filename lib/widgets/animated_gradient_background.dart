// Updated AnimatedGradientBackground widget with more visible effect
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  
  const AnimatedGradientBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Define base colors from AppTheme
  final Color color1 = AppTheme.primaryColor;
  final Color color2 = const Color(0xFF0F1526); // From AppTheme's primaryGradient
  
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;
  late Animation<Alignment> _alignmentAnimation1;
  late Animation<Alignment> _alignmentAnimation2;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 8), // Faster animation cycle
      vsync: this,
    )..repeat(reverse: true);
    
    // Create more noticeable color shifts
    _colorAnimation1 = ColorTween(
      begin: color1,
      end: Color.lerp(color1, color2, 0.5), // More color variation
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _colorAnimation2 = ColorTween(
      begin: color2,
      end: Color.lerp(color2, color1, 0.25), // More color variation
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    // Add subtle position shift to the gradient
    _alignmentAnimation1 = AlignmentTween(
      begin: const Alignment(0.0, -1.0), // TopCenter
      end: const Alignment(-0.2, -0.8),  // Slight shift
    ).animate(_controller);
    
    _alignmentAnimation2 = AlignmentTween(
      begin: const Alignment(0.0, 1.0),  // BottomCenter
      end: const Alignment(0.2, 0.8),    // Slight shift
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_colorAnimation1.value!, _colorAnimation2.value!],
              begin: _alignmentAnimation1.value,
              end: _alignmentAnimation2.value,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}