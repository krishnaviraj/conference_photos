import 'package:flutter/material.dart';
import 'dart:io';
import '../models/photo.dart';
import '../theme/app_theme.dart';

class PhotoListItem extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(DismissDirection) onDismissed;
  final bool isSelected;
  final bool isReorderingMode;

  const PhotoListItem({
    Key? key,
    required this.photo,
    required this.onTap,
    required this.onLongPress,
    required this.onDismissed,
    this.isSelected = false,
    this.isReorderingMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('dismissible-${photo.id}'),
      direction: isReorderingMode ? DismissDirection.none : DismissDirection.startToEnd,
      onDismissed: onDismissed,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF2A3550), // Dark blue card background
          borderRadius: BorderRadius.circular(12.0),
          border: isSelected 
              ? Border.all(color: AppTheme.accentColor, width: 2.0)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isReorderingMode ? null : onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(12.0),
            child: Row(
              children: [
                if (isReorderingMode)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      Icons.drag_handle,
                      color: Colors.white.withAlpha(179),
                    ),
                  ),
                // Photo annotation (left side)
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      photo.annotation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Photo thumbnail (right side)
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 100, // Fixed height for the item
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12.0),
                        bottomRight: Radius.circular(12.0),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12.0),
                        bottomRight: Radius.circular(12.0),
                      ),
                      child: Image.file(
                        File(photo.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for triangle
class TrianglePainter extends CustomPainter {
  final Color color;
  
  TrianglePainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}