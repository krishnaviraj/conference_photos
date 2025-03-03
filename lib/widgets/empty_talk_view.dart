// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyTalkView extends StatelessWidget {
  const EmptyTalkView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom illustration container - replace with actual SVG or custom painter
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withAlpha(51),
              borderRadius: BorderRadius.circular(80),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Purple base shape
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA28CFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  // Smaller stacked image element
                  Positioned(
                    top: 30,
                    right: 30,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFAFBBFF),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                  // White dot detail
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Mountain detail
                  Positioned(
                    bottom: 20,
                    left: 10,
                    child: Container(
                      width: 25,
                      height: 20,
                      child: const CustomPaint(
                        painter: MountainPainter(),
                        size: Size(25, 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Start by taking a photo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Everything for this talk will fill in here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(179),
                ),
          ),
        ],
      ),
    );
  }
}

class MountainPainter extends CustomPainter {
  const MountainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}