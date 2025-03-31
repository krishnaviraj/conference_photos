// ignore_for_file: use_super_parameters, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/talk.dart';
import '../widgets/empty_state_tile.dart';
import '../widgets/talk_card.dart';
import '../widgets/create_talk_sheet.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/contextual_app_bar.dart';
import '../screens/talk_view_screen.dart';
import '../services/storage_service.dart';
import '../mixins/undo_operation_mixin.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_fab.dart';
import '../utils/page_transitions.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/settings_screen.dart';
import '../widgets/edit_talk_sheet.dart';
import '../services/app_state_manager.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/new_item_animator.dart';
import '../widgets/diagonal_animated_background.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;

  const HomeScreen({
    Key? key,
    required this.storageService,
  }) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with UndoOperationMixin {
  List<Talk> talks = [];
  Map<String, Talk> _pendingDeletions = {}; // Track talks by their IDs
  Set<String> _selectedTalks = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = true;
  String? _newItemId;


  @override
void initState() {
  super.initState();
  
  // Check if we need to do a deep reload
  if (AppStateManager().needsDataReload) {
    debugPrint('HomeScreen detected pending reload flag');
    widget.storageService.hardReset().then((_) {
      _loadTalks();
      AppStateManager().clearReloadFlag();
      debugPrint('HomeScreen completed deep reload');
    });
  } else {
    // Normal loading
    _loadTalks();
  }
  
  // Still keep the post-frame callback
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadTalks();
  });
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  debugPrint("HomeScreen didChangeDependencies called - checking for data");
  // This will ensure data loads whenever the screen becomes visible again
  _loadTalks();
}

  Future<void> _loadTalks() async {
  try {
    setState(() {
      _isLoading = true;
    });
    
    debugPrint('Loading talks from storage...');
    final loadedTalks = await widget.storageService.loadTalks();
    debugPrint('Loaded ${loadedTalks.length} talks from storage');
    
    if (mounted) {
      setState(() {
        talks = loadedTalks;
        _isLoading = false;
      });
    }
  } catch (e) {
    debugPrint('Error loading talks: $e');
    // Show an error message if something goes wrong
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

  void _showCreateTalkSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => CreateTalkSheet(
        onCreateTalk: (name, presenter) async {
          // Create the talk
          final talk = Talk(
            id: DateTime.now().toString(),
            name: name,
            presenter: presenter,
            createdAt: DateTime.now(),
          );

          // Update local state and storage
          setState(() {
            talks.add(talk);
            _newItemId = talk.id; // Track the new item
          });
          await widget.storageService.saveTalks(talks);

          // Clear the new item ID after a delay
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _newItemId = null;
            });
          }
        });

          if (!mounted) return;

          // Use the same navigation method we use for existing talks
          _navigateToTalkView(talk);
        },
      ),
    );
  }

  void _navigateToTalkView(Talk talk) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TalkViewScreen(
          talk: talk,
          allTalks: talks,
          onTalkSelected: _navigateToTalkView,
          onNewTalk: _showCreateTalkSheet,
          storageService: widget.storageService,
        ),
      ),
    ).then((_) {
      // Reload talks when returning from TalkViewScreen
      if (mounted) {
        _loadTalks();
      }
    });
  }

  void _handleTalkLongPress(String talkId) {
    setState(() {
      if (_selectedTalks.contains(talkId)) {
        _selectedTalks.remove(talkId);
      } else {
        _selectedTalks.add(talkId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedTalks.clear();
    });
  }

  void _deleteSelectedTalks() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Talks',
        message: 'Are you sure you want to delete ${_selectedTalks.length} talks? This cannot be undone.',
        onConfirm: () async {
          final talksToDelete = talks.where((t) => _selectedTalks.contains(t.id)).toList();
          setState(() {
            talks.removeWhere((t) => _selectedTalks.contains(t.id));
            _selectedTalks.clear();
          });

          for (final talk in talksToDelete) {
            await widget.storageService.deleteTalk(talk.id);
          }
        },
      ),
    );
  }

  void _showEditTalkSheet(Talk talk) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (bottomSheetContext) => EditTalkSheet(
      talk: talk,
      onUpdateTalk: (name, presenter) async {
        // Update the talk
        final updatedTalk = talk.copyWith(
          name: name,
          presenter: presenter,
        );
        
        // Update local state
        setState(() {
          final index = talks.indexWhere((t) => t.id == talk.id);
          if (index != -1) {
            talks[index] = updatedTalk;
          }
          _selectedTalks.clear(); // Clear selection after editing
        });
        
        // Update storage
        await widget.storageService.saveTalks(talks);
        
        // Show confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Talk updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    ),
  );
}

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  void _handleTalkTap(Talk talk) {
  // If already in selection mode, toggle selection instead of navigating
  if (_selectedTalks.isNotEmpty) {
    setState(() {
      if (_selectedTalks.contains(talk.id)) {
        _selectedTalks.remove(talk.id);
      } else {
        _selectedTalks.add(talk.id);
      }
    });
  } else {
    // Normal navigation when not in selection mode
    _navigateToTalkView(talk);
  }
}

