// ignore_for_file: use_super_parameters, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';

import '../mixins/undo_operation_mixin.dart';
import '../models/photo.dart';
import '../models/talk.dart';
import '../screens/annotation_screen.dart';
import '../screens/home_screen.dart';
import '../screens/photo_view_screen.dart';
import '../services/camera_service.dart';
import '../services/date_format_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/edit_annotation_sheet.dart';
import '../widgets/empty_talk_view.dart';
import '../widgets/photo_list_item.dart';
import '../widgets/talk_menu.dart';
import '../widgets/custom_fab.dart';
import '../utils/page_transitions.dart';

class TalkViewScreen extends StatefulWidget {
  final Talk talk;
  final List<Talk> allTalks;
  final Function(Talk) onTalkSelected;
  final VoidCallback onNewTalk;
  final StorageService storageService;

  const TalkViewScreen({
    Key? key,
    required this.talk,
    required this.allTalks,
    required this.onTalkSelected,
    required this.onNewTalk,
    required this.storageService,
  }) : super(key: key);

  @override
  TalkViewScreenState createState() => TalkViewScreenState();
}

class TalkViewScreenState extends State<TalkViewScreen> with UndoOperationMixin {
  List<Photo> photos = [];
  List<Photo> _originalPhotoOrder = [];
  final Map<String, Photo> _pendingDeletions = {}; // Track photos by their IDs
  final Set<String> _selectedPhotos = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final CameraService _cameraService = CameraService();

  bool _isReorderingMode = false;

