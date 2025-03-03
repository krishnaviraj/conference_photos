import 'package:flutter/material.dart';

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
        top: 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit annotation',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          TextField(
            controller: _annotationController,
            decoration: const InputDecoration(
              labelText: 'Why is it interesting?',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          const SizedBox(height: 24.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton(
                onPressed: _isValid
                    ? () {
                        final newAnnotation = _annotationController.text.trim();
                        Navigator.pop(context, newAnnotation);
                      }
                    : null,
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}