void forceReloadData() async {
  setState(() {
    talks = []; // Clear current data
  });
  await _loadTalks(); // Reload from storage
}

Widget _buildLoadingShimmer() {
  return ListView.builder(
    itemCount: 4, // Show 4 placeholder items
    padding: const EdgeInsets.symmetric(vertical: 8),
    itemBuilder: (context, index) {
      return ShimmerLoading(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 0,
          color: const Color(0xFF2A3550),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title placeholder
                Container(
                  height: 24,
                  width: 180,
                  color: Colors.white.withOpacity(0.1),
                ),
                const SizedBox(height: 12),
                // Presenter name placeholder (optional)
                if (index % 2 == 0) // Show for some cards
                  Container(
                    height: 18,
                    width: 140,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white.withOpacity(0.1),
                  ),
                // Info row placeholder
                Container(
                  height: 16,
                  width: 200,
                  color: Colors.white.withOpacity(0.1),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Static method to access this from anywhere
static void reloadHomeScreen(BuildContext context) {
  final homeScreenState = context.findAncestorStateOfType<HomeScreenState>();
  homeScreenState?.forceReloadData();
}

@override
Widget build(BuildContext context) {
  return PopScope(
    // Only allow pop if no items are selected
    canPop: _selectedTalks.isEmpty,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        // If talks are selected, clear selection instead of exiting
        setState(() {
          _selectedTalks.clear();
        });
      }
    },
    child: DiagonalAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _selectedTalks.isEmpty
            ? AppBar(
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search for something...',
                          hintStyle: TextStyle(color: Colors.white.withAlpha(179)),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                        autofocus: true,
                      )
                    : Align(
  alignment: Alignment.centerLeft,
  child: SvgPicture.asset(
    'assets/logo/mosaic_logo.svg', // Use icon-only version
    height: 40,
  ),
),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                   if (_isSearching)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _toggleSearch,
                      ),
                    if (!_isSearching)
                      IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: 'Settings',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(storageService: widget.storageService),
                            ),
                          ).then((_) {
                            // Reload talks when returning from Settings - same pattern as TalkViewScreen
                            if (mounted) {
                              debugPrint('Returning from settings screen, reloading talks');
                              _loadTalks();
                            }
                          });
                        },
                      ),
                ],
              )
            : ContextualAppBar(
                title: '${_selectedTalks.length} selected',
                backgroundColor: Colors.grey[800]!,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                ),
                actions: [
                  // Only show edit when a single talk is selected
                  if (_selectedTalks.length == 1)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        final talkId = _selectedTalks.first;
                        final talk = talks.firstWhere((t) => t.id == talkId);
                        _showEditTalkSheet(talk);
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteSelectedTalks,
                  ),
                ],
              ),
        body: _isLoading
    ? _buildLoadingShimmer()
    : talks.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                    // App logo container (replace with actual logo)
                     SvgPicture.asset(
                        'assets/images/home_empty.svg',
                        width: 100,
                        height: 100,
                        semanticsLabel: 'Empty home illustration',
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Create a group to get started',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: talks.length,
                      itemBuilder: (context, index) {
                        final talk = talks[index];
                        return Dismissible(
                          key: Key(talk.id),
                          direction: DismissDirection.startToEnd,
                          onDismissed: (direction) async {
                            final deletedTalkId = talk.id;
                            setState(() {
                              talks.removeAt(index);
                              _pendingDeletions[deletedTalkId] = talk;
                            });

                            showUndoSnackBar(
                              message: 'Talk deleted',
                              onUndo: () {
                                setState(() {
                                  if (_pendingDeletions.containsKey(deletedTalkId)) {
                                    talks.insert(index, _pendingDeletions[deletedTalkId]!);
                                    _pendingDeletions.remove(deletedTalkId);
                                  }
                                });
                              },
                              onDismissed: () async {
                                if (_pendingDeletions.containsKey(deletedTalkId)) {
                                  await widget.storageService.deleteTalk(_pendingDeletions[deletedTalkId]!.id);
                                  _pendingDeletions.remove(deletedTalkId);
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
                          child: NewItemAnimator(
                            isNew: talk.id == _newItemId,
                            child: TalkCard(
                              talk: talk,
                              onTap: () => _handleTalkTap(talk),
                              onLongPress: () => _handleTalkLongPress(talk.id),
                              isSelected: _selectedTalks.contains(talk.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
        floatingActionButton: Hero(
          tag: 'camera-fab',
          child: FlowerShapedFab(
            onPressed: _showCreateTalkSheet,
            icon: Icons.add,
            animate: talks.isEmpty, // Animate when no talks exist
          ),
        ),
      ),
    ),
  );
}
}