import 'package:flutter/material.dart';
import 'dart:io';
import '../models/photo.dart';
import '../services/storage_service.dart';
import '../widgets/confirmation_dialog.dart';
import '../services/date_format_service.dart';

class PhotoViewScreen extends StatefulWidget {
  final Photo photo;
  final String talkId;
  final StorageService storageService;
  final VoidCallback? onPhotoDeleted;
  final Function(String)? onAnnotationUpdated;

  const PhotoViewScreen({
    super.key,
    required this.photo,
    required this.talkId,
    required this.storageService,
    this.onPhotoDeleted,
    this.onAnnotationUpdated,
  });

  @override
  State<PhotoViewScreen> createState() => PhotoViewScreenState();
}

class PhotoViewScreenState extends State<PhotoViewScreen> {
  bool _isEditing = false;
  late TextEditingController _annotationController;
  String? _errorText;
  late String _currentAnnotation;

  @override
  void initState() {
    super.initState();
    _currentAnnotation = widget.photo.annotation;
    _annotationController = TextEditingController(text: _currentAnnotation);
  }

  @override
  void dispose() {
    _annotationController.dispose();
    super.dispose();
  }

  Future<void> _saveAnnotation() async {
    final newAnnotation = _annotationController.text.trim();

    await widget.storageService.updatePhotoAnnotation(
      widget.talkId,
      widget.photo.id,
      newAnnotation,
    );

    if (!mounted) return;

    // Notify parent of the update
    widget.onAnnotationUpdated?.call(newAnnotation);

    setState(() {
      _currentAnnotation = newAnnotation;
      _isEditing = false;
      _errorText = null;
    });

    // Show success message
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Annotation updated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _errorText = null;
      _annotationController.text = _currentAnnotation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ConfirmationDialog(
                  title: 'Delete Photo',
                  message: 'Are you sure you want to delete this photo? This cannot be undone.',
                  onConfirm: () async {
                    await widget.storageService.deletePhoto(widget.talkId, widget.photo);
                    widget.onPhotoDeleted?.call();
                    if (!mounted) return;
                    Navigator.of(context).pop(); // Pop the photo view
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(widget.photo.path),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isEditing
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _annotationController,
                              decoration: InputDecoration(
                                labelText: 'Edit annotation',
                                errorText: _errorText,
                                border: const OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              autofocus: true,
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _cancelEditing,
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                ElevatedButton(
                                  onPressed: _saveAnnotation,
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _currentAnnotation,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                              tooltip: 'Edit annotation',
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  DateFormatService.formatDateTime(widget.photo.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}