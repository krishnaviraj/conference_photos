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
import '../widgets/edit_talk_sheet.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/new_item_animator.dart';
import '../widgets/diagonal_animated_background.dart';

// Define the view modes as an enum
enum PhotoViewMode {
  sideBySide,
  fullWidth
}

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
  late Talk _currentTalk;
  bool _isLoading = true;
  String? _newPhotoId;

  // Add view mode state
  PhotoViewMode _viewMode = PhotoViewMode.sideBySide;

  final CameraService _cameraService = CameraService();

  bool _isReorderingMode = false;

  bool isSelected(String photoId) {
    return _selectedPhotos.contains(photoId);
  }

  @override
  void initState() {
    super.initState();
    _currentTalk = widget.talk; // Initialize with the talk passed from widget
    _loadPhotos();
    
    // Load saved view mode preference if you want to persist it
    _loadViewModePreference();
  }
  
  // Optional: Load view mode from shared preferences
  Future<void> _loadViewModePreference() async {
    // Implementation could go here if you want to save view mode preference
    // For now, we'll just use the default value (sideBySide)
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });
    
    final loadedPhotos = await widget.storageService.loadPhotos(widget.talk.id);
    
    if (mounted) {
      setState(() {
        photos = loadedPhotos;
        _isLoading = false;
      });
    }
  }

  void _launchCamera() async {
    if (!mounted) return;

    try {
      final imagePath = await _cameraService.captureImage();
      if (!mounted || imagePath == null) return;

      // Show loading indicator
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
            talkTitle: _currentTalk.name, // Use _currentTalk instead of widget.talk
          ),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context); // Remove loading indicator

      if (result != null) {
        final savedPath = await _cameraService.saveImageToTalkDirectory(
          _currentTalk.id, // Use _currentTalk instead of widget.talk
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
          _newPhotoId = photo.id; // Track the new photo
        });

        // Clear the new photo ID after a delay
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _newPhotoId = null;
            });
          }
        });

        await widget.storageService.savePhotos(_currentTalk.id, photos); // Use _currentTalk
        await widget.storageService.saveTalks(
          widget.allTalks.map((t) {
            if (t.id == _currentTalk.id) { // Use _currentTalk
              return t.updatePhotoCount(photos.length);
            }
            return t;
          }).toList(),
        );

        await _cameraService.deleteImage(imagePath);
        // Show confirmation with Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo saved'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Error handling
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
      context,
      SlideUpPageRoute(
        page: PhotoViewScreen(
          photo: photo,
          talkId: _currentTalk.id,
          storageService: widget.storageService,
          talkName: _currentTalk.name,
          presenterName: _currentTalk.presenter,
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

  // Toggle between view modes
  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == PhotoViewMode.sideBySide
          ? PhotoViewMode.fullWidth
          : PhotoViewMode.sideBySide;
    });
    
    // Optional: Save the preference
    _saveViewModePreference();
  }
  
  // Optional: Save view mode to shared preferences  
  Future<void> _saveViewModePreference() async {
    // Implementation could go here if you want to save view mode preference
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
        title: 'Delete photos',
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
        title: 'Delete group',
        message:
            'Are you sure you want to delete "${widget.talk.name}"? All photos in this group will be deleted. This cannot be undone.',
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
          content: Text('Failed to delete group'),
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

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 5, // Show 5 placeholder items
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (context, index) {
        return ShimmerLoading(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: const Color(0xFF2A3550),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Container(
              height: 100,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Placeholder for text
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: 140,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: 100,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ),
                  // Placeholder for image
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditTalkSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => EditTalkSheet(
        talk: _currentTalk,
        onUpdateTalk: (name, presenter) async {
          // Create updated talk
          final updatedTalk = _currentTalk.copyWith(
            name: name,
            presenter: presenter,
          );

          // Update in storage
          final updatedTalks = widget.allTalks.map((talk) {
            if (talk.id == _currentTalk.id) {
              return updatedTalk;
            }
            return talk;
          }).toList();
          
          await widget.storageService.saveTalks(updatedTalks);
          
          // Update local state immediately
          if (mounted) {
            setState(() {
              _currentTalk = updatedTalk;
            });
            
            // Show confirmation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Group updated successfully'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  // New method to build list item based on view mode
  Widget _buildPhotoItem(Photo photo, int index) {
    if (_viewMode == PhotoViewMode.sideBySide) {
      // Current side-by-side view
      return NewItemAnimator(
        isNew: photo.id == _newPhotoId,
        child: PhotoListItem(
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
        ),
      );
    } else {
      // Full width view with annotation below
      return NewItemAnimator(
        isNew: photo.id == _newPhotoId,
        child: Dismissible(
          key: Key('fullwidth-${photo.id}'),
          direction: DismissDirection.startToEnd,
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
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: const Color(0xFF2A3550),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: InkWell(
              onTap: () => _handlePhotoTap(photo.id),
              onLongPress: () => _handlePhotoLongPress(photo.id),
              borderRadius: BorderRadius.circular(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo on top (full width)
                  Container(
                    height: 200, // Adjust height as needed
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
                      ),
                      child: Image.file(
                        File(photo.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  
                  // Annotation below
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      photo.annotation.isEmpty ? 'No annotation' : photo.annotation,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontStyle: photo.annotation.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
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
  
  // Build reordering item based on view mode
  Widget _buildReorderingItem(Photo photo, int index) {
    if (_viewMode == PhotoViewMode.sideBySide) {
      // Side-by-side reordering view
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
    } else {
      // Full width reordering view
      return ReorderableDragStartListener(
        key: Key('reorder-fullwidth-${photo.id}'),
        index: index,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: const Color(0xFF2A3550),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle and image in a row
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      Icons.drag_handle,
                      color: Colors.white.withAlpha(179),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(
                          File(photo.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                ],
              ),
              
              // Annotation
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
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
            ],
          ),
        ),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return PopScope(
    canPop: !_isReorderingMode && _selectedPhotos.isEmpty,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        // If in reordering mode, cancel reordering
        if (_isReorderingMode) {
          _cancelReordering();
        } 
        // If items are selected, clear selection
        else if (_selectedPhotos.isNotEmpty) {
          setState(() {
            _selectedPhotos.clear();
          });
        }
      }
    },
    child: DiagonalAnimatedBackground(
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
                        _currentTalk.name,
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
                          if (_currentTalk.presenter != null) ...[
                            Text(
                              _currentTalk.presenter!,
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
                            DateFormatService.formatDate(_currentTalk.createdAt),
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
                  // View toggle button
                  IconButton(
                    icon: Icon(
                      _viewMode == PhotoViewMode.sideBySide
                          ? Icons.view_agenda_outlined // Icon for current side-by-side view
                          : Icons.featured_play_list_outlined, // Icon for current full-width view
                    ),
                    tooltip: 'Toggle view mode',
                    onPressed: _toggleViewMode,
                  ),
                  // Reorder button
                  IconButton(
                    icon: const Icon(Icons.swap_vert),
                    tooltip: 'Reorder photos',
                    onPressed: _toggleReorderingMode,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') _handleDeleteTalk();
                      if (value == 'edit') _showEditTalkSheet();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 8),
                              Text('Edit group details'),
                            ],
                          ),
                        ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline),
                            SizedBox(width: 8),
                            Text('Delete group'),
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
                       if (_selectedPhotos.length == 1)
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
                currentTalk: _currentTalk,
                allTalks: widget.allTalks,
                onTalkSelected: widget.onTalkSelected,
                onNewTalk: widget.onNewTalk,
                storageService: widget.storageService,
              ),
        body: GestureDetector(
          onTap: () {
            if (!_isReorderingMode && _selectedPhotos.isNotEmpty) _clearSelection();
          },
           child: _isLoading 
            ? _buildLoadingShimmer()
            : photos.isEmpty
                ? const EmptyTalkView()
                : _isReorderingMode
                  ? ReorderableListView.builder(
  onReorder: _handleReorder,
  itemCount: photos.length,
  padding: const EdgeInsets.only(bottom: 100),
  buildDefaultDragHandles: false, // Disable default drag handles
  itemBuilder: (context, index) {
    final photo = photos[index];
    return _buildReorderingItem(photo, index);
  },
)
                  : ListView.builder(
                      itemCount: photos.length,
                      padding: const EdgeInsets.only(bottom: 100),
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        
                        // Build different item based on view mode
                        if (_viewMode == PhotoViewMode.sideBySide) {
                          // Current side-by-side view
                          return NewItemAnimator(
                            isNew: photo.id == _newPhotoId,
                            child: PhotoListItem(
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
                            ),
                          );
                        } else {
                          // Full width view with annotation below
                          return NewItemAnimator(
                            isNew: photo.id == _newPhotoId,
                            child: Dismissible(
                              key: Key('fullwidth-${photo.id}'),
                              direction: DismissDirection.startToEnd,
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
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                color: const Color(0xFF2A3550),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: InkWell(
                                  onTap: () => _handlePhotoTap(photo.id),
                                  onLongPress: () => _handlePhotoLongPress(photo.id),
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Photo on top (full width)
                                      Container(
                                        height: 200, // Adjust height as needed
                                        width: double.infinity,
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12.0),
                                            topRight: Radius.circular(12.0),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12.0),
                                            topRight: Radius.circular(12.0),
                                          ),
                                          child: Image.file(
                                            File(photo.path),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                      ),
                                      
                                      // Annotation below
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          photo.annotation.isEmpty ? 'No annotation' : photo.annotation,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.0,
                                            fontStyle: photo.annotation.isEmpty ? FontStyle.italic : FontStyle.normal,
                                          ),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
        ),
        floatingActionButton: _isReorderingMode
          ? null
          : Hero(
              tag: 'camera-fab',
              child: FlowerShapedFab(
                onPressed: _launchCamera,
                icon: Icons.camera_alt,
                animate: photos.isEmpty, // Animate when no photos exist
              ),
            ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    ),
  );
}
}