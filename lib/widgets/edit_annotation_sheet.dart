import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EditAnnotationSheet extends StatefulWidget {
  final String initialAnnotation;
  final Function(String) onSave;

  const EditAnnotationSheet({
    super.key,
    required this.initialAnnotation,
    required this.onSave,
  });

  @override
  State<EditAnnotationSheet> createState() => _EditAnnotationSheetState();
}

class _EditAnnotationSheetState extends State<EditAnnotationSheet> {
  late TextEditingController _annotationController;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _annotationController = TextEditingController(text: widget.initialAnnotation);
    _annotationController.addListener(_validateInput);
  }

  void _validateInput() {
    // Always valid - annotations are now optional
    setState(() {
      _isValid = true;
    });
  }

  @override
  void dispose() {
    _annotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16.0,
        right: 16.0,
        top: 24.0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit annotation',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          TextField(
            controller: _annotationController,
            decoration: InputDecoration(
              labelText: 'Why is it interesting?',
              labelStyle: const TextStyle(color: Colors.black54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade500),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(color: Colors.black87),
            maxLines: 5,
            autofocus: true,
          ),
          const SizedBox(height: 24.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black54,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _isValid
                    ? () {
                        final newAnnotation = _annotationController.text.trim();
                        Navigator.pop(context, newAnnotation);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}