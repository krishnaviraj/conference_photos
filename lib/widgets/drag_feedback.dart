import 'package:flutter/material.dart';

// Custom widget to detect and provide feedback during drag operations
class DragFeedback extends StatefulWidget {
  final Widget child;
  final Function(DragUpdateDetails) onDragUpdate;

  const DragFeedback({
    Key? key,
    required this.child,
    required this.onDragUpdate,
  }) : super(key: key);

  @override
  State<DragFeedback> createState() => _DragFeedbackState();
}

class _DragFeedbackState extends State<DragFeedback> {
  // Add a timer to continuously update positions
  @override
  void initState() {
    super.initState();
    
    // Use post-frame callback to ensure we have render info
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }
  
  void _startListening() {
    // Use a delayed call to update position
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      // Get current pointer position and send it to the parent
      final RenderBox box = context.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      
      // Send update with current position
      widget.onDragUpdate(DragUpdateDetails(
        sourceTimeStamp: null,
        delta: Offset.zero,
        primaryDelta: 0,
        globalPosition: position,
        localPosition: Offset.zero,
      ));
      
      // Continue checking position
      _startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (details) {
        // Send immediate updates when pointer moves
        widget.onDragUpdate(DragUpdateDetails(
          sourceTimeStamp: null,
          delta: details.delta,
          primaryDelta: details.delta.dy,
          globalPosition: details.position,
          localPosition: details.localPosition,
        ));
        
        print('DragFeedback: Pointer at ${details.position}');
      },
      child: Material(
        elevation: 6.0,
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.purple, // Use a different color to make it obvious
              width: 3.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.purple.withOpacity(0.1),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}