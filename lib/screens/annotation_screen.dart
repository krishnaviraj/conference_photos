// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'dart:io';

class AnnotationScreen extends StatefulWidget {
  final String imagePath;
  final String talkTitle;

  const AnnotationScreen({
    Key? key,
    required this.imagePath,
    required this.talkTitle,
  }) : super(key: key);

  @override
  AnnotationScreenState createState() => AnnotationScreenState();
}

class AnnotationScreenState extends State<AnnotationScreen> {
  final TextEditingController _annotationController = TextEditingController();
  // Annotations are now optional, so we'll initialize _isValid to true
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    // We still keep the listener but it's no longer needed for validation
    // This allows us to update UI if needed when text changes
    _annotationController.addListener(() {
      // No need to update _isValid as it's always true now
    });
  }

  @override
  void dispose() {
    _annotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.talkTitle,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
            ),
          ),
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Annotate it',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _annotationController,
                  decoration: const InputDecoration(
                    labelText: 'Why is it interesting? (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Retake photo'),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: ElevatedButton(
                        // The button is now always enabled
                        onPressed: () {
                          Navigator.pop(
                            context,
                            {
                              'path': widget.imagePath,
                              'annotation': _annotationController.text.trim(),
                            },
                          );
                        },
                        child: const Text('Save photo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}