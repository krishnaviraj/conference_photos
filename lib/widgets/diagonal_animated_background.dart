import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DiagonalAnimatedBackground extends StatefulWidget {
  final Widget child;
  
  const DiagonalAnimatedBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<DiagonalAnimatedBackground> createState() => _DiagonalAnimatedBackgroundState();
}

class _DiagonalAnimatedBackgroundState extends State<DiagonalAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Base colors - using more contrast
  final Color darkBlue = const Color(0xFF0A1020); // Darker than original
  final Color mediumBlue = AppTheme.primaryColor;
  final Color lightAccent = const Color(0xFF2A4060); // Lighter accent for contrast
  
  // Animation values
  late Animation<Alignment> _begin1Animation;
  late Animation<Alignment> _end1Animation;
  late Animation<Alignment> _begin2Animation;
  late Animation<Alignment> _end2Animation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
    
    // Animate the gradient positions for a more noticeable effect
    _begin1Animation = AlignmentTween(
      begin: const Alignment(-1.5, -1.5),  // Top-left
      end: const Alignment(-0.5, -0.5),    // More centered
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _end1Animation = AlignmentTween(
      begin: const Alignment(1.5, 1.5),    // Bottom-right
      end: const Alignment(0.5, 0.5),      // More centered
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    // Second gradient with different timing for depth
    _begin2Animation = AlignmentTween(
      begin: const Alignment(-0.8, -0.8),
      end: const Alignment(-1.8, -1.8),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _end2Animation = AlignmentTween(
      begin: const Alignment(0.8, 0.8),
      end: const Alignment(1.8, 1.8),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
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
        return Stack(
          children: [
            // First gradient layer
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [darkBlue, mediumBlue, lightAccent],
                  begin: _begin1Animation.value,
                  end: _end1Animation.value,
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            
            // Second gradient layer with opacity
            Opacity(
              opacity: 0.7,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [darkBlue.withOpacity(0.8), mediumBlue.withOpacity(0.4)],
                    begin: _begin2Animation.value,
                    end: _end2Animation.value,
                  ),
                ),
              ),
            ),
            
            // Content
            widget.child,
          ],
        );
      },
    );
  }
}