  bool isSelected(String photoId) {
    return _selectedPhotos.contains(photoId);
  }

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final loadedPhotos = await widget.storageService.loadPhotos(widget.talk.id);
    setState(() {
      photos = loadedPhotos;
    });
  }

  void _launchCamera() async {
    if (!mounted) return;

    try {
      final imagePath = await _cameraService.captureImage();
      if (!mounted || imagePath == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await Navigator.push<Map<String, String>>(
        context,
        MaterialPageRoute(
          builder: (context) => AnnotationScreen(
            imagePath: imagePath,
            talkTitle: widget.talk.name,
          ),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context); // Remove loading indicator

      if (result != null) {
        final savedPath = await _cameraService.saveImageToTalkDirectory(
          widget.talk.id,
          File(imagePath),
        );

        final photo = Photo(
          id: DateTime.now().toString(),
          path: savedPath,
          annotation: result['annotation']!,
          createdAt: DateTime.now(),
        );

        setState(() {
          photos.add(photo);
        });

        await widget.storageService.savePhotos(widget.talk.id, photos);
        await widget.storageService.saveTalks(
          widget.allTalks.map((t) {
            if (t.id == widget.talk.id) {
              return t.updatePhotoCount(photos.length);
            }
            return t;
          }).toList(),
        );

        await _cameraService.deleteImage(imagePath);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture image')),
      );
    }
  }

  void _handlePhotoTap(String photoId) {
    if (_selectedPhotos.isNotEmpty) {
      setState(() {
        if (_selectedPhotos.contains(photoId)) {
          _selectedPhotos.remove(photoId);
        } else {
          _selectedPhotos.add(photoId);
        }
      });
      return;
    }

    final photo = photos.firstWhere((p) => p.id == photoId);
    Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => PhotoViewScreen(
    //       photo: photo,
    //       talkId: widget.talk.id,
    //       storageService: widget.storageService,
    //       talkName: widget.talk.name,
    //       presenterName: widget.talk.presenter,
    //       onPhotoDeleted: () {
    //         setState(() {
    //           photos.removeWhere((p) => p.id == photoId);
    //         });
    //       },
    //       onAnnotationUpdated: (newAnnotation) {
    //         setState(() {
    //           final index = photos.indexWhere((p) => p.id == photoId);
    //           if (index != -1) {
    //             photos[index] = photos[index].copyWith(annotation: newAnnotation);
    //           }
    //         });
    //       },
    //     ),
    //   ),
    // );
     context,
      SlideUpPageRoute(
        page: PhotoViewScreen(
          photo: photo,
          talkId: widget.talk.id,
          storageService: widget.storageService,
          talkName: widget.talk.name,
          presenterName: widget.talk.presenter,
          onPhotoDeleted: () {
            setState(() {
              photos.removeWhere((p) => p.id == photoId);
            });
          },
          onAnnotationUpdated: (newAnnotation) {
            setState(() {
              final index = photos.indexWhere((p) => p.id == photoId);
              if (index != -1) {
                photos[index] = photos[index].copyWith(annotation: newAnnotation);
              }
            });
          },
        ),
      ),
    );
  }

  void _handlePhotoLongPress(String photoId) {
    if (_isReorderingMode) return;
    setState(() {
      if (_selectedPhotos.contains(photoId)) {
        _selectedPhotos.remove(photoId);
      } else {
        _selectedPhotos.add(photoId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPhotos.clear();
    });
  }

  Future<void> _editSelectedPhoto() async {
    if (_selectedPhotos.length != 1) return;

    final photoId = _selectedPhotos.first;
    final photo = photos.firstWhere((p) => p.id == photoId);

    final editResult = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => EditAnnotationSheet(
        initialAnnotation: photo.annotation,
        onSave: (newAnnotation) {
          Navigator.pop(sheetContext, newAnnotation);
        },
      ),
    );

    if (!mounted || editResult == null) return;

    try {
      await widget.storageService.updatePhotoAnnotation(
        widget.talk.id,
        photo.id,
        editResult,
      );

      setState(() {
        final index = photos.indexWhere((p) => p.id == photoId);
        if (index != -1) {
          photos[index] = photos[index].copyWith(annotation: editResult);
        }
        _selectedPhotos.clear();
      });

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

  void _deleteSelectedPhotos() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Photos',
        message: 'Are you sure you want to delete ${_selectedPhotos.length} photos? This cannot be undone.',
        onConfirm: () async {
          final photosToDelete = photos.where((p) => _selectedPhotos.contains(p.id)).toList();
          setState(() {
            photos.removeWhere((p) => _selectedPhotos.contains(p.id));
            _selectedPhotos.clear();
          });

          for (final photo in photosToDelete) {
            await widget.storageService.deletePhoto(widget.talk.id, photo);
          }
        },
      ),
    );
  }

  Future<void> _handleDeleteTalk() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Talk',
        message:
            'Are you sure you want to delete "${widget.talk.name}"? All photos in this talk will be deleted. This cannot be undone.',
        onConfirm: () {
          Navigator.of(context).pop(true);
        },
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await widget.storageService.deleteTalk(widget.talk.id);

      if (!mounted) return;
      Navigator.of(context).pop(); // Pop loading dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(storageService: widget.storageService),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Pop loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete talk'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleReorderingMode() {
    setState(() {
      if (!_isReorderingMode) {
        // Entering reordering mode - store original order
        _originalPhotoOrder = List.from(photos);
      }
      
      _isReorderingMode = !_isReorderingMode;
      // Clear selections when entering reordering mode
      if (_isReorderingMode) {
        _selectedPhotos.clear();
      }
    });
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = photos.removeAt(oldIndex);
      photos.insert(newIndex, item);
    });
  }

  // Add this new method to cancel reordering:
  void _cancelReordering() {
    setState(() {
      // Restore original order
      photos = List.from(_originalPhotoOrder);
      _isReorderingMode = false;
    });
    
    // Notify the user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reordering cancelled'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  //confirm and save reordering:
  void _confirmReordering() async {
    // Save the current order to storage
    await widget.storageService.savePhotos(widget.talk.id, photos);
    
    setState(() {
      _isReorderingMode = false;
      // Clear the original order reference since we've saved the new order
      _originalPhotoOrder.clear();
    });
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo order updated'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isReorderingMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _cancelReordering();
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          appBar: _selectedPhotos.isEmpty && !_isReorderingMode
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  title: Center(
                    child: Column(
                      children: [
                        Text(
                          widget.talk.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.talk.presenter != null) ...[
                              Text(
                                widget.talk.presenter!,
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
                              DateFormatService.formatDate(widget.talk.createdAt),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withAlpha(179),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    // Reorder button
                    IconButton(
                      icon: const Icon(Icons.swap_vert),
                      tooltip: 'Reorder photos',
                      onPressed: _toggleReorderingMode,
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') _handleDeleteTalk();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline),
                              SizedBox(width: 8),
                              Text('Delete talk'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : _isReorderingMode
                  ? AppBar(
                      backgroundColor: Colors.grey[800],
                      title: const Text('Reorder photos'),
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _cancelReordering, 
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.check),
                          tooltip: 'Done reordering',
                          onPressed: _confirmReordering, 
                        ),
                      ],
                    )
                  : AppBar(
                      title: Text('${_selectedPhotos.length} selected'),
                      backgroundColor: Colors.grey[800]!,
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _clearSelection,
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _editSelectedPhoto,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: _deleteSelectedPhotos,
                        ),
                      ],
                    ),
          drawer: _isReorderingMode
              ? null
              : TalkMenu(
                  currentTalk: widget.talk,
                  allTalks: widget.allTalks,
                  onTalkSelected: widget.onTalkSelected,
                  onNewTalk: widget.onNewTalk,
                ),
          body: GestureDetector(
            onTap: () {
              if (!_isReorderingMode && _selectedPhotos.isNotEmpty) _clearSelection();
            },
            child: photos.isEmpty
                ? const EmptyTalkView()
                : _isReorderingMode
                    ? ReorderableListView.builder(
                        onReorder: _handleReorder,
                        itemCount: photos.length,
                        padding: const EdgeInsets.only(bottom: 100),
                        buildDefaultDragHandles: false, // Disable default drag handles
                        itemBuilder: (context, index) {
                          final photo = photos[index];
                          return ReorderableDragStartListener(
                            key: Key('reorder-${photo.id}'),
                            index: index,
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              color: const Color(0xFF2A3550),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Icon(
                                      Icons.drag_handle,
                                      color: Colors.white.withAlpha(179),
                                    ),
                                  ),
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
                                  Expanded(
                                    flex: 3,
                                    child: SizedBox(
                                      height: 100,
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(12.0),
                                          bottomRight: Radius.circular(12.0),
                                        ),
                                        child: Image.file(
                                          File(photo.path),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        itemCount: photos.length,
                        padding: const EdgeInsets.only(bottom: 100),
                        itemBuilder: (context, index) {
                          final photo = photos[index];
                          return PhotoListItem(
                            key: Key('regular-${photo.id}'),
                            photo: photo,
                            isSelected: _selectedPhotos.contains(photo.id),
                            onTap: () => _handlePhotoTap(photo.id),
                            onLongPress: () => _handlePhotoLongPress(photo.id),
                            onDismissed: (direction) async {
                              final deletedPhotoId = photo.id;
                              setState(() {
                                photos.removeAt(index);
                                _pendingDeletions[deletedPhotoId] = photo;
                              });

                              showUndoSnackBar(
                                message: 'Photo deleted',
                                onUndo: () {
                                  setState(() {
                                    if (_pendingDeletions.containsKey(deletedPhotoId)) {
                                      photos.insert(index, _pendingDeletions[deletedPhotoId]!);
                                      _pendingDeletions.remove(deletedPhotoId);
                                    }
                                  });
                                },
                                onDismissed: () async {
                                  if (_pendingDeletions.containsKey(deletedPhotoId)) {
                                    await widget.storageService.deletePhoto(
                                      widget.talk.id,
                                      _pendingDeletions[deletedPhotoId]!,
                                    );
                                    _pendingDeletions.remove(deletedPhotoId);
                                  }
                                },
                              );
                            },
                            isReorderingMode: false,
                          );
                        },
                      ),
          ),
          floatingActionButton: _isReorderingMode
              // ? null
              // : Container(
              //     width: 72,
              //     height: 72,
              //     decoration: BoxDecoration(
              //       shape: BoxShape.circle,
              //       color: AppTheme.accentColor,
              //       boxShadow: [
              //         BoxShadow(
              //           color: Colors.black.withAlpha(51),
              //           blurRadius: 8,
              //           offset: const Offset(0, 3),
              //         ),
              //       ],
              //     ),
              //     child: IconButton(
              //       onPressed: _launchCamera,
              //       icon: const Icon(
              //         Icons.camera_alt,
              //         color: AppTheme.primaryColor,
              //         size: 32,
              //       ),
              //     ),
              //   ),
              ? null
              : Hero(
                  tag: 'camera-fab',
                  child: FlowerShapedFab(
                    onPressed: _launchCamera,
                    icon: Icons.camera_alt,
                  ),
                ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }
}