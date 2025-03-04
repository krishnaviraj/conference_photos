import 'package:flutter/material.dart';
import 'dart:io';
import '../models/photo.dart';
import '../services/storage_service.dart';
import '../widgets/confirmation_dialog.dart';
import '../services/date_format_service.dart';
import '../theme/app_theme.dart';
import '../widgets/edit_annotation_sheet.dart';
import '../widgets/custom_fab.dart';
import '../utils/page_transitions.dart';

class PhotoViewScreen extends StatefulWidget {
  final Photo photo;
  final String talkId;
  final StorageService storageService;
  final VoidCallback? onPhotoDeleted;
  final Function(String)? onAnnotationUpdated;
  final String talkName;
  final String? presenterName;
  final Function(String, String?)? onTalkDetailsUpdated;

  const PhotoViewScreen({
    super.key,
    required this.photo,
    required this.talkId,
    required this.storageService,
    required this.talkName,
    this.presenterName,
    this.onPhotoDeleted,
    this.onAnnotationUpdated,
    this.onTalkDetailsUpdated,
  });

  @override
  State<PhotoViewScreen> createState() => PhotoViewScreenState();
}

class PhotoViewScreenState extends State<PhotoViewScreen> {
  late String _currentAnnotation;
  late String _currentTalkName;
  String? _currentPresenterName;

  @override
  void initState() {
    super.initState();
    _currentAnnotation = widget.photo.annotation;
    _currentTalkName = widget.talkName;
    _currentPresenterName = widget.presenterName;
  }

  Future<void> _editAnnotation() async {
    final editResult = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => EditAnnotationSheet(
        initialAnnotation: _currentAnnotation,
        onSave: (newAnnotation) {
          Navigator.pop(sheetContext, newAnnotation);
        },
      ),
    );

    if (!mounted || editResult == null) return;

    try {
      await widget.storageService.updatePhotoAnnotation(
        widget.talkId,
        widget.photo.id,
        editResult,
      );

      if (!mounted) return;
      
      // Notify parent of the update
      widget.onAnnotationUpdated?.call(editResult);

      setState(() {
        _currentAnnotation = editResult;
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annotation updated'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update annotation'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

   void updateTalkDetails(String name, String? presenter) {
  setState(() {
    _currentTalkName = name;
    _currentPresenterName = presenter;
  });
}

  void _deletePhoto() {
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            children: [
              Text(
                _currentTalkName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentPresenterName != null) ...[
                    Text(
                      _currentPresenterName!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(179),
                      ),
                    ),
                    Text(
                      " • ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(179),
                      ),
                    ),
                  ],
                  Text(
                    DateFormatService.formatDateTime(widget.photo.createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.white,
              onPressed: _deletePhoto,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Nothing to do here now
                },
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(widget.photo.path),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentAnnotation.isNotEmpty 
                          ? _currentAnnotation 
                          : "No annotation provided",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontStyle: _currentAnnotation.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                        fontWeight: _currentAnnotation.isNotEmpty ? FontWeight.normal : FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _editAnnotation,
                      tooltip: 'Edit annotation',